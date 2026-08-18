from __future__ import annotations

from marshmallow import Schema, ValidationError, fields, validates_schema


class SendOtpSchema(Schema):
    email = fields.Email(required=True)


class VerifyOtpSchema(Schema):
    email = fields.Email(required=True)
    otpChallengeId = fields.UUID(required=True, data_key="otpChallengeId")
    otpCode = fields.String(required=True, data_key="otpCode")

    @validates_schema
    def validate_otp_code(self, data: dict, **_kwargs) -> None:
        otp_code = data.get("otpCode", "")
        if not otp_code.isdigit() or len(otp_code) != 6:
            raise ValidationError(
                {"otpCode": ["otpCode must be a 6-digit numeric code."]}
            )


class RefreshTokenSchema(Schema):
    refreshToken = fields.String(required=True, data_key="refreshToken")


class LogoutSchema(Schema):
    refreshToken = fields.String(
        required=False, allow_none=True, data_key="refreshToken"
    )


class UpdateProfileSchema(Schema):
    name = fields.String(required=False, allow_none=True)
    avatarUrl = fields.String(required=False, allow_none=True, data_key="avatarUrl")
