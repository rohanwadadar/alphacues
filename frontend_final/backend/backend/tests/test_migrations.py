from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

BACKEND_ROOT = Path(__file__).resolve().parents[1]

MIGRATION_TEST_DATABASE_URL = (
    "postgresql+psycopg://alphacues:alphacues@localhost:5432/alphacues_migration_test"
)

_ENSURE_DB_SCRIPT = """
import os
import subprocess
import sys

database_url = os.environ["MIGRATION_TEST_DATABASE_URL"]
prefix, db_name = database_url.rsplit("/", 1)
admin_url = f"{prefix}/alphacues"

check = subprocess.run(
    [
        "docker",
        "compose",
        "-f",
        os.environ["COMPOSE_FILE"],
        "exec",
        "-T",
        "postgres",
        "psql",
        "-U",
        "alphacues",
        "-d",
        "alphacues",
        "-tc",
        f"SELECT 1 FROM pg_database WHERE datname = '{db_name}'",
    ],
    capture_output=True,
    text=True,
    check=False,
)
if "1" not in check.stdout:
    create = subprocess.run(
        [
            "docker",
            "compose",
            "-f",
            os.environ["COMPOSE_FILE"],
            "exec",
            "-T",
            "postgres",
            "psql",
            "-U",
            "alphacues",
            "-d",
            "alphacues",
            "-c",
            f"CREATE DATABASE {db_name};",
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    if create.returncode != 0:
        sys.stderr.write(create.stderr or create.stdout)
        sys.exit(create.returncode)
"""

_RESET_SCHEMA_SCRIPT = """
from sqlalchemy import text

from app import create_app
from app.extensions import db

app = create_app("testing")
with app.app_context():
    with db.engine.begin() as connection:
        connection.execute(text("DROP SCHEMA public CASCADE"))
        connection.execute(text("CREATE SCHEMA public"))
"""


def _migration_env() -> dict[str, str]:
    env = os.environ.copy()
    env["APP_ENV"] = "testing"
    env["FLASK_ENV"] = "testing"
    env["FLASK_APP"] = "wsgi.py"
    env["MIGRATION_TEST_DATABASE_URL"] = os.getenv(
        "MIGRATION_TEST_DATABASE_URL", MIGRATION_TEST_DATABASE_URL
    )
    env["DATABASE_URL"] = env["MIGRATION_TEST_DATABASE_URL"]
    env.setdefault(
        "COMPOSE_FILE",
        str(BACKEND_ROOT.parent / "docker-compose.yml"),
    )
    return env


def _run(
    command: list[str], *, env: dict[str, str]
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=BACKEND_ROOT,
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )


def test_alembic_check_passes():
    env = _migration_env()

    ensure_db = _run([sys.executable, "-c", _ENSURE_DB_SCRIPT], env=env)
    assert ensure_db.returncode == 0, ensure_db.stderr or ensure_db.stdout

    reset = _run([sys.executable, "-c", _RESET_SCHEMA_SCRIPT], env=env)
    assert reset.returncode == 0, reset.stderr or reset.stdout

    for command in ("upgrade", "check"):
        result = _run([sys.executable, "-m", "flask", "db", command], env=env)
        assert result.returncode == 0, result.stderr or result.stdout
