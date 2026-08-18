from __future__ import annotations

import time
from functools import wraps
from typing import Any, Callable, TypeVar

import jwt
from flask import current_app, g, request

from app.shared.exceptions import TokenExpiredError, UnauthorizedError

F = TypeVar("F", bound=Callable[..., Any])

ACCESS_TOKEN_TYPE = "access"
REFRESH_TOKEN_TYPE = "refresh"


def extract_bearer_token() -> str:
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        raise UnauthorizedError(message="Missing or invalid Authorization header.")
    token = auth_header.removeprefix("Bearer ").strip()
    if not token:
        raise UnauthorizedError(message="Missing or invalid Authorization header.")
    return token


def decode_token(token: str, *, expected_type: str | None = None) -> dict[str, Any]:
    try:
        payload = jwt.decode(
            token,
            current_app.config["SECRET_KEY"],
            algorithms=["HS256"],
            issuer=current_app.config["JWT_ISSUER"],
            audience=current_app.config["JWT_AUDIENCE"],
        )
    except jwt.ExpiredSignatureError as exc:
        raise TokenExpiredError(message="Access token has expired.") from exc
    except jwt.InvalidTokenError as exc:
        raise UnauthorizedError(message="Invalid access token.") from exc

    token_type = payload.get("typ")
    if expected_type is not None and token_type != expected_type:
        raise UnauthorizedError(message="Invalid token type.")

    return payload


def verify_access_token(token: str) -> dict[str, Any]:
    return decode_token(token, expected_type=ACCESS_TOKEN_TYPE)


def issue_token(
    *,
    user_id: str,
    email: str,
    session_id: str,
    token_type: str,
    ttl_seconds: int,
) -> str:
    now = int(time.time())
    payload = {
        "sub": user_id,
        "email": email,
        "sid": session_id,
        "typ": token_type,
        "iat": now,
        "exp": now + ttl_seconds,
        "iss": current_app.config["JWT_ISSUER"],
        "aud": current_app.config["JWT_AUDIENCE"],
    }
    return jwt.encode(
        payload,
        current_app.config["SECRET_KEY"],
        algorithm="HS256",
    )


def require_auth(func: F) -> F:
    @wraps(func)
    def wrapper(*args: Any, **kwargs: Any):
        token = extract_bearer_token()
        payload = verify_access_token(token)
        g.current_user = payload
        g.user_id = payload.get("sub")
        g.session_id = payload.get("sid")
        return func(*args, **kwargs)

    return wrapper  # type: ignore[return-value]


# ---------------------------------------------------------------------------
# TODO(admin-auth): require_admin stub — DENY BY DEFAULT
# ---------------------------------------------------------------------------
# The plan does not define an admin role, an `is_admin` column, or any admin
# authentication mechanism.  This decorator is a safe placeholder that denies
# ALL requests until the real mechanism is chosen and wired in.
#
# When you are ready to implement, pick ONE of the options below and replace
# the stub body:
#
# Option A — users.role column (recommended for long-term RBAC):
#   1. Add `role TEXT NOT NULL DEFAULT 'user'` to the `users` table.
#   2. Include `"role": user.role` in the JWT payload issued by issue_token().
#   3. Replace the stub body with:
#        payload = g.get("current_user") or {}
#        if payload.get("role") != "admin":
#            raise UnauthorizedError(message="Admin access required.")
#
# Option B — ADMIN_EMAILS env-var allowlist (fast to ship, but coarse-grained):
#   1. Add ADMIN_EMAILS=admin@example.com (comma-separated) to .env.
#   2. Replace the stub body with:
#        import os
#        allowed = {e.strip() for e in os.getenv("ADMIN_EMAILS","").split(",") if e.strip()}
#        payload = g.get("current_user") or {}
#        if payload.get("email") not in allowed:
#            raise UnauthorizedError(message="Admin access required.")
#
# Option C — shared service-to-service secret header (for internal tooling):
#   1. Add ADMIN_SECRET=<long-random-string> to .env.
#   2. Replace the stub body with:
#        import os
#        secret = os.getenv("ADMIN_SECRET", "")
#        if not secret or request.headers.get("X-Admin-Secret") != secret:
#            raise UnauthorizedError(message="Admin access required.")
#
# ---------------------------------------------------------------------------
def require_admin(func: F) -> F:
    """Admin-only guard — deny by default.

    See the TODO(admin-auth) block above for the three implementation
    options.  Do NOT ship this stub to production; it rejects every request.
    """
    @wraps(func)
    def wrapper(*args: Any, **kwargs: Any):
        # TODO(admin-auth): replace this body with the chosen mechanism.
        # Until then every admin request is denied with 401.
        raise UnauthorizedError(
            message=(
                "Admin access is not yet configured. "
                "See the TODO(admin-auth) block in shared/auth.py."
            )
        )

    return wrapper  # type: ignore[return-value]
