from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.shared.db import db


class User(db.Model):
    __tablename__ = "users"

    user_id: Mapped[int] = mapped_column(
        BigInteger().with_variant(Integer, "sqlite"), primary_key=True, autoincrement=True
    )
    email: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    name: Mapped[str | None] = mapped_column(Text, nullable=True)
    avatar_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default="true"
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=datetime.utcnow, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=datetime.utcnow, server_default=func.now()
    )

    otp_tokens: Mapped[list[OtpToken]] = relationship(back_populates="user")
    sessions: Mapped[list[UserSession]] = relationship(back_populates="user")
    device_push_tokens: Mapped[list[DevicePushToken]] = relationship(
        back_populates="user"
    )

    __table_args__ = (Index("idx_users_email", "email"),)


class OtpToken(db.Model):
    __tablename__ = "otp_tokens"

    id: Mapped[int] = mapped_column(BigInteger().with_variant(Integer, "sqlite"), primary_key=True, autoincrement=True)
    challenge_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), nullable=False, unique=True
    )
    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("users.user_id"), nullable=False
    )
    email: Mapped[str] = mapped_column(Text, nullable=False)
    otp_hash: Mapped[str] = mapped_column(Text, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    used: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, server_default="false"
    )
    failed_attempts: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, server_default="0"
    )
    locked_until: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=datetime.utcnow, server_default=func.now()
    )

    user: Mapped[User] = relationship(back_populates="otp_tokens")

    __table_args__ = (
        Index("idx_otp_email", "email"),
        Index("idx_otp_expires", "expires_at"),
    )


class UserSession(db.Model):
    __tablename__ = "user_sessions"

    session_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("users.user_id"), nullable=False
    )
    refresh_token_hash: Mapped[str] = mapped_column(Text, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    revoked_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=datetime.utcnow, server_default=func.now()
    )

    user: Mapped[User] = relationship(back_populates="sessions")

    __table_args__ = (Index("idx_user_sessions_user", "user_id"),)


class DevicePushToken(db.Model):
    __tablename__ = "device_push_tokens"

    device_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("users.user_id"), nullable=False
    )
    fcm_token: Mapped[str] = mapped_column(Text, nullable=False)
    platform: Mapped[str] = mapped_column(Text, nullable=False)
    app_version: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default="true"
    )
    last_seen_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=datetime.utcnow, server_default=func.now()
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=datetime.utcnow, server_default=func.now()
    )

    user: Mapped[User] = relationship(back_populates="device_push_tokens")

    __table_args__ = (
        CheckConstraint(
            "platform IN ('ios','android')", name="ck_device_push_tokens_platform"
        ),
        UniqueConstraint(
            "user_id", "fcm_token", name="uq_device_push_tokens_user_fcm_token"
        ),
        Index("idx_device_push_tokens_user_active", "user_id", "is_active"),
    )
