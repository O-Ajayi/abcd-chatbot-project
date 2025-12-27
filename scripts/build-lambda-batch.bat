@echo off
REM Lambda Function Batch Build Script for Windows
REM Builds Python Lambda functions that connect to RDS and read from DynamoDB

setlocal enabledelayedexpansion

REM Configuration
set "LAMBDA_FUNCTIONS_DIR=lambda-functions"
set "BUILD_DIR=build"
set "PACKAGE_DIR=packages"
set "PROJECT_ROOT=%~dp0.."

cd /d "%PROJECT_ROOT%"

if not exist "%LAMBDA_FUNCTIONS_DIR%" (
    echo [ERROR] Lambda functions directory not found: %LAMBDA_FUNCTIONS_DIR%
    exit /b 1
)

REM Create build directories
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%PACKAGE_DIR%" mkdir "%PACKAGE_DIR%"

set "count=0"
set "success_count=0"
set "fail_count=0"

echo [INFO] Building all Lambda functions from %LAMBDA_FUNCTIONS_DIR%...

REM Build all functions
for /d %%d in ("%LAMBDA_FUNCTIONS_DIR%\*") do (
    set "function_dir=%%d"
    set "function_name=%%~nd"
    
    if exist "!function_dir!\index.py" (
        set /a count+=1
        echo [INFO] Building Lambda function: !function_name!
        
        REM Create build directory
        set "build_path=%BUILD_DIR%\!function_name!"
        if exist "!build_path!" rmdir /s /q "!build_path!"
        mkdir "!build_path!"
        
        REM Copy function code
        echo [INFO] Copying function code...
        xcopy /E /I /Y "!function_dir!\*" "!build_path!\" >nul
        
        REM Install dependencies if requirements.txt exists
        if exist "!function_dir!\requirements.txt" (
            echo [INFO] Installing Python dependencies...
            pip install -q -r "!function_dir!\requirements.txt" -t "!build_path!" --upgrade
            if !errorlevel! equ 0 (
                echo [INFO] Dependencies installed
            ) else (
                echo [WARNING] Failed to install dependencies
            )
        ) else (
            echo [WARNING] No requirements.txt found for !function_name!
        )
        
        REM Check for RDS and DynamoDB imports
        findstr /C:"psycopg2" /C:"pymysql" "!function_dir!\index.py" >nul 2>&1
        if !errorlevel! equ 0 echo [INFO] RDS connection library detected
        
        findstr /C:"boto3" /C:"dynamodb" "!function_dir!\index.py" >nul 2>&1
        if !errorlevel! equ 0 echo [INFO] DynamoDB client detected
        
        REM Create deployment package
        echo [INFO] Creating deployment package...
        cd "!build_path!"
        powershell -Command "Compress-Archive -Path * -DestinationPath ..\..\%PACKAGE_DIR%\!function_name!.zip -Force" >nul 2>&1
        cd /d "%PROJECT_ROOT%"
        
        if exist "%PACKAGE_DIR%\!function_name!.zip" (
            for %%A in ("%PACKAGE_DIR%\!function_name!.zip") do (
                set "size=%%~zA"
                set /a size_mb=!size!/1048576
            )
            echo [INFO] Package created: %PACKAGE_DIR%\!function_name!.zip ^(!size_mb! MB^)
            set /a success_count+=1
        ) else (
            echo [ERROR] Failed to create package: %PACKAGE_DIR%\!function_name!.zip
            set /a fail_count+=1
        )
        
        REM Cleanup build directory
        rmdir /s /q "!build_path!"
    )
)

echo.
echo [INFO] Build complete! Success: !success_count!, Failed: !fail_count!, Total: !count!

if !success_count! gtr 0 (
    echo [INFO] Packages are in: %PACKAGE_DIR%
    echo [INFO] To use with Terraform, update terraform.tfvars:
    echo.
    echo lambda_package_paths = {
    for %%f in ("%PACKAGE_DIR%\*.zip") do (
        set "zip_file=%%f"
        set "func_name=%%~nf"
        echo   "!func_name!" = "../packages/!func_name!.zip"
    )
    echo }
)

endlocal

