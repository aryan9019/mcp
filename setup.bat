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

echo [*] Installing pystray (for system tray)...
python -m pip install pystray pillow >nul 2>&1

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
echo [8/11] Creating system tray wrapper...
echo.

:: Create system tray Python wrapper
(
    echo import sys
    echo import os
    echo import subprocess
    echo import threading
    echo from PIL import Image, ImageDraw
    echo import pystray
    echo from pystray import MenuItem as item
    echo.
    echo class MCPServerTray:
    echo     def __init__^(self^):
    echo         self.process = None
    echo         self.icon = None
    echo         
    echo     def create_icon_image^(self^):
    echo         """Create a simple icon for the system tray"""
    echo         # Create a 64x64 image with a colored circle
    echo         width = 64
    echo         height = 64
    echo         color1 = ^(255, 0, 0^)  # Red
    echo         color2 = ^(0, 255, 0^)  # Green
    echo         
    echo         image = Image.new^('RGB', ^(width, height^), color=^(255, 255, 255^)^)
    echo         dc = ImageDraw.Draw^(image^)
    echo         
    echo         # Draw a circle
    echo         if self.process and self.process.poll^(^) is None:
    echo             color = color2  # Green when running
    echo         else:
    echo             color = color1  # Red when stopped
    echo         
    echo         dc.ellipse^([10, 10, width-10, height-10], fill=color^)
    echo         
    echo         return image
    echo     
    echo     def start_server^(self^):
    echo         """Start the MCP server"""
    echo         if self.process is None or self.process.poll^(^) is not None:
    echo             script_dir = os.path.dirname^(os.path.abspath^(__file__^)^)
    echo             script_path = os.path.join^(script_dir, 'my_mcp.py'^)
    echo             
    echo             try:
    echo                 self.process = subprocess.Popen^(
    echo                     [sys.executable, script_path],
    echo                     stdout=subprocess.PIPE,
    echo                     stderr=subprocess.PIPE,
    echo                     creationflags=subprocess.CREATE_NO_WINDOW
    echo                 ^)
    echo                 print^("MCP Server started"^)
    echo                 if self.icon:
    echo                     self.icon.icon = self.create_icon_image^(^)
    echo             except Exception as e:
    echo                 print^(f"Failed to start server: {e}"^)
    echo     
    echo     def stop_server^(self^):
    echo         """Stop the MCP server"""
    echo         if self.process and self.process.poll^(^) is None:
    echo             self.process.terminate^(^)
    echo             try:
    echo                 self.process.wait^(timeout=5^)
    echo             except subprocess.TimeoutExpired:
    echo                 self.process.kill^(^)
    echo             print^("MCP Server stopped"^)
    echo             if self.icon:
    echo                 self.icon.icon = self.create_icon_image^(^)
    echo     
    echo     def restart_server^(self, icon, item^):
    echo         """Restart the MCP server"""
    echo         self.stop_server^(^)
    echo         self.start_server^(^)
    echo     
    echo     def quit_app^(self, icon, item^):
    echo         """Quit the application"""
    echo         self.stop_server^(^)
    echo         icon.stop^(^)
    echo     
    echo     def show_status^(self, icon, item^):
    echo         """Show server status"""
    echo         if self.process and self.process.poll^(^) is None:
    echo             print^("Server Status: RUNNING"^)
    echo         else:
    echo             print^("Server Status: STOPPED"^)
    echo     
    echo     def run^(self^):
    echo         """Run the system tray application"""
    echo         # Start the server
    echo         self.start_server^(^)
    echo         
    echo         # Create system tray icon
    echo         menu = pystray.Menu^(
    echo             item^('Status', self.show_status^),
    echo             item^('Restart Server', self.restart_server^),
    echo             pystray.Menu.SEPARATOR,
    echo             item^('Quit', self.quit_app^)
    echo         ^)
    echo         
    echo         self.icon = pystray.Icon^(
    echo             "mcp_server",
    echo             self.create_icon_image^(^),
    echo             "YouTube MCP Server",
    echo             menu
    echo         ^)
    echo         
    echo         self.icon.run^(^)
    echo.
    echo if __name__ == "__main__":
    echo     app = MCPServerTray^(^)
    echo     app.run^(^)
) > "%INSTALL_DIR%mcp_tray.py"

