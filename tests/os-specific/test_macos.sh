#!/usr/bin/env bash
# macOS-specific Testing Script

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

echo "🍎 macOS Specific Tests"
echo "================================"
echo ""

# Check if running on macOS
if [ "$(uname)" != "Darwin" ]; then
    echo -e "${YELLOW}⚠️  Not running on macOS - skipping tests${NC}"
    exit 0
fi

echo "OS: $(sw_vers -productName) $(sw_vers -productVersion)"
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

echo "🍺 Homebrew Tests"
echo "-----------------"

# Test: Homebrew is installed
run_test "Homebrew is installed" "command -v brew"

# Test: Homebrew is up to date
if command -v brew &> /dev/null; then
    run_test "Homebrew is functional" "brew --version"

    # Check Homebrew health
    echo "Running brew doctor (this may take a moment)..."
    if brew doctor &> /tmp/brew_doctor.log; then
        echo -e "${GREEN}✓ Homebrew health check passed${NC}"
    else
        echo -e "${YELLOW}⚠️  Homebrew has warnings (see /tmp/brew_doctor.log)${NC}"
    fi
fi

echo ""
echo "📦 Formula Tests"
echo "----------------"

# Test: Required formulas are installed
if command -v brew &> /dev/null; then
    run_test "zsh installed via Homebrew" "brew list zsh"
    run_test "tmux installed via Homebrew" "brew list tmux"
    run_test "neovim installed via Homebrew" "brew list neovim"
    run_test "git installed via Homebrew" "brew list git"
fi

echo ""
echo "🎨 Cask Tests"
echo "-------------"

# Test: Casks are functional (if any GUI apps installed)
if command -v brew &> /dev/null; then
    run_test "Homebrew Cask is available" "brew --cask --version"
fi

echo ""
echo "👤 User and Shell Tests"
echo "------------------------"

# Test: User shell is zsh
run_test "Default shell is zsh" "[ \"$SHELL\" = \"/bin/zsh\" ] || [ \"$SHELL\" = \"$(brew --prefix)/bin/zsh\" ]"

# Test: Shell in /etc/shells
if [ -f /etc/shells ]; then
    run_test "Zsh is in /etc/shells" "grep -q $(which zsh) /etc/shells"
fi

echo ""
echo "🔑 macOS Specific Features"
echo "--------------------------"

# Test: Command Line Tools installed
run_test "Xcode Command Line Tools installed" "xcode-select -p"

# Test: Important macOS utilities
run_test "pbcopy is available (clipboard)" "command -v pbcopy"
run_test "pbpaste is available (clipboard)" "command -v pbpaste"
run_test "open command is available" "command -v open"

echo ""
echo "⚙️  System Preferences Tests"
echo "----------------------------"

# Test: User preferences directory exists
run_test "User Library exists" "[ -d \"$HOME/Library\" ]"
run_test "Application Support directory exists" "[ -d \"$HOME/Library/Application Support\" ]"

echo ""
echo "================================"
echo "📊 macOS Test Summary:"
echo "  Total tests: $TOTAL_TESTS"
echo -e "  ${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "  ${RED}Failed: $FAILED_TESTS${NC}"
echo "================================"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✅ All macOS tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi
