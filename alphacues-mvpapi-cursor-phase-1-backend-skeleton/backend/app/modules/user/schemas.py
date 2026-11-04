from __future__ import annotations

from marshmallow import EXCLUDE, Schema, ValidationError, fields, validates_schema


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
    class Meta:
        unknown = EXCLUDE

    name = fields.String(required=False, allow_none=True)
    avatarUrl = fields.String(required=False, allow_none=True, data_key="avatarUrl")
    avatar_url = fields.String(required=False, allow_none=True, data_key="avatar_url")
    phone = fields.String(required=False, allow_none=True)
    gender = fields.String(required=False, allow_none=True)
    dateOfBirth = fields.String(required=False, allow_none=True, data_key="dateOfBirth")
    date_of_birth = fields.String(required=False, allow_none=True, data_key="date_of_birth")
    maritalStatus = fields.String(required=False, allow_none=True, data_key="maritalStatus")
    marital_status = fields.String(required=False, allow_none=True, data_key="marital_status")
    incomeRange = fields.String(required=False, allow_none=True, data_key="incomeRange")
    income_range = fields.String(required=False, allow_none=True, data_key="income_range")
    occupation = fields.String(required=False, allow_none=True)
    sourceOfFund = fields.String(required=False, allow_none=True, data_key="sourceOfFund")
    source_of_fund = fields.String(required=False, allow_none=True, data_key="source_of_fund")
    identityType = fields.String(required=False, allow_none=True, data_key="identityType")
    identity_type = fields.String(required=False, allow_none=True, data_key="identity_type")
    identityNumber = fields.String(required=False, allow_none=True, data_key="identityNumber")
    identity_number = fields.String(required=False, allow_none=True, data_key="identity_number")
    address = fields.String(required=False, allow_none=True)
    primaryAddress = fields.String(required=False, allow_none=True, data_key="primaryAddress")
    primary_address = fields.String(required=False, allow_none=True, data_key="primary_address")
    secondaryAddress = fields.String(required=False, allow_none=True, data_key="secondaryAddress")
    secondary_address = fields.String(required=False, allow_none=True, data_key="secondary_address")
    phoneType = fields.String(required=False, allow_none=True, data_key="phoneType")
    phone_type = fields.String(required=False, allow_none=True, data_key="phone_type")
    investmentExperience = fields.String(required=False, allow_none=True, data_key="investmentExperience")
    investment_experience = fields.String(required=False, allow_none=True, data_key="investment_experience")
    productType = fields.String(required=False, allow_none=True, data_key="productType")
    product_type = fields.String(required=False, allow_none=True, data_key="product_type")
    tradingFrequency = fields.String(required=False, allow_none=True, data_key="tradingFrequency")
    trading_frequency = fields.String(required=False, allow_none=True, data_key="trading_frequency")
    investmentObjective = fields.String(required=False, allow_none=True, data_key="investmentObjective")
    investment_objective = fields.String(required=False, allow_none=True, data_key="investment_objective")
    tradingStyle = fields.String(required=False, allow_none=True, data_key="tradingStyle")
    trading_style = fields.String(required=False, allow_none=True, data_key="trading_style")
    riskTolerance = fields.String(required=False, allow_none=True, data_key="riskTolerance")
    risk_tolerance = fields.String(required=False, allow_none=True, data_key="risk_tolerance")
    kycStatus = fields.String(required=False, allow_none=True, data_key="kycStatus")
    kyc_status = fields.String(required=False, allow_none=True, data_key="kyc_status")
    isNewUser = fields.Boolean(required=False, allow_none=True, data_key="isNewUser")
    is_new_user = fields.Boolean(required=False, allow_none=True, data_key="is_new_user")