echo [+] System tray wrapper created
echo.

echo [9/11] Creating launcher files...
echo.

:: Create start.bat file for system tray
(
    echo @echo off
    echo :: Start YouTube MCP Server in System Tray
    echo.
    echo :: Get current directory
    echo set "INSTALL_DIR=%%~dp0"
    echo set "VENV_DIR=%%INSTALL_DIR%%venv"
    echo.
    echo :: Check if virtual environment exists
    echo if not exist "%%VENV_DIR%%" ^(
    echo     echo Virtual environment not found!
    echo     echo Please run setup.bat first.
    echo     pause
    echo     exit /b 1
    echo ^)
    echo.
    echo :: Activate virtual environment and start tray app
    echo call "%%VENV_DIR%%\Scripts\activate.bat"
    echo start /B pythonw "%%INSTALL_DIR%%mcp_tray.py"
    echo.
    echo echo YouTube MCP Server started in system tray!
    echo echo Look for the icon in your system tray ^(bottom-right corner^).
    echo echo.
    echo timeout /t 3 /nobreak ^>nul
) > "%INSTALL_DIR%start.bat"

echo [+] start.bat created successfully

:: Create start-visible.bat for debugging
(
    echo @echo off
    echo :: Start YouTube MCP Server with visible window ^(for debugging^)
    echo.
    echo title YouTube MCP Server
    echo color 0B
    echo.
    echo echo ========================================
    echo echo   YouTube MCP Server - Starting...
    echo echo ========================================
    echo echo.
    echo.
    echo :: Get current directory
    echo set "INSTALL_DIR=%%~dp0"
    echo set "VENV_DIR=%%INSTALL_DIR%%venv"
    echo set "SCRIPT_PATH=%%INSTALL_DIR%%my_mcp.py"
    echo.
    echo :: Activate virtual environment
    echo call "%%VENV_DIR%%\Scripts\activate.bat"
    echo.
    echo :: Start the MCP server
    echo echo [+] Server is running...
    echo echo [+] Use Gemini CLI to interact with the server
    echo echo.
    echo echo Press Ctrl+C to stop the server
    echo echo.
    echo.
    echo python "%%SCRIPT_PATH%%"
    echo.
    echo pause
) > "%INSTALL_DIR%start-visible.bat"

echo [+] start-visible.bat created successfully

:: Create start-gemini.bat file
(
    echo @echo off
    echo :: Launch Gemini CLI with Virtual Environment
    echo :: This script activates the virtual environment and starts Gemini CLI
    echo.
    echo title Gemini CLI - YouTube MCP Server
    echo.
    echo :: Set colors for better UX
    echo color 0B
    echo.
    echo :: Get current directory
    echo set "INSTALL_DIR=%%~dp0"
    echo set "VENV_DIR=%%INSTALL_DIR%%venv"
    echo.
    echo echo ========================================
    echo echo   Gemini CLI - YouTube MCP Server
    echo echo ========================================
    echo echo.
    echo.
    echo :: Check if virtual environment exists
    echo if not exist "%%VENV_DIR%%" ^(
    echo     echo [!] Virtual environment not found!
    echo     echo.
    echo     echo Please run setup.bat first to install the MCP server.
    echo     echo.
    echo     pause
    echo     exit /b 1
    echo ^)
    echo.
    echo :: Activate virtual environment
    echo echo [*] Activating virtual environment...
    echo call "%%VENV_DIR%%\Scripts\activate.bat"
    echo.
    echo if errorlevel 1 ^(
    echo     echo [!] Failed to activate virtual environment
    echo     pause
    echo     exit /b 1
    echo ^)
    echo.
    echo echo [+] Virtual environment activated
    echo echo.
    echo.
    echo :: Check if gemini is installed
    echo where gemini ^>nul 2^>^&1
    echo if errorlevel 1 ^(
    echo     echo [!] Gemini CLI not found in virtual environment
    echo     echo.
    echo     echo Installing Gemini CLI...
    echo     python -m pip install gemini-cli
    echo     echo.
    echo ^)
    echo.
    echo echo ========================================
    echo echo   Starting Gemini CLI...
    echo echo ========================================
    echo echo.
    echo echo [+] MCP Server should be running in system tray
    echo echo [+] You can now use YouTube download features!
    echo echo.
    echo echo Available commands:
    echo echo   - Search and download YouTube videos
    echo echo   - Download audio as MP3
    echo echo   - Get video information
    echo echo.
    echo echo Downloads location: %%USERPROFILE%%\Downloads\mcp_ytdlp
    echo echo.
    echo echo ========================================
    echo echo.
    echo.
    echo :: Start Gemini CLI
    echo gemini
    echo.
    echo :: Keep window open if gemini exits
    echo echo.
    echo echo Gemini CLI closed.
    echo pause
) > "%INSTALL_DIR%start-gemini.bat"

