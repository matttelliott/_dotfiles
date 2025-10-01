#!/usr/bin/env bash
# Debian/Ubuntu-specific Testing Script

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

echo "🐧 Debian/Ubuntu Specific Tests"
echo "================================"
echo ""

# Check if running on Debian/Ubuntu
if [ ! -f /etc/debian_version ]; then
    echo -e "${YELLOW}⚠️  Not running on Debian/Ubuntu - skipping tests${NC}"
    exit 0
fi

echo "OS: $(lsb_release -ds 2>/dev/null || cat /etc/debian_version)"
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

echo "📦 APT Package Tests"
echo "--------------------"

# Test: APT is working
run_test "APT package manager is functional" "dpkg --version"

# Test: Package cache is updated (warning only)
if [ -d /var/lib/apt/lists ]; then
    cache_age=$(($(date +%s) - $(stat -c %Y /var/lib/apt/lists/partial 2>/dev/null || echo 0)))
    if [ $cache_age -gt 604800 ]; then  # 7 days
        echo -e "${YELLOW}⚠️  APT cache is older than 7 days${NC}"
    fi
fi

# Test: Required packages are installed
run_test "build-essential is installed" "dpkg -l build-essential"
run_test "git is installed via apt" "dpkg -l git"
run_test "curl is installed via apt" "dpkg -l curl"
run_test "wget is installed via apt" "dpkg -l wget"

# Test: Python is available
run_test "Python3 is installed" "command -v python3"
run_test "pip3 is installed" "command -v pip3 || command -v pip"

echo ""
echo "🔐 Repository Tests"
echo "-------------------"

# Test: Required repositories are configured
run_test "Universe repository enabled" \
    "grep -r '^deb.*universe' /etc/apt/sources.list /etc/apt/sources.list.d/ || \
     grep -r 'Components:.*universe' /etc/apt/sources.list /etc/apt/sources.list.d/"

echo ""
echo "👤 User and Permissions Tests"
echo "------------------------------"

# Test: User has sudo access (if applicable)
if command -v sudo &> /dev/null; then
    run_test "User has sudo access" "sudo -n true 2>/dev/null || sudo -v"
fi

# Test: User shell is set correctly
run_test "User shell is /bin/zsh" "[ \"$(getent passwd $USER | cut -d: -f7)\" = \"/bin/zsh\" ] || \
    [ \"$(getent passwd $USER | cut -d: -f7)\" = \"/usr/bin/zsh\" ]"

echo ""
echo "🌐 Network Tests"
echo "----------------"

# Test: Can reach package repositories
run_test "Can reach Ubuntu/Debian repositories" \
    "timeout 5 curl -s http://archive.ubuntu.com > /dev/null || \
     timeout 5 curl -s http://deb.debian.org > /dev/null"

echo ""
echo "================================"
echo "📊 Debian/Ubuntu Test Summary:"
echo "  Total tests: $TOTAL_TESTS"
echo -e "  ${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "  ${RED}Failed: $FAILED_TESTS${NC}"
echo "================================"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✅ All Debian/Ubuntu tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi
