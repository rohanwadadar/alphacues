from __future__ import annotations

from flask import Blueprint, request

from app.modules.admin.service import AdminFlagService
from app.shared.auth import require_admin
from app.shared.exceptions import ValidationError
from app.shared.response import json_response

admin_bp = Blueprint("admin", __name__, url_prefix="/api/v1/admin")


@admin_bp.get("/flags")
@require_admin
def list_flags():
    """GET /api/v1/admin/flags — list all feature flags.

    Returns all rows from feature_flags ordered by flag_key.
    Restricted to admin users via require_admin guard.
    """
    flags = AdminFlagService.list_flags()
    return json_response(
        {"flags": [AdminFlagService.flag_to_dict(f) for f in flags]}
    )


@admin_bp.get("/flags/<string:flag_key>")
@require_admin
def get_flag(flag_key: str):
    """GET /api/v1/admin/flags/<flag_key> — retrieve a single flag.

    Raises 404 NOT_FOUND if the flag_key does not exist.
    """
    flag = AdminFlagService.get_flag(flag_key)
    return json_response(AdminFlagService.flag_to_dict(flag))


@admin_bp.patch("/flags/<string:flag_key>")
@require_admin
def update_flag(flag_key: str):
    """PATCH /api/v1/admin/flags/<flag_key> — toggle is_enabled.

    Expected body: {"is_enabled": true | false}

    After a successful update the Redis cache key for this flag is
    invalidated immediately, so the next is_enabled() read reflects
    the new value without waiting for the cache TTL to expire.

    Raises:
      - 400 VALIDATION_ERROR if body is missing or is_enabled is not a bool.
      - 404 NOT_FOUND if the flag_key does not exist.
    """
    body = request.get_json(silent=True) or {}

    if "is_enabled" not in body:
        raise ValidationError(
            message="Missing required field: is_enabled.",
            details={"is_enabled": ["Field is required."]},
        )

    is_enabled_raw = body["is_enabled"]
    if not isinstance(is_enabled_raw, bool):
        raise ValidationError(
            message="Field 'is_enabled' must be a boolean.",
            details={"is_enabled": ["Must be true or false."]},
        )

    flag = AdminFlagService.update_flag(flag_key, is_enabled=is_enabled_raw)
    return json_response(AdminFlagService.flag_to_dict(flag))