echo [+] start-gemini.bat created successfully

echo.
echo [10/11] Creating update utility...
echo.

:: Create update.bat file
(
    echo @echo off
    echo :: Update Script for YouTube MCP Server
    echo :: This script updates the MCP server and all dependencies
    echo.
    echo title YouTube MCP Server - Update
    echo color 0D
    echo.
    echo :: Get current directory
    echo set "INSTALL_DIR=%%~dp0"
    echo set "VENV_DIR=%%INSTALL_DIR%%venv"
    echo set "SCRIPT_NAME=my_mcp.py"
    echo set "SCRIPT_URL=https://aryan9019.github.io/mcp/my_mcp.py"
    echo set "BACKUP_DIR=%%INSTALL_DIR%%backup"
    echo.
    echo echo ========================================
    echo echo   YouTube MCP Server - Update
    echo echo ========================================
    echo echo.
    echo echo This will update:
    echo echo   - MCP server script
    echo echo   - Python packages ^(mcp, yt-dlp, pystray, etc.^)
    echo echo   - Gemini CLI
    echo echo.
    echo set /p "CONFIRM=Continue with update? ^(Y/N^): "
    echo if /i not "%%CONFIRM%%"=="Y" ^(
    echo     echo Update cancelled.
    echo     pause
    echo     exit /b 0
    echo ^)
    echo.
    echo echo [1/5] Creating backup...
    echo echo.
    echo.
    echo :: Create backup directory
    echo if not exist "%%BACKUP_DIR%%" mkdir "%%BACKUP_DIR%%"
    echo.
    echo :: Backup current script with timestamp
    echo for /f "tokens=2 delims==" %%%%I in ^('wmic os get localdatetime /value'^) do set datetime=%%%%I
    echo set TIMESTAMP=%%datetime:~0,8%%_%%datetime:~8,6%%
    echo.
    echo if exist "%%INSTALL_DIR%%%%SCRIPT_NAME%%" ^(
    echo     copy "%%INSTALL_DIR%%%%SCRIPT_NAME%%" "%%BACKUP_DIR%%\%%SCRIPT_NAME%%.%%TIMESTAMP%%.bak" ^>nul
    echo     echo [+] Backup created: %%SCRIPT_NAME%%.%%TIMESTAMP%%.bak
    echo ^) else ^(
    echo     echo [!] No existing script to backup
    echo ^)
    echo echo.
    echo.
    echo echo [2/5] Downloading latest MCP server script...
    echo echo.
    echo.
    echo :: Download the latest script
    echo powershell -Command "& {Invoke-WebRequest -Uri '%%SCRIPT_URL%%' -OutFile '%%INSTALL_DIR%%%%SCRIPT_NAME%%'}" ^>nul 2^>^&1
    echo if errorlevel 1 ^(
    echo     echo [!] Failed to download script from %%SCRIPT_URL%%
    echo     echo [*] Restoring from backup...
    echo     copy "%%BACKUP_DIR%%\%%SCRIPT_NAME%%.%%TIMESTAMP%%.bak" "%%INSTALL_DIR%%%%SCRIPT_NAME%%" ^>nul
    echo     echo.
    echo     echo Update failed. Original script restored.
    echo     pause
    echo     exit /b 1
    echo ^)
    echo.
    echo echo [+] Script downloaded successfully
    echo echo.
    echo.
    echo echo [3/5] Updating Python packages...
    echo echo.
    echo.
    echo :: Activate virtual environment
    echo call "%%VENV_DIR%%\Scripts\activate.bat"
    echo.
    echo if errorlevel 1 ^(
    echo     echo [!] Failed to activate virtual environment
    echo     pause
    echo     exit /b 1
    echo ^)
    echo.
    echo :: Upgrade pip
    echo echo [*] Upgrading pip...
    echo python -m pip install --upgrade pip ^>nul 2^>^&1
    echo.
    echo :: Update packages
    echo echo [*] Updating mcp...
    echo python -m pip install --upgrade mcp ^>nul 2^>^&1
    echo.
    echo echo [*] Updating yt-dlp...
    echo python -m pip install --upgrade yt-dlp ^>nul 2^>^&1
    echo.
    echo echo [*] Updating pystray...
    echo python -m pip install --upgrade pystray pillow ^>nul 2^>^&1
    echo.
    echo echo [+] All packages updated successfully
    echo echo.
    echo.
    echo echo [4/5] Updating Gemini CLI...
    echo echo.
    echo.
    echo :: Update Gemini CLI
    echo python -m pip install --upgrade gemini-cli ^>nul 2^>^&1
    echo if errorlevel 1 ^(
    echo     echo [!] Failed to update Gemini CLI
    echo ^) else ^(
    echo     echo [+] Gemini CLI updated successfully
    echo ^)
    echo echo.
    echo.
    echo echo [5/5] Verifying update...
    echo echo.
    echo.
    echo :: Show versions
    echo echo Installed versions:
    echo echo.
    echo for /f "tokens=2" %%%%i in ^('python -m pip show mcp ^| findstr "Version"'^) do echo   mcp: %%%%i
    echo for /f "tokens=2" %%%%i in ^('python -m pip show yt-dlp ^| findstr "Version"'^) do echo   yt-dlp: %%%%i
    echo for /f "tokens=2" %%%%i in ^('python -m pip show pystray ^| findstr "Version"'^) do echo   pystray: %%%%i
    echo for /f "tokens=2" %%%%i in ^('python -m pip show gemini-cli ^| findstr "Version"'^) do echo   gemini-cli: %%%%i
    echo echo.
    echo.
    echo echo ========================================
    echo echo   Update Complete!
    echo echo ========================================
    echo echo.
    echo echo Backups are stored in: %%BACKUP_DIR%%
    echo echo.
    echo echo If you experience any issues:
    echo echo   1. Check the backup folder
    echo echo   2. Run check-status.bat to verify installation
    echo echo   3. Re-run setup.bat if needed
    echo echo.
    echo echo To start using the updated server:
    echo echo   1. Double-click "start.bat" to start the MCP server
    echo echo   2. Double-click "start-gemini.bat" to launch Gemini CLI
    echo echo.
    echo pause
) > "%INSTALL_DIR%update.bat"

