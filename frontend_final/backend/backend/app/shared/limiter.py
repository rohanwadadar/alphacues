from __future__ import annotations

from functools import wraps
from typing import Any, Callable, TypeVar

from flask import current_app, g, request
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

from app.shared.cache import get_redis
from app.shared.exceptions import RateLimitedError, ServiceUnavailableError

F = TypeVar("F", bound=Callable[..., Any])

# Rate limits per plan reliability design.
AUTH_OTP_SEND_IP_LIMIT = "5 per minute"
AUTH_OTP_SEND_EMAIL_LIMIT = "3 per 15 minutes"
MARKET_SEARCH_USER_LIMIT = "30 per minute"

limiter = Limiter(key_func=get_remote_address)


def init_limiter(app) -> None:
    storage_uri = app.config.get("RATELIMIT_STORAGE_URI")
    if not storage_uri:
        redis_url = app.config.get("REDIS_URL", "redis://localhost:6379/0")
        app_env = app.config.get("APP_ENV", "development")
        if app_env in ("development", "testing") or app.debug:
            try:
                import redis
                r = redis.Redis.from_url(redis_url, socket_connect_timeout=1)
                r.ping()
                storage_uri = redis_url
            except Exception:
                storage_uri = "memory://"
        else:
            storage_uri = redis_url

    app.config["RATELIMIT_STORAGE_URI"] = storage_uri
    limiter.init_app(app)
    limiter.enabled = True


def is_rate_limit_storage_available() -> bool:
    storage_uri = current_app.config.get("RATELIMIT_STORAGE_URI") or ""
    app_env = current_app.config.get("APP_ENV", "development")
    if (
        storage_uri.startswith("memory://")
        or current_app.config.get("MOCK_EXTERNAL_SERVICES")
        or current_app.config.get("TESTING")
        or app_env == "development"
        or current_app.debug
    ):
        return True
    try:
        return bool(get_redis().ping())
    except Exception:
        return False


def require_rate_limit_storage(func: F) -> F:
    """Fail closed for auth paths when Redis rate-limit state is unavailable."""

    @wraps(func)
    def wrapper(*args: Any, **kwargs: Any):
        if not is_rate_limit_storage_available():
            raise ServiceUnavailableError(
                message="Rate limiting is temporarily unavailable.",
                details={"reason": "redis_unavailable"},
            )
        return func(*args, **kwargs)

    return wrapper  # type: ignore[return-value]


def auth_ip_key() -> str:
    return get_remote_address()


def auth_email_key() -> str:
    email = getattr(g, "rate_limit_email", None)
    if email:
        return f"email:{email}"
    return get_remote_address()


def market_search_user_key() -> str:
    user_id = getattr(g, "user_id", None)
    if user_id:
        return f"user:{user_id}"
    return get_remote_address()


def on_rate_limit_breach(_request_limit=None) -> None:
    from app.shared.logging import log_rate_limit_exceeded
    log_rate_limit_exceeded(request.path)
    raise RateLimitedError(message="Too many requests. Please try again later.")


def configure_auth_rate_limits() -> None:
    """Apply auth endpoint rate limits from application config."""
    current_app.config.setdefault(
        "AUTH_OTP_SEND_IP_LIMIT",
        AUTH_OTP_SEND_IP_LIMIT,
    )
    current_app.config.setdefault(
        "AUTH_OTP_SEND_EMAIL_LIMIT",
        AUTH_OTP_SEND_EMAIL_LIMIT,
    )


def bind_rate_limit_email(email: str) -> None:
    g.rate_limit_email = email


def is_auth_path(path: str) -> bool:
    return path.startswith("/api/v1/auth")


def enforce_auth_fail_closed() -> None:
    if request.method == "OPTIONS":
        return
    if is_auth_path(request.path) and not is_rate_limit_storage_available():
        raise ServiceUnavailableError(
            message="Rate limiting is temporarily unavailable.",
            details={"reason": "redis_unavailable"},
        )
