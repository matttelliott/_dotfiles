#!/usr/bin/env bash
# Ansible Syntax Validation Script
# Validates all Ansible playbooks and roles for syntax errors

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL_FILES=0
PASSED_FILES=0
FAILED_FILES=0

# Find project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🔍 Ansible Syntax Validation"
echo "================================"
echo "Project Root: $PROJECT_ROOT"
echo ""

# Check if ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${RED}❌ Error: ansible-playbook not found${NC}"
    echo "Install Ansible: pip install ansible"
    exit 1
fi

# Check if ansible-lint is installed
LINT_AVAILABLE=false
if command -v ansible-lint &> /dev/null; then
    LINT_AVAILABLE=true
    echo -e "${GREEN}✓ ansible-lint found${NC}"
else
    echo -e "${YELLOW}⚠ ansible-lint not found (optional but recommended)${NC}"
    echo "Install: pip install ansible-lint"
fi

echo ""

# Function to validate playbook syntax
validate_playbook() {
    local file=$1
    echo -n "Checking $file... "

    if ansible-playbook --syntax-check "$file" &> /dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASSED_FILES++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        ansible-playbook --syntax-check "$file" 2>&1 | sed 's/^/  /'
        ((FAILED_FILES++))
        return 1
    fi
}

# Function to lint playbook
lint_playbook() {
    local file=$1

    if [ "$LINT_AVAILABLE" = true ]; then
        echo -n "Linting $file... "

        if ansible-lint "$file" &> /dev/null; then
            echo -e "${GREEN}✓ PASS${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ WARNINGS${NC}"
            ansible-lint "$file" 2>&1 | sed 's/^/  /'
            return 1
        fi
    fi
}

# Find and validate all playbooks
echo "📋 Validating Playbooks:"
echo "------------------------"

while IFS= read -r -d '' playbook; do
    ((TOTAL_FILES++))
    validate_playbook "$playbook"
    lint_playbook "$playbook"
    echo ""
done < <(find "$PROJECT_ROOT" -type f \( -name "*.yml" -o -name "*.yaml" \) -not -path "*/\.*" -not -path "*/tests/*" -print0)

# Summary
echo ""
echo "================================"
echo "📊 Validation Summary:"
echo "  Total files: $TOTAL_FILES"
echo -e "  ${GREEN}Passed: $PASSED_FILES${NC}"
echo -e "  ${RED}Failed: $FAILED_FILES${NC}"
echo "================================"

if [ $FAILED_FILES -gt 0 ]; then
    echo -e "${RED}❌ Syntax validation failed${NC}"
    exit 1
else
    echo -e "${GREEN}✅ All syntax checks passed${NC}"
    exit 0
fi
