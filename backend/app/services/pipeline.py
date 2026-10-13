"""Orchestrates download -> transcribe -> hook extraction -> render and reports progress."""
import logging
import shutil

from ..config import settings
from ..jobs import jobs
from . import downloader, renderer, segmenter, transcriber

log = logging.getLogger("clipflow.pipeline")


def run_pipeline(job_id: str, url: str) -> None:
    workdir = settings.media_dir / job_id
    workdir.mkdir(parents=True, exist_ok=True)
    try:
        # 1. Download (progress 0-25)
        jobs.update(job_id, status="running", stage="downloading", progress=2)
        source, title, duration = downloader.download_video(
            url, workdir, on_progress=lambda f: jobs.update(job_id, progress=2 + f * 23))
        jobs.update(job_id, video_title=title)

        # 2. Transcribe (25-55)
        jobs.update(job_id, stage="transcribing", progress=25)
        segments = transcriber.transcribe(source)
        if not segments:
            log.warning("No speech detected in %s", url)

        # 3. Hook extraction (55-65)
        jobs.update(job_id, stage="extracting_hooks", progress=55)
        plans = segmenter.plan_clips(segments, duration)
        if not plans:
            raise ValueError("Couldn't find a clip-worthy section in this video.")

        # 4. Render (65-100)
        jobs.update(job_id, stage="rendering", progress=65)
        clips = []
        base = settings.public_base_url
        for n, plan in enumerate(plans, start=1):
            mp4, jpg = renderer.render_clip(source, plan, n)
            clips.append({
                "id": f"{job_id}-{n}",
                "title": plan.title or f"Clip {n}",
                "url": f"{base}/media/{job_id}/{mp4}",
                "download_url": f"{base}/api/v1/download/{job_id}/{mp4}",
                "thumbnail_url": f"{base}/media/{job_id}/{jpg}",
                "start": round(plan.start, 2), "end": round(plan.end, 2),
                "duration": round(plan.duration, 1), "score": plan.score,
            })
            jobs.update(job_id, progress=65 + 35 * n / len(plans), clips=list(clips))

        jobs.update(job_id, status="done", stage="done", progress=100)
        source.unlink(missing_ok=True)  # the large original is no longer needed
    except Exception as exc:  # surface a readable message to the UI, keep details in logs
        log.exception("Job %s failed", job_id)
        shutil.rmtree(workdir, ignore_errors=True)
        jobs.update(job_id, status="failed", error=str(exc)[:300] or "Processing failed.")
