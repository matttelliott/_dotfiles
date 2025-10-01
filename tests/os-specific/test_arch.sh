#!/usr/bin/env bash
# Arch Linux-specific Testing Script

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

echo "🏔️  Arch Linux Specific Tests"
echo "================================"
echo ""

# Check if running on Arch Linux
if [ ! -f /etc/arch-release ]; then
    echo -e "${YELLOW}⚠️  Not running on Arch Linux - skipping tests${NC}"
    exit 0
fi

echo "OS: Arch Linux"
echo "Kernel: $(uname -r)"
echo ""

run_test() {
    local test_name=$1
    local test_command=$2

    ((TOTAL_TESTS++))
    echo -n "Testing: $test_name... "

    if eval "$test_command" &> /dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((FAILED_TESTS++))
        return 1
    fi
}

echo "📦 Pacman Tests"
echo "---------------"

# Test: Pacman is working
run_test "Pacman package manager is functional" "pacman --version"

# Test: Package database is synchronized (warning only)
if [ -d /var/lib/pacman/sync ]; then
    newest_db=$(find /var/lib/pacman/sync -name '*.db' -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    if [ -n "$newest_db" ]; then
        db_age=$(($(date +%s) - $(stat -c %Y "$newest_db")))
        if [ $db_age -gt 604800 ]; then  # 7 days
            echo -e "${YELLOW}⚠️  Pacman database is older than 7 days (run pacman -Sy)${NC}"
        fi
    fi
fi

# Test: Required packages are installed
run_test "base-devel group is installed" "pacman -Qg base-devel"
run_test "git is installed via pacman" "pacman -Q git"
run_test "zsh is installed via pacman" "pacman -Q zsh"
run_test "tmux is installed via pacman" "pacman -Q tmux"
run_test "neovim is installed via pacman" "pacman -Q neovim"

echo ""
echo "🔧 AUR Helper Tests"
echo "-------------------"

# Test: AUR helper is installed (yay or paru)
if command -v yay &> /dev/null; then
    run_test "yay (AUR helper) is installed" "command -v yay"
    run_test "yay is functional" "yay --version"
elif command -v paru &> /dev/null; then
    run_test "paru (AUR helper) is installed" "command -v paru"
    run_test "paru is functional" "paru --version"
else
    echo -e "${YELLOW}⚠️  No AUR helper found (yay or paru recommended)${NC}"
fi

echo ""
echo "👤 User and Shell Tests"
echo "------------------------"

# Test: User shell is zsh
run_test "User shell is /bin/zsh or /usr/bin/zsh" \
    "[ \"$(getent passwd $USER | cut -d: -f7)\" = \"/bin/zsh\" ] || \
     [ \"$(getent passwd $USER | cut -d: -f7)\" = \"/usr/bin/zsh\" ]"

# Test: zsh is in /etc/shells
run_test "zsh is listed in /etc/shells" "grep -q '/bin/zsh\|/usr/bin/zsh' /etc/shells"

echo ""
echo "🔐 System Tests"
echo "---------------"

# Test: System is up to date check (informational)
outdated=$(pacman -Qu 2>/dev/null | wc -l)
if [ "$outdated" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  $outdated packages can be updated${NC}"
else
    echo -e "${GREEN}✓ System is up to date${NC}"
fi

# Test: Important system files
run_test "Pacman mirror list exists" "[ -f /etc/pacman.d/mirrorlist ]"
run_test "Pacman configuration exists" "[ -f /etc/pacman.conf ]"

echo ""
echo "⚡ Performance Tests"
echo "--------------------"

# Test: Parallel downloads enabled (Arch specific feature)
if grep -q "^ParallelDownloads" /etc/pacman.conf; then
    run_test "Pacman parallel downloads is enabled" "grep -q '^ParallelDownloads' /etc/pacman.conf"
else
    echo -e "${YELLOW}⚠️  Parallel downloads not enabled (can speed up updates)${NC}"
fi

# Test: Color output enabled
run_test "Pacman color output is enabled" "grep -q '^Color' /etc/pacman.conf"

echo ""
echo "🌐 Network Tests"
echo "----------------"

# Test: Can reach Arch mirrors
run_test "Can reach Arch Linux mirrors" \
    "timeout 5 curl -s https://archlinux.org > /dev/null"

echo ""
echo "================================"
echo "📊 Arch Linux Test Summary:"
echo "  Total tests: $TOTAL_TESTS"
echo -e "  ${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "  ${RED}Failed: $FAILED_TESTS${NC}"
echo "================================"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✅ All Arch Linux tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi
