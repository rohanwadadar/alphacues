from __future__ import annotations

import logging
from typing import TYPE_CHECKING
from flask import Flask, request
from flask_cors import CORS

if TYPE_CHECKING:
    pass

logger = logging.getLogger(__name__)

DEFAULT_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://localhost:5000",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:5000",
]


def configure_cors(app: Flask) -> None:
    """
    Configures CORS rules to restrict origins to exact trusted frontend domains.
    Disallows wildcard '*' origins in production.
    """
    cors_origins = app.config.get("CORS_ORIGINS")
    app_env = app.config.get("APP_ENV", "development")

    if app_env in ("development", "testing"):
        origins = "*"
    elif not cors_origins or cors_origins == "*":
        origins = DEFAULT_ALLOWED_ORIGINS
    elif isinstance(cors_origins, str):
        origins = [o.strip() for o in cors_origins.split(",") if o.strip()]
    elif isinstance(cors_origins, (list, tuple)):
        origins = list(cors_origins)
    else:
        origins = DEFAULT_ALLOWED_ORIGINS

    CORS(
        app,
        resources={r"/*": {"origins": origins}},
        supports_credentials=True,
    )
    logger.info("Configured CORS allowed origins: %s", origins)


def configure_security_headers(app: Flask) -> None:
    """
    Attaches standard security response headers to all API responses.
    """

    @app.after_request
    def apply_security_headers(response):
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers[
            "Content-Security-Policy"
        ] = "default-src 'self'; frame-ancestors 'none';"

        app_env = app.config.get("APP_ENV", "development")
        if app_env == "production" or request.is_secure:
            response.headers[
                "Strict-Transport-Security"
            ] = "max-age=31536000; includeSubDomains; preload"

        return response


def audit_secrets_safety(app: Flask) -> dict[str, str]:
    """
    Audits active configuration to ensure no mock or hardcoded production secrets exist.
    """
    app_env = app.config.get("APP_ENV", "development")
    warnings: dict[str, str] = {}

    secret_key = app.config.get("SECRET_KEY", "")
    if not isinstance(secret_key, str) or len(secret_key) < 32 or secret_key == "replace-me":
        warnings["SECRET_KEY"] = "SECRET_KEY must be a non-placeholder value of at least 32 characters."

    database_url = app.config.get("SQLALCHEMY_DATABASE_URI", "")
    if "alphacues:alphacues@localhost" in database_url and app_env == "production":
        warnings["DATABASE_URL"] = "DATABASE_URL contains default local credentials in production."

    if app_env == "production":
        if not app.config.get("ALPACA_API_KEY") or not app.config.get("ALPACA_SECRET_KEY"):
            warnings["ALPACA_CREDENTIALS"] = "Alpaca credentials are required in production."
        if app.config.get("MOCK_EXTERNAL_SERVICES"):
            warnings["MOCK_EXTERNAL_SERVICES"] = "Mock external services must be disabled in production."

    if app_env == "production" and warnings:
        logger.error("PRODUCTION SECRETS AUDIT FAILED: %s", warnings)
        raise RuntimeError(
            "Unsafe production configuration: " + ", ".join(sorted(warnings))
        )
    else:
        logger.info("Secrets audit completed. Active warnings count: %d", len(warnings))

    return warnings
