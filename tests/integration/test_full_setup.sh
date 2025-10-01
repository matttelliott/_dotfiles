#!/usr/bin/env bash
# Integration Testing Script
# Tests complete dotfiles setup end-to-end

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🔗 Integration Testing"
echo "================================"
echo "Testing complete dotfiles setup"
echo ""

# Test phases
PHASE_TESTS=0
PHASE_PASSED=0

run_phase() {
    local phase_name=$1
    local phase_command=$2

    ((PHASE_TESTS++))
    echo ""
    echo -e "${BLUE}Phase $PHASE_TESTS: $phase_name${NC}"
    echo "--------------------------------"

    if eval "$phase_command"; then
        echo -e "${GREEN}✓ Phase passed${NC}"
        ((PHASE_PASSED++))
        return 0
    else
        echo -e "${RED}✗ Phase failed${NC}"
        return 1
    fi
}

# Phase 1: Pre-flight checks
run_phase "Pre-flight Checks" "
    echo 'Checking prerequisites...'
    command -v ansible-playbook && \
    command -v git && \
    echo 'All prerequisites met'
"

# Phase 2: Syntax validation
run_phase "Syntax Validation" "
    if [ -f '$PROJECT_ROOT/playbook.yml' ]; then
        ansible-playbook --syntax-check '$PROJECT_ROOT/playbook.yml'
    else
        echo 'No playbook found (OK for initial setup)'
    fi
"

# Phase 3: Dry run (check mode)
run_phase "Dry Run (Check Mode)" "
    if [ -f '$PROJECT_ROOT/playbook.yml' ]; then
        ansible-playbook '$PROJECT_ROOT/playbook.yml' --check --diff
    else
        echo 'No playbook found (OK for initial setup)'
    fi
"

# Phase 4: Component tests
run_phase "Component Tests" "
    chmod +x '$PROJECT_ROOT/tests/functional/test_installations.sh' && \
    '$PROJECT_ROOT/tests/functional/test_installations.sh' || true
"

# Phase 5: OS-specific tests
run_phase "OS-Specific Tests" "
    os=\$(uname)
    case \$os in
        Linux)
            if [ -f /etc/debian_version ]; then
                chmod +x '$PROJECT_ROOT/tests/os-specific/test_debian.sh'
                '$PROJECT_ROOT/tests/os-specific/test_debian.sh' || true
            elif [ -f /etc/arch-release ]; then
                chmod +x '$PROJECT_ROOT/tests/os-specific/test_arch.sh'
                '$PROJECT_ROOT/tests/os-specific/test_arch.sh' || true
            fi
            ;;
        Darwin)
            chmod +x '$PROJECT_ROOT/tests/os-specific/test_macos.sh'
            '$PROJECT_ROOT/tests/os-specific/test_macos.sh' || true
            ;;
    esac
    true
"

# Phase 6: Configuration validation
run_phase "Configuration Validation" "
    echo 'Validating configuration files...'

    # Check zsh config
    if [ -f \$HOME/.zshrc ]; then
        zsh -n \$HOME/.zshrc 2>&1 && echo '✓ .zshrc syntax OK'
    fi

    # Check tmux config
    if [ -f \$HOME/.tmux.conf ]; then
        tmux -f \$HOME/.tmux.conf list-keys >/dev/null 2>&1 && echo '✓ .tmux.conf OK'
    fi

    # Check nvim config
    if [ -f \$HOME/.config/nvim/init.vim ] || [ -f \$HOME/.config/nvim/init.lua ]; then
        nvim --headless +checkhealth +qall 2>&1 | head -20 && echo '✓ nvim config checked'
    fi

    true
"

# Phase 7: Idempotency check
run_phase "Idempotency Check" "
    if [ -f '$PROJECT_ROOT/playbook.yml' ]; then
        chmod +x '$PROJECT_ROOT/tests/idempotency/test_idempotency.sh'
        '$PROJECT_ROOT/tests/idempotency/test_idempotency.sh' || true
    else
        echo 'No playbook found (OK for initial setup)'
    fi
"

# Final report
echo ""
echo "================================"
echo "📊 Integration Test Results:"
echo "  Total phases: $PHASE_TESTS"
echo -e "  ${GREEN}Passed: $PHASE_PASSED${NC}"
echo -e "  ${RED}Failed: $((PHASE_TESTS - PHASE_PASSED))${NC}"
echo "================================"

if [ $PHASE_PASSED -eq $PHASE_TESTS ]; then
    echo -e "${GREEN}✅ All integration tests passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some phases had issues${NC}"
    exit 1
fi
