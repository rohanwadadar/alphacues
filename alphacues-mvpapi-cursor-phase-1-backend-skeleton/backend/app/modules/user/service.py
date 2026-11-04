from __future__ import annotations

import hashlib
import hmac
import secrets
import unicodedata
import uuid
from datetime import datetime, timedelta, timezone
from typing import Any

from flask import current_app
from sqlalchemy import and_, select, update

from app.adapters.protocols import EmailSender
from app.modules.user.models import OtpToken, User, UserSession
from app.shared.auth import (
    ACCESS_TOKEN_TYPE,
    REFRESH_TOKEN_TYPE,
    issue_token,
    verify_access_token,
)
from app.shared.db import db
from app.shared.exceptions import (
    OtpChallengeNotFoundError,
    OtpExpiredError,
    OtpInvalidError,
    OtpLockedError,
    UnauthorizedError,
)

OTP_TTL_SECONDS = 300
OTP_LOCK_MINUTES = 15
MAX_OTP_ATTEMPTS = 5


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def normalize_email(email: str) -> str:
    normalized = unicodedata.normalize("NFKC", email.strip())
    return normalized.lower()


def mask_email(email: str) -> str:
    local, _, domain = email.partition("@")
    if not local:
        return f"***@{domain}"
    return f"{local[0]}***@{domain}"


def hash_secret(value: str) -> str:
    pepper = current_app.config["SECRET_KEY"]
    digest = hashlib.sha256(f"{pepper}:{value}".encode("utf-8")).hexdigest()
    return digest


def verify_secret(value: str, stored_hash: str) -> bool:
    return hmac.compare_digest(hash_secret(value), stored_hash)


def generate_otp_code() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


def user_to_dict(user: User) -> dict[str, Any]:
    return {
        "userId": str(user.user_id),
        "email": user.email,
        "name": user.name,
        "avatarUrl": user.avatar_url,
        "phone": getattr(user, "phone", None),
        "gender": getattr(user, "gender", None),
        "dateOfBirth": getattr(user, "date_of_birth", None),
        "maritalStatus": getattr(user, "marital_status", None),
        "incomeRange": getattr(user, "income_range", None),
        "occupation": getattr(user, "occupation", None),
        "sourceOfFund": getattr(user, "source_of_fund", None),
        "identityType": getattr(user, "identity_type", None),
        "identityNumber": getattr(user, "identity_number", None),
        "address": getattr(user, "address", None),
        "primaryAddress": getattr(user, "primary_address", None),
        "secondaryAddress": getattr(user, "secondary_address", None),
        "phoneType": getattr(user, "phone_type", None),
        "investmentExperience": getattr(user, "investment_experience", None),
        "productType": getattr(user, "product_type", None),
        "tradingFrequency": getattr(user, "trading_frequency", None),
        "investmentObjective": getattr(user, "investment_objective", None),
        "tradingStyle": getattr(user, "trading_style", None),
        "riskTolerance": getattr(user, "risk_tolerance", None),
        "kycStatus": getattr(user, "kyc_status", "Verified"),
        "updatedAt": user.updated_at.isoformat() if hasattr(user, "updated_at") and user.updated_at else None,
        "isNewUser": getattr(user, "is_new_user", False),
    }


def tokens_response(
    *,
    user: User,
    access_token: str,
    refresh_token: str,
) -> dict[str, Any]:
    return {
        "accessToken": access_token,
        "refreshToken": refresh_token,
        "expiresInSeconds": current_app.config["ACCESS_TOKEN_TTL_SECONDS"],
        "user": user_to_dict(user),
    }


def refresh_tokens_response(
    *,
    access_token: str,
    refresh_token: str,
) -> dict[str, Any]:
    return {
        "accessToken": access_token,
        "refreshToken": refresh_token,
        "expiresInSeconds": current_app.config["ACCESS_TOKEN_TTL_SECONDS"],
    }


