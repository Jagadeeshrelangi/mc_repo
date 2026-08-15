"""Refresh-token model (``refresh_tokens`` table).

Stores only the SHA-256 digest of each refresh token (D1/D2) — never the
plaintext token — plus lifecycle/rotation metadata (D6).
"""

from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, ForeignKey, Index, String, Uuid, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class RefreshToken(Base):
    """A single refresh-token session for a user.

    ``token_digest`` is the SHA-256 hexadecimal digest (64 chars) of the
    plaintext refresh token (D2). The digest is unique so the lookup/verify
    path (D6 rotation) is indexed and unambiguous.
    """

    __tablename__ = "refresh_tokens"

    __table_args__ = (
        Index("ix_refresh_tokens_user_id", "user_id"),
        Index("uq_refresh_tokens_token_digest", "token_digest", unique=True),
        Index("uq_refresh_tokens_jti", "jti", unique=True),
    )

    id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )

    # Owning user (D1). FK to ``users.id``.
    user_id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False),
        ForeignKey("users.id", name="fk_refresh_tokens_user_id_users", ondelete="CASCADE"),
        nullable=False,
    )

    # SHA-256 hex digest of the refresh token (D2). Never the plaintext token.
    token_digest: Mapped[str] = mapped_column(String(64), nullable=False)

    # JWT ``jti`` claim — stable identifier of the token/session.
    jti: Mapped[str] = mapped_column(String(64), nullable=False)

    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )
    revoked_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # Rotation support (D6): id of the refresh token that replaced this one.
    replaced_by_id: Mapped[Optional[str]] = mapped_column(
        Uuid(as_uuid=False),
        ForeignKey("refresh_tokens.id", name="fk_refresh_tokens_replaced_by_id", ondelete="SET NULL"),
        nullable=True,
    )

    # --- Relationships ---
    user: Mapped["User"] = relationship(back_populates="refresh_tokens")

    # self-referential rotation lineage: the token that replaced this one.
    replaced_by: Mapped[Optional["RefreshToken"]] = relationship(
        remote_side="RefreshToken.id",
        foreign_keys=[replaced_by_id],
        post_update=True,
    )


from app.models.user import User  # noqa: E402  (avoid circular import)