@echo off
setlocal enabledelayedexpansion

:: MCP Server Setup Script for Windows
:: This script will install everything needed to run the YouTube MCP Server

echo ========================================
echo   YouTube MCP Server Setup
echo ========================================
echo.

:: Set colors for better UX
color 0A

:: Get current directory
set "INSTALL_DIR=%~dp0"
set "SCRIPT_NAME=my_mcp.py"
set "VENV_DIR=%INSTALL_DIR%venv"
set "SCRIPT_URL=https://aryan9019.github.io/mcp/my_mcp.py"

echo [1/7] Checking Python installation...
echo.

:: Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo [!] Python is not installed!
    echo.
    echo Please install Python from: https://www.python.org/downloads/
    echo.
    echo IMPORTANT: During installation, make sure to check:
    echo   - "Add Python to PATH"
    echo   - "Install pip"
    echo.
    echo After installing Python, run this setup.bat again.
    echo.
    pause
    exit /b 1
)

:: Get Python version
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo [+] Python %PYTHON_VERSION% is installed
echo.

:: Check Python version (need 3.8+)
for /f "tokens=1,2 delims=." %%a in ("%PYTHON_VERSION%") do (
    set MAJOR=%%a
    set MINOR=%%b
)

if %MAJOR% LSS 3 (
    echo [!] Python 3.8 or higher is required. You have Python %PYTHON_VERSION%
    echo Please upgrade Python from: https://www.python.org/downloads/
    pause
    exit /b 1
)

if %MAJOR% EQU 3 if %MINOR% LSS 8 (
    echo [!] Python 3.8 or higher is required. You have Python %PYTHON_VERSION%
    echo Please upgrade Python from: https://www.python.org/downloads/
    pause
    exit /b 1
)

echo [2/7] Checking pip installation...
echo.

:: Check if pip is installed
python -m pip --version >nul 2>&1
if errorlevel 1 (
    echo [!] pip is not installed. Installing pip...
    python -m ensurepip --default-pip
    if errorlevel 1 (
        echo [!] Failed to install pip. Please install it manually.
        pause
        exit /b 1
    )
)

echo [+] pip is installed
echo.

echo [3/7] Creating virtual environment...
echo.

:: Create virtual environment if it doesn't exist
if not exist "%VENV_DIR%" (
    python -m venv "%VENV_DIR%"
    if errorlevel 1 (
        echo [!] Failed to create virtual environment
        pause
        exit /b 1
    )
    echo [+] Virtual environment created at: %VENV_DIR%
) else (
    echo [+] Virtual environment already exists
)
echo.

echo [4/7] Downloading MCP server script...
echo.

:: Download the script using PowerShell
powershell -Command "& {Invoke-WebRequest -Uri '%SCRIPT_URL%' -OutFile '%INSTALL_DIR%%SCRIPT_NAME%'}" >nul 2>&1
if errorlevel 1 (
    echo [!] Failed to download script from %SCRIPT_URL%
    echo Please check your internet connection and try again.
    pause
    exit /b 1
)

echo [+] Script downloaded successfully
echo.

echo [5/7] Installing required Python packages...
echo.

:: Activate virtual environment and install packages
call "%VENV_DIR%\Scripts\activate.bat"

:: Upgrade pip first
echo [*] Upgrading pip...
python -m pip install --upgrade pip >nul 2>&1

:: Install required packages
echo [*] Installing mcp...
python -m pip install mcp >nul 2>&1

echo [*] Installing yt-dlp...
python -m pip install yt-dlp >nul 2>&1

echo.
echo [+] All packages installed successfully
echo.

echo [6/7] Checking Gemini CLI installation...
echo.

:: Check if gemini is installed
where gemini >nul 2>&1
if errorlevel 1 (
    echo [!] Gemini CLI is not installed
    echo.
    echo Installing Gemini CLI...
    echo.
    
    :: Install gemini CLI using pip
    python -m pip install gemini-cli
    
    if errorlevel 1 (
        echo [!] Failed to install Gemini CLI
        echo.
        echo Please install it manually:
        echo   pip install gemini-cli
        echo.
        pause
        exit /b 1
    )
    
    echo [+] Gemini CLI installed successfully
) else (
    echo [+] Gemini CLI is already installed
)
echo.

