from __future__ import annotations

from flask import Flask
from flask_migrate import Migrate
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()
migrate = Migrate()


def init_db(app: Flask) -> None:
    """Initialize SQLAlchemy and Alembic migration wiring."""
    db.init_app(app)
    migrate.init_app(app, db)
