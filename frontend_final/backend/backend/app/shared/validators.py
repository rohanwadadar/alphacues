from __future__ import annotations

import re
from typing import Any

from app.shared.exceptions import ValidationError

SYMBOL_PATTERN = re.compile(r"^[A-Z][A-Z0-9._-]{0,14}$")

DEFAULT_LIMIT = 20
MAX_LIMIT = 100


def normalize_email(email: str) -> str:
    return email.strip().lower()


def validate_email(email: str) -> str:
    normalized = normalize_email(email)
    if (
        not normalized
        or "@" not in normalized
        or normalized.startswith("@")
        or normalized.endswith("@")
    ):
        raise ValidationError(
            message="A valid email address is required.",
            details={"field": "email"},
        )
    return normalized


def normalize_symbol(symbol: str) -> str:
    return symbol.strip().upper()


def validate_symbol(symbol: str) -> str:
    normalized = normalize_symbol(symbol)
    if not SYMBOL_PATTERN.fullmatch(normalized):
        raise ValidationError(
            message=(
                "Symbol must be an uppercase ticker matching "
                "^[A-Z][A-Z0-9._-]{0,14}$."
            ),
            details={"field": "symbol", "value": symbol},
        )
    return normalized


def validate_symbol_input(symbol: str) -> str:
    stripped = symbol.strip()
    if not SYMBOL_PATTERN.fullmatch(stripped):
        raise ValidationError(
            message=(
                "Symbol must be an uppercase ticker matching "
                "^[A-Z][A-Z0-9._-]{0,14}$."
            ),
            details={"field": "symbol", "value": symbol},
        )
    return stripped


def parse_limit(
    raw_limit: str | int | None,
    *,
    default: int = DEFAULT_LIMIT,
    max_limit: int = MAX_LIMIT,
) -> int:
    if raw_limit is None or raw_limit == "":
        return default
    try:
        limit = int(raw_limit)
    except (TypeError, ValueError) as exc:
        raise ValidationError(
            message="limit must be an integer.",
            details={"field": "limit", "value": raw_limit},
        ) from exc
    if limit < 1:
        raise ValidationError(
            message="limit must be at least 1.",
            details={"field": "limit", "value": limit},
        )
    if limit > max_limit:
        raise ValidationError(
            message=f"limit must not exceed {max_limit}.",
            details={"field": "limit", "value": limit, "max": max_limit},
        )
    return limit


def parse_cursor(raw_cursor: str | None) -> str | None:
    if raw_cursor is None or raw_cursor == "":
        return None
    return raw_cursor


def validate_sort(
    raw_sort: str | None,
    allowed: set[str],
    *,
    field: str = "sort",
    required: bool = False,
) -> str | None:
    if raw_sort is None or raw_sort == "":
        if required:
            raise ValidationError(
                message=f"{field} is required.",
                details={"field": field},
            )
        return None
    if raw_sort not in allowed:
        raise ValidationError(
            message=f"{field} must be one of: {', '.join(sorted(allowed))}.",
            details={"field": field, "value": raw_sort, "allowed": sorted(allowed)},
        )
    return raw_sort


def pagination_meta(*, next_cursor: str | None = None, **extra: Any) -> dict[str, Any]:
    meta: dict[str, Any] = {"nextCursor": next_cursor}
    meta.update(extra)
    return meta
