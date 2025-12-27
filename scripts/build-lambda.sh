#!/bin/bash

# Lambda Function Build Script
# This script packages Python Lambda functions with their dependencies

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
if [ ! -d "$LAMBDA_FUNCTIONS_DIR" ]; then
    print_error "Lambda functions directory not found. Please run from project root."
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
        python3 -m venv "$build_path/venv" 2>/dev/null || {
            print_warning "venv not available, using pip directly"
        }
        
        # Install dependencies
        if [ -d "$build_path/venv" ]; then
            source "$build_path/venv/bin/activate"
            pip install -q -r "$function_dir/requirements.txt" -t "$build_path" --upgrade
            deactivate
        else
            pip3 install -q -r "$function_dir/requirements.txt" -t "$build_path" --upgrade
        fi
        
        print_message "Dependencies installed"
    else
        print_warning "No requirements.txt found for $function_name"
    fi
    
    # Create deployment package
    print_message "Creating deployment package..."
    cd "$build_path"
    zip -r "../../$package_path" . -q
    cd - > /dev/null
    
    # Get package size
    package_size=$(du -h "$package_path" | cut -f1)
    print_message "Package created: $package_path (${package_size})"
    
    # Cleanup build directory
    rm -rf "$build_path"
}

# Function to build all Lambda functions
build_all() {
    print_message "Building all Lambda functions..."
    
    for function_dir in "$LAMBDA_FUNCTIONS_DIR"/*; do
        if [ -d "$function_dir" ]; then
            function_name=$(basename "$function_dir")
            build_lambda "$function_name"
        fi
    done
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

print_message "Build complete! Packages are in: $PACKAGE_DIR"
print_message "To deploy, copy packages to Terraform or upload to S3"

