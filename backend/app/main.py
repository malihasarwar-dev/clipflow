"""ClipFlow API entrypoint.   Run:  uvicorn app.main:app --reload --port 8000"""
import re
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from . import db
from .config import settings
from .routers import auth, videos


@asynccontextmanager
async def lifespan(_: FastAPI):
    db.init_db()
    yield


app = FastAPI(title="ClipFlow API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware, allow_origins=settings.cors_origins, allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"])

app.include_router(auth.router)
app.include_router(videos.router)

# Rendered clips (unguessable job ids; add signed URLs or auth if clips must stay private).
app.mount("/media", StaticFiles(directory=settings.media_dir), name="media")


@app.get("/api/v1/download/{job_id}/{filename}")
def download(job_id: str, filename: str):
    """Same file as /media but with Content-Disposition: attachment so browsers save it."""
    if not re.fullmatch(r"[0-9a-f]{32}", job_id) or not re.fullmatch(r"clip_\d{2}\.mp4", filename):
        raise HTTPException(404, "File not found.")
    path = settings.media_dir / job_id / filename
    if not path.is_file():
        raise HTTPException(404, "File not found.")
    return FileResponse(path, media_type="video/mp4", filename=f"clipflow_{filename}")


@app.get("/health")
def health():
    return {"status": "ok"}
