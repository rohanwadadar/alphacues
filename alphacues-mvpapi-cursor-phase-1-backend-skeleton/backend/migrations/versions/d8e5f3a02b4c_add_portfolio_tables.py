"""add portfolio tables

Revision ID: d8e5f3a02b4c
Revises: c7d4e2f81a9b
Create Date: 2026-06-16 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "d8e5f3a02b4c"
down_revision = "c7d4e2f81a9b"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "portfolio_event",
        sa.Column("event_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("time_stamp", sa.DateTime(timezone=True), nullable=False),
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("symbol", sa.Text(), nullable=False),
        sa.Column("action", sa.Text(), nullable=False),
        sa.Column("price", sa.Numeric(precision=18, scale=6), nullable=False),
        sa.Column("volume", sa.Integer(), nullable=False),
        sa.CheckConstraint(
            "action IN ('BUY','SELL')",
            name="ck_portfolio_event_action",
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.user_id"]),
        sa.PrimaryKeyConstraint("event_id"),
    )
    with op.batch_alter_table("portfolio_event", schema=None) as batch_op:
        batch_op.create_index(
            "idx_portfolio_event_user_time",
            ["user_id", "time_stamp"],
            unique=False,
        )

    op.create_table(
        "positions",
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("symbol", sa.Text(), nullable=False),
        sa.Column(
            "volume",
            sa.Integer(),
            server_default=sa.text("0"),
            nullable=False,
        ),
        sa.Column(
            "total_price",
            sa.Numeric(precision=18, scale=6),
            server_default=sa.text("0"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.user_id"]),
        sa.PrimaryKeyConstraint("user_id", "symbol"),
    )
    with op.batch_alter_table("positions", schema=None) as batch_op:
        batch_op.create_index("idx_positions_user", ["user_id"], unique=False)

    op.create_table(
        "portfolio_snapshot",
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("time_stamp", sa.DateTime(timezone=True), nullable=False),
        sa.Column("symbol", sa.Text(), nullable=False),
        sa.Column("quantity", sa.BigInteger(), nullable=False),
        sa.Column("total_price", sa.Numeric(precision=18, scale=6), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.user_id"]),
        sa.PrimaryKeyConstraint("user_id", "time_stamp", "symbol"),
    )


def downgrade():
    op.drop_table("portfolio_snapshot")

    with op.batch_alter_table("positions", schema=None) as batch_op:
        batch_op.drop_index("idx_positions_user")
    op.drop_table("positions")

    with op.batch_alter_table("portfolio_event", schema=None) as batch_op:
        batch_op.drop_index("idx_portfolio_event_user_time")
    op.drop_table("portfolio_event")
