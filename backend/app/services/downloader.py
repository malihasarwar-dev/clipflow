"""Step 1 - download the source video with yt-dlp."""
from pathlib import Path
from typing import Callable, Optional

import yt_dlp

from ..config import settings


def download_video(url: str, workdir: Path,
                   on_progress: Optional[Callable[[float], None]] = None) -> tuple[Path, str, float]:
    """Download <=1080p MP4 into workdir/source.mp4. Returns (path, title, duration_seconds)."""

    def hook(d: dict) -> None:
        if on_progress and d.get("status") == "downloading":
            total = d.get("total_bytes") or d.get("total_bytes_estimate")
            if total:
                on_progress(min(d["downloaded_bytes"] / total, 1.0))

    opts = {
        "format": "bv*[height<=1080]+ba/b[height<=1080]/b",
        "merge_output_format": "mp4",
        "outtmpl": str(workdir / "source.%(ext)s"),
        "noplaylist": True,
        "quiet": True,
        "no_warnings": True,
        "progress_hooks": [hook],
    }
    with yt_dlp.YoutubeDL(opts) as ydl:
        # Probe first so we can reject over-long videos before spending bandwidth.
        info = ydl.extract_info(url, download=False)
        duration = float(info.get("duration") or 0)
        if info.get("is_live"):
            raise ValueError("Live streams are not supported.")
        if duration > settings.max_video_minutes * 60:
            raise ValueError(f"Video is longer than the {settings.max_video_minutes}-minute limit.")
        ydl.download([url])

    path = workdir / "source.mp4"
    if not path.exists():  # yt-dlp occasionally keeps another container
        candidates = list(workdir.glob("source.*"))
        if not candidates:
            raise RuntimeError("Download finished but no file was produced.")
        path = candidates[0]
    return path, info.get("title") or "Untitled video", duration
