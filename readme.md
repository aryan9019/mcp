# YouTube MCP Server - Easy Installation Guide

## What is this?

This is a YouTube downloader that works with Google's Gemini AI. You can ask Gemini to:
- Search for YouTube videos
- Download videos in any quality (720p, 1080p, 4K, etc.)
- Download audio as MP3
- Get video information

## Requirements

- **Windows 10 or 11**
- **Python 3.8 or higher** - Download from: https://www.python.org/downloads/
  - ⚠️ **IMPORTANT**: During Python installation, check "Add Python to PATH"!
- **Internet connection**

## Installation Steps

### Step 1: Install Python (if not already installed)

1. Go to https://www.python.org/downloads/
2. Download the latest Python version
3. Run the installer
4. ✅ **CHECK THE BOX**: "Add Python to PATH" (very important!)
5. Click "Install Now"

### Step 2: Download the Setup Script

1. Create a new folder anywhere (e.g., `C:\YouTube-MCP`)
2. Download `setup.bat` and save it in that folder
3. Double-click `setup.bat`

### Step 3: Let the Setup Run

The setup will automatically:
- ✅ Check Python installation
- ✅ Download the MCP server script
- ✅ Create a virtual environment
- ✅ Install all required packages (mcp, yt-dlp, etc.)
- ✅ Install Gemini CLI
- ✅ Configure everything
- ✅ Create a `start.bat` launcher

**Wait for the setup to complete!** It may take 2-5 minutes.

### Step 4: Start Using It!

1. **Start the server**: Double-click `start.bat` in your folder
   - A black window will open - **KEEP IT OPEN**!
   - You should see "Server Status: RUNNING"

2. **Open Gemini CLI**: 
   - Open a **NEW** Command Prompt (search for "cmd" in Windows)
   - Type: `gemini` and press Enter
   - Wait for Gemini to start

3. **Try it out!**
   - Ask Gemini: "Search for Python tutorial videos"
   - Ask Gemini: "Download the first video in 720p"
   - Ask Gemini: "Download audio from this video: [paste URL]"

## Where are my downloads?

All downloads are saved to:
```
C:\Users\[YourUsername]\Downloads\mcp_ytdlp
```

## Usage Examples

**Search videos:**
```
"Search YouTube for cooking recipes"
"Find recent tech review videos"
```

**Download videos:**
```
"Download this video in 1080p: https://youtube.com/watch?v=..."
"Download the first search result in best quality"
"Download video in 720p"
```

**Download audio:**
```
"Download audio from this video as MP3"
"Download only the audio in MP3 format"
```

**Get video info:**
```
"Get information about this video: [URL]"
"What formats are available for this video?"
```

## Troubleshooting

### "Python is not recognized..."
- You forgot to check "Add Python to PATH" during installation
- Uninstall Python and reinstall it, **making sure to check that box**

### "Gemini is not recognized..."
- Close Command Prompt and open a new one
- The setup installed Gemini CLI but you need a fresh terminal

### Downloads fail with "403 Forbidden"
- Make sure you're logged into YouTube in your browser (Chrome, Firefox, or Edge)
- Try watching the video in your browser first
- Wait a few minutes and try again (rate limiting)

### Server window closes immediately
- Right-click `start.bat` → "Edit"
- Check if the paths are correct
- Run `setup.bat` again

### "Virtual environment not found"
- Run `setup.bat` again - it will recreate everything

## Need to Update?

To update yt-dlp (the downloader):
1. Open Command Prompt in your installation folder
2. Run: `venv\Scripts\activate`
3. Run: `pip install -U yt-dlp`
4. Done!

## Uninstallation

To remove everything:
1. Delete the entire folder where you installed it
2. Delete: `C:\Users\[YourUsername]\.gemini` folder (if you want to remove Gemini settings)

## Tips

- Keep the server window open while using Gemini
- You can minimize the server window, just don't close it
- Downloads may take time depending on video size and your internet speed
- For private videos, make sure you're logged into YouTube in your browser

## Support

If something doesn't work:
1. Make sure Python is installed correctly
2. Run `setup.bat` again
3. Check that `start.bat` opens without errors
4. Make sure you're using a **NEW** Command Prompt for Gemini

---

**Enjoy your YouTube downloads with Gemini AI! 🎉**
