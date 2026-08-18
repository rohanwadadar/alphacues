from __future__ import annotations

import base64
import json
from datetime import datetime
from typing import Any, Callable, Sequence, TypeVar

from app.shared.exceptions import ValidationError
from app.shared.validators import pagination_meta, parse_cursor, parse_limit

T = TypeVar("T")


def encode_cursor(*, sort_value: str, row_id: int) -> str:
    payload = {"v": sort_value, "id": row_id}
    encoded = json.dumps(payload, separators=(",", ":")).encode("utf-8")
    return base64.urlsafe_b64encode(encoded).decode("ascii")


def decode_cursor(raw_cursor: str) -> tuple[str, int]:
    try:
        decoded = base64.urlsafe_b64decode(raw_cursor.encode("ascii")).decode("utf-8")
        payload = json.loads(decoded)
        sort_value = str(payload["v"])
        row_id = int(payload["id"])
    except (KeyError, TypeError, ValueError, json.JSONDecodeError) as exc:
        raise ValidationError(
            message="cursor is invalid.",
            details={"field": "cursor", "value": raw_cursor},
        ) from exc
    return sort_value, row_id


def parse_pagination_params(
    *,
    raw_limit: str | int | None = None,
    raw_cursor: str | None = None,
    default_limit: int = 20,
    max_limit: int = 100,
) -> tuple[int, str | None]:
    limit = parse_limit(raw_limit, default=default_limit, max_limit=max_limit)
    cursor = parse_cursor(raw_cursor)
    return limit, cursor


def paginate_rows(
    rows: Sequence[T],
    *,
    limit: int,
    cursor_extractor: Callable[[T], tuple[str, int]],
) -> tuple[list[T], str | None]:
    """Apply limit+1 pattern and build next cursor from the last returned row."""
    has_more = len(rows) > limit
    page = list(rows[:limit])
    next_cursor = None
    if has_more and page:
        sort_value, row_id = cursor_extractor(page[-1])
        next_cursor = encode_cursor(sort_value=sort_value, row_id=row_id)
    return page, next_cursor


def paginated_envelope(
    items: list[dict[str, Any]],
    *,
    next_cursor: str | None = None,
) -> tuple[dict[str, Any], dict[str, Any]]:
    """Return (data, meta) for json_response meta= parameter."""
    return {"items": items}, pagination_meta(next_cursor=next_cursor)