echo [+] update.bat created successfully
echo.

echo [11/11] Creating system check utility...
echo.

:: Create check-status.bat file (updated version)
(
    echo @echo off
    echo :: System Status Checker for YouTube MCP Server
    echo :: This script checks if everything is installed correctly
    echo.
    echo title System Status Check - YouTube MCP Server
    echo color 0E
    echo.
    echo :: Get current directory
    echo set "INSTALL_DIR=%%~dp0"
    echo set "VENV_DIR=%%INSTALL_DIR%%venv"
    echo set "SCRIPT_NAME=my_mcp.py"
    echo set "SCRIPT_PATH=%%INSTALL_DIR%%%%SCRIPT_NAME%%"
    echo.
    echo echo ========================================
    echo echo   YouTube MCP Server - Status Check
    echo echo ========================================
    echo echo.
    echo echo Checking system components...
    echo echo.
    echo.
    echo :: Check 1: Python Installation
    echo echo [1/9] Checking Python installation...
    echo python --version ^>nul 2^>^&1
    echo if errorlevel 1 ^(
    echo     echo [X] Python is NOT installed
    echo     echo     ^> Install from: https://www.python.org/downloads/
    echo     set "STATUS_FAILED=1"
    echo ^) else ^(
    echo     for /f "tokens=2" %%%%i in ^('python --version 2^>^&1'^) do set PYTHON_VERSION=%%%%i
    echo     echo [+] Python !PYTHON_VERSION! is installed
    echo ^)
    echo echo.
    echo.
    echo :: Check 2: pip Installation
    echo echo [2/9] Checking pip installation...
    echo python -m pip --version ^>nul 2^>^&1
    echo if errorlevel 1 ^(
    echo     echo [X] pip is NOT installed
    echo     set "STATUS_FAILED=1"
    echo ^) else ^(
    echo     for /f "tokens=2" %%%%i in ^('python -m pip --version 2^>^&1'^) do set PIP_VERSION=%%%%i
    echo     echo [+] pip !PIP_VERSION! is installed
    echo ^)
    echo echo.
    echo.
    echo :: Check 3: Virtual Environment
    echo echo [3/9] Checking virtual environment...
    echo if not exist "%%VENV_DIR%%" ^(
    echo     echo [X] Virtual environment NOT found
    echo     echo     ^> Location: %%VENV_DIR%%
    echo     echo     ^> Run setup.bat to create it
    echo     set "STATUS_FAILED=1"
    echo ^) else ^(
    echo     echo [+] Virtual environment exists
    echo     echo     ^> Location: %%VENV_DIR%%
    echo ^)
    echo echo.
    echo.
    echo :: Check 4: MCP Script
    echo echo [4/9] Checking MCP server script...
    echo if not exist "%%SCRIPT_PATH%%" ^(
    echo     echo [X] MCP server script NOT found
    echo     echo     ^> Expected: %%SCRIPT_PATH%%
    echo     echo     ^> Run setup.bat to download it
    echo     set "STATUS_FAILED=1"
    echo ^) else ^(
    echo     echo [+] MCP server script exists
    echo     echo     ^> Location: %%SCRIPT_PATH%%
    echo ^)
    echo echo.
    echo.
    echo :: Check 5: System Tray Wrapper
    echo echo [5/9] Checking system tray wrapper...
    echo if not exist "%%INSTALL_DIR%%mcp_tray.py" ^(
    echo     echo [X] System tray wrapper NOT found
    echo     echo     ^> Run setup.bat to create it
    echo     set "STATUS_FAILED=1"
    echo ^) else ^(
    echo     echo [+] System tray wrapper exists
    echo ^)
    echo echo.
    echo.
    echo :: Check 6: Required Python Packages
    echo echo [6/9] Checking Python packages in virtual environment...
    echo call "%%VENV_DIR%%\Scripts\activate.bat" ^>nul 2^>^&1
    echo if errorlevel 1 ^(
    echo     echo [X] Cannot activate virtual environment
    echo     set "STATUS_FAILED=1"
    echo ^) else ^(
    echo     python -m pip show mcp ^>nul 2^>^&1
    echo     if errorlevel 1 ^(
    echo         echo [X] mcp package NOT installed
    echo         set "STATUS_FAILED=1"
    echo     ^) else ^(
    echo         echo [+] mcp package is installed
    echo     ^)
    echo     
    echo     python -m pip show yt-dlp ^>nul 2^>^&1
    echo     if errorlevel 1 ^(
    echo         echo [X] yt-dlp package NOT installed
    echo         set "STATUS_FAILED=1"
    echo     ^) else ^(
    echo         echo [+] yt-dlp package is installed
    echo     ^)
    echo     
    echo     python -m pip show pystray ^>nul 2^>^&1
    echo     if errorlevel 1 ^(
    echo         echo [X] pystray package NOT installed
    echo         set "STATUS_FAILED=1"
    echo     ^) else ^(
    echo         echo [+] pystray package is installed
    echo     ^)
    echo ^)
    echo echo.
    echo.
    echo :: Check 7: Gemini CLI
    echo echo [7/9] Checking Gemini CLI...
    echo where gemini ^>nul 2^>^&1
    echo if errorlevel 1 ^(
    echo     echo [X] Gemini CLI NOT installed
    echo     echo     ^> Run setup.bat to install it
    echo     set "STATUS_FAILED=1"
    echo ^) else ^(
    echo     echo [+] Gemini CLI is installed
    echo ^)
    echo echo.
    echo.
    echo :: Check 8: Gemini Configuration
    echo echo [8/9] Checking Gemini configuration...
    echo set "GEMINI_CONFIG=%%USERPROFILE%%\.gemini\settings.json"
    echo if not exist "%%GEMINI_CONFIG%%" ^(
    echo     echo [!] Gemini settings.json NOT found
    echo     echo     ^> Location: %%GEMINI_CONFIG%%
    echo     echo     ^> This will be created on first run
    echo ^) else ^(
    echo     echo [+] Gemini settings.json exists
    echo     echo     ^> Location: %%GEMINI_CONFIG%%
    echo ^)
    echo echo.
    echo.
    echo :: Check 9: Launcher Files
    echo echo [9/9] Checking launcher files...
    echo if not exist "%%INSTALL_DIR%%start.bat" ^(
    echo     echo [X] start.bat NOT found
    echo     set "STATUS_FAILED=1"
    echo ^) else ^(
    echo     echo [+] start.bat exists
    echo ^)
    echo.
    echo if not exist "%%INSTALL_DIR%%start-visible.bat" ^(
    echo     echo [X] start-visible.bat NOT found
    echo     set "STATUS_FAILED=1"
    echo ^) else ^(
    echo     echo [+] start-visible.bat exists
    echo ^)
    echo.
    echo if not exist "%%INSTALL_DIR%%start-gemini.bat" ^(
    echo     echo [X] start-gemini.bat NOT found
    echo     set "STATUS_FAILED=1"
    echo ^) else ^(
    echo     echo [+] start-gemini.bat exists
    echo ^)
    echo.
    echo if not exist "%%INSTALL_DIR%%update.bat" ^(
    echo     echo [X] update.bat NOT found
    echo     set "STATUS_FAILED=1"
    echo ^) else ^(
    echo     echo [+] update.bat exists
    echo ^)
    echo echo.
    echo.
    echo echo ========================================
    echo if defined STATUS_FAILED ^(
    echo     echo   STATUS: ISSUES FOUND!
    echo     echo ========================================
    echo     echo.
    echo     echo Some components are missing or not installed correctly.
    echo     echo Please run setup.bat to fix the issues.
    echo ^) else ^(
    echo     echo   STATUS: ALL SYSTEMS GO!
    echo     echo ========================================
    echo     echo.
    echo     echo Everything is installed correctly!
    echo     echo.
    echo     echo To start using the MCP server:
    echo     echo   1. Double-click "start.bat" to start MCP server in system tray
    echo     echo   2. Double-click "start-gemini.bat" to launch Gemini CLI
    echo     echo   3. Start downloading YouTube videos!
    echo     echo.
    echo     echo Note: Use "start-visible.bat" for debugging if needed
    echo ^)
    echo echo.
    echo echo Installation directory: %%INSTALL_DIR%%
    echo echo Downloads location: %%USERPROFILE%%\Downloads\mcp_ytdlp
    echo echo.
    echo pause
) > "%INSTALL_DIR%check-status.bat"

