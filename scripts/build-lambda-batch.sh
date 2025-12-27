#!/bin/bash

# Lambda Function Batch Build Script
# Builds Python Lambda functions that connect to RDS and read from DynamoDB
# This script processes all Lambda functions in the lambda-functions directory

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
LAMBDA_FUNCTIONS_DIR="lambda-functions"
BUILD_DIR="build"
PACKAGE_DIR="packages"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Function to print colored messages
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running from project root
cd "$PROJECT_ROOT"

if [ ! -d "$LAMBDA_FUNCTIONS_DIR" ]; then
    print_error "Lambda functions directory not found: $LAMBDA_FUNCTIONS_DIR"
    exit 1
fi

# Create build directories
mkdir -p "$BUILD_DIR"
mkdir -p "$PACKAGE_DIR"

# Function to build a Lambda function
build_lambda() {
    local function_name=$1
    local function_dir="$LAMBDA_FUNCTIONS_DIR/$function_name"
    local build_path="$BUILD_DIR/$function_name"
    local package_path="$PACKAGE_DIR/$function_name.zip"
    
    print_message "Building Lambda function: $function_name"
    
    # Check if function directory exists
    if [ ! -d "$function_dir" ]; then
        print_error "Function directory not found: $function_dir"
        return 1
    fi
    
    # Check if index.py exists
    if [ ! -f "$function_dir/index.py" ]; then
        print_warning "index.py not found in $function_dir, skipping..."
        return 1
    fi
    
    # Create build directory for this function
    rm -rf "$build_path"
    mkdir -p "$build_path"
    
    # Copy function code
    print_message "Copying function code..."
    cp -r "$function_dir"/* "$build_path/" 2>/dev/null || true
    
    # Check if requirements.txt exists
    if [ -f "$function_dir/requirements.txt" ]; then
        print_message "Installing Python dependencies..."
        
        # Create virtual environment
        if command -v python3 &> /dev/null; then
            python3 -m venv "$build_path/venv" 2>/dev/null || {
                print_warning "venv not available, using pip directly"
            }
            
            # Install dependencies
            if [ -d "$build_path/venv" ]; then
                source "$build_path/venv/bin/activate"
                pip install --quiet --upgrade pip
                pip install --quiet -r "$function_dir/requirements.txt" -t "$build_path" --upgrade
                deactivate
            else
                pip3 install --quiet -r "$function_dir/requirements.txt" -t "$build_path" --upgrade
            fi
            
            print_message "Dependencies installed"
        else
            print_error "Python 3 is not installed"
            return 1
        fi
    else
        print_warning "No requirements.txt found for $function_name"
    fi
    
    # Verify RDS and DynamoDB imports in code
    if grep -q "psycopg2\|pymysql" "$function_dir/index.py" 2>/dev/null; then
        print_message "RDS connection library detected"
    fi
    
    if grep -q "boto3.*dynamodb\|dynamodb" "$function_dir/index.py" 2>/dev/null; then
        print_message "DynamoDB client detected"
    fi
    
    # Create deployment package
    print_message "Creating deployment package..."
    cd "$build_path"
    zip -r "../../$package_path" . -q -x "venv/*" "*.pyc" "__pycache__/*" ".DS_Store"
    cd - > /dev/null
    
    # Get package size
    if [ -f "$package_path" ]; then
        package_size=$(du -h "$package_path" | cut -f1)
        print_message "Package created: $package_path (${package_size})"
    else
        print_error "Failed to create package: $package_path"
        return 1
    fi
    
    # Cleanup build directory
    rm -rf "$build_path"
}

# Function to build all Lambda functions
build_all() {
    print_message "Building all Lambda functions from $LAMBDA_FUNCTIONS_DIR..."
    
    local count=0
    local success_count=0
    local fail_count=0
    
    for function_dir in "$LAMBDA_FUNCTIONS_DIR"/*; do
        if [ -d "$function_dir" ] && [ -f "$function_dir/index.py" ]; then
            function_name=$(basename "$function_dir")
            count=$((count + 1))
            
            if build_lambda "$function_name"; then
                success_count=$((success_count + 1))
            else
                fail_count=$((fail_count + 1))
            fi
        fi
    done
    
    print_message "Build complete! Success: $success_count, Failed: $fail_count, Total: $count"
    
    if [ $success_count -gt 0 ]; then
        print_message "Packages are in: $PACKAGE_DIR"
        print_message "To use with Terraform, update terraform.tfvars:"
        echo ""
        echo "lambda_package_paths = {"
        for zip_file in "$PACKAGE_DIR"/*.zip; do
            if [ -f "$zip_file" ]; then
                func_name=$(basename "$zip_file" .zip)
                echo "  \"$func_name\" = \"../packages/$func_name.zip\""
            fi
        done
        echo "}"
    fi
}

# Main execution
if [ $# -eq 0 ]; then
    # Build all functions
    build_all
else
    # Build specific function(s)
    for function_name in "$@"; do
        build_lambda "$function_name"
    done
fi

