import os

from app.config.base import BaseConfig


class TestingConfig(BaseConfig):
    DEBUG = False
    TESTING = True
    SQLALCHEMY_DATABASE_URI = os.getenv(
        "DATABASE_URL",
        os.getenv(
            "TEST_DATABASE_URL",
            "postgresql+psycopg://alphacues:alphacues@localhost:5432/alphacues_test",
        ),
    )
    REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    MOCK_EXTERNAL_SERVICES = True
    EMAIL_BACKEND = "console"
    RATELIMIT_STORAGE_URI = "memory://"
