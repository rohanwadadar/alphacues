from __future__ import annotations

import json
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import pytest

from scripts.contract_check import run_contract_check

CONTRACTS_DIR = Path(__file__).resolve().parent / "fixtures" / "contracts"


def _resolve_fixture_path(filename: str) -> Path:
    """Find a fixture JSON file either under root CONTRACTS_DIR or modular subdirectories."""
    direct = CONTRACTS_DIR / filename
    if direct.exists():
        return direct
    matches = list(CONTRACTS_DIR.rglob(filename))
    if matches:
        return matches[0]
    raise FileNotFoundError(f"Contract fixture '{filename}' not found in {CONTRACTS_DIR}")


@dataclass(frozen=True)
class AuthContractCase:
    fixture_name: str
    method: str
    path: str
    prepare: Callable[[Any, Any], dict[str, Any]]
    required_data_paths: tuple[str, ...]


def _nested_get(payload: dict[str, Any], dotted_path: str) -> Any:
    current: Any = payload
    for part in dotted_path.split("."):
        if not isinstance(current, dict) or part not in current:
            raise KeyError(dotted_path)
        current = current[part]
    return current


def _assert_success_envelope(body: dict[str, Any], fixture: dict[str, Any]) -> None:
    assert isinstance(body["success"], bool)
    assert body["success"] is True
    assert body["error"] is None
    assert isinstance(body["meta"]["requestId"], str)
    assert body["meta"]["requestId"]
    assert body["meta"]["apiVersion"] == "1"
    assert set(body.keys()) >= {"success", "data", "error", "meta"}
    assert "data" in body
    assert fixture["data"] is None or isinstance(body["data"], dict)


def _prepare_send_otp(_client, _fake_email_sender) -> dict[str, Any]:
    return {"json": {"email": "user@example.com"}}


def _prepare_verify_otp(client, fake_email_sender) -> dict[str, Any]:
    send = client.post("/api/v1/auth/send-otp", json={"email": "user@example.com"})
    challenge_id = send.get_json()["data"]["otpChallengeId"]
    otp_code = fake_email_sender.last_otp_for("user@example.com")
    return {
        "json": {
            "email": "user@example.com",
            "otpChallengeId": challenge_id,
            "otpCode": otp_code,
        }
    }


def _prepare_refresh(client, fake_email_sender) -> dict[str, Any]:
    verify_kwargs = _prepare_verify_otp(client, fake_email_sender)
    verify = client.post("/api/v1/auth/verify-otp", **verify_kwargs)
    refresh_token = verify.get_json()["data"]["refreshToken"]
    return {"json": {"refreshToken": refresh_token}}


def _prepare_logout(client, fake_email_sender) -> dict[str, Any]:
    verify_kwargs = _prepare_verify_otp(client, fake_email_sender)
    verify = client.post("/api/v1/auth/verify-otp", **verify_kwargs)
    refresh_token = verify.get_json()["data"]["refreshToken"]
    return {"json": {"refreshToken": refresh_token}}


AUTH_CONTRACT_CASES = (
    AuthContractCase(
        fixture_name="auth_send_otp_response.json",
        method="POST",
        path="/api/v1/auth/send-otp",
        prepare=_prepare_send_otp,
        required_data_paths=("otpChallengeId", "emailMasked", "expiresInSeconds"),
    ),
    AuthContractCase(
        fixture_name="auth_verify_otp_response.json",
        method="POST",
        path="/api/v1/auth/verify-otp",
        prepare=_prepare_verify_otp,
        required_data_paths=(
            "accessToken",
            "refreshToken",
            "expiresInSeconds",
            "user.userId",
            "user.email",
            "user.name",
            "user.avatarUrl",
        ),
    ),
    AuthContractCase(
        fixture_name="auth_refresh_response.json",
        method="POST",
        path="/api/v1/auth/refresh",
        prepare=_prepare_refresh,
        required_data_paths=("accessToken", "refreshToken", "expiresInSeconds"),
    ),
    AuthContractCase(
        fixture_name="auth_logout_response.json",
        method="POST",
        path="/api/v1/auth/logout",
        prepare=_prepare_logout,
        required_data_paths=(),
    ),
)


@pytest.mark.parametrize(
    "case", AUTH_CONTRACT_CASES, ids=lambda case: case.fixture_name
)
def test_auth_endpoint_contract_envelope(
    client, fake_email_sender, case: AuthContractCase
):
    fixture_path = _resolve_fixture_path(case.fixture_name)
    fixture = json.loads(fixture_path.read_text())
    request_kwargs = case.prepare(client, fake_email_sender)
    response = client.open(case.path, method=case.method, **request_kwargs)
    body = response.get_json()

    _assert_success_envelope(body, fixture)

    for dotted_path in case.required_data_paths:
        _nested_get(body["data"], dotted_path)

    for key in fixture["data"] or {}:
        assert key in body["data"], f"Missing contract field: {key}"

    if case.fixture_name == "auth_logout_response.json":
        assert body["data"] is None
    elif case.fixture_name == "auth_verify_otp_response.json":
        user_fixture = fixture["data"]["user"]
        for key in user_fixture:
            assert key in body["data"]["user"], f"Missing user contract field: {key}"
        assert isinstance(body["data"]["user"]["userId"], str)


def test_contract_fixtures_pass_contract_check():
    """CI contract check test wrapper verifying all modular contract fixtures."""
    passed, failed = run_contract_check(CONTRACTS_DIR)
    assert failed == 0, f"Contract check failed for {failed} fixtures."
    assert passed > 0, "No contract fixtures were evaluated."
