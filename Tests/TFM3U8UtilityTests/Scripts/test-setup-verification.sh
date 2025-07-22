#!/bin/bash

# Test data setup verification script
set -e

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}🔍 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🧪 TFM3U8Utility2 Test Data Setup Verification"
echo "========================================"

# Verify source data exists
print_step "Checking source test data..."
SOURCE_TEST_DATA="$PROJECT_ROOT/TestData"
if [ -d "$SOURCE_TEST_DATA" ]; then
    file_count=$(find "$SOURCE_TEST_DATA/ts_segments" -name "fileSequence*.ts" 2>/dev/null | wc -l)
    print_success "Source data exists, contains $file_count test files"
else
    echo "❌ Source test data does not exist: $SOURCE_TEST_DATA"
    exit 1
fi

# Verify script files
print_step "Checking script files..."
if [ -f "$SCRIPT_DIR/setup-test-data.sh" ]; then
    print_success "setup-test-data.sh exists"
else
    print_warning "setup-test-data.sh does not exist"
fi

# Verify key paths
print_step "Verifying key test data paths..."
key_paths=(
    "/private/tmp/Tests/TFM3U8UtilityTests/TestData"
    # "$HOME/.tmp/TFM3U8UtilityTests/TestData"
)

successful_paths=0
for path in "${key_paths[@]}"; do
    if [ -d "$path/ts_segments" ]; then
        file_count=$(find "$path/ts_segments" -name "fileSequence*.ts" 2>/dev/null | wc -l)
        print_success "Path verification passed: $path ($file_count files)"
        ((successful_paths++))
    else
        print_warning "Path does not exist: $path"
    fi
done

echo ""
echo "🎯 Verification summary: $successful_paths paths available"
echo "💡 Run setup script: ./Scripts/setup-test-data.sh"
