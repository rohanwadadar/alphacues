from celery import Celery
from flask_socketio import SocketIO

from app.shared.cache import init_redis
from app.shared.db import db  # noqa: F401
from app.shared.limiter import init_limiter

socketio = SocketIO()
celery = Celery("alphacues")


def init_extensions(app) -> None:
    from app.shared.db import init_db

    init_db(app)
    init_redis(app.config["REDIS_URL"])
    init_limiter(app)

    celery.conf.update(
        broker_url=app.config["CELERY_BROKER_URL"],
        result_backend=app.config["CELERY_RESULT_BACKEND"],
        task_ignore_result=True,
        broker_connection_retry_on_startup=True,
    )

    # TODO: Railway production requires sticky sessions for Socket.IO scaling.
    socketio_init_kwargs = {
        "async_mode": "eventlet",
        "cors_allowed_origins": app.config.get("CORS_ORIGINS", "*"),
    }
    if not app.config.get("TESTING") and not app.config.get("MOCK_EXTERNAL_SERVICES"):
        socketio_init_kwargs["message_queue"] = app.config["REDIS_URL"]
    socketio.init_app(app, **socketio_init_kwargs)
