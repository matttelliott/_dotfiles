---
created: 2026-01-20T16:06
title: Sort tmux sessions alphabetically
area: config
files:
  - tools/tmux/tmux.conf.j2
---

## Problem

Currently tmux session list is not sorted, making it harder to find specific sessions when you have many open. Sessions appear in creation order or arbitrary order.

## Solution

Add tmux configuration to sort session list alphabetically (A-Z). This likely involves tmux display/menu settings or a custom key binding that displays sessions in sorted order.

Research tmux options for:
- Session list display sorting
- Custom session chooser with sort
- Potential hook or script integration
