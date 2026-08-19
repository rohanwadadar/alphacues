import datetime
import sqlite3
from flask import Flask
from flask_migrate import Migrate
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import event
from sqlalchemy.engine import Engine

db = SQLAlchemy()
migrate = Migrate()


@event.listens_for(Engine, "connect")
def register_sqlite_functions(dbapi_connection, connection_record):
    if isinstance(dbapi_connection, sqlite3.Connection):
        dbapi_connection.create_function(
            "now", 0, lambda: datetime.datetime.now(datetime.timezone.utc).isoformat()
        )


def init_db(app: Flask) -> None:
    """Initialize SQLAlchemy and Alembic migration wiring."""
    db.init_app(app)
    migrate.init_app(app, db)
