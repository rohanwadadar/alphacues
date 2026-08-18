from __future__ import annotations

import json
import logging
import re
from datetime import datetime, timezone
from typing import Any

from flask import Flask, request, session
from flask_socketio import Namespace, join_room, leave_room

from app.extensions import socketio
from app.shared.auth import verify_access_token
from app.shared.cache import get_redis
from app.shared.exceptions import TokenExpiredError, UnauthorizedError

logger = logging.getLogger(__name__)

STREAM_NAMESPACE = "/stream"
SYMBOL_PATTERN = re.compile(r"^[A-Z][A-Z0-9._-]{0,14}$")
# TODO: 50-symbol cap per connection guards Alpaca upstream quota.
SUBSCRIPTION_LIMIT = 50
QUOTE_STALE_SECONDS = 5


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _parse_as_of(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def _quote_room(symbol: str) -> str:
    return f"quote:{symbol}"


def _user_room(user_id: str) -> str:
    return f"user:{user_id}"


def _connection_state(subscriptions: set[str]) -> dict[str, Any]:
    return {
        "status": "connected",
        "subscribedSymbols": sorted(subscriptions),
    }


class StreamNamespace(Namespace):
    def on_connect(self, auth: dict[str, Any] | None = None) -> bool:
        token = None
        if auth and isinstance(auth, dict):
            token = auth.get("token")
        if not token:
            token = request.args.get("token")

        if not token:
            return False

        try:
            payload = verify_access_token(token)
        except (UnauthorizedError, TokenExpiredError):
            return False

        user_id = payload.get("sub")
        if not user_id:
            return False

        session["user_id"] = user_id
        session["subscriptions"] = set()
        self.emit("connection_state", _connection_state(session["subscriptions"]))
        return True

    def on_disconnect(self) -> None:
        session["subscriptions"] = set()

    def on_subscribe_quotes(self, data: dict[str, Any] | None) -> None:
        symbols = (data or {}).get("symbols") or []
        if not isinstance(symbols, list):
            return

        subscriptions: set[str] = session.get("subscriptions") or set()
        valid_symbols: list[str] = []
        for raw_symbol in symbols:
            if not isinstance(raw_symbol, str):
                continue
            symbol = raw_symbol.upper()
            if not SYMBOL_PATTERN.match(symbol):
                continue
            valid_symbols.append(symbol)

        remaining = SUBSCRIPTION_LIMIT - len(subscriptions)
        if len(valid_symbols) > remaining:
            self.emit(
                "error",
                {
                    "code": "SUBSCRIPTION_LIMIT",
                    "message": "Max 50 symbols per connection",
                },
            )
            valid_symbols = valid_symbols[: max(remaining, 0)]

        for symbol in valid_symbols:
            join_room(_quote_room(symbol))
            subscriptions.add(symbol)

        session["subscriptions"] = subscriptions

    def on_unsubscribe_quotes(self, data: dict[str, Any] | None) -> None:
        symbols = (data or {}).get("symbols") or []
        if not isinstance(symbols, list):
            return

        subscriptions: set[str] = session.get("subscriptions") or set()
        for raw_symbol in symbols:
            if not isinstance(raw_symbol, str):
                continue
            symbol = raw_symbol.upper()
            leave_room(_quote_room(symbol))
            subscriptions.discard(symbol)

        session["subscriptions"] = subscriptions

    def on_subscribe_notifications(self) -> None:
        user_id = session.get("user_id")
        if not user_id:
            return
        join_room(_user_room(str(user_id)))

    def on_resume_session(self) -> None:
        subscriptions: set[str] = session.get("subscriptions") or set()
        self.emit("connection_state", _connection_state(subscriptions))


class QuoteBatcher:
    """Coalesces rapid quote ticks per symbol to optimize Socket.IO fan-out."""

    def __init__(self, batch_interval_ms: float = 50.0) -> None:
        import threading
        self.batch_interval_ms = batch_interval_ms
        self._buffer: dict[str, dict[str, Any]] = {}
        self._lock = threading.Lock()

    def buffer_quote(self, symbol: str, payload: dict[str, Any]) -> None:
        with self._lock:
            self._buffer[symbol] = payload

    def flush(self) -> list[tuple[str, dict[str, Any]]]:
        with self._lock:
            items = list(self._buffer.items())
            self._buffer.clear()
            return items


quote_batcher = QuoteBatcher()


def _handle_quote_message(app: Flask, channel: str, raw_payload: str, *, batch: bool = False) -> None:
    if not channel.startswith("quotes:"):
        return

    symbol = channel.split(":", 1)[1]
    try:
        payload = json.loads(raw_payload)
    except json.JSONDecodeError:
        logger.warning("Invalid quote payload on channel=%s", channel)
        return

    as_of_raw = payload.get("asOf")
    if not as_of_raw:
        return

    try:
        as_of = _parse_as_of(as_of_raw)
    except ValueError:
        return

    age_seconds = (_utcnow() - as_of).total_seconds()
    if age_seconds > QUOTE_STALE_SECONDS:
        return

    emit_payload = {
        "symbol": payload.get("symbol", symbol),
        "lastPrice": float(payload["lastPrice"]),
        "changeAmount": float(payload["changeAmount"]),
        "changePercent": float(payload["changePercent"]),
        "asOf": as_of_raw,
    }

    if batch:
        quote_batcher.buffer_quote(symbol, emit_payload)
    else:
        socketio.emit(
            "quote_update",
            emit_payload,
            room=_quote_room(symbol),
            namespace=STREAM_NAMESPACE,
        )


def flush_quote_batch() -> int:
    """Flushes all buffered quote ticks out to their respective symbol rooms."""
    items = quote_batcher.flush()
    for symbol, emit_payload in items:
        socketio.emit(
            "quote_update",
            emit_payload,
            room=_quote_room(symbol),
            namespace=STREAM_NAMESPACE,
        )
    return len(items)



def _redis_quote_listener(app: Flask) -> None:
    pubsub = get_redis().pubsub(ignore_subscribe_messages=True)
    pubsub.psubscribe("quotes:*")
    logger.info("Redis quote listener subscribed to quotes:*")

    for message in pubsub.listen():
        if message.get("type") != "pmessage":
            continue
        channel = message.get("channel") or ""
        data = message.get("data")
        if not isinstance(data, str):
            continue
        with app.app_context():
            _handle_quote_message(app, channel, data)


def init_websocket(app: Flask) -> None:
    socketio.on_namespace(StreamNamespace(STREAM_NAMESPACE))

    if not app.config.get("TESTING"):
        try:
            redis_client = get_redis()
            redis_client.ping()
            socketio.start_background_task(_redis_quote_listener, app)
        except Exception:
            logger.warning(
                "Redis server is not running or unavailable. WebSocket quote listener NOT started.",
                exc_info=True
            )


# notification_new and alert_triggered are emitted by the Celery worker via
# socketio.emit(..., room="user:<user_id>", namespace="/stream").
# See backend/worker.py.
