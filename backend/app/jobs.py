"""In-memory job registry. Fine for a single-process MVP; use Redis + Celery/RQ to scale out."""
import threading
import uuid
from typing import Any, Optional


class JobStore:
    def __init__(self) -> None:
        self._jobs: dict[str, dict[str, Any]] = {}
        self._lock = threading.Lock()

    def create(self, owner_id: int, url: str) -> str:
        job_id = uuid.uuid4().hex
        with self._lock:
            self._jobs[job_id] = {
                "job_id": job_id, "owner_id": owner_id, "url": url,
                "status": "queued", "stage": "downloading", "progress": 0.0,
                "video_title": None, "error": None, "clips": [],
            }
        return job_id

    def update(self, job_id: str, **fields: Any) -> None:
        with self._lock:
            self._jobs[job_id].update(fields)

    def get(self, job_id: str) -> Optional[dict[str, Any]]:
        with self._lock:
            job = self._jobs.get(job_id)
            return dict(job) if job else None

    def has_active_job(self, owner_id: int) -> bool:
        with self._lock:
            return any(j["owner_id"] == owner_id and j["status"] in ("queued", "running")
                       for j in self._jobs.values())


jobs = JobStore()
