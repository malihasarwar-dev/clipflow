"""Step 4 - FFmpeg: crop to 9:16, scale to 1080x1920 and burn word-grouped captions (ASS)."""
import subprocess
from pathlib import Path

from .segmenter import ClipPlan

ASS_HEADER = """[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
WrapStyle: 2

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,86,&H00FFFFFF,&H000000FF,&H00000000,&H64000000,-1,0,0,0,100,100,0,0,1,7,2,2,60,60,520,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""


def _ass_time(t: float) -> str:
    t = max(t, 0.0)
    return f"{int(t // 3600)}:{int(t % 3600 // 60):02d}:{t % 60:05.2f}"


def build_ass(plan: ClipPlan, words_per_line: int = 3) -> str:
    """Group words into short punchy lines; timestamps are relative to the clip start."""
    lines = [ASS_HEADER]
    words = [w for w in plan.words if w.end > plan.start and w.start < plan.end]
    for i in range(0, len(words), words_per_line):
        group = words[i:i + words_per_line]
        start = max(group[0].start - plan.start, 0.0)
        end = min(group[-1].end - plan.start, plan.duration)
        end = max(end, start + 0.3)
        text = " ".join(w.text for w in group).upper().replace("{", "(").replace("}", ")")
        lines.append(f"Dialogue: 0,{_ass_time(start)},{_ass_time(end)},Default,,0,0,0,,{text}\n")
    return "".join(lines)


def _ffmpeg(args: list[str], cwd: Path) -> None:
    proc = subprocess.run(["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", *args],
                          cwd=cwd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"FFmpeg failed: {proc.stderr.strip()[-400:]}")


def render_clip(source: Path, plan: ClipPlan, index: int) -> tuple[str, str]:
    """Render one short. Returns (video_filename, thumbnail_filename) inside source's folder."""
    workdir = source.parent                      # run ffmpeg here so filter paths stay relative
    ass_name, mp4_name, jpg_name = f"clip_{index:02d}.ass", f"clip_{index:02d}.mp4", f"clip_{index:02d}.jpg"
    (workdir / ass_name).write_text(build_ass(plan), encoding="utf-8")

    vf = (
        "crop='min(iw,ih*9/16)':'min(ih,iw*16/9)',"          # centre 9:16 crop (handles portrait sources)
        "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setsar=1,"
        f"subtitles={ass_name}"
    )
    _ffmpeg([
        "-ss", f"{plan.start:.2f}", "-t", f"{plan.duration:.2f}", "-i", source.name,
        "-vf", vf, "-c:v", "libx264", "-preset", "veryfast", "-crf", "21", "-pix_fmt", "yuv420p",
        "-c:a", "aac", "-b:a", "128k", "-movflags", "+faststart", mp4_name,
    ], workdir)
    _ffmpeg(["-i", mp4_name, "-ss", "1", "-frames:v", "1", "-vf", "scale=360:-2", jpg_name], workdir)
    (workdir / ass_name).unlink(missing_ok=True)
    return mp4_name, jpg_name
