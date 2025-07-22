#!/bin/bash

# TFM3U8Utility2 Test Data Setup Script
set -e

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
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

print_info "Starting TFM3U8Utility2 test data setup..."
print_info "Project root: $PROJECT_ROOT"

# Test data source path
SOURCE_TEST_DATA="$PROJECT_ROOT/TestData"
print_info "Source test data path: $SOURCE_TEST_DATA"

# Check if source data exists
if [ ! -d "$SOURCE_TEST_DATA" ]; then
    echo "❌ Source test data directory does not exist: $SOURCE_TEST_DATA"
    exit 1
fi

print_success "Found source test data directory"

# Function: Copy test data to specified directory
copy_test_data() {
    local target_dir="$1"
    local target_parent="$(dirname "$target_dir")"
    
    print_info "Preparing to copy to: $target_dir"
    
    # Create parent directory
    if [ ! -d "$target_parent" ]; then
        mkdir -p "$target_parent" 2>/dev/null || {
            print_warning "Cannot create directory: $target_parent (insufficient permissions)"
            return 1
        }
    fi
    
    # If target already exists, delete first
    if [ -d "$target_dir" ]; then
        rm -rf "$target_dir" 2>/dev/null || {
            print_warning "Cannot delete existing directory: $target_dir"
            return 1
        }
    fi
    
    # Copy test data
    cp -r "$SOURCE_TEST_DATA" "$target_dir" 2>/dev/null || {
        print_warning "Cannot copy to: $target_dir"
        return 1
    }
    
    print_success "Successfully copied to: $target_dir"
    return 0
}

print_info "Setting up Xcode environment test data paths..."

# 1. /private/tmp path (Xcode test working directory)
copy_test_data "/private/tmp/Tests/TFM3U8UtilityTests/TestData"

## 2. Current user's temporary directory
#USER_TEMP_DIR="$HOME/.tmp/TFM3U8UtilityTests/TestData"
#copy_test_data "$USER_TEMP_DIR"

# 3. Project build directory
print_info "Setting up build directory test data..."
for build_config in debug release; do
    build_test_data="$PROJECT_ROOT/.build/$build_config/Tests/TFM3U8UtilityTests/TestData"
    copy_test_data "$build_test_data"
done

# Verify copy results
print_info "Verifying test data files..."
validate_test_data() {
    local data_dir="$1"
    if [ -d "$data_dir/ts_segments" ]; then
        local file_count=$(find "$data_dir/ts_segments" -name "fileSequence*.ts" | wc -l)
        if [ "$file_count" -ge 5 ]; then
            print_success "Verification passed: $data_dir (contains $file_count test files)"
            return 0
        else
            print_warning "Insufficient files: $data_dir (only $file_count files)"
            return 1
        fi
    else
        print_warning "Missing ts_segments directory: $data_dir"
        return 1
    fi
}

# Verify key paths
print_info "Verifying key test data paths..."
validate_test_data "/private/tmp/Tests/TFM3U8UtilityTests/TestData"
#validate_test_data "$USER_TEMP_DIR"

print_success "Test data setup completed! Now both Xcode and command line environments should be able to access test data correctly."
