"""Pydantic request/response models."""
from typing import Optional

from pydantic import BaseModel, EmailStr, Field


class SignupIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    name: str = Field(default="", max_length=80)


class LoginIn(BaseModel):
    email: EmailStr
    password: str


class GoogleIn(BaseModel):
    """Flutter Web may deliver an ID token (GIS button) or an access token (popup flow)."""
    id_token: Optional[str] = None
    access_token: Optional[str] = None


class UserOut(BaseModel):
    id: int
    email: str
    name: str
    picture: Optional[str] = None


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class ProcessIn(BaseModel):
    url: str = Field(min_length=10, max_length=300)


class ClipOut(BaseModel):
    id: str
    title: str
    url: str
    download_url: str
    thumbnail_url: str
    start: float
    end: float
    duration: float
    score: float


class JobOut(BaseModel):
    job_id: str
    status: str                 # queued | running | done | failed
    stage: str                  # downloading | transcribing | extracting_hooks | rendering | done
    progress: float             # 0..100
    video_title: Optional[str] = None
    error: Optional[str] = None
    clips: list[ClipOut] = []
