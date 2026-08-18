from __future__ import annotations
from flask_cors import CORS
import os

import sentry_sdk
from flask import Flask
from sentry_sdk.integrations.flask import FlaskIntegration
from sqlalchemy import text

from app.config.development import DevelopmentConfig
from app.config.production import ProductionConfig
from app.config.testing import TestingConfig
from app.extensions import db, init_extensions
from app.shared.cache import get_redis
from app.shared.error_handler import register_error_handlers
from app.shared.limiter import enforce_auth_fail_closed
from app.shared.logging import configure_logging, register_request_correlation
from app.shared.security import audit_secrets_safety, configure_cors, configure_security_headers

CONFIG_BY_NAME = {
    "development": DevelopmentConfig,
    "production": ProductionConfig,
    "testing": TestingConfig,
}


def create_app(config_name: str | None = None) -> Flask:
    app_env = (
        config_name or os.getenv("APP_ENV") or os.getenv("FLASK_ENV") or "development"
    )
    config_class = CONFIG_BY_NAME.get(app_env, DevelopmentConfig)

    app = Flask(__name__)
    app.config.from_object(config_class)
    configure_cors(app)
    configure_security_headers(app)
    configure_logging(app)
    audit_secrets_safety(app)

    if app.config.get("SENTRY_DSN"):
        sentry_sdk.init(
            dsn=app.config["SENTRY_DSN"],
            integrations=[FlaskIntegration()],
            environment=app_env,
        )

    try:
        import firebase_admin
        from firebase_admin import credentials
        if not firebase_admin._apps:
            # For MVP, we can use default credentials or a service account path from config
            cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
            if cred_path and os.path.exists(cred_path):
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
            else:
                # Fallback to default if running on GCP or if no credentials provided (will fail on actual send if invalid)
                firebase_admin.initialize_app()
    except Exception as e:
        import logging
        logging.getLogger(__name__).warning(f"Failed to initialize Firebase Admin: {e}")

    init_extensions(app)
    register_request_correlation(app)
    register_error_handlers(app)

    from app.adapters.email_sender import create_email_sender
    from app.adapters.market_data import create_market_data_adapter
    from app.modules.market import models as _market_models  # noqa: F401
    from app.modules.market.routes import dashboard_bp, market_bp
    from app.modules.alerts import models as _alerts_models  # noqa: F401
    from app.modules.alerts.routes import alerts_bp
    from app.modules.notifications import models as _notifications_models  # noqa: F401
    from app.modules.notifications.routes import notifications_bp
    from app.modules.notifications.devices_routes import devices_bp
    from app.modules.portfolio import models as _portfolio_models  # noqa: F401
    from app.modules.portfolio.routes import portfolio_bp
    from app.modules.admin.routes import admin_bp
    from app.modules.screener import models as _screener_models  # noqa: F401
    from app.modules.screener.routes import screener_bp
    from app.modules.user.routes import auth_bp
    from app.modules.watchlist import models as _watchlist_models  # noqa: F401
    from app.modules.watchlist.routes import watchlist_bp
    from app.modules.news.routes import news_bp

    if "email_sender" not in app.extensions:
        app.extensions["email_sender"] = create_email_sender(app)
    app.extensions["market_data_adapter"] = create_market_data_adapter(app)
    app.register_blueprint(auth_bp)
    app.register_blueprint(market_bp)
    app.register_blueprint(dashboard_bp)
    app.register_blueprint(watchlist_bp, url_prefix="/api/v1/watchlist")
    app.register_blueprint(alerts_bp, url_prefix="/api/v1/alerts")
    app.register_blueprint(notifications_bp, url_prefix="/api/v1/notifications")
    app.register_blueprint(devices_bp, url_prefix="/api/v1/devices")
    app.register_blueprint(portfolio_bp, url_prefix="/api/v1/portfolio")
    app.register_blueprint(screener_bp, url_prefix="/api/v1/screener")
    app.register_blueprint(admin_bp, url_prefix="/api/v1/admin")
    app.register_blueprint(news_bp, url_prefix="/api/v1/news")

    from app.shared.websocket import init_websocket

    init_websocket(app)

    @app.before_request
    def auth_rate_limit_fail_closed() -> None:
        enforce_auth_fail_closed()

    register_health_routes(app)

    return app


def register_health_routes(app: Flask) -> None:
    @app.get("/health/live")
    def health_live():
        return {"status": "ok"}, 200

    @app.get("/health/ready")
    def health_ready():
        checks: dict[str, str] = {}

        try:
            db.session.execute(text("SELECT 1"))
            checks["postgres"] = "ok"
        except Exception:
            checks["postgres"] = "unavailable"
            return json_response(
                status_code=503,
                error_code="SERVICE_UNAVAILABLE",
                error_message="Postgres is unavailable.",
                error_details=checks,
            )

        try:
            if get_redis().ping():
                checks["redis"] = "ok"
            else:
                raise RuntimeError("Redis ping failed")
        except Exception:
            checks["redis"] = "unavailable"
            return json_response(
                status_code=503,
                error_code="SERVICE_UNAVAILABLE",
                error_message="Redis is unavailable.",
                error_details=checks,
            )

        return json_response({"status": "ready", "checks": checks})


def create_celery_app(flask_app: Flask | None = None):
    from app.extensions import celery

    app = flask_app or create_app()
    celery.conf.update(
        broker_url=app.config["CELERY_BROKER_URL"],
        result_backend=app.config["CELERY_RESULT_BACKEND"],
    )

    class ContextTask(celery.Task):
        def __call__(self, *args, **kwargs):
            with app.app_context():
                return self.run(*args, **kwargs)

    celery.Task = ContextTask
    return celery
