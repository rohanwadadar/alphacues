from __future__ import annotations

from typing import Any

from flask import Blueprint, current_app, g, request
from marshmallow import ValidationError as MarshmallowValidationError

from app.modules.screener.schemas import (
    CreateStrategySchema,
    ScreenerScanRequestSchema,
    UpdateStrategySchema,
)
from app.modules.screener.service import ScreenerService
from app.shared.auth import require_auth
from app.shared.exceptions import ValidationError
from app.shared.feature_flags import require_feature_flag
from app.shared.response import json_response
from app.shared.validators import pagination_meta, parse_cursor, parse_limit

screener_bp = Blueprint("screener", __name__, url_prefix="/api/v1/screener")

scan_request_schema = ScreenerScanRequestSchema()
create_strategy_schema = CreateStrategySchema()
update_strategy_schema = UpdateStrategySchema()


def _load_json(schema) -> dict[str, Any]:
    payload = request.get_json(silent=True)
    if payload is None:
        payload = {}
    try:
        return schema.load(payload)
    except MarshmallowValidationError as exc:
        raise ValidationError(
            message="Request validation failed.",
            details=exc.normalized_messages(),
        ) from exc


def _user_id() -> int:
    return int(g.user_id)


@screener_bp.post("/run")
@screener_bp.post("/scan")
@require_feature_flag("enable_screener")
@require_auth
def run_scan():
    params = _load_json(scan_request_schema)
    market_adapter = current_app.extensions["market_data_adapter"]
    result = ScreenerService.run_scan(
        market_adapter=market_adapter,
        filters=params.get("filters", {}),
        sort_by=params.get("sort_by", "marketCap"),
        sort_order=params.get("sort_order", "desc"),
        limit=params.get("limit", 50),
    )
    return json_response(result)


@screener_bp.get("/strategies")
@require_feature_flag("enable_screener")
@require_auth
def list_strategies():
    limit = parse_limit(request.args.get("limit"), default=20, max_limit=100)
    cursor = parse_cursor(request.args.get("cursor"))
    strategies, next_cursor = ScreenerService.get_user_strategies_paginated(
        _user_id(), limit=limit, cursor=cursor
    )
    items = [ScreenerService.strategy_to_dict(s) for s in strategies]
    return json_response({"items": items}, meta=pagination_meta(next_cursor=next_cursor))


@screener_bp.post("/strategies")
@require_feature_flag("enable_screener")
@require_auth
def create_strategy():
    data = _load_json(create_strategy_schema)
    strategy = ScreenerService.create_strategy(
        user_id=_user_id(),
        name=data["name"],
        description=data.get("description"),
        filters=data.get("filters", {}),
        sort_by=data.get("sort_by", "marketCap"),
        sort_order=data.get("sort_order", "desc"),
    )
    return json_response(
        ScreenerService.strategy_to_dict(strategy),
        status_code=201,
    )


@screener_bp.get("/strategies/<int:strategy_id>")
@require_feature_flag("enable_screener")
@require_auth
def get_strategy(strategy_id: int):
    strategy = ScreenerService.get_strategy(_user_id(), strategy_id)
    return json_response(ScreenerService.strategy_to_dict(strategy))


@screener_bp.put("/strategies/<int:strategy_id>")
@require_feature_flag("enable_screener")
@require_auth
def update_strategy(strategy_id: int):
    updates = _load_json(update_strategy_schema)
    strategy = ScreenerService.update_strategy(_user_id(), strategy_id, updates)
    return json_response(ScreenerService.strategy_to_dict(strategy))


@screener_bp.delete("/strategies/<int:strategy_id>")
@require_feature_flag("enable_screener")
@require_auth
def delete_strategy(strategy_id: int):
    ScreenerService.delete_strategy(_user_id(), strategy_id)
    return json_response({}, status_code=204)


@screener_bp.post("/strategies/<int:strategy_id>/run")
@require_feature_flag("enable_screener")
@require_auth
def run_strategy(strategy_id: int):
    strategy = ScreenerService.get_strategy(_user_id(), strategy_id)
    market_adapter = current_app.extensions["market_data_adapter"]
    result = ScreenerService.run_scan(
        market_adapter=market_adapter,
        filters=strategy.filters or {},
        sort_by=strategy.sort_by or "marketCap",
        sort_order=strategy.sort_order or "desc",
    )
    return json_response(result)