echo [+] check-status.bat created successfully
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
echo Created files:
echo   [+] start.bat - Starts MCP server in system tray
echo   [+] start-visible.bat - Starts server with visible window (debug)
echo   [+] start-gemini.bat - Launches Gemini CLI
echo   [+] update.bat - Updates server and dependencies
echo   [+] check-status.bat - Checks system status
echo   [+] mcp_tray.py - System tray wrapper
echo.
echo ========================================
echo   Quick Start Guide
echo ========================================
echo.
echo Step 1: Double-click "start.bat"
echo   ^> This starts the MCP server in your system tray
echo   ^> Look for the icon in the bottom-right corner
echo   ^> Right-click the icon to see options
echo.
echo Step 2: Double-click "start-gemini.bat"
echo   ^> This opens Gemini CLI in a new window
echo.
echo Step 3: Start using YouTube features!
echo   - Search YouTube videos
echo   - Download videos (various resolutions^)
echo   - Download audio (MP3^)
echo   - Get video information
echo.
echo Downloads will be saved to: %USERPROFILE%\Downloads\mcp_ytdlp
echo.
echo ========================================
echo   System Tray Features
echo ========================================
echo.
echo The system tray icon shows server status:
echo   - Green: Server is running
echo   - Red: Server is stopped
echo.
echo Right-click the tray icon for options:
echo   - Status: Check if server is running
echo   - Restart Server: Restart the MCP server
echo   - Quit: Stop server and close tray app
echo.
echo ========================================
echo   Maintenance
echo ========================================
echo.
echo To UPDATE the server: Run "update.bat"
echo   ^> Updates MCP server script and all packages
echo   ^> Creates automatic backups
echo.
echo To CHECK STATUS: Run "check-status.bat"
echo   ^> Verifies all components are installed
echo.
echo For DEBUGGING: Use "start-visible.bat"
echo   ^> Shows server output in a console window
echo.
echo ========================================
echo.
pause
