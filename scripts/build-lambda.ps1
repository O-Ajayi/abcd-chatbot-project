# Lambda Function Build Script for Windows PowerShell
# This script packages Python Lambda functions with their dependencies

param(
    [string[]]$Functions = @()
)

# Configuration
$LambdaFunctionsDir = "lambda-functions"
$BuildDir = "build"
$PackageDir = "packages"

# Function to build a Lambda function
function Build-Lambda {
    param(
        [string]$FunctionName
    )
    
    $FunctionDir = Join-Path $LambdaFunctionsDir $FunctionName
    $BuildPath = Join-Path $BuildDir $FunctionName
    $PackagePath = Join-Path $PackageDir "$FunctionName.zip"
    
    Write-Host "[INFO] Building Lambda function: $FunctionName" -ForegroundColor Green
    
    # Check if function directory exists
    if (-not (Test-Path $FunctionDir)) {
        Write-Host "[ERROR] Function directory not found: $FunctionDir" -ForegroundColor Red
        return $false
    }
    
    # Create build directory for this function
    if (Test-Path $BuildPath) {
        Remove-Item -Path $BuildPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $BuildPath -Force | Out-Null
    
    # Copy function code
    Write-Host "[INFO] Copying function code..." -ForegroundColor Green
    Copy-Item -Path "$FunctionDir\*" -Destination $BuildPath -Recurse -Force
    
    # Check if requirements.txt exists
    $RequirementsFile = Join-Path $FunctionDir "requirements.txt"
    if (Test-Path $RequirementsFile) {
        Write-Host "[INFO] Installing Python dependencies..." -ForegroundColor Green
        
        # Install dependencies
        pip install -q -r $RequirementsFile -t $BuildPath --upgrade
        
        Write-Host "[INFO] Dependencies installed" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] No requirements.txt found for $FunctionName" -ForegroundColor Yellow
    }
    
    # Create deployment package
    Write-Host "[INFO] Creating deployment package..." -ForegroundColor Green
    Compress-Archive -Path "$BuildPath\*" -DestinationPath $PackagePath -Force
    
    # Get package size
    $PackageSize = (Get-Item $PackagePath).Length / 1MB
    Write-Host "[INFO] Package created: $PackagePath ($([math]::Round($PackageSize, 2)) MB)" -ForegroundColor Green
    
    # Cleanup build directory
    Remove-Item -Path $BuildPath -Recurse -Force
    
    return $true
}

# Create build directories
New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
New-Item -ItemType Directory -Path $PackageDir -Force | Out-Null

# Main execution
if ($Functions.Count -eq 0) {
    # Build all functions
    Write-Host "[INFO] Building all Lambda functions..." -ForegroundColor Green
    
    Get-ChildItem -Path $LambdaFunctionsDir -Directory | ForEach-Object {
        $FunctionName = $_.Name
        Build-Lambda -FunctionName $FunctionName
    }
} else {
    # Build specific function(s)
    foreach ($FunctionName in $Functions) {
        Build-Lambda -FunctionName $FunctionName
    }
}

Write-Host "[INFO] Build complete! Packages are in: $PackageDir" -ForegroundColor Green
Write-Host "[INFO] To deploy, copy packages to Terraform or upload to S3" -ForegroundColor Green