echo [7/7] Configuring MCP server in Gemini settings...
echo.

:: Get Python path in venv
set "PYTHON_PATH=%VENV_DIR%\Scripts\python.exe"
set "SCRIPT_PATH=%INSTALL_DIR%%SCRIPT_NAME%"

:: Convert paths to forward slashes for JSON (handle spaces)
set "PYTHON_PATH_JSON=%PYTHON_PATH:\=/%"
set "SCRIPT_PATH_JSON=%SCRIPT_PATH:\=/%"
set "INSTALL_DIR_JSON=%INSTALL_DIR:\=/%"

:: Get Python site-packages path
for /f "delims=" %%i in ('"%PYTHON_PATH%" -c "import site; print(site.getsitepackages()[0])"') do set SITE_PACKAGES=%%i
set "SITE_PACKAGES_JSON=!SITE_PACKAGES:\=/!"

:: Find Gemini config file
set "GEMINI_CONFIG=%USERPROFILE%\.gemini\settings.json"

if not exist "%USERPROFILE%\.gemini" (
    mkdir "%USERPROFILE%\.gemini"
)

:: Check if settings.json exists
if not exist "%GEMINI_CONFIG%" (
    echo [*] Creating new Gemini settings.json...
    (
        echo {
        echo   "mcpServers": {
        echo     "my-mcp": {
        echo       "command": "%PYTHON_PATH_JSON%",
        echo       "args": ["%SCRIPT_PATH_JSON%"],
        echo       "cwd": "%INSTALL_DIR_JSON%",
        echo       "env": {
        echo         "PYTHONPATH": "%SITE_PACKAGES_JSON%"
        echo       }
        echo     }
        echo   }
        echo }
    ) > "%GEMINI_CONFIG%"
    echo [+] Gemini settings.json created
) else (
    echo [*] Gemini settings.json already exists
    echo [*] Please manually add this configuration to your settings.json:
    echo.
    echo "my-mcp": {
    echo   "command": "%PYTHON_PATH_JSON%",
    echo   "args": ["%SCRIPT_PATH_JSON%"],
    echo   "cwd": "%INSTALL_DIR_JSON%",
    echo   "env": {
    echo     "PYTHONPATH": "%SITE_PACKAGES_JSON%"
    echo   }
    echo }
    echo.
)

echo.
echo [8/7] Creating start.bat launcher...
echo.

:: Create start.bat file
(
    echo @echo off
    echo :: Start YouTube MCP Server
    echo.
    echo title YouTube MCP Server
    echo color 0B
    echo.
    echo echo ========================================
    echo echo   YouTube MCP Server - Starting...
    echo echo ========================================
    echo echo.
    echo.
    echo :: Activate virtual environment
    echo call "%VENV_DIR%\Scripts\activate.bat"
    echo.
    echo :: Start the MCP server
    echo echo [+] Server is running...
    echo echo [+] Use Gemini CLI to interact with the server
    echo echo.
    echo echo Press Ctrl+C to stop the server
    echo echo.
    echo.
    echo python "%SCRIPT_PATH%"
    echo.
    echo pause
) > "%INSTALL_DIR%start.bat"

echo [+] start.bat created successfully
echo.

echo ========================================
echo   Setup Complete!
echo ========================================
echo.
echo Installation directory: %INSTALL_DIR%
echo Virtual environment: %VENV_DIR%
echo Python path: %PYTHON_PATH%
echo Script path: %SCRIPT_PATH%
echo.
echo Next steps:
echo   1. Double-click "start.bat" to start the MCP server
echo   2. Open a new terminal and run: gemini
echo   3. Start using YouTube download features!
echo.
echo Available commands in Gemini:
echo   - Search YouTube videos
echo   - Download videos (various resolutions)
echo   - Download audio (MP3)
echo   - Get video information
echo.
echo Downloads will be saved to: %USERPROFILE%\Downloads\mcp_ytdlp
echo.
pause
