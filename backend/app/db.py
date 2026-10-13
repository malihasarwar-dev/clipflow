"""Tiny SQLite persistence layer for users (swap for Postgres + SQLAlchemy in production)."""
import sqlite3
from contextlib import closing
from datetime import datetime, timezone
from typing import Optional

from .config import settings


def _conn() -> sqlite3.Connection:
    conn = sqlite3.connect(settings.db_path)
    conn.row_factory = sqlite3.Row
    return conn


def init_db() -> None:
    with closing(_conn()) as c:
        c.execute(
            """CREATE TABLE IF NOT EXISTS users (
                id            INTEGER PRIMARY KEY AUTOINCREMENT,
                email         TEXT NOT NULL UNIQUE,
                name          TEXT NOT NULL DEFAULT '',
                picture       TEXT,
                password_hash TEXT,
                google_sub    TEXT UNIQUE,
                created_at    TEXT NOT NULL
            )"""
        )
        c.commit()


def get_user_by_email(email: str) -> Optional[sqlite3.Row]:
    with closing(_conn()) as c:
        return c.execute("SELECT * FROM users WHERE email = ?", (email.lower(),)).fetchone()


def get_user_by_id(user_id: int) -> Optional[sqlite3.Row]:
    with closing(_conn()) as c:
        return c.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()


def create_user(email: str, name: str = "", password_hash: str | None = None,
                google_sub: str | None = None, picture: str | None = None) -> sqlite3.Row:
    with closing(_conn()) as c:
        cur = c.execute(
            "INSERT INTO users (email, name, picture, password_hash, google_sub, created_at) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            (email.lower(), name, picture, password_hash, google_sub,
             datetime.now(timezone.utc).isoformat()),
        )
        c.commit()
        return c.execute("SELECT * FROM users WHERE id = ?", (cur.lastrowid,)).fetchone()


def link_google(user_id: int, google_sub: str, name: str, picture: str | None) -> sqlite3.Row:
    """Attach a Google identity to an existing email/password account."""
    with closing(_conn()) as c:
        c.execute(
            "UPDATE users SET google_sub = ?, picture = COALESCE(?, picture), "
            "name = CASE WHEN name = '' THEN ? ELSE name END WHERE id = ?",
            (google_sub, picture, name, user_id),
        )
        c.commit()
        return c.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
