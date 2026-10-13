"""Password hashing, JWT session tokens and the `get_current_user` dependency."""
from datetime import datetime, timedelta, timezone

import bcrypt
import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from . import db
from .config import settings

_bearer = HTTPBearer(auto_error=False)
ALGORITHM = "HS256"


def hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str | None) -> bool:
    if not hashed:
        return False  # Google-only account
    try:
        return bcrypt.checkpw(plain.encode(), hashed.encode())
    except ValueError:
        return False


def create_access_token(user_id: int) -> str:
    now = datetime.now(timezone.utc)
    payload = {"sub": str(user_id), "iat": now,
               "exp": now + timedelta(minutes=settings.token_ttl_minutes)}
    return jwt.encode(payload, settings.secret_key, algorithm=ALGORITHM)


def get_current_user(creds: HTTPAuthorizationCredentials | None = Depends(_bearer)):
    """FastAPI dependency: protects any route that includes it."""
    unauthorized = HTTPException(status.HTTP_401_UNAUTHORIZED, "Not authenticated",
                                 headers={"WWW-Authenticate": "Bearer"})
    if creds is None:
        raise unauthorized
    try:
        payload = jwt.decode(creds.credentials, settings.secret_key, algorithms=[ALGORITHM])
        user = db.get_user_by_id(int(payload["sub"]))
    except (jwt.PyJWTError, KeyError, ValueError):
        raise unauthorized
    if user is None:
        raise unauthorized
    return user
