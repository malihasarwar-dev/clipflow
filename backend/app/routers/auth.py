"""Authentication endpoints: email/password + Google OAuth."""
import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from google.auth.transport import requests as g_requests
from google.oauth2 import id_token as google_id_token

from .. import db
from ..config import settings
from ..schemas import GoogleIn, LoginIn, SignupIn, TokenOut, UserOut
from ..security import create_access_token, get_current_user, hash_password, verify_password

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


def _token_response(user) -> TokenOut:
    return TokenOut(
        access_token=create_access_token(user["id"]),
        user=UserOut(id=user["id"], email=user["email"], name=user["name"], picture=user["picture"]),
    )


@router.post("/signup", response_model=TokenOut, status_code=201)
def signup(body: SignupIn):
    if db.get_user_by_email(body.email):
        raise HTTPException(status.HTTP_409_CONFLICT, "An account with this email already exists.")
    user = db.create_user(body.email, body.name.strip(), password_hash=hash_password(body.password))
    return _token_response(user)


@router.post("/login", response_model=TokenOut)
def login(body: LoginIn):
    user = db.get_user_by_email(body.email)
    # Same error for unknown email and wrong password -> no account enumeration.
    if not user or not verify_password(body.password, user["password_hash"]):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Incorrect email or password.")
    return _token_response(user)


def _verify_google(body: GoogleIn) -> dict:
    """Return verified Google profile claims (sub, email, name, picture)."""
    if not settings.google_client_id:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Google sign-in is not configured.")
    try:
        if body.id_token:
            # Signature, expiry and audience are all checked by google-auth.
            claims = google_id_token.verify_oauth2_token(
                body.id_token, g_requests.Request(), settings.google_client_id)
        elif body.access_token:
            # Popup flow on web yields an access token: confirm it was issued to OUR client,
            # then fetch the profile.
            info = httpx.get("https://oauth2.googleapis.com/tokeninfo",
                             params={"access_token": body.access_token}, timeout=10)
            if info.status_code != 200 or info.json().get("aud") != settings.google_client_id:
                raise ValueError("Access token was not issued for this application.")
            prof = httpx.get("https://www.googleapis.com/oauth2/v3/userinfo",
                             headers={"Authorization": f"Bearer {body.access_token}"}, timeout=10)
            prof.raise_for_status()
            claims = prof.json()
        else:
            raise ValueError("Provide id_token or access_token.")
    except (ValueError, httpx.HTTPError) as exc:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, f"Invalid Google credential: {exc}")

    if not claims.get("email") or claims.get("email_verified") in (False, "false"):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Google account email is not verified.")
    return claims


@router.post("/google", response_model=TokenOut)
def google_login(body: GoogleIn):
    """Verify a Google credential, create the user on first sight, return a ClipFlow session token."""
    claims = _verify_google(body)
    email, sub = claims["email"], claims["sub"]
    name, picture = claims.get("name", ""), claims.get("picture")

    user = db.get_user_by_email(email)
    if user is None:
        user = db.create_user(email, name, google_sub=sub, picture=picture)
    elif user["google_sub"] != sub:
        user = db.link_google(user["id"], sub, name, picture)
    return _token_response(user)


@router.get("/me", response_model=UserOut)
def me(user=Depends(get_current_user)):
    return UserOut(id=user["id"], email=user["email"], name=user["name"], picture=user["picture"])
