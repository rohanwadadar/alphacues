from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class FakeEmailSender:
    """Captures OTP codes in memory for tests."""

    sent_messages: list[tuple[str, str]] = field(default_factory=list)

    def send_otp(self, to_email: str, otp_code: str) -> None:
        self.sent_messages.append((to_email, otp_code))

    def last_otp_for(self, email: str) -> str | None:
        for to_email, otp_code in reversed(self.sent_messages):
            if to_email == email:
                return otp_code
        return None

    def clear(self) -> None:
        self.sent_messages.clear()
