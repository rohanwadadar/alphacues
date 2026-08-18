from __future__ import annotations

import logging
from typing import Any

from app.shared.db import db
from app.shared.exceptions import NotFoundError
from app.shared.feature_flags import FeatureFlag, invalidate_flag_cache

logger = logging.getLogger(__name__)

# The closed set of required flags seeded by Task 3. No flags may be
# created or deleted through the admin API — only their is_enabled value
# may be toggled.
REQUIRED_FLAG_KEYS = (
    "use_microservice_auth",
    "use_microservice_portfolio",
    "use_microservice_market",
    "enable_live_trading",
    "enable_simulator",
    "enable_screener",
)


class AdminFlagService:
    """Service layer for admin flag read/update operations.

    All mutations go through this class so that cache invalidation is
    always performed alongside the database commit.
    """

    @staticmethod
    def list_flags() -> list[FeatureFlag]:
        """Return all feature flag rows ordered by flag_key."""
        return (
            db.session.query(FeatureFlag)
            .order_by(FeatureFlag.flag_key)
            .all()
        )

    @staticmethod
    def get_flag(flag_key: str) -> FeatureFlag:
        """Return a single flag or raise NotFoundError."""
        row = db.session.get(FeatureFlag, flag_key)
        if row is None:
            raise NotFoundError(
                message=f"Feature flag '{flag_key}' was not found.",
                details={"flagKey": flag_key},
            )
        return row

    @staticmethod
    def update_flag(flag_key: str, is_enabled: bool) -> FeatureFlag:
        """Toggle a flag's is_enabled value.

        Steps:
        1. Fetch the row (raises NotFoundError if absent).
        2. Apply the change and commit.
        3. Invalidate the Redis cache key so the next is_enabled()
           call reads the fresh value from Postgres instead of stale cache.
        """
        row = AdminFlagService.get_flag(flag_key)
        row.is_enabled = is_enabled
        db.session.commit()
        # Invalidate the Redis cache immediately after commit so that the
        # "flag flip without deploy" promise is upheld within milliseconds.
        invalidate_flag_cache(flag_key)
        logger.info(
            "Feature flag updated: flag_key=%s is_enabled=%s",
            flag_key,
            is_enabled,
        )
        return row

    @staticmethod
    def flag_to_dict(flag: FeatureFlag) -> dict[str, Any]:
        """Serialize a FeatureFlag row to a JSON-safe dict."""
        return {
            "flagKey": flag.flag_key,
            "isEnabled": flag.is_enabled,
            "description": flag.description,
            "updatedAt": flag.updated_at.isoformat() if flag.updated_at else None,
        }
