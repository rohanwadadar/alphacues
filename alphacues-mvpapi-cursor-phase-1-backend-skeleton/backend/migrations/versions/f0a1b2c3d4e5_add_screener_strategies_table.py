"""add screener_strategies table

Revision ID: f0a1b2c3d4e5
Revises: e9f6a4b13c5d
Create Date: 2026-07-28 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "f0a1b2c3d4e5"
down_revision = "1a4af1cf30bf"
branch_labels = None
depends_on = None


def upgrade():
    bigint_id = sa.Integer() if op.get_bind().dialect.name == "sqlite" else sa.BigInteger()
    json_type = sa.JSON().with_variant(postgresql.JSONB(astext_type=sa.Text()), "postgresql")
    default_json = sa.text("'{}'::jsonb") if op.get_bind().dialect.name == "postgresql" else sa.text("'{}'")
    op.create_table(
        "screener_strategies",
        sa.Column("strategy_id", bigint_id, autoincrement=True, nullable=False),
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column(
            "filters",
            json_type,
            server_default=default_json,
            nullable=False,
        ),
        sa.Column(
            "sort_by",
            sa.Text(),
            server_default=sa.text("'marketCap'"),
            nullable=False,
        ),
        sa.Column(
            "sort_order",
            sa.Text(),
            server_default=sa.text("'desc'"),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.user_id"]),
        sa.PrimaryKeyConstraint("strategy_id"),
    )
    with op.batch_alter_table("screener_strategies", schema=None) as batch_op:
        batch_op.create_index("idx_screener_strategies_user", ["user_id"], unique=False)


def downgrade():
    with op.batch_alter_table("screener_strategies", schema=None) as batch_op:
        batch_op.drop_index("idx_screener_strategies_user")
    op.drop_table("screener_strategies")
