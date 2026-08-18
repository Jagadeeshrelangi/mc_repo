"""Booking lifecycle states (Task 6, Mechanics module).

Single canonical Python representation of the seven frozen booking states
(D6-4). Values match the Flutter ``BookingStatus`` enum exactly
(``frontend/lib/features/mechanic/models/mechanic_models.dart``) so a future
MechanicService can persist/return them verbatim:

    requested → accepted → mechanicAssigned → enRoute → arrived → completed
    (+ cancelled)

Stored as TEXT in ``mechanic_bookings.status`` / ``booking_events.status``
following the project convention; the ORM CHECK constraint
(``ck_mechanic_bookings_status``) mirrors ``ck_users_role`` / ``ck_chat_messages_role``.
"""

from enum import Enum


class BookingStatus(str, Enum):
    """The seven frozen booking lifecycle states (D6-4)."""

    REQUESTED = "requested"
    ACCEPTED = "accepted"
    MECHANIC_ASSIGNED = "mechanicAssigned"
    EN_ROUTE = "enRoute"
    ARRIVED = "arrived"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


# Tuple of the seven canonical values (used by services/tests).
BookingStatus.VALUES = tuple(member.value for member in BookingStatus)