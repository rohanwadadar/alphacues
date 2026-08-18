from __future__ import annotations

import uuid

import pytest

from app.extensions import socketio
from app.shared.auth import (
    ACCESS_TOKEN_TYPE,
    REFRESH_TOKEN_TYPE,
    issue_token,
)


def _make_access_token(app, *, ttl_seconds: int = 900) -> str:
    with app.app_context():
        return issue_token(
            user_id="42",
            email="user@example.com",
            session_id=str(uuid.uuid4()),
            token_type=ACCESS_TOKEN_TYPE,
            ttl_seconds=ttl_seconds,
        )


def _make_refresh_token(app) -> str:
    with app.app_context():
        return issue_token(
            user_id="42",
            email="user@example.com",
            session_id=str(uuid.uuid4()),
            token_type=REFRESH_TOKEN_TYPE,
            ttl_seconds=604800,
        )


def _connect_client(app, token: str):
    return socketio.test_client(
        app,
        flask_test_client=app.test_client(),
        auth={"token": token},
        namespace="/stream",
    )


def test_handshake_with_expired_jwt_is_rejected(app):
    expired_token = _make_access_token(app, ttl_seconds=-60)
    client = _connect_client(app, expired_token)
    assert not client.is_connected("/stream")


def test_handshake_with_valid_jwt_connects(app):
    access_token = _make_access_token(app)
    client = _connect_client(app, access_token)
    assert client.is_connected("/stream")


def test_subscribe_quotes_over_limit_emits_error(app):
    access_token = _make_access_token(app)
    client = _connect_client(app, access_token)
    assert client.is_connected("/stream")
    client.get_received("/stream")

    symbols = [f"A{i:03d}" for i in range(51)]
    client.emit("subscribe_quotes", {"symbols": symbols}, namespace="/stream")
    received = client.get_received("/stream")

    errors = [event for event in received if event["name"] == "error"]
    assert errors
    assert errors[0]["args"][0]["code"] == "SUBSCRIPTION_LIMIT"


def test_handshake_with_refresh_jwt_is_rejected(app):
    refresh_token = _make_refresh_token(app)
    client = _connect_client(app, refresh_token)
    assert not client.is_connected("/stream")
