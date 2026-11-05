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


def migrate_user_columns(app: Flask) -> None:
    with app.app_context():
        try:
            from sqlalchemy import text
            db.create_all()
            columns_to_add = [
                ("phone", "TEXT"),
                ("gender", "TEXT"),
                ("date_of_birth", "TEXT"),
                ("marital_status", "TEXT"),
                ("income_range", "TEXT"),
                ("occupation", "TEXT"),
                ("source_of_fund", "TEXT"),
                ("identity_type", "TEXT"),
                ("identity_number", "TEXT"),
                ("address", "TEXT"),
                ("kyc_status", "TEXT DEFAULT 'Verified'"),
                ("is_new_user", "BOOLEAN DEFAULT 1"),
            ]
            for col_name, col_type in columns_to_add:
                try:
                    db.session.execute(text(f"ALTER TABLE users ADD COLUMN {col_name} {col_type}"))
                    db.session.commit()
                except Exception:
                    db.session.rollback()
            try:
                from app.modules.alerts.service import AlertsService
                AlertsService.ensure_history_migrated()
            except Exception:
                pass
            try:
                db.session.execute(text("ALTER TABLE portfolio_event ADD COLUMN watchlist_name TEXT"))
                db.session.commit()
            except Exception:
                db.session.rollback()
        except Exception:
            pass


def init_db(app: Flask) -> None:
    """Initialize SQLAlchemy and Alembic migration wiring."""
    db.init_app(app)
    migrate.init_app(app, db)
    migrate_user_columns(app)
    migrate_user_columns(app)
