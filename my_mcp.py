import asyncio
import os
import json
import random
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

server = Server("yt-dlp-mcp-server")

DOWNLOAD_DIR = os.path.expanduser("~/Downloads/mcp_ytdlp")
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

# Custom cookie path - Update this path for your browser
# For Windows Firefox: C:/Users/USERNAME/AppData/Roaming/Mozilla/Firefox/Profiles/XXXXX.default/cookies.sqlite
# For Windows Chrome: C:/Users/USERNAME/AppData/Local/Google/Chrome/User Data/Default/Network/Cookies
CUSTOM_COOKIE_PATH = ""  # Leave empty if you want to use browser auto-detection

# Rotate user agents to avoid detection
USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
]

def get_base_ytdlp_args(use_oauth=False):
    """Get base yt-dlp arguments with anti-403 measures"""
    args = [
        "yt-dlp",
        "--no-check-certificates",
        "--user-agent", random.choice(USER_AGENTS),
        "--referer", "https://www.youtube.com/",
        "--sleep-interval", "1",
        "--max-sleep-interval", "3",
        "--force-ipv4",
    ]
    
    if use_oauth:
        args.extend(["--extractor-args", "youtube:player_client=android,web"])
    
    return args

async def try_download_with_cookies(url, format_str, output_path):
    """
    Try downloading with cookies in this order:
    1. Custom path (if set)
    2. Firefox
    3. Chrome
    4. Edge
    5. No cookies
    
    Returns: (success: bool, stdout: str, stderr: str, method: str)
    """
    
    # Method 1: Custom cookie path
    if CUSTOM_COOKIE_PATH and os.path.exists(CUSTOM_COOKIE_PATH):
        shell_command = f'yt-dlp --cookies "{CUSTOM_COOKIE_PATH}" -f "{format_str}" -o "{output_path}" "{url}"'
        
        process = await asyncio.create_subprocess_shell(
            shell_command,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        stdout, stderr = await process.communicate()
        
        if process.returncode == 0:
            return (True, stdout.decode(), stderr.decode(), "custom_path")
    
    # Method 2: Firefox cookies
    shell_command = f'yt-dlp --cookies-from-browser firefox -f "{format_str}" -o "{output_path}" "{url}"'
    
    process = await asyncio.create_subprocess_shell(
        shell_command,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    
    stdout, stderr = await process.communicate()
    
    if process.returncode == 0:
        return (True, stdout.decode(), stderr.decode(), "firefox")
    
    # Method 3: Chrome cookies
    shell_command = f'yt-dlp --cookies-from-browser chrome -f "{format_str}" -o "{output_path}" "{url}"'
    
    process = await asyncio.create_subprocess_shell(
        shell_command,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    
    stdout, stderr = await process.communicate()
    
    if process.returncode == 0:
        return (True, stdout.decode(), stderr.decode(), "chrome")
    
    # Method 4: Edge cookies (Windows specific)
    shell_command = f'yt-dlp --cookies-from-browser edge -f "{format_str}" -o "{output_path}" "{url}"'
    
    process = await asyncio.create_subprocess_shell(
        shell_command,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    
    stdout, stderr = await process.communicate()
    
    if process.returncode == 0:
        return (True, stdout.decode(), stderr.decode(), "edge")
    
    # Method 5: No cookies (last resort)
    shell_command = f'yt-dlp -f "{format_str}" -o "{output_path}" "{url}"'
    
    process = await asyncio.create_subprocess_shell(
        shell_command,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    
    stdout, stderr = await process.communicate()
    
    if process.returncode == 0:
        return (True, stdout.decode(), stderr.decode(), "no_cookies")
    
    # All methods failed
    return (False, stdout.decode(), stderr.decode(), "all_failed")

async def try_audio_download_with_cookies(url, output_path):
    """
    Try downloading audio with cookies in fallback order.
    Returns: (success: bool, stdout: str, stderr: str, method: str)
    """
    
    # Method 1: Custom cookie path
    if CUSTOM_COOKIE_PATH and os.path.exists(CUSTOM_COOKIE_PATH):
        shell_command = f'yt-dlp --cookies "{CUSTOM_COOKIE_PATH}" -x --audio-format mp3 --audio-quality 0 -o "{output_path}" "{url}"'
        
        process = await asyncio.create_subprocess_shell(
            shell_command,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        stdout, stderr = await process.communicate()
        
        if process.returncode == 0:
            return (True, stdout.decode(), stderr.decode(), "custom_path")
    
    # Method 2: Firefox cookies
    shell_command = f'yt-dlp --cookies-from-browser firefox -x --audio-format mp3 --audio-quality 0 -o "{output_path}" "{url}"'
    
    process = await asyncio.create_subprocess_shell(
        shell_command,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    
    stdout, stderr = await process.communicate()
    
    if process.returncode == 0:
        return (True, stdout.decode(), stderr.decode(), "firefox")
    
    # Method 3: Chrome cookies
    shell_command = f'yt-dlp --cookies-from-browser chrome -x --audio-format mp3 --audio-quality 0 -o "{output_path}" "{url}"'
    
    process = await asyncio.create_subprocess_shell(
        shell_command,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    
    stdout, stderr = await process.communicate()
    
    if process.returncode == 0:
        return (True, stdout.decode(), stderr.decode(), "chrome")
    
    # Method 4: Edge cookies
    shell_command = f'yt-dlp --cookies-from-browser edge -x --audio-format mp3 --audio-quality 0 -o "{output_path}" "{url}"'
    
    process = await asyncio.create_subprocess_shell(
        shell_command,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    
    stdout, stderr = await process.communicate()
    
    if process.returncode == 0:
        return (True, stdout.decode(), stderr.decode(), "edge")
    
    # Method 5: No cookies
    shell_command = f'yt-dlp -x --audio-format mp3 --audio-quality 0 -o "{output_path}" "{url}"'
    
    process = await asyncio.create_subprocess_shell(
        shell_command,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    
    stdout, stderr = await process.communicate()
    
    if process.returncode == 0:
        return (True, stdout.decode(), stderr.decode(), "no_cookies")
    
    # All methods failed
    return (False, stdout.decode(), stderr.decode(), "all_failed")

# ----------------------
# 1. Advertise tools
# ----------------------
@server.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="search_youtube",
            description="Search for YouTube videos. Returns a list of videos with titles, URLs, durations, and view counts.",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Search query"},
                    "max_results": {
                        "type": "integer",
                        "description": "Maximum number of results to return (1-20)",
                        "default": 5,
                        "minimum": 1,
                        "maximum": 20
                    }
                },
                "required": ["query"]
            }
        ),
        Tool(
            name="download_youtube_video",
            description="Download a YouTube video as MP4 using yt-dlp. Args: url, resolution (best, 720p, 1080p, 1440p, 2160p/4k).",
            inputSchema={
                "type": "object",
                "properties": {
                    "url": {"type": "string", "description": "YouTube video URL"},
                    "resolution": {
                        "type": "string",
                        "description": "Preferred resolution",
                        "enum": ["best", "720p", "1080p", "1440p", "2160p", "4k"],
                        "default": "best"
                    }
                },
                "required": ["url"]
            }
        ),
        Tool(
            name="download_youtube_audio",
            description="Download audio from a YouTube video as MP3.",
            inputSchema={
                "type": "object",
                "properties": {
                    "url": {"type": "string", "description": "YouTube video URL"}
                },
                "required": ["url"]
            }
        ),
        Tool(
            name="get_video_info",
            description="Get detailed information about a YouTube video (title, duration, description, formats available).",
            inputSchema={
                "type": "object",
                "properties": {
                    "url": {"type": "string", "description": "YouTube video URL"}
                },
                "required": ["url"]
            }
        )
    ]

# ----------------------
# 2. Handle tool call
# ----------------------
@server.call_tool()
async def call_tool(name: str, arguments: dict):
    if name == "search_youtube":
        return await handle_search(arguments)
    elif name == "download_youtube_video":
        return await handle_download(arguments)
    elif name == "download_youtube_audio":
        return await handle_audio_download(arguments)
    elif name == "get_video_info":
        return await handle_video_info(arguments)
    else:
        return [TextContent(type="text", text=f"Unknown tool: {name}")]

async def handle_search(arguments: dict):
    """Handle YouTube search requests"""
    query = arguments.get("query")
    max_results = arguments.get("max_results", 5)
    
    if not query:
        return [TextContent(type="text", text="Error: 'query' argument is required.")]
    
    max_results = max(1, min(20, max_results))
    
    try:
        cmd_args = get_base_ytdlp_args(use_oauth=True) + [
            "--dump-json",
            "--flat-playlist",
            "--playlist-end", str(max_results),
            f"ytsearch{max_results}:{query}"
        ]
        
        process = await asyncio.create_subprocess_exec(
            *cmd_args,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        stdout, stderr = await process.communicate()
        
        if process.returncode != 0:
            error_msg = stderr.decode() if stderr else "Unknown error"
            return [TextContent(type="text", text=f"Search failed. Error: {error_msg}")]
        
        results = []
        for line in stdout.decode().strip().split('\n'):
            if line.strip():
                try:
                    video_info = json.loads(line)
                    results.append({
                        "title": video_info.get("title", "Unknown"),
                        "url": f"https://www.youtube.com/watch?v={video_info.get('id', '')}",
                        "duration": video_info.get("duration_string", "Unknown"),
                        "views": video_info.get("view_count", "Unknown"),
                        "uploader": video_info.get("uploader", "Unknown"),
                        "id": video_info.get("id", "")
                    })
                except json.JSONDecodeError:
                    continue
        
        if not results:
            return [TextContent(type="text", text=f"No results found for: {query}")]
        
        output = f"🔍 Found {len(results)} results for '{query}':\n\n"
        for i, video in enumerate(results, 1):
            views_formatted = f"{video['views']:,}" if isinstance(video['views'], int) else video['views']
            output += f"{i}. **{video['title']}**\n"
            output += f"   👤 {video['uploader']} | ⏱️ {video['duration']} | 👁️ {views_formatted} views\n"
            output += f"   🔗 {video['url']}\n\n"
        
        return [TextContent(type="text", text=output)]
        
    except Exception as e:
        return [TextContent(type="text", text=f"Exception during search: {str(e)}")]

async def handle_download(arguments: dict):
    """Handle YouTube video download requests with cookie fallback chain"""
    url = arguments.get("url")
    resolution = arguments.get("resolution", "best")
    
    if not url:
        return [TextContent(type="text", text="Error: 'url' argument is required.")]
    
    try:
        output_path = os.path.join(DOWNLOAD_DIR, "%(title)s.%(ext)s")
        
        if resolution == "best":
            format_str = "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]"
        else:
            if resolution.lower() == "4k":
                resolution = "2160p"
            
            res_num = resolution.lower().replace("p", "")
            format_str = f"bestvideo[height<={res_num}][ext=mp4]+bestaudio[ext=m4a]/best[height<={res_num}][ext=mp4]"
        
        # Try download with cookie fallback
        success, stdout, stderr, method = await try_download_with_cookies(url, format_str, output_path)
        
        if success:
            method_names = {
                "custom_path": "custom browser cookies",
                "firefox": "Firefox cookies",
                "chrome": "Chrome cookies",
                "edge": "Edge cookies",
                "no_cookies": "no cookies (public video)"
            }
            
            # Extract only the filename from stdout (ignore progress lines)
            filename = None
            for line in stdout.split('\n'):
                if 'Merging formats into' in line or 'has already been downloaded' in line:
                    # Extract filename from merger message
                    if '"' in line:
                        filename = line.split('"')[1].split('/')[-1].split('\\')[-1]
                        break
            
            result_msg = f"✅ Download complete! (using {method_names.get(method, method)})\n📁 Saved in {DOWNLOAD_DIR}"
            if filename:
                result_msg += f"\n📄 File: {filename}"
            
            return [TextContent(type="text", text=result_msg)]
        else:
            # All methods failed
            if "403" in stderr or "HTTP Error 403" in stderr:
                return [TextContent(type="text", text=f"❌ Download failed with 403 Forbidden error.\n\n"
                    f"Suggestions:\n"
                    f"1. Make sure you're logged into YouTube in Firefox, Chrome, or Edge\n"
                    f"2. Wait a few minutes and try again (rate limiting)\n"
                    f"3. Update yt-dlp: pip install -U yt-dlp\n"
                    f"4. Try watching the video in your browser first\n\n"
                    f"Tried all cookie sources:\n"
                    f"✗ Custom path\n"
                    f"✗ Firefox\n"
                    f"✗ Chrome\n"
                    f"✗ Edge\n"
                    f"✗ No cookies\n\n"
                    f"Error details: {stderr}")]
            
            return [TextContent(type="text", text=f"❌ Download failed after trying all cookie sources.\n"
                f"Error: {stderr}\nURL: {url}\nResolution: {resolution}")]
        
    except Exception as e:
        return [TextContent(type="text", text=f"Exception: {str(e)}")]

async def handle_audio_download(arguments: dict):
    """Handle YouTube audio download requests with cookie fallback chain"""
    url = arguments.get("url")
    
    if not url:
        return [TextContent(type="text", text="Error: 'url' argument is required.")]
    
    try:
        output_path = os.path.join(DOWNLOAD_DIR, "%(title)s.%(ext)s")
        
        # Try download with cookie fallback
        success, stdout, stderr, method = await try_audio_download_with_cookies(url, output_path)
        
        if success:
            method_names = {
                "custom_path": "custom browser cookies",
                "firefox": "Firefox cookies",
                "chrome": "Chrome cookies",
                "edge": "Edge cookies",
                "no_cookies": "no cookies (public video)"
            }
            
            # Extract only the filename from stdout
            filename = None
            for line in stdout.split('\n'):
                if 'Destination:' in line or 'has already been downloaded' in line:
                    if '/' in line or '\\' in line:
                        filename = line.split('/')[-1].split('\\')[-1].strip()
                        break
            
            result_msg = f"🎵 Audio download complete! (using {method_names.get(method, method)})\n📁 Saved in {DOWNLOAD_DIR}"
            if filename:
                result_msg += f"\n📄 File: {filename}"
            
            return [TextContent(type="text", text=result_msg)]
        else:
            return [TextContent(type="text", text=f"❌ Audio download failed after trying all cookie sources.\n"
                f"Error: {stderr}")]
        
    except Exception as e:
        return [TextContent(type="text", text=f"Exception: {str(e)}")]

async def handle_video_info(arguments: dict):
    """Get detailed information about a YouTube video"""
    url = arguments.get("url")
    
    if not url:
        return [TextContent(type="text", text="Error: 'url' argument is required.")]
    
    try:
        cmd_args = get_base_ytdlp_args(use_oauth=False) + [
            "--dump-json",
            "--no-playlist",
            url
        ]
        
        process = await asyncio.create_subprocess_exec(
            *cmd_args,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        stdout, stderr = await process.communicate()
        
        if process.returncode != 0:
            error_msg = stderr.decode() if stderr else "Unknown error"
            return [TextContent(type="text", text=f"Failed to get video info. Error: {error_msg}")]
        
        video_info = json.loads(stdout.decode())
        
        title = video_info.get("title", "Unknown")
        uploader = video_info.get("uploader", "Unknown")
        duration = video_info.get("duration_string", "Unknown")
        views = video_info.get("view_count", 0)
        likes = video_info.get("like_count", 0)
        description = video_info.get("description", "No description")[:500]
        upload_date = video_info.get("upload_date", "Unknown")
        
        if upload_date != "Unknown" and len(upload_date) == 8:
            upload_date = f"{upload_date[:4]}-{upload_date[4:6]}-{upload_date[6:]}"
        
        formats = video_info.get("formats", [])
        resolutions = set()
        for fmt in formats:
            height = fmt.get("height")
            if height:
                resolutions.add(f"{height}p")
        
        output = f"📹 **{title}**\n\n"
        output += f"👤 Uploader: {uploader}\n"
        output += f"📅 Upload Date: {upload_date}\n"
        output += f"⏱️ Duration: {duration}\n"
        output += f"👁️ Views: {views:,}\n"
        output += f"👍 Likes: {likes:,}\n"
        output += f"🎬 Available Resolutions: {', '.join(sorted(resolutions, key=lambda x: int(x.replace('p', '')), reverse=True))}\n\n"
        output += f"📝 Description (preview):\n{description}...\n"
        
        return [TextContent(type="text", text=output)]
        
    except Exception as e:
        return [TextContent(type="text", text=f"Exception: {str(e)}")]

# ----------------------
# 3. Entry point
# ----------------------
async def main():
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            server.create_initialization_options()
        )

if __name__ == "__main__":
    asyncio.run(main())
