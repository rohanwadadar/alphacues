from __future__ import annotations

import json
from pathlib import Path

import pytest

from app.shared.db import db
from app.shared.feature_flags import FeatureFlag

CONTRACTS_DIR = Path(__file__).resolve().parents[4] / "tests" / "fixtures" / "contracts"


@pytest.fixture(autouse=True)
def enable_screener_flag(app):
    with app.app_context():
        flag = db.session.get(FeatureFlag, "enable_screener")
        if flag is None:
            flag = FeatureFlag(flag_key="enable_screener", is_enabled=True)
            db.session.add(flag)
        else:
            flag.is_enabled = True
        db.session.commit()
    yield
    with app.app_context():
        flag = db.session.get(FeatureFlag, "enable_screener")
        if flag:
            flag.is_enabled = False
            db.session.commit()


@pytest.fixture
def auth_headers(client, fake_email_sender):
    send = client.post(
        "/api/v1/auth/send-otp",
        json={"email": "screener-user@example.com"},
    )
    challenge_id = send.get_json()["data"]["otpChallengeId"]
    otp_code = fake_email_sender.last_otp_for("screener-user@example.com")
    verify = client.post(
        "/api/v1/auth/verify-otp",
        json={
            "email": "screener-user@example.com",
            "otpChallengeId": challenge_id,
            "otpCode": otp_code,
        },
    )
    access_token = verify.get_json()["data"]["accessToken"]
    return {"Authorization": f"Bearer {access_token}"}


def test_screener_feature_flag_disabled(client, auth_headers, app):
    with app.app_context():
        flag = db.session.get(FeatureFlag, "enable_screener")
        if flag:
            flag.is_enabled = False
            db.session.commit()

    res = client.post("/api/v1/screener/run", json={}, headers=auth_headers)
    assert res.status_code == 403
    body = res.get_json()
    assert body["success"] is False
    assert body["error"]["code"] == "FEATURE_DISABLED"


def test_screener_scan_deterministic(client, auth_headers):
    payload = {
        "filters": {
            "marketCapMin": 2000000000000,
            "peRatioMax": 36.0,
        },
        "sort_by": "marketCap",
        "sort_order": "desc",
    }
    # Run scan twice with identical filters
    res1 = client.post("/api/v1/screener/run", json=payload, headers=auth_headers)
    assert res1.status_code == 200
    body1 = res1.get_json()

    res2 = client.post("/api/v1/screener/run", json=payload, headers=auth_headers)
    assert res2.status_code == 200
    body2 = res2.get_json()

    assert body1["data"] == body2["data"]
    symbols1 = [item["symbol"] for item in body1["data"]["items"]]
    symbols2 = [item["symbol"] for item in body2["data"]["items"]]
    assert symbols1 == symbols2
    assert symbols1[0] == "MSFT"


def test_screener_filter_validation_error(client, auth_headers):
    # Invalid range: marketCapMin > marketCapMax -> HTTP 422
    payload = {
        "filters": {
            "marketCapMin": 5000000000000,
            "marketCapMax": 1000000000000,
        }
    }
    res = client.post("/api/v1/screener/run", json=payload, headers=auth_headers)
    assert res.status_code == 422
    body = res.get_json()
    assert body["success"] is False
    assert body["error"]["code"] == "VALIDATION_ERROR"


def test_screener_invalid_sort_by(client, auth_headers):
    # Invalid sort_by string -> HTTP 422
    payload = {
        "sort_by": "invalid_column_name; DROP TABLE users; --"
    }
    res = client.post("/api/v1/screener/run", json=payload, headers=auth_headers)
    assert res.status_code == 422
    body = res.get_json()
    assert body["success"] is False
    assert body["error"]["code"] == "VALIDATION_ERROR"


def test_screener_strategy_crud(client, auth_headers):
    # 1. Create Strategy (POST /api/v1/screener/strategies)
    create_payload = {
        "name": "Mega Cap Tech",
        "description": "Filter for mega cap technology stocks",
        "filters": {
            "marketCapMin": 1000000000000,
            "peRatioMax": 40.0,
        },
        "sort_by": "marketCap",
        "sort_order": "desc",
    }
    res = client.post(
        "/api/v1/screener/strategies", json=create_payload, headers=auth_headers
    )
    assert res.status_code == 201
    body = res.get_json()
    assert body["success"] is True
    strategy_id = body["data"]["strategyId"]
    assert body["data"]["name"] == "Mega Cap Tech"

    # 2. List Strategies (GET /api/v1/screener/strategies)
    res = client.get("/api/v1/screener/strategies", headers=auth_headers)
    assert res.status_code == 200
    body = res.get_json()
    assert body["success"] is True
    items = body["data"]["items"]
    assert len(items) == 1
    assert items[0]["strategyId"] == strategy_id
    assert "nextCursor" in body["meta"]

    # 3. Get Strategy (GET /api/v1/screener/strategies/:id)
    res = client.get(
        f"/api/v1/screener/strategies/{strategy_id}", headers=auth_headers
    )
    assert res.status_code == 200
    assert res.get_json()["data"]["name"] == "Mega Cap Tech"

    # 4. Run Strategy (POST /api/v1/screener/strategies/:id/run)
    res = client.post(
        f"/api/v1/screener/strategies/{strategy_id}/run", headers=auth_headers
    )
    assert res.status_code == 200
    assert res.get_json()["data"]["total"] >= 1

    # 5. Delete Strategy (DELETE /api/v1/screener/strategies/:id)
    res = client.delete(
        f"/api/v1/screener/strategies/{strategy_id}", headers=auth_headers
    )
    assert res.status_code == 204

    # Confirm deleted -> HTTP 404
    res = client.get(
        f"/api/v1/screener/strategies/{strategy_id}", headers=auth_headers
    )
    assert res.status_code == 404


def test_screener_contract_fixtures():
    # Verify contract fixtures exist and parse as valid JSON with standard response structure
    for filename in (
        "screener_results.json",
        "screener_strategy.json",
        "screener_strategy_list.json",
    ):
        path = CONTRACTS_DIR / filename
        assert path.exists(), f"Contract fixture missing: {filename}"
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
            assert "success" in data
            assert "data" in data
            assert "meta" in data
            assert "requestId" in data["meta"]
            assert "apiVersion" in data["meta"]
