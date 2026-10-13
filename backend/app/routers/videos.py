"""Video processing endpoints. Heavy work runs in a background thread; the UI polls /jobs/{id}."""
import re

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status

from ..jobs import jobs
from ..schemas import JobOut, ProcessIn
from ..security import get_current_user
from ..services.pipeline import run_pipeline

router = APIRouter(prefix="/api/v1", tags=["videos"])

YOUTUBE_RE = re.compile(
    r"^https?://(www\.|m\.)?(youtube\.com/(watch\?v=|shorts/|live/)|youtu\.be/)[\w\-]{6,}", re.I)


def _public(job: dict) -> JobOut:
    return JobOut(**{k: v for k, v in job.items() if k in JobOut.model_fields})


@router.post("/process-video", response_model=JobOut, status_code=status.HTTP_202_ACCEPTED)
def process_video(body: ProcessIn, background: BackgroundTasks, user=Depends(get_current_user)):
    """Queue a YouTube URL for clipping. Returns immediately with a job to poll."""
    url = body.url.strip()
    if not YOUTUBE_RE.match(url):
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Enter a valid YouTube video URL.")
    if jobs.has_active_job(user["id"]):
        raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS,
                            "You already have a video processing. Wait for it to finish.")
    job_id = jobs.create(user["id"], url)
    background.add_task(run_pipeline, job_id, url)
    return _public(jobs.get(job_id))


@router.get("/jobs/{job_id}", response_model=JobOut)
def get_job(job_id: str, user=Depends(get_current_user)):
    job = jobs.get(job_id)
    if not job or job["owner_id"] != user["id"]:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Job not found.")
    return _public(job)
