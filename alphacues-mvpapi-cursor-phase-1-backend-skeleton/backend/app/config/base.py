import os
from pathlib import Path

from dotenv import load_dotenv

_BACKEND_ROOT = Path(__file__).resolve().parents[2]
load_dotenv(_BACKEND_ROOT / ".env")


class BaseConfig:
    APP_ENV = os.getenv("APP_ENV", "development")
    SECRET_KEY = os.getenv("SECRET_KEY", "replace-me")

    JWT_ISSUER = os.getenv("JWT_ISSUER", "alphacues")
    JWT_AUDIENCE = os.getenv("JWT_AUDIENCE", "alphacues-web")
    ACCESS_TOKEN_TTL_SECONDS = int(os.getenv("ACCESS_TOKEN_TTL_SECONDS", "900"))
    REFRESH_TOKEN_TTL_SECONDS = int(os.getenv("REFRESH_TOKEN_TTL_SECONDS", "604800"))

    SQLALCHEMY_DATABASE_URI = os.getenv(
        "DATABASE_URL",
        "postgresql+psycopg://alphacues:alphacues@localhost:5432/alphacues",
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {
        "pool_pre_ping": True,
    }

    REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    RATELIMIT_STORAGE_URI = os.getenv("RATELIMIT_STORAGE_URI")

    API_BASE_URL = os.getenv("API_BASE_URL", "http://localhost:5000")
    FRONTEND_BASE_URL = os.getenv("FRONTEND_BASE_URL", "http://localhost:3000")
    API_VERSION = "1"

    MOCK_EXTERNAL_SERVICES = (
        os.getenv("MOCK_EXTERNAL_SERVICES", "false").lower() == "true"
    )
    EMAIL_BACKEND = os.getenv("EMAIL_BACKEND", "console")
    SMTP_HOST = os.getenv("SMTP_HOST", "localhost")
    SMTP_PORT = int(os.getenv("SMTP_PORT", "1025"))

    SENDGRID_API_KEY = os.getenv("SENDGRID_API_KEY", "")
    SENDGRID_FROM_EMAIL = os.getenv("SENDGRID_FROM_EMAIL", "alerts@alphacues.local")

    ALPACA_API_KEY = os.getenv("ALPACA_API_KEY", "")
    ALPACA_SECRET_KEY = os.getenv("ALPACA_SECRET_KEY", "")
    ALPACA_DATA_FEED = os.getenv("ALPACA_DATA_FEED", "iex")
    ALPACA_STREAM_URL = os.getenv(
        "ALPACA_STREAM_URL",
        "wss://stream.data.alpaca.markets/v2/iex",
    )

    ALPHA_VANTAGE_API_KEY = os.getenv("ALPHA_VANTAGE_API_KEY", "")

    RATE_LIMIT_AUTH_PER_MINUTE = int(os.getenv("RATE_LIMIT_AUTH_PER_MINUTE", "5"))
    RATE_LIMIT_MARKET_SEARCH_PER_MINUTE = int(
        os.getenv("RATE_LIMIT_MARKET_SEARCH_PER_MINUTE", "30")
    )

    SENTRY_DSN = os.getenv("SENTRY_DSN", "")
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

    FCM_PROJECT_ID = os.getenv("FCM_PROJECT_ID", "")
    GOOGLE_APPLICATION_CREDENTIALS = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "")

    CELERY_BROKER_URL = os.getenv("CELERY_BROKER_URL") or REDIS_URL
    CELERY_RESULT_BACKEND = os.getenv("CELERY_RESULT_BACKEND") or REDIS_URL

    SOCKETIO_MESSAGE_QUEUE = os.getenv("SOCKETIO_MESSAGE_QUEUE") or REDIS_URL

    _raw_cors_origins = os.getenv("CORS_ORIGINS", "*")
    CORS_ORIGINS = (
        [origin.strip() for origin in _raw_cors_origins.split(",") if origin.strip()]
        if _raw_cors_origins != "*"
        else "*"
    )
