#!/usr/bin/env bash
# Idempotency Testing Script
# Runs Ansible playbooks twice and verifies no changes on second run

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test configuration
PLAYBOOK="${1:-$PROJECT_ROOT/playbook.yml}"
INVENTORY="${2:-$PROJECT_ROOT/inventory}"
TEST_LOG_DIR="/tmp/ansible-idempotency-tests"

echo "🔄 Idempotency Testing"
echo "================================"
echo "Playbook: $PLAYBOOK"
echo "Inventory: $INVENTORY"
echo "Log Directory: $TEST_LOG_DIR"
echo ""

# Create log directory
mkdir -p "$TEST_LOG_DIR"

# Function to run playbook and check results
run_playbook() {
    local run_number=$1
    local log_file="$TEST_LOG_DIR/run_${run_number}_$(date +%Y%m%d_%H%M%S).log"

    echo -e "${BLUE}Running playbook (Run #$run_number)...${NC}"

    if ansible-playbook \
        "$PLAYBOOK" \
        ${INVENTORY:+-i "$INVENTORY"} \
        --check \
        --diff \
        -vv \
        > "$log_file" 2>&1; then

        echo -e "${GREEN}✓ Playbook completed successfully${NC}"
    else
        echo -e "${RED}✗ Playbook execution failed${NC}"
        echo "See log: $log_file"
        return 1
    fi

    # Parse results
    local changed=$(grep -c "changed:" "$log_file" || echo "0")
    local ok=$(grep -c "ok:" "$log_file" || echo "0")
    local failed=$(grep -c "failed:" "$log_file" || echo "0")

    echo "  📊 Results:"
    echo "    Changed: $changed"
    echo "    OK: $ok"
    echo "    Failed: $failed"

    echo "$log_file|$changed|$ok|$failed"
}

# Function to compare two runs
compare_runs() {
    local run1_data=$1
    local run2_data=$2

    IFS='|' read -r log1 changed1 ok1 failed1 <<< "$run1_data"
    IFS='|' read -r log2 changed2 ok2 failed2 <<< "$run2_data"

    echo ""
    echo "📋 Idempotency Analysis:"
    echo "------------------------"

    if [ "$changed2" -eq 0 ] && [ "$failed2" -eq 0 ]; then
        echo -e "${GREEN}✅ IDEMPOTENT${NC}"
        echo "Second run produced no changes - playbook is idempotent!"
        return 0
    elif [ "$changed2" -gt 0 ]; then
        echo -e "${RED}❌ NOT IDEMPOTENT${NC}"
        echo "Second run produced $changed2 changes"
        echo ""
        echo "Tasks that changed on second run:"
        grep "changed:" "$log2" | sed 's/^/  /'
        return 1
    else
        echo -e "${RED}❌ FAILED${NC}"
        echo "Second run had $failed2 failures"
        return 1
    fi
}

# Function to test idempotency with actual execution
test_actual_idempotency() {
    echo ""
    echo -e "${YELLOW}⚠️  WARNING: This will actually modify the system${NC}"
    echo "This test runs the playbook twice without --check mode"
    echo ""
    read -p "Continue? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        echo "Aborted"
        return 1
    fi

    local log1="$TEST_LOG_DIR/actual_run1.log"
    local log2="$TEST_LOG_DIR/actual_run2.log"

    echo ""
    echo "🔨 First actual run..."
    ansible-playbook "$PLAYBOOK" ${INVENTORY:+-i "$INVENTORY"} | tee "$log1"

    echo ""
    echo "🔨 Second actual run..."
    ansible-playbook "$PLAYBOOK" ${INVENTORY:+-i "$INVENTORY"} | tee "$log2"

    local changed_run2=$(grep -oP 'changed=\K[0-9]+' "$log2" | head -1)

    echo ""
    if [ "${changed_run2:-0}" -eq 0 ]; then
        echo -e "${GREEN}✅ ACTUAL IDEMPOTENCY: PASSED${NC}"
        return 0
    else
        echo -e "${RED}❌ ACTUAL IDEMPOTENCY: FAILED${NC}"
        echo "Second run had $changed_run2 changes"
        return 1
    fi
}

# Main execution
main() {
    if [ ! -f "$PLAYBOOK" ]; then
        echo -e "${RED}❌ Playbook not found: $PLAYBOOK${NC}"
        exit 1
    fi

    # Run in check mode first
    echo "🧪 Testing with --check mode (dry run)"
    echo ""

    RUN1_DATA=$(run_playbook 1)
    echo ""
    sleep 2
    RUN2_DATA=$(run_playbook 2)

    compare_runs "$RUN1_DATA" "$RUN2_DATA"
    CHECK_RESULT=$?

    # Optionally test actual execution
    if [ "${ANSIBLE_TEST_ACTUAL:-false}" = "true" ]; then
        test_actual_idempotency
        ACTUAL_RESULT=$?
    else
        echo ""
        echo "💡 Tip: Set ANSIBLE_TEST_ACTUAL=true to test actual execution"
        ACTUAL_RESULT=0
    fi

    echo ""
    echo "================================"
    echo "Final Result:"
    if [ $CHECK_RESULT -eq 0 ]; then
        echo -e "${GREEN}✅ Idempotency test PASSED${NC}"
        exit 0
    else
        echo -e "${RED}❌ Idempotency test FAILED${NC}"
        exit 1
    fi
}

main
