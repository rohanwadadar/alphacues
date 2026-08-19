from __future__ import annotations

import logging
from datetime import datetime, timezone
from functools import wraps
from typing import Any, Callable, TypeVar

from sqlalchemy import Boolean, DateTime, Text
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.shared.db import db
from app.shared.exceptions import FeatureDisabledError

logger = logging.getLogger(__name__)

REQUIRED_FEATURE_FLAGS = (
    "use_microservice_auth",
    "use_microservice_portfolio",
    "use_microservice_market",
    "enable_live_trading",
    "enable_simulator",
    "enable_screener",
)

DEFAULT_ENABLED_FLAGS = {
    "enable_screener": True,
    "enable_simulator": True,
    "enable_live_trading": True,
    "use_microservice_auth": False,
    "use_microservice_portfolio": False,
    "use_microservice_market": False,
}


def seed_feature_flags() -> None:
    """Seed default feature flags into the database if missing."""
    try:
        updated = False
        for flag_key, is_enabled in DEFAULT_ENABLED_FLAGS.items():
            row = db.session.get(FeatureFlag, flag_key)
            if row is None:
                db.session.add(FeatureFlag(flag_key=flag_key, is_enabled=is_enabled, description=f"{flag_key} feature flag"))
                updated = True
        if updated:
            db.session.commit()
    except Exception as e:
        logger.warning("Failed to seed feature flags: %s", e)
        db.session.rollback()


# ---------------------------------------------------------------------------
# Caching constants
# ---------------------------------------------------------------------------
# Short TTL so a flag flip through the admin endpoint propagates within
# seconds. Per plan risk note: "overly aggressive caching can violate the
# 'flag flip without deploy' promise."  5 s is intentionally short.
# The admin update path calls invalidate_flag_cache() immediately after
# the DB commit, so in practice the propagation delay is < 1 s even if
# Redis is warm.
FLAG_CACHE_TTL_SECONDS: int = 5
_FLAG_CACHE_PREFIX: str = "ff:"

F = TypeVar("F", bound=Callable[..., Any])


# ---------------------------------------------------------------------------
# SQLAlchemy model (unchanged from Phase 1)
# ---------------------------------------------------------------------------
class FeatureFlag(db.Model):
    __tablename__ = "feature_flags"

    flag_key: Mapped[str] = mapped_column(Text, primary_key=True)
    is_enabled: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, server_default="false"
    )
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )


# ---------------------------------------------------------------------------
# Cache helpers
# ---------------------------------------------------------------------------
def _flag_cache_key(flag_key: str) -> str:
    return f"{_FLAG_CACHE_PREFIX}{flag_key}"


def invalidate_flag_cache(flag_key: str) -> None:
    """Delete the Redis cache entry for a flag.

    Called by AdminFlagService.update_flag() immediately after the DB
    commit so that the next is_enabled() call reads the fresh value.
    Safe to call when Redis is unavailable — the deletion attempt is
    silently swallowed.
    """
    try:
        from app.shared.cache import get_redis
        redis = get_redis()
        redis.delete(_flag_cache_key(flag_key))
        logger.debug("Feature flag cache invalidated: flag_key=%s", flag_key)
    except Exception:
        # Redis unavailable — next read will fall through to Postgres anyway.
        logger.debug(
            "Flag cache invalidation skipped (Redis unavailable): flag_key=%s",
            flag_key,
        )


# ---------------------------------------------------------------------------
# Service
# ---------------------------------------------------------------------------
class FeatureFlagService:
    """Read-path service used by every module to check a feature flag.

    Caching strategy
    ----------------
    Each call to is_enabled() checks Redis first (cache key ``ff:<flag_key>``
    with a TTL of FLAG_CACHE_TTL_SECONDS).  On a cache miss the value is
    read from Postgres and written back to Redis.  If Redis is unavailable
    the read goes straight to Postgres — no error is raised.

    When an admin updates a flag via the admin endpoint,
    AdminFlagService.update_flag() calls invalidate_flag_cache() which
    deletes the Redis key immediately after the DB commit.  This means
    the propagation delay for a flag flip is bounded by the time it takes
    the next in-flight request to finish, not by FLAG_CACHE_TTL_SECONDS.
    """

    def is_enabled(self, flag_key: str, *, default: bool = False) -> bool:
        # --- try Redis cache first ---
        cached = self._read_cache(flag_key)
        if cached is not None:
            return cached

        # --- cache miss: read from Postgres ---
        row = db.session.get(FeatureFlag, flag_key)
        if row is None:
            return DEFAULT_ENABLED_FLAGS.get(flag_key, default)
        value = bool(row.is_enabled)

        # --- populate cache for subsequent reads ---
        self._write_cache(flag_key, value)
        return value

    def require_enabled(self, flag_key: str) -> None:
        if not self.is_enabled(flag_key):
            raise FeatureDisabledError(
                message=f"Feature '{flag_key}' is disabled.",
                details={"flagKey": flag_key},
            )

    # ------------------------------------------------------------------
    # Internal cache helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _read_cache(flag_key: str) -> bool | None:
        """Return the cached boolean value, or None on miss / unavailable."""
        try:
            from app.shared.cache import get_redis
            from flask import current_app

            # Honour the testing bypass used by CacheService.
            if current_app and (
                current_app.config.get("MOCK_EXTERNAL_SERVICES")
                or current_app.config.get("TESTING")
            ):
                return None

            raw = get_redis().get(_flag_cache_key(flag_key))
            if raw is None:
                return None
            return raw == "1"
        except Exception:
            return None

    @staticmethod
    def _write_cache(flag_key: str, value: bool) -> None:
        """Write the boolean value to Redis with FLAG_CACHE_TTL_SECONDS TTL."""
        try:
            from app.shared.cache import get_redis
            from flask import current_app

            if current_app and (
                current_app.config.get("MOCK_EXTERNAL_SERVICES")
                or current_app.config.get("TESTING")
            ):
                return

            get_redis().setex(
                _flag_cache_key(flag_key),
                FLAG_CACHE_TTL_SECONDS,
                "1" if value else "0",
            )
        except Exception:
            pass


feature_flag_service = FeatureFlagService()


# ---------------------------------------------------------------------------
# Decorator (unchanged public API from Phase 1)
# ---------------------------------------------------------------------------
def require_feature_flag(flag_key: str) -> Callable[[F], F]:
    def decorator(func: F) -> F:
        @wraps(func)
        def wrapper(*args: Any, **kwargs: Any):
            feature_flag_service.require_enabled(flag_key)
            return func(*args, **kwargs)

        return wrapper  # type: ignore[return-value]

    return decorator
