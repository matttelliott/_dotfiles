#!/usr/bin/env bash
# Functional Testing Script
# Validates that all expected software is installed and configured correctly

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test result tracking
declare -a FAILED_TEST_NAMES=()

echo "🧪 Functional Testing Suite"
echo "================================"
echo ""

# Helper function to run test
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
        FAILED_TEST_NAMES+=("$test_name")
        ((FAILED_TESTS++))
        return 1
    fi
}

# Helper function to check command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Helper function to check file exists
file_exists() {
    [ -f "$1" ]
}

# Helper function to check directory exists
dir_exists() {
    [ -d "$1" ]
}

# Helper function to check file contains string
file_contains() {
    local file=$1
    local pattern=$2
    grep -q "$pattern" "$file" 2>/dev/null
}

echo "📦 Software Installation Tests"
echo "------------------------------"

# Test: Zsh installed
run_test "Zsh is installed" "command_exists zsh"

# Test: Zsh is default shell
run_test "Zsh is default shell" "[ \"$SHELL\" = \"/bin/zsh\" ] || [ \"$SHELL\" = \"/usr/bin/zsh\" ]"

# Test: Tmux installed
run_test "Tmux is installed" "command_exists tmux"

# Test: Neovim installed
run_test "Neovim is installed" "command_exists nvim"

# Test: Git installed
run_test "Git is installed" "command_exists git"

# Test: Curl installed
run_test "Curl is installed" "command_exists curl"

# Test: Wget installed
run_test "Wget is installed" "command_exists wget"

echo ""
echo "⚙️  Configuration File Tests"
echo "------------------------------"

# Test: .zshrc exists
run_test ".zshrc exists in home directory" "file_exists $HOME/.zshrc"

# Test: .tmux.conf exists
run_test ".tmux.conf exists in home directory" "file_exists $HOME/.tmux.conf"

# Test: Neovim config directory exists
run_test "Neovim config directory exists" "dir_exists $HOME/.config/nvim"

# Test: Neovim init file exists
run_test "Neovim init.vim or init.lua exists" \
    "file_exists $HOME/.config/nvim/init.vim || file_exists $HOME/.config/nvim/init.lua"

# Test: .gitconfig exists
run_test ".gitconfig exists" "file_exists $HOME/.gitconfig"

echo ""
echo "🔧 Configuration Content Tests"
echo "------------------------------"

# Test: Zsh has custom configuration
run_test ".zshrc has custom configuration" \
    "[ -f $HOME/.zshrc ] && [ \$(wc -l < $HOME/.zshrc) -gt 10 ]"

# Test: Tmux has custom keybindings
if [ -f "$HOME/.tmux.conf" ]; then
    run_test "Tmux has custom prefix or bindings" \
        "file_contains $HOME/.tmux.conf 'bind\\|prefix\\|set-option'"
fi

# Test: Git has user configuration
run_test "Git user.name is configured" "git config user.name &> /dev/null"
run_test "Git user.email is configured" "git config user.email &> /dev/null"

echo ""
echo "🚀 Functionality Tests"
echo "------------------------------"

# Test: Zsh can execute
run_test "Zsh can execute commands" "zsh -c 'echo test' | grep -q test"

# Test: Tmux can start
run_test "Tmux can start session" "tmux -V | grep -q tmux"

# Test: Neovim can execute
run_test "Neovim can execute" "nvim --version | grep -q NVIM"

# Test: Neovim has plugin manager
run_test "Neovim plugin manager exists" \
    "dir_exists $HOME/.local/share/nvim/site/pack || \
     dir_exists $HOME/.local/share/nvim/lazy || \
     dir_exists $HOME/.vim/plugged"

echo ""
echo "🔌 Plugin and Extension Tests"
echo "------------------------------"

# Test: Oh My Zsh installed (if used)
if [ -d "$HOME/.oh-my-zsh" ]; then
    run_test "Oh My Zsh is installed" "dir_exists $HOME/.oh-my-zsh"
    run_test ".zshrc sources Oh My Zsh" "file_contains $HOME/.zshrc oh-my-zsh"
fi

# Test: Tmux Plugin Manager (if used)
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    run_test "Tmux Plugin Manager is installed" "dir_exists $HOME/.tmux/plugins/tpm"
fi

# Test: Neovim LSP support (if configured)
run_test "Neovim has LSP support" \
    "nvim --headless -c 'lua print(vim.lsp ~= nil)' -c 'quit' 2>&1 | grep -q true || true"

echo ""
echo "📋 Permission Tests"
echo "------------------------------"

# Test: Config files are readable
run_test ".zshrc is readable" "[ -r $HOME/.zshrc ]"
run_test ".tmux.conf is readable" "[ -r $HOME/.tmux.conf ] || [ ! -e $HOME/.tmux.conf ]"

# Test: Config files have correct ownership
run_test "Config files owned by current user" \
    "[ \$(stat -c '%U' $HOME/.zshrc 2>/dev/null || stat -f '%Su' $HOME/.zshrc) = \"\$(whoami)\" ]"

echo ""
echo "================================"
echo "📊 Test Summary:"
echo "  Total tests: $TOTAL_TESTS"
echo -e "  ${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "  ${RED}Failed: $FAILED_TESTS${NC}"

if [ $FAILED_TESTS -gt 0 ]; then
    echo ""
    echo -e "${RED}Failed tests:${NC}"
    for test_name in "${FAILED_TEST_NAMES[@]}"; do
        echo -e "  ${RED}✗${NC} $test_name"
    done
fi

echo "================================"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✅ All functional tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi
