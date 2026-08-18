from __future__ import annotations

from typing import Any

from flask import Blueprint, g, request
from marshmallow import ValidationError as MarshmallowValidationError

from app.modules.watchlist.schemas import (
    AddWatchlistItemSchema,
    CreateWatchlistSchema,
    RenameWatchlistSchema,
)
from app.modules.watchlist.service import WatchlistService
from app.shared.auth import require_auth
from app.shared.exceptions import ValidationError
from app.shared.response import json_response

watchlist_bp = Blueprint("watchlist", __name__, url_prefix="/api/v1/watchlist")

create_watchlist_schema = CreateWatchlistSchema()
rename_watchlist_schema = RenameWatchlistSchema()
add_watchlist_item_schema = AddWatchlistItemSchema()


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


@watchlist_bp.get("")
@require_auth
def list_watchlists():
    data = WatchlistService.get_watchlist_list_data(_user_id())
    return json_response(data)


@watchlist_bp.post("")
@require_auth
def create_watchlist():
    data = _load_json(create_watchlist_schema)
    watchlist = WatchlistService.create_watchlist(_user_id(), data["name"])
    return json_response(
        WatchlistService.watchlist_summary_for(watchlist),
        status_code=201,
    )


@watchlist_bp.get("/<int:watchlist_id>")
@require_auth
def get_watchlist_detail(watchlist_id: int):
    data = WatchlistService.get_watchlist_detail(_user_id(), watchlist_id)
    return json_response(data)


@watchlist_bp.put("/<int:watchlist_id>")
@require_auth
def rename_watchlist(watchlist_id: int):
    data = _load_json(rename_watchlist_schema)
    watchlist = WatchlistService.rename_watchlist(
        _user_id(),
        watchlist_id,
        data["name"],
    )
    return json_response(WatchlistService.watchlist_summary_for(watchlist))


@watchlist_bp.delete("/<int:watchlist_id>")
@require_auth
def delete_watchlist(watchlist_id: int):
    WatchlistService.delete_watchlist(_user_id(), watchlist_id)
    return json_response({})


@watchlist_bp.post("/<int:watchlist_id>/items")
@require_auth
def add_watchlist_item(watchlist_id: int):
    data = _load_json(add_watchlist_item_schema)
    item = WatchlistService.add_symbol(_user_id(), watchlist_id, data["symbol"])
    return json_response(
        WatchlistService.watchlist_item_to_dict(item),
        status_code=201,
    )


@watchlist_bp.delete("/<int:watchlist_id>/items/<symbol>")
@require_auth
def remove_watchlist_item(watchlist_id: int, symbol: str):
    WatchlistService.remove_symbol(_user_id(), watchlist_id, symbol)
    return json_response({})
