"""add alerts and notifications tables

Revision ID: c7d4e2f81a9b
Revises: b2c8f4a91d3e
Create Date: 2026-06-13 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "c7d4e2f81a9b"
down_revision = "b2c8f4a91d3e"
branch_labels = None
depends_on = None


def upgrade():
    bigint_id = sa.Integer() if op.get_bind().dialect.name == "sqlite" else sa.BigInteger()
    op.create_table(
        "alerts",
        sa.Column("alert_id", bigint_id, autoincrement=True, nullable=False),
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("symbol", sa.Text(), nullable=False),
        sa.Column("condition", sa.Text(), nullable=False),
        sa.Column("target", sa.Numeric(precision=18, scale=6), nullable=False),
        sa.Column(
            "is_active",
            sa.Boolean(),
            server_default=sa.text("true"),
            nullable=False,
        ),
        sa.Column(
            "triggered",
            sa.Boolean(),
            server_default=sa.text("false"),
            nullable=False,
        ),
        sa.Column(
            "cooldown_seconds",
            sa.Integer(),
            server_default=sa.text("0"),
            nullable=False,
        ),
        sa.Column("last_triggered_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "condition IN ('ABOVE','BELOW','PERCENT_CHANGE')",
            name="ck_alerts_condition",
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.user_id"]),
        sa.PrimaryKeyConstraint("alert_id"),
    )
    with op.batch_alter_table("alerts", schema=None) as batch_op:
        batch_op.create_index("idx_alerts_user", ["user_id"], unique=False)
        batch_op.create_index("idx_alerts_active", ["is_active"], unique=False)
        batch_op.create_index(
            "idx_alerts_symbol_active", ["symbol", "is_active"], unique=False
        )

    op.create_table(
        "alert_trigger_events",
        sa.Column("id", bigint_id, autoincrement=True, nullable=False),
        sa.Column("alert_id", sa.BigInteger(), nullable=False),
        sa.Column("triggered_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("trigger_price", sa.Numeric(precision=18, scale=6), nullable=False),
        sa.ForeignKeyConstraint(["alert_id"], ["alerts.alert_id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    if op.get_bind().dialect.name == "postgresql":
        op.execute(
            """
            CREATE UNIQUE INDEX uq_alert_trigger_events_alert_minute
            ON alert_trigger_events (
                alert_id,
                date_trunc('minute', triggered_at AT TIME ZONE 'UTC')
            )
            """
        )

    op.create_table(
        "notifications",
        sa.Column(
            "notification_id", bigint_id, autoincrement=True, nullable=False
        ),
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("alert_id", sa.BigInteger(), nullable=True),
        sa.Column("title", sa.Text(), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column(
            "is_read",
            sa.Boolean(),
            server_default=sa.text("false"),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["alert_id"], ["alerts.alert_id"]),
        sa.ForeignKeyConstraint(["user_id"], ["users.user_id"]),
        sa.PrimaryKeyConstraint("notification_id"),
    )
    with op.batch_alter_table("notifications", schema=None) as batch_op:
        batch_op.create_index("idx_notifications_user", ["user_id"], unique=False)
        batch_op.create_index(
            "idx_notifications_unread",
            ["user_id", "is_read"],
            unique=False,
            postgresql_where=sa.text("is_read = false"),
        )

    json_type = sa.JSON().with_variant(postgresql.JSONB(astext_type=sa.Text()), "postgresql")
    op.create_table(
        "outbox_events",
        sa.Column("id", bigint_id, autoincrement=True, nullable=False),
        sa.Column("event_type", sa.Text(), nullable=False),
        sa.Column("payload", json_type, nullable=False),
        sa.Column(
            "status",
            sa.Text(),
            server_default=sa.text("'pending'"),
            nullable=False,
        ),
        sa.Column(
            "next_attempt_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    with op.batch_alter_table("outbox_events", schema=None) as batch_op:
        batch_op.create_index(
            "idx_outbox_events_status_next_attempt",
            ["status", "next_attempt_at"],
            unique=False,
        )


def downgrade():
    with op.batch_alter_table("outbox_events", schema=None) as batch_op:
        batch_op.drop_index("idx_outbox_events_status_next_attempt")
    op.drop_table("outbox_events")

    with op.batch_alter_table("notifications", schema=None) as batch_op:
        batch_op.drop_index("idx_notifications_unread")
        batch_op.drop_index("idx_notifications_user")
    op.drop_table("notifications")

    op.execute("DROP INDEX IF EXISTS uq_alert_trigger_events_alert_minute")
    op.drop_table("alert_trigger_events")

    with op.batch_alter_table("alerts", schema=None) as batch_op:
        batch_op.drop_index("idx_alerts_symbol_active")
        batch_op.drop_index("idx_alerts_active")
        batch_op.drop_index("idx_alerts_user")
    op.drop_table("alerts")
