"""add watchlist tables

Revision ID: b2c8f4a91d3e
Revises: 0141d3d0feea
Create Date: 2026-06-07 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


revision = "b2c8f4a91d3e"
down_revision = "0141d3d0feea"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "watchlists",
        sa.Column("watchlist_id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("user_id", sa.BigInteger(), nullable=False),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.user_id"]),
        sa.PrimaryKeyConstraint("watchlist_id"),
    )
    with op.batch_alter_table("watchlists", schema=None) as batch_op:
        batch_op.create_index("idx_watchlist_user", ["user_id"], unique=False)

    op.create_table(
        "watchlist_items",
        sa.Column("id", sa.BigInteger(), autoincrement=True, nullable=False),
        sa.Column("watchlist_id", sa.BigInteger(), nullable=False),
        sa.Column("symbol", sa.Text(), nullable=False),
        sa.Column(
            "added_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["watchlist_id"], ["watchlists.watchlist_id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("watchlist_id", "symbol", name="uq_watchlist_items_symbol"),
    )
    with op.batch_alter_table("watchlist_items", schema=None) as batch_op:
        batch_op.create_index(
            "idx_watchlist_items_watchlist", ["watchlist_id"], unique=False
        )


def downgrade():
    with op.batch_alter_table("watchlist_items", schema=None) as batch_op:
        batch_op.drop_index("idx_watchlist_items_watchlist")

    op.drop_table("watchlist_items")
    with op.batch_alter_table("watchlists", schema=None) as batch_op:
        batch_op.drop_index("idx_watchlist_user")

    op.drop_table("watchlists")
