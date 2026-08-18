from __future__ import annotations

import uuid
from typing import Any

from flask import Blueprint, g, request
from marshmallow import ValidationError as MarshmallowValidationError

from app.modules.portfolio.schemas import PortfolioEventSchema, PortfolioEventUpdateSchema
from app.modules.portfolio.service import PortfolioService
from app.shared.auth import require_auth
from app.shared.exceptions import ValidationError
from app.shared.pagination import parse_pagination_params
from app.shared.response import json_response

portfolio_bp = Blueprint("portfolio", __name__, url_prefix="/api/v1/portfolio")

event_schema = PortfolioEventSchema()
update_event_schema = PortfolioEventUpdateSchema()


def _load_json(schema) -> dict[str, Any]:
    payload = request.get_json(silent=True)
    if payload is None:
        raise ValidationError(
            message="Request validation failed.",
            details={"body": ["Request body must be valid JSON."]},
        )
    try:
        return schema.load(payload)
    except MarshmallowValidationError as exc:
        raise ValidationError(
            message="Request validation failed.",
            details=exc.normalized_messages(),
        ) from exc


def _user_id() -> int:
    return int(g.user_id)


def _transactions_page_size() -> str | None:
    page_size = request.args.get("pageSize")
    if page_size is not None and page_size != "":
        return page_size
    return request.args.get("limit")


@portfolio_bp.get("")
@require_auth
def portfolio_summary():
    data = PortfolioService.get_summary(_user_id())
    return json_response(data)


@portfolio_bp.get("/history")
@require_auth
def portfolio_history():
    snapshots = PortfolioService.get_history(_user_id())
    data = {
        "history": [PortfolioService.snapshot_to_dict(snapshot) for snapshot in snapshots]
    }
    return json_response(data)


@portfolio_bp.get("/transactions")
@require_auth
def list_transactions():
    limit, cursor = parse_pagination_params(
        raw_limit=_transactions_page_size(),
        raw_cursor=request.args.get("cursor"),
    )
    data, meta = PortfolioService.list_transactions(
        _user_id(), limit=limit, cursor=cursor
    )
    return json_response(data, meta=meta)


@portfolio_bp.post("/event")
@require_auth
def record_event():
    data = _load_json(event_schema)
    idempotency_key = request.headers.get("Idempotency-Key")
    event = PortfolioService.record_event(
        _user_id(),
        symbol=data["symbol"],
        action=data["action"],
        price=data["price"],
        volume=data["volume"],
        time_stamp=data["time_stamp"],
        idempotency_key=idempotency_key,
    )
    return json_response(PortfolioService.event_to_dict(event), status_code=201)


@portfolio_bp.put("/event/<uuid:event_id>")
@require_auth
def update_event(event_id: uuid.UUID):
    data = _load_json(update_event_schema)
    event = PortfolioService.update_event(
        _user_id(),
        event_id,
        symbol=data["symbol"],
        action=data["action"],
        price=data["price"],
        volume=data["volume"],
        time_stamp=data.get("time_stamp"),
    )
    return json_response(PortfolioService.event_to_dict(event))


@portfolio_bp.delete("/event/<uuid:event_id>")
@require_auth
def delete_event(event_id: uuid.UUID):
    PortfolioService.delete_event(_user_id(), event_id)
    return json_response(None)