class AuthService:
    def __init__(self, email_sender: EmailSender | None = None) -> None:
        self._email_sender = email_sender

    @property
    def email_sender(self) -> EmailSender:
        if self._email_sender is not None:
            return self._email_sender
        sender = current_app.extensions.get("email_sender")
        if sender is None:
            raise RuntimeError("Email sender is not configured on the application.")
        return sender

    def check_email(self, email: str) -> dict[str, Any]:
        """Returns whether the email is registered and is_new_user status."""
        normalized_email = normalize_email(email)
        user = db.session.scalar(select(User).where(User.email == normalized_email))
        if user is None:
            return {"exists": False, "isNewUser": False}
        return {"exists": True, "isNewUser": user.is_new_user}

    def send_otp(self, email: str, allow_new_user: bool = True) -> dict[str, Any]:
        normalized_email = normalize_email(email)
        # If this is the login endpoint (allow_new_user=False), reject unregistered emails
        existing_user = db.session.scalar(select(User).where(User.email == normalized_email))
        if not allow_new_user and existing_user is None:
            from app.shared.exceptions import NotFoundError
            raise NotFoundError(
                message="No account found for this email. Please register as a new user."
            )
        user = self._get_or_create_user(normalized_email)
        now = utcnow()

        (
            db.session.execute(
                update(OtpToken)
                .where(
                    and_(
                        OtpToken.email == normalized_email,
                        OtpToken.used.is_(False),
                        OtpToken.expires_at > now,
                    )
                )
                .values(used=True)
            )
        )

        otp_code = generate_otp_code()
        challenge_id = uuid.uuid4()
        expires_at = now + timedelta(seconds=OTP_TTL_SECONDS)

        challenge = OtpToken(
            challenge_id=challenge_id,
            user_id=user.user_id,
            email=normalized_email,
            otp_hash=hash_secret(otp_code),
            expires_at=expires_at,
        )
        db.session.add(challenge)
        db.session.flush()

        self.email_sender.send_otp(normalized_email, otp_code)
        db.session.commit()

        from app.shared.logging import log_otp_request
        log_otp_request(mask_email(normalized_email))

        return {
            "otpChallengeId": str(challenge_id),
            "emailMasked": mask_email(normalized_email),
            "expiresInSeconds": OTP_TTL_SECONDS,
        }

    def verify_otp(
        self,
        *,
        email: str,
        challenge_id: uuid.UUID,
        otp_code: str,
    ) -> dict[str, Any]:
        from app.shared.logging import log_otp_failed, log_otp_lockout
        normalized_email = normalize_email(email)
        challenge = self._get_challenge(normalized_email, challenge_id)
        self._ensure_challenge_active(challenge)

        if verify_secret(otp_code, challenge.otp_hash):
            challenge.used = True
            user = db.session.get(User, challenge.user_id)
            if user is None:
                raise OtpChallengeNotFoundError(message="OTP challenge was not found.")
            db.session.flush()
            response = self._issue_session_tokens(user)
            db.session.commit()
            return response

        challenge.failed_attempts += 1
        masked = mask_email(normalized_email)
        attempts_left = max(0, MAX_OTP_ATTEMPTS - challenge.failed_attempts)
        log_otp_failed(masked, attempts_left)

        if challenge.failed_attempts >= MAX_OTP_ATTEMPTS:
            challenge.locked_until = utcnow() + timedelta(minutes=OTP_LOCK_MINUTES)
            db.session.commit()
            log_otp_lockout(masked, OTP_LOCK_MINUTES)
            raise OtpLockedError(
                message="Too many incorrect attempts. Try again later."
            )

        db.session.commit()
        raise OtpInvalidError(message="The verification code is incorrect.")

    def refresh_tokens(self, refresh_token: str) -> dict[str, Any]:
        from app.shared.auth import decode_token
        from app.shared.logging import log_token_refresh_failed

        try:
            payload = decode_token(refresh_token, expected_type=REFRESH_TOKEN_TYPE)
        except Exception as exc:
            log_token_refresh_failed(str(exc))
            raise UnauthorizedError(message="Invalid refresh token.") from exc

        session_id = payload.get("sid")
        user_id = payload.get("sub")
        if not session_id or not user_id:
            log_token_refresh_failed("missing_sid_or_sub")
            raise UnauthorizedError(message="Invalid refresh token.")

        session = db.session.get(UserSession, uuid.UUID(session_id))
        if session is None:
            raise UnauthorizedError(message="Session not found.")

        now = utcnow()
        expires_at = session.expires_at
        if expires_at.tzinfo is None:
            from datetime import timezone
            expires_at = expires_at.replace(tzinfo=timezone.utc)
            
        if session.revoked_at is not None or expires_at <= now:
            raise UnauthorizedError(message="Session is no longer valid.")

        if not verify_secret(refresh_token, session.refresh_token_hash):
            raise UnauthorizedError(message="Invalid refresh token.")

        user = db.session.get(User, int(user_id))
        if user is None or not user.is_active:
            raise UnauthorizedError(message="User is not active.")

        session.revoked_at = now
        response = self._issue_refresh_tokens(user)
        db.session.commit()
        return response

    def logout(
        self,
        *,
        refresh_token: str | None = None,
        access_token: str | None = None,
    ) -> None:
        session: UserSession | None = None
        now = utcnow()

        if refresh_token:
            from app.shared.auth import decode_token

            try:
                payload = decode_token(refresh_token, expected_type=REFRESH_TOKEN_TYPE)
            except UnauthorizedError:
                return None
            session_id = payload.get("sid")
            if session_id:
                session = db.session.get(UserSession, uuid.UUID(session_id))
                if session and verify_secret(refresh_token, session.refresh_token_hash):
                    session.revoked_at = now
                    db.session.commit()
            return None

        if access_token:
            payload = verify_access_token(access_token)
            session_id = payload.get("sid")
            if session_id:
                session = db.session.get(UserSession, uuid.UUID(session_id))
                if session and session.revoked_at is None:
                    session.revoked_at = now
                    db.session.commit()
        return None

    def verify_access(self, access_token: str) -> dict[str, Any]:
        payload = verify_access_token(access_token)
        user_id = payload.get("sub")
        if not user_id:
            raise UnauthorizedError(message="Invalid access token.")
        return {"valid": True, "userId": str(user_id)}

    def get_profile(self, user_id: int) -> dict[str, Any]:
        user = self._get_active_user(user_id)
        return user_to_dict(user)

    def update_profile(
        self,
        user_id: int,
        **kwargs: Any,
    ) -> dict[str, Any]:
        user = self._get_active_user(user_id)
        
        field_mapping = {
            "name": "name",
            "avatarUrl": "avatar_url",
            "avatar_url": "avatar_url",
            "phone": "phone",
            "gender": "gender",
            "dateOfBirth": "date_of_birth",
            "date_of_birth": "date_of_birth",
            "maritalStatus": "marital_status",
            "marital_status": "marital_status",
            "incomeRange": "income_range",
            "income_range": "income_range",
            "occupation": "occupation",
            "sourceOfFund": "source_of_fund",
            "source_of_fund": "source_of_fund",
            "identityType": "identity_type",
            "identity_type": "identity_type",
            "identityNumber": "identity_number",
            "identity_number": "identity_number",
            "address": "address",
            "primaryAddress": "primary_address",
            "primary_address": "primary_address",
            "secondaryAddress": "secondary_address",
            "secondary_address": "secondary_address",
            "phoneType": "phone_type",
            "phone_type": "phone_type",
            "investmentExperience": "investment_experience",
            "investment_experience": "investment_experience",
            "productType": "product_type",
            "product_type": "product_type",
            "tradingFrequency": "trading_frequency",
            "trading_frequency": "trading_frequency",
            "investmentObjective": "investment_objective",
            "investment_objective": "investment_objective",
            "tradingStyle": "trading_style",
            "trading_style": "trading_style",
            "riskTolerance": "risk_tolerance",
            "risk_tolerance": "risk_tolerance",
            "kycStatus": "kyc_status",
            "kyc_status": "kyc_status",
            "isNewUser": "is_new_user",
            "is_new_user": "is_new_user",
        }

        for key, val in kwargs.items():
            if key in field_mapping:
                col_name = field_mapping[key]
                if hasattr(user, col_name):
                    if col_name == "is_new_user":
                        setattr(user, col_name, bool(val))
                    else:
                        setattr(user, col_name, val)

        user.updated_at = utcnow()
        db.session.commit()
        return user_to_dict(user)

    def _get_or_create_user(self, email: str) -> User:
        user = db.session.scalar(select(User).where(User.email == email))
        if user is not None:
            return user
        user = User(email=email)
        user.is_new_user = True
        db.session.add(user)
        db.session.flush()
        self._seed_user_defaults(user.user_id)
        return user

    def _seed_user_defaults(self, user_id: int) -> None:
        try:
            from app.modules.watchlist.models import Watchlist, WatchlistItem

            wl = Watchlist(user_id=user_id, name="My Wishlist")
            db.session.add(wl)
            db.session.flush()

            item = WatchlistItem(watchlist_id=wl.watchlist_id, symbol="AAPL")
            db.session.add(item)
            db.session.flush()
        except Exception as exc:
            import logging
            logging.getLogger(__name__).warning("Failed to seed user defaults: %s", exc)

    def _get_challenge(self, email: str, challenge_id: uuid.UUID) -> OtpToken:
        challenge = db.session.scalar(
            select(OtpToken).where(
                OtpToken.challenge_id == challenge_id,
                OtpToken.email == email,
            )
        )
        if challenge is None:
            raise OtpChallengeNotFoundError(message="OTP challenge was not found.")
        return challenge

    def _ensure_challenge_active(self, challenge: OtpToken) -> None:
        now = utcnow()
        locked_until = challenge.locked_until
        if locked_until and locked_until.tzinfo is None:
            locked_until = locked_until.replace(tzinfo=timezone.utc)

        if locked_until and locked_until > now:
            raise OtpLockedError(
                message="Too many incorrect attempts. Try again later."
            )

        expires_at = challenge.expires_at
        if expires_at and expires_at.tzinfo is None:
            expires_at = expires_at.replace(tzinfo=timezone.utc)

        if challenge.used or (expires_at and expires_at <= now):
            raise OtpExpiredError(message="This code expired. Request a new one.")

    def _issue_session_tokens(self, user: User) -> dict[str, Any]:
        session_id = uuid.uuid4()
        now = utcnow()
        refresh_token_plain = issue_token(
            user_id=str(user.user_id),
            email=user.email,
            session_id=str(session_id),
            token_type=REFRESH_TOKEN_TYPE,
            ttl_seconds=current_app.config["REFRESH_TOKEN_TTL_SECONDS"],
        )
        access_token = issue_token(
            user_id=str(user.user_id),
            email=user.email,
            session_id=str(session_id),
            token_type=ACCESS_TOKEN_TYPE,
            ttl_seconds=current_app.config["ACCESS_TOKEN_TTL_SECONDS"],
        )
        session = UserSession(
            session_id=session_id,
            user_id=user.user_id,
            refresh_token_hash=hash_secret(refresh_token_plain),
            expires_at=now
            + timedelta(seconds=current_app.config["REFRESH_TOKEN_TTL_SECONDS"]),
        )
        db.session.add(session)
        db.session.flush()
        return tokens_response(
            user=user,
            access_token=access_token,
            refresh_token=refresh_token_plain,
        )

    def _issue_refresh_tokens(self, user: User) -> dict[str, Any]:
        session_id = uuid.uuid4()
        now = utcnow()
        refresh_token_plain = issue_token(
            user_id=str(user.user_id),
            email=user.email,
            session_id=str(session_id),
            token_type=REFRESH_TOKEN_TYPE,
            ttl_seconds=current_app.config["REFRESH_TOKEN_TTL_SECONDS"],
        )
        access_token = issue_token(
            user_id=str(user.user_id),
            email=user.email,
            session_id=str(session_id),
            token_type=ACCESS_TOKEN_TYPE,
            ttl_seconds=current_app.config["ACCESS_TOKEN_TTL_SECONDS"],
        )
        session = UserSession(
            session_id=session_id,
            user_id=user.user_id,
            refresh_token_hash=hash_secret(refresh_token_plain),
            expires_at=now
            + timedelta(seconds=current_app.config["REFRESH_TOKEN_TTL_SECONDS"]),
        )
        db.session.add(session)
        db.session.flush()
        return refresh_tokens_response(
            access_token=access_token,
            refresh_token=refresh_token_plain,
        )

    def _get_active_user(self, user_id: int) -> User:
        user = db.session.get(User, user_id)
        if user is None or not user.is_active:
            raise UnauthorizedError(message="User is not authorized.")
        return user
