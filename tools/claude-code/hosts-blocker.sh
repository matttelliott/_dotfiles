#!/usr/bin/env bash
# PreToolUse hook: block modifications to /etc/hosts.
#
# Reads a JSON payload on stdin:
#   { "tool_name": "...", "tool_input": { ... }, ... }
#
# Blocks:
#   Edit/Write/MultiEdit with file_path == /etc/hosts (or /private/etc/hosts)
#   Bash commands that would modify /etc/hosts (redirects, known writers)
#
# Exit codes:
#   0 - allow
#   2 - block (stderr shown to Claude)

payload=$(cat)
tool_name=$(printf '%s' "$payload" | jq -r '.tool_name // ""')

block() {
	printf '%s\n' "Blocked: modifying /etc/hosts is not allowed by policy." >&2
	exit 2
}

case "$tool_name" in
Edit | Write | MultiEdit)
	fp=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""')
	case "$fp" in
	/etc/hosts | /private/etc/hosts) block ;;
	esac
	exit 0
	;;
Bash)
	cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')
	[ -z "$cmd" ] && exit 0

	# Quick exit: if /etc/hosts isn't mentioned, allow.
	case "$cmd" in
	*"/etc/hosts"*) ;;
	*) exit 0 ;;
	esac

	# Pattern A: redirect to /etc/hosts (> or >>, any fd).
	if printf '%s' "$cmd" | grep -Eq '>>?[[:space:]]*(/private)?/etc/hosts([^A-Za-z0-9._/-]|$)'; then
		block
	fi

	# Pattern B: dd of=/etc/hosts
	if printf '%s' "$cmd" | grep -Eq '\bdd\b.*\bof=(/private)?/etc/hosts([^A-Za-z0-9._/-]|$)'; then
		block
	fi

	# Pattern C: known writer command with /etc/hosts as argument in the same segment.
	# Interpreters (python/perl/ruby/...) are intentionally excluded: can't tell
	# read from write without parsing their scripts, and user asked to allow reads.
	writers='^(tee|sed|awk|cp|mv|rm|chmod|chown|chgrp|install|ln|touch|truncate|dd|patch|vim|vi|nvim|nano|emacs|ed|ex|micro|hx|kak|code|subl|gedit|pico|mg|joe|jed)$'

	# Split on shell separators and inspect every sub-command.
	# Includes ( ) ` so $(...), `...`, and (...) cannot bypass.
	# bash 3.2 (macOS) has no mapfile; use while-read with a heredoc.
	segments_raw=$(printf '%s' "$cmd" |
		tr ';&|()`{}<>\n' '\n' |
		sed -E 's/^[[:space:]]*//; s/[[:space:]]*$//' |
		grep -v '^$')

	while IFS= read -r seg; do
		[ -z "$seg" ] && continue

		# Only care if this segment touches the exact /etc/hosts path.
		if ! printf '%s' "$seg" | grep -Eq '(/private)?/etc/hosts([^A-Za-z0-9._/-]|$)'; then
			continue
		fi

		# Strip leading env-var assignments.
		s=$(printf '%s' "$seg" | sed -E 's/^([A-Za-z_][A-Za-z0-9_]*=[^ ]* +)+//')
		# Strip wrappers repeatedly (e.g. `sudo env tee ...`).
		while :; do
			prev="$s"
			s=$(printf '%s' "$s" | sed -E 's/^(sudo|doas|command|exec|nohup|time|builtin|env|xargs|eval) +//')
			[ "$s" = "$prev" ] && break
		done

		first=$(printf '%s' "$s" | awk '{print $1}')
		first_base="${first##*/}"

		if printf '%s' "$first_base" | grep -Eq "$writers"; then
			block
		fi
	done <<EOF
$segments_raw
EOF
	exit 0
	;;
*)
	exit 0
	;;
esac
