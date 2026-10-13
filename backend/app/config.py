"""Central configuration. Everything is overridable through environment variables / .env."""
import os
from dataclasses import dataclass, field
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent


def _list(name: str, default: str) -> list[str]:
    return [v.strip() for v in os.getenv(name, default).split(",") if v.strip()]


@dataclass(frozen=True)
class Settings:
    # Security
    secret_key: str = os.getenv("SECRET_KEY", "dev-only-change-me")
    token_ttl_minutes: int = int(os.getenv("TOKEN_TTL_MINUTES", "10080"))
    google_client_id: str = os.getenv("GOOGLE_CLIENT_ID", "")

    # Networking
    cors_origins: list[str] = field(
        default_factory=lambda: _list("CORS_ORIGINS", "http://localhost:5000,http://localhost:8080")
    )
    public_base_url: str = os.getenv("PUBLIC_BASE_URL", "http://localhost:8000").rstrip("/")

    # Storage
    media_dir: Path = Path(os.getenv("MEDIA_DIR", BASE_DIR / "media"))
    db_path: Path = Path(os.getenv("DB_PATH", BASE_DIR / "clipflow.db"))

    # Pipeline
    whisper_model: str = os.getenv("WHISPER_MODEL", "base")
    whisper_device: str = os.getenv("WHISPER_DEVICE", "auto")
    whisper_compute_type: str = os.getenv("WHISPER_COMPUTE_TYPE", "int8")
    max_video_minutes: int = int(os.getenv("MAX_VIDEO_MINUTES", "180"))
    clips_per_video: int = int(os.getenv("CLIPS_PER_VIDEO", "4"))
    min_clip_seconds: int = int(os.getenv("MIN_CLIP_SECONDS", "30"))
    max_clip_seconds: int = int(os.getenv("MAX_CLIP_SECONDS", "60"))


settings = Settings()
settings.media_dir.mkdir(parents=True, exist_ok=True)
