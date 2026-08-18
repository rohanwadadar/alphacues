import pytest
from app import create_app
from app.shared.security import audit_secrets_safety


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("CORS_ORIGINS", "http://localhost:3000,http://localhost:5000")
    app = create_app("testing")
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_cors_headers_on_cross_origin_request(client):
    response = client.options(
        "/api/v1/auth/send-otp",
        headers={
            "Origin": "http://localhost:3000",
            "Access-Control-Request-Method": "POST",
        },
    )
    assert response.status_code == 200
    assert response.headers.get("Access-Control-Allow-Origin") == "http://localhost:3000"


def test_cors_rejects_unauthorized_origin(client):
    response = client.options(
        "/api/v1/auth/send-otp",
        headers={
            "Origin": "http://evil-attacker.com",
            "Access-Control-Request-Method": "POST",
        },
    )
    assert response.headers.get("Access-Control-Allow-Origin") != "http://evil-attacker.com"


def test_security_headers_present_on_all_responses(client):
    response = client.get("/health/live")
    assert response.status_code == 200
    assert response.headers.get("X-Content-Type-Options") == "nosniff"
    assert response.headers.get("X-Frame-Options") == "DENY"
    assert response.headers.get("X-XSS-Protection") == "1; mode=block"
    assert response.headers.get("Referrer-Policy") == "strict-origin-when-cross-origin"
    assert "default-src 'self'" in response.headers.get("Content-Security-Policy", "")


def test_secrets_audit_detects_default_placeholder():
    app = create_app("testing")
    app.config["SECRET_KEY"] = "replace-me"
    warnings = audit_secrets_safety(app)
    assert "SECRET_KEY" in warnings
