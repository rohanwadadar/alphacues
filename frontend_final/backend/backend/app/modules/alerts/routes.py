from __future__ import annotations

from typing import Any

from flask import Blueprint, g, request
from marshmallow import ValidationError as MarshmallowValidationError

from app.modules.alerts.schemas import AlertCreateSchema, AlertUpdateSchema
from app.modules.alerts.service import AlertsService
from app.shared.auth import require_auth
from app.shared.exceptions import ValidationError
from app.shared.pagination import parse_pagination_params
from app.shared.response import json_response

alerts_bp = Blueprint("alerts", __name__, url_prefix="/api/v1/alerts")

create_alert_schema = AlertCreateSchema()
update_alert_schema = AlertUpdateSchema()


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


@alerts_bp.get("")
@require_auth
def list_alerts():
    limit, cursor = parse_pagination_params(
        raw_limit=request.args.get("limit"),
        raw_cursor=request.args.get("cursor"),
    )
    data, meta = AlertsService.list_alerts(_user_id(), limit=limit, cursor=cursor)
    return json_response(data, meta=meta)


@alerts_bp.get("/history")
@require_auth
def list_alert_history():
    limit, cursor = parse_pagination_params(
        raw_limit=request.args.get("limit"),
        raw_cursor=request.args.get("cursor"),
    )
    data, meta = AlertsService.list_trigger_history(
        _user_id(), limit=limit, cursor=cursor
    )
    return json_response(data, meta=meta)


@alerts_bp.post("")
@require_auth
def create_alert():
    data = _load_json(create_alert_schema)
    idempotency_key = request.headers.get("Idempotency-Key")
    alert = AlertsService.create_alert(
        _user_id(),
        symbol=data["symbol"],
        condition=data["condition"],
        target=data["target"],
        cooldown_seconds=data.get("cooldown_seconds", 0),
        idempotency_key=idempotency_key,
    )
    return json_response(AlertsService.alert_to_dict(alert), status_code=201)


@alerts_bp.put("/<int:alert_id>")
@require_auth
def update_alert(alert_id: int):
    data = _load_json(update_alert_schema)
    alert = AlertsService.update_alert(_user_id(), alert_id, data)
    return json_response(AlertsService.alert_to_dict(alert))


@alerts_bp.delete("/<int:alert_id>")
@require_auth
def delete_alert(alert_id: int):
    AlertsService.delete_alert(_user_id(), alert_id)
    return json_response({}, status_code=204)
