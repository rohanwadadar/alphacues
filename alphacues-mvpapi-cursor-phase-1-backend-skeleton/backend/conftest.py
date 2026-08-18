from __future__ import annotations

import os

import pytest

os.environ.setdefault("APP_ENV", "testing")
os.environ.setdefault("FLASK_ENV", "testing")
os.environ.setdefault(
    "DATABASE_URL",
    "postgresql+psycopg://alphacues:alphacues@127.0.0.1:5432/alphacues",
)
os.environ.setdefault("REDIS_URL", "redis://localhost:6379/0")

from app import create_app
from app.adapters.fake_email_sender import FakeEmailSender
from app.extensions import db

@pytest.fixture
def app():
    application = create_app("testing")
    application.config["TESTING"] = True
    application.config["RATELIMIT_STORAGE_URI"] = "memory://"
    fake_sender = FakeEmailSender()
    application.extensions["email_sender"] = fake_sender

    with application.app_context():
        from app.shared.limiter import limiter

        limiter.enabled = False
        db.create_all()
        yield application
        db.session.remove()


@pytest.fixture
def fake_email_sender(app):
    return app.extensions["email_sender"]


@pytest.fixture
def client(app):
    return app.test_client()



class _FakeRedis:
    def __init__(self) -> None:
        self._store: dict[str, str] = {}

    def ping(self) -> bool:
        return True

    def get(self, key: str) -> str | None:
        return self._store.get(key)

    def setex(self, key: str, ttl_seconds: int, value: str) -> bool:
        self._store[key] = value
        return True

    def delete(self, *keys: str) -> int:
        deleted = 0
        for key in keys:
            if key in self._store:
                del self._store[key]
                deleted += 1
        return deleted


_fake_redis_instance = _FakeRedis()


@pytest.fixture(autouse=True)
def redis_available(monkeypatch):
    _fake_redis_instance._store.clear()
    monkeypatch.setattr(
        "app.shared.limiter.is_rate_limit_storage_available",
        lambda: True,
    )
    monkeypatch.setattr(
        "app.shared.cache.get_redis",
        lambda: _fake_redis_instance,
    )

