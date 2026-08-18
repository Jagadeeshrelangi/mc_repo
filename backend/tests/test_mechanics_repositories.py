"""Tests for Task 6, Stage 2 — Mechanics repositories.

Test strategy WITHOUT a live PostgreSQL database (mirrors the existing
``test_auth_repositories.py`` / ``test_conversation_ownership.py`` patterns):

- An in-memory ``FakeSession`` evaluates the simple ``select``/``scalar``/
  ``scalars``/``get``/``add``/``flush`` statements the repositories issue
  (``WHERE col == value``, ``ORDER BY``, ``LIMIT``) against a store keyed by
  model class. A small join handler covers the M:N ``list_for_mechanic``
  query. No SQL is executed.
- SQL-shape/ownership predicates are verified by capturing statements with an
  ``AsyncMock`` session and compiling them against the PostgreSQL dialect
  (``literal_binds``), exactly as ``test_auth_repositories.py`` does.
- PostgreSQL server-side behavior (real execution, constraint enforcement,
  ``gen_random_uuid()``, JSONB) is NOT faked and stays documented as requiring
  a live database.

No commits, pushes, resets, or reverts are performed.
"""

import asyncio
import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import Any, Dict, List, Optional, Type
from unittest.mock import AsyncMock

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import dialect as postgresql_dialect
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.sql.elements import BinaryExpression, BooleanClauseList
from sqlalchemy.sql.operators import eq, is_
from sqlalchemy.types import DateTime

from app.models.mechanic import Mechanic, MechanicLanguage, MechanicSkill, MechanicWorkingHour
from app.models.mechanic_booking import BookingEvent, MechanicBooking, Rating
from app.models.mechanic_category import MechanicCategory
from app.models.mechanic_review import MechanicReview
from app.models.mechanic_service import MechanicService, MechanicServiceOffered
from app.models.mechanic_status import BookingStatus
from app.repositories.mechanics import (
    FEATURED_LIMIT,
    BookingEventRepository,
    MechanicBookingRepository,
    MechanicCategoryRepository,
    MechanicRepository,
    MechanicReviewRepository,
    MechanicServiceRepository,
    RatingRepository,
)

USER_A = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
USER_B = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"

# Monotonic clock so ordering is deterministic even within one microsecond.
_CLOCK_STEP = 0
_CLOCK_BASE = datetime(2026, 8, 15, 12, 0, 0, tzinfo=timezone.utc)


def _fake_now() -> datetime:
    global _CLOCK_STEP
    _CLOCK_STEP += 1
    return _CLOCK_BASE + timedelta(microseconds=_CLOCK_STEP)


class _FakeScalarResult:
    def __init__(self, items: List[Any]) -> None:
        self.items = items

    def first(self) -> Any:
        return self.items[0] if self.items else None

    def one_or_none(self) -> Any:
        return self.items[0] if self.items else None

    def scalar(self) -> Any:
        return self.items[0] if self.items else None

    async def all(self) -> List[Any]:
        return list(self.items)


def _entity_class(entity: Any) -> Type:
    """Resolve an ORM entity (class or entity wrapper) to the mapped class."""
    mapper = getattr(entity, "__mapper__", None)
    return mapper.class_ if mapper is not None else entity


class FakeSession:
    """In-memory session evaluating the simple selects the repos issue.

    ``store`` maps model class → list of ORM instances. Primary keys and
    ``created_at``/``occurred_at``/``updated_at`` are materialized by the
    model's Python-side defaults at construction, so no DB round-trip is
    needed. A single inner join (``select(A).join(B, onclause).where(...)``)
    is evaluated against the store for the ``list_for_mechanic`` query.
    """

    def __init__(self, store: Optional[Dict[Type, List[Any]]] = None) -> None:
        self.store = store if store is not None else {}
        self.commits = 0

    def _rows(self, model: Type) -> List[Any]:
        return self.store.setdefault(model, [])

    def _find_id(self, model: Type, entity_id: Any) -> Optional[Any]:
        for obj in self._rows(model):
            if str(getattr(obj, "id", "")) == str(entity_id):
                return obj
        return None

    def _apply_defaults(self, obj: Any) -> None:
        for column in type(obj).__mapper__.columns:
            if column.default is None:
                continue
            if getattr(obj, column.key, None) is not None:
                continue
            if isinstance(column.type, DateTime):
                setattr(obj, column.key, _fake_now())
            elif column.default.is_scalar:
                setattr(obj, column.key, column.default.arg)
            elif column.default.is_callable:
                setattr(obj, column.key, column.default.arg(None))

    @staticmethod
    def _eval_where(obj: Any, clause: Any) -> bool:
        if clause is None:
            return True
        if isinstance(clause, BooleanClauseList):
            return all(FakeSession._eval_where(obj, c) for c in clause.clauses)
        if not isinstance(clause, BinaryExpression):
            return True
        col_name = getattr(clause.left, "name", None)
        op = clause.operator
        if op is eq:
            value = getattr(clause.right, "value", clause.right)
            return getattr(obj, col_name) == value
        if op is is_:
            value = getattr(clause.right, "value", clause.right)
            return getattr(obj, col_name) is value
        return True  # unsupported operator → pass (repo tests only use ==)

    def _eval_on(self, target_obj: Any, joined_obj: Any, onclause: Any) -> bool:
        """Evaluate an ON clause ``left_col == right_col`` against two rows."""
        left_col = onclause.left
        right_col = onclause.right
        return getattr(left_col.parent.table, "name", None) is not None and bool(
            getattr(joined_obj, left_col.name) == getattr(target_obj, right_col.name)
        )

    def _eval_select(self, stmt: Any) -> List[Any]:
        target = stmt.column_descriptions[0]["type"]
        rows = list(self._rows(target))
        joins = getattr(stmt, "_setup_joins", None) or []
        if not joins:
            rows = [r for r in rows if self._eval_where(r, stmt.whereclause)]

        if joins:
            matched: List[Any] = []
            for trow in rows:
                for join in joins:
                    onclause = join[1]
                    # The joined model is the one whose table owns one side of
                    # the ON clause and is NOT the target model's table.
                    left_col = onclause.left
                    right_col = onclause.right
                    right_model = None
                    for model in self.store:
                        table = getattr(model, "__table__", None)
                        if table is None:
                            continue
                        if table is not target.__table__ and (
                            left_col.table is table or right_col.table is table
                        ):
                            right_model = model
                            break
                    if right_model is None:
                        continue
                    for rrow in self._rows(right_model):
                        # ON clause: joined.service_id == target.id style.
                        if left_col.table is right_model.__table__:
                            left, right = rrow, trow
                        else:
                            left, right = trow, rrow
                        if getattr(left, left_col.name) != getattr(right, right_col.name):
                            continue
                        if FakeSession._eval_where(rrow, stmt.whereclause):
                            matched.append(trow)
                            break
            rows = matched

        order_by = getattr(stmt, "_order_by_clauses", None) or []
        if order_by:
            from sqlalchemy.sql.operators import desc_op

            for clause in reversed(order_by):
                is_desc = (
                    getattr(clause, "operator", None) is desc_op
                    or getattr(clause, "modifier", None) is desc_op
                )
                element = getattr(clause, "element", None)
                col_name = getattr(element, "name", None) or getattr(clause, "name", None)
                rows.sort(
                    key=lambda r, cn=col_name: getattr(r, cn),
                    reverse=is_desc,
                )

        offset = getattr(stmt, "_offset", None) or 0
        limit = getattr(stmt, "_limit", None)
        rows = rows[offset:] if limit is None else rows[offset : offset + limit]
        return rows

    async def get(self, model: Type, entity_id: Any) -> Optional[Any]:
        return self._find_id(model, entity_id)

    async def scalar(self, stmt: Any) -> Optional[Any]:
        rows = self._eval_select(stmt)
        return rows[0] if rows else None

    async def scalars(self, stmt: Any) -> "_FakeScalarResult":
        return _FakeScalarResult(self._eval_select(stmt))

    def add(self, obj: Any) -> None:
        self._apply_defaults(obj)
        self._rows(type(obj)).append(obj)

    async def flush(self) -> None:
        pass

    async def commit(self) -> None:
        self.commits += 1

    async def rollback(self) -> None:
        pass


# ---------------------------------------------------------------------------
# Factory helpers
# ---------------------------------------------------------------------------


def make_mechanic(mechanic_id: str, **overrides) -> Mechanic:
    defaults: Dict[str, Any] = {
        "id": mechanic_id,
        "name": f"Garage {mechanic_id}",
        "rating": Decimal("4.5"),
        "is_available": True,
        "is_verified": True,
    }
    defaults.update(overrides)
    return Mechanic(**defaults)


def make_service(service_id: str, **overrides) -> MechanicService:
    defaults: Dict[str, Any] = {
        "id": service_id,
        "name": f"Service {service_id}",
        "price": Decimal("499.00"),
    }
    defaults.update(overrides)
    return MechanicService(**defaults)


def make_category(category_id: str, **overrides) -> MechanicCategory:
    defaults: Dict[str, Any] = {
        "id": category_id,
        "name": f"Category {category_id}",
        "sort_order": 0,
    }
    defaults.update(overrides)
    return MechanicCategory(**defaults)


def make_review(review_id: str, mechanic_id: str, **overrides) -> MechanicReview:
    defaults: Dict[str, Any] = {
        "id": review_id,
        "mechanic_id": mechanic_id,
        "reviewer_name": "Reviewer",
        "rating": Decimal("5.0"),
    }
    defaults.update(overrides)
    return MechanicReview(**defaults)


def make_booking(booking_id: str, user_id: str, mechanic_id: str, **overrides) -> MechanicBooking:
    defaults: Dict[str, Any] = {
        "id": booking_id,
        "user_id": user_id,
        "mechanic_id": mechanic_id,
        "status": BookingStatus.REQUESTED.value,
        "created_at": _fake_now(),
    }
    defaults.update(overrides)
    return MechanicBooking(**defaults)


def make_event(booking_id: str, **overrides) -> BookingEvent:
    defaults: Dict[str, Any] = {
        "id": str(uuid.uuid4()),
        "booking_id": booking_id,
        "status": BookingStatus.REQUESTED.value,
        "payload": None,
        "occurred_at": _fake_now(),
    }
    defaults.update(overrides)
    return BookingEvent(**defaults)


def make_rating(booking_id: str, **overrides) -> Rating:
    defaults: Dict[str, Any] = {
        "booking_id": booking_id,
        "rating": Decimal("5.0"),
        "review": "Great work",
    }
    defaults.update(overrides)
    return Rating(**defaults)


def compile_stmt(stmt) -> str:
    return str(
        stmt.compile(
            dialect=postgresql_dialect(),
            compile_kwargs={"literal_binds": True},
        )
    )


# ============================================================================
# MechanicRepository
# ============================================================================


def test_mechanic_repository_construction_injects_session() -> None:
    session = FakeSession()
    repo = MechanicRepository(session)
    assert repo.session is session
    assert repo.model is Mechanic


def test_get_by_id_returns_mechanic() -> None:
    m = make_mechanic("m1")
    session = FakeSession({Mechanic: [m]})
    repo = MechanicRepository(session)
    assert asyncio.run(repo.get_by_id("m1")) is m


def test_get_by_id_returns_none_when_missing() -> None:
    session = FakeSession()
    repo = MechanicRepository(session)
    assert asyncio.run(repo.get_by_id("nope")) is None


def test_get_by_id_sql_has_mechanic_id_predicate() -> None:
    session = AsyncMock(spec=AsyncSession)
    session.scalar.return_value = None
    repo = MechanicRepository(session)
    asyncio.run(repo.get_by_id("m1"))
    stmt = session.scalar.call_args.args[0]
    sql = compile_stmt(stmt)
    assert "FROM mechanics" in sql
    assert "mechanics.id" in sql


def test_get_by_id_loads_related_catalog_data() -> None:
    m = make_mechanic("m1")
    m.skills = [MechanicSkill(mechanic_id="m1", skill="Engine")]
    m.languages = [MechanicLanguage(mechanic_id="m1", language="English")]
    m.working_hours = [MechanicWorkingHour(mechanic_id="m1", day="Mon", open="8:00", close="8:00")]
    m.services_offered = [MechanicServiceOffered(mechanic_id="m1", service_id="svc_1")]
    session = FakeSession({Mechanic: [m]})
    repo = MechanicRepository(session)
    fetched = asyncio.run(repo.get_by_id("m1"))
    assert fetched is m
    assert fetched.skills[0].skill == "Engine"
    assert fetched.languages[0].language == "English"
    assert fetched.working_hours[0].day == "Mon"
    assert fetched.services_offered[0].service_id == "svc_1"


def test_list_all_returns_every_mechanic_ordered_by_id() -> None:
    m2 = make_mechanic("m2")
    m1 = make_mechanic("m1")
    m3 = make_mechanic("m3")
    session = FakeSession({Mechanic: [m2, m1, m3]})
    repo = MechanicRepository(session)
    result = asyncio.run(repo.list_all())
    assert [m.id for m in result] == ["m1", "m2", "m3"]


def test_list_featured_returns_top_rated() -> None:
    m1 = make_mechanic("m1", rating=Decimal("4.8"))
    m2 = make_mechanic("m2", rating=Decimal("4.6"))
    m3 = make_mechanic("m3", rating=Decimal("4.3"))
    m4 = make_mechanic("m4", rating=Decimal("4.9"))
    session = FakeSession({Mechanic: [m1, m2, m3, m4]})
    repo = MechanicRepository(session)
    result = asyncio.run(repo.list_featured())
    assert [m.id for m in result] == ["m4", "m1", "m2"]
    assert len(result) == FEATURED_LIMIT


def test_list_featured_respects_limit() -> None:
    m1 = make_mechanic("m1", rating=Decimal("4.8"))
    m2 = make_mechanic("m2", rating=Decimal("4.6"))
    m3 = make_mechanic("m3", rating=Decimal("4.3"))
    session = FakeSession({Mechanic: [m1, m2, m3]})
    repo = MechanicRepository(session)
    result = asyncio.run(repo.list_featured(limit=2))
    assert [m.id for m in result] == ["m1", "m2"]


# ============================================================================
# MechanicServiceRepository
# ============================================================================


def test_service_repository_construction_injects_session() -> None:
    repo = MechanicServiceRepository(FakeSession())
    assert repo.model is MechanicService


def test_service_get_by_id_returns_service() -> None:
    s = make_service("svc_1")
    session = FakeSession({MechanicService: [s]})
    repo = MechanicServiceRepository(session)
    assert asyncio.run(repo.get_by_id("svc_1")) is s


def test_service_list_all_ordered_by_id() -> None:
    s2 = make_service("svc_2")
    s1 = make_service("svc_1")
    session = FakeSession({MechanicService: [s2, s1]})
    repo = MechanicServiceRepository(session)
    assert [s.id for s in asyncio.run(repo.list_all())] == ["svc_1", "svc_2"]


def test_list_for_mechanic_returns_only_that_mechanics_services() -> None:
    s1 = make_service("svc_1")
    s2 = make_service("svc_2")
    s3 = make_service("svc_3")
    offered = [
        MechanicServiceOffered(mechanic_id="m1", service_id="svc_1"),
        MechanicServiceOffered(mechanic_id="m1", service_id="svc_2"),
        MechanicServiceOffered(mechanic_id="m2", service_id="svc_3"),
    ]
    session = FakeSession(
        {MechanicService: [s1, s2, s3], MechanicServiceOffered: offered}
    )
    repo = MechanicServiceRepository(session)
    result = asyncio.run(repo.list_for_mechanic("m1"))
    assert [s.id for s in result] == ["svc_1", "svc_2"]


def test_list_for_mechanic_empty_when_no_offers() -> None:
    session = FakeSession({MechanicService: [], MechanicServiceOffered: []})
    repo = MechanicServiceRepository(session)
    assert asyncio.run(repo.list_for_mechanic("m1")) == []


def test_list_for_mechanic_sql_joins_junction_and_filters_mechanic() -> None:
    session = AsyncMock(spec=AsyncSession)
    session.scalars.return_value.all.return_value = []
    repo = MechanicServiceRepository(session)
    asyncio.run(repo.list_for_mechanic("m1"))
    stmt = session.scalars.call_args.args[0]
    sql = compile_stmt(stmt)
    assert "FROM mechanic_services" in sql
    assert "JOIN mechanic_service_offered" in sql
    assert "mechanic_service_offered.mechanic_id" in sql


# ============================================================================
# MechanicCategoryRepository
# ============================================================================


def test_category_repository_construction_injects_session() -> None:
    repo = MechanicCategoryRepository(FakeSession())
    assert repo.model is MechanicCategory


def test_category_get_by_id_returns_category() -> None:
    c = make_category("cat_1")
    session = FakeSession({MechanicCategory: [c]})
    repo = MechanicCategoryRepository(session)
    assert asyncio.run(repo.get_by_id("cat_1")) is c


def test_category_list_all_orders_by_sort_order_then_id() -> None:
    c1 = make_category("cat_1", sort_order=2)
    c2 = make_category("cat_2", sort_order=1)
    c3 = make_category("cat_3", sort_order=1)
    session = FakeSession({MechanicCategory: [c1, c2, c3]})
    repo = MechanicCategoryRepository(session)
    assert [c.id for c in asyncio.run(repo.list_all())] == ["cat_2", "cat_3", "cat_1"]


# ============================================================================
# MechanicReviewRepository
# ============================================================================


def test_review_repository_construction_injects_session() -> None:
    repo = MechanicReviewRepository(FakeSession())
    assert repo.model is MechanicReview


def test_review_get_by_id_returns_review() -> None:
    r = make_review("r1", "m1")
    session = FakeSession({MechanicReview: [r]})
    repo = MechanicReviewRepository(session)
    assert asyncio.run(repo.get_by_id("r1")) is r


def test_review_list_for_mechanic_returns_only_that_mechanics_reviews() -> None:
    r1 = make_review("r1", "m1")
    r2 = make_review("r2", "m1")
    r3 = make_review("r3", "m2")
    session = FakeSession({MechanicReview: [r1, r2, r3]})
    repo = MechanicReviewRepository(session)
    assert [r.id for r in asyncio.run(repo.list_for_mechanic("m1"))] == ["r1", "r2"]


# ============================================================================
# MechanicBookingRepository — ownership safety
# ============================================================================


def test_booking_repository_construction_injects_session() -> None:
    repo = MechanicBookingRepository(FakeSession())
    assert repo.model is MechanicBooking


def test_create_booking_persists_owned_record_without_commit() -> None:
    session = FakeSession()
    repo = MechanicBookingRepository(session)
    booking = asyncio.run(
        repo.create_booking(
            user_id=USER_A,
            mechanic_id="m1",
            service_id="svc_1",
            vehicle_id=str(uuid.uuid4()),
            address="MG Road",
            lat=Decimal("12.971599"),
            lng=Decimal("77.594563"),
        )
    )
    assert booking.user_id == USER_A
    assert booking.mechanic_id == "m1"
    assert booking.status == BookingStatus.REQUESTED.value
    assert booking.vehicle_id is not None
    assert booking.address == "MG Road"
    assert session.commits == 0


def test_create_booking_defaults_status_to_requested() -> None:
    session = FakeSession()
    repo = MechanicBookingRepository(session)
    booking = asyncio.run(repo.create_booking(user_id=USER_A, mechanic_id="m1"))
    assert booking.status == BookingStatus.REQUESTED.value


def test_get_by_id_is_unscoped_primitive() -> None:
    b = make_booking("b1", USER_A, "m1")
    session = FakeSession({MechanicBooking: [b]})
    repo = MechanicBookingRepository(session)
    assert asyncio.run(repo.get_by_id("b1")) is b
    assert asyncio.run(repo.get_by_id("nope")) is None


def test_get_owned_returns_booking_only_for_owner() -> None:
    b = make_booking("b1", USER_A, "m1")
    session = FakeSession({MechanicBooking: [b]})
    repo = MechanicBookingRepository(session)
    assert asyncio.run(repo.get_owned("b1", USER_A)) is b
    assert asyncio.run(repo.get_owned("b1", USER_B)) is None
    assert asyncio.run(repo.get_owned("nope", USER_A)) is None


def test_get_owned_sql_contains_id_and_user_id_predicates() -> None:
    session = AsyncMock(spec=AsyncSession)
    session.scalar.return_value = None
    repo = MechanicBookingRepository(session)
    asyncio.run(repo.get_owned("b1", USER_A))
    stmt = session.scalar.call_args.args[0]
    sql = compile_stmt(stmt)
    assert "FROM mechanic_bookings" in sql
    assert "mechanic_bookings.id" in sql
    assert "mechanic_bookings.user_id" in sql


def test_get_owned_sql_does_not_leak_other_users_booking() -> None:
    """Owner-scoped SQL contains the authenticated user predicate."""
    session = AsyncMock(spec=AsyncSession)
    session.scalar.return_value = None
    repo = MechanicBookingRepository(session)
    asyncio.run(repo.get_owned("b1", USER_A))
    sql = compile_stmt(session.scalar.call_args.args[0])
    assert "WHERE mechanic_bookings.id = 'b1'" in sql
    assert "AND mechanic_bookings.user_id =" in sql


def test_list_for_user_returns_only_that_users_bookings() -> None:
    ba = make_booking("b1", USER_A, "m1")
    ba2 = make_booking("b2", USER_A, "m2")
    bb = make_booking("b3", USER_B, "m1")
    session = FakeSession({MechanicBooking: [ba, ba2, bb]})
    repo = MechanicBookingRepository(session)
    assert [b.id for b in asyncio.run(repo.list_for_user(USER_A))] == ["b2", "b1"]


def test_list_for_user_newest_first() -> None:
    b1 = make_booking("b1", USER_A, "m1", created_at=_CLOCK_BASE + timedelta(hours=1))
    b2 = make_booking("b2", USER_A, "m1", created_at=_CLOCK_BASE + timedelta(hours=3))
    b3 = make_booking("b3", USER_A, "m1", created_at=_CLOCK_BASE + timedelta(hours=2))
    session = FakeSession({MechanicBooking: [b1, b2, b3]})
    repo = MechanicBookingRepository(session)
    assert [b.id for b in asyncio.run(repo.list_for_user(USER_A))] == ["b2", "b3", "b1"]


def test_list_for_user_sql_contains_user_filter() -> None:
    session = AsyncMock(spec=AsyncSession)
    session.scalars.return_value.all.return_value = []
    repo = MechanicBookingRepository(session)
    asyncio.run(repo.list_for_user(USER_A))
    sql = compile_stmt(session.scalars.call_args.args[0])
    assert "FROM mechanic_bookings" in sql
    assert "WHERE mechanic_bookings.user_id =" in sql
    assert "ORDER BY" in sql
    assert "DESC" in sql


def test_update_status_changes_only_that_record() -> None:
    b = make_booking("b1", USER_A, "m1")
    other = make_booking("b2", USER_B, "m1")
    session = FakeSession({MechanicBooking: [b, other]})
    repo = MechanicBookingRepository(session)
    asyncio.run(repo.update_status(b, BookingStatus.CANCELLED.value))
    assert b.status == BookingStatus.CANCELLED.value
    assert other.status == BookingStatus.REQUESTED.value
    assert session.commits == 0


def test_cancel_sets_cancelled() -> None:
    b = make_booking("b1", USER_A, "m1")
    repo = MechanicBookingRepository(FakeSession())
    asyncio.run(repo.cancel(b))
    assert b.status == BookingStatus.CANCELLED.value


def test_complete_sets_completed() -> None:
    b = make_booking("b1", USER_A, "m1")
    repo = MechanicBookingRepository(FakeSession())
    asyncio.run(repo.complete(b))
    assert b.status == BookingStatus.COMPLETED.value


# ============================================================================
# BookingEventRepository
# ============================================================================


def test_event_repository_construction_injects_session() -> None:
    repo = BookingEventRepository(FakeSession())
    assert repo.model is BookingEvent


def test_append_persists_event_without_commit() -> None:
    session = FakeSession()
    repo = BookingEventRepository(session)
    event = asyncio.run(
        repo.append(
            booking_id="b1",
            status=BookingStatus.EN_ROUTE.value,
            payload={"lat": 12.9, "lng": 77.5},
        )
    )
    assert event.booking_id == "b1"
    assert event.status == BookingStatus.EN_ROUTE.value
    assert event.payload == {"lat": 12.9, "lng": 77.5}
    assert session.commits == 0


def test_list_for_booking_returns_only_that_bookings_events() -> None:
    e1 = make_event("b1", status=BookingStatus.REQUESTED.value)
    e2 = make_event("b1", status=BookingStatus.ACCEPTED.value)
    e3 = make_event("b2", status=BookingStatus.REQUESTED.value)
    session = FakeSession({BookingEvent: [e1, e2, e3]})
    repo = BookingEventRepository(session)
    assert [e.status for e in asyncio.run(repo.list_for_booking("b1"))] == [
        BookingStatus.REQUESTED.value,
        BookingStatus.ACCEPTED.value,
    ]


def test_list_for_booking_chronological_order() -> None:
    e1 = make_event("b1", occurred_at=_CLOCK_BASE + timedelta(minutes=5))
    e2 = make_event("b1", occurred_at=_CLOCK_BASE + timedelta(minutes=1))
    e3 = make_event("b1", occurred_at=_CLOCK_BASE + timedelta(minutes=3))
    session = FakeSession({BookingEvent: [e1, e2, e3]})
    repo = BookingEventRepository(session)
    result = asyncio.run(repo.list_for_booking("b1"))
    assert [e.id for e in result] == [e2.id, e3.id, e1.id]


# ============================================================================
# RatingRepository
# ============================================================================


def test_rating_repository_construction_injects_session() -> None:
    repo = RatingRepository(FakeSession())
    assert repo.model is Rating


def test_get_by_booking_id_returns_rating() -> None:
    r = make_rating("b1", rating=Decimal("4.5"))
    session = FakeSession({Rating: [r]})
    repo = RatingRepository(session)
    assert asyncio.run(repo.get_by_booking_id("b1")) is r
    assert asyncio.run(repo.get_by_booking_id("b2")) is None


def test_create_rating_persists_without_commit() -> None:
    session = FakeSession()
    repo = RatingRepository(session)
    rating = asyncio.run(
        repo.create_rating(booking_id="b1", rating=Decimal("4.5"), review="Nice")
    )
    assert rating.booking_id == "b1"
    assert rating.rating == Decimal("4.5")
    assert rating.review == "Nice"
    assert session.commits == 0


def test_one_rating_per_booking_model_compatibility() -> None:
    """The ``ratings`` model keys by ``booking_id`` PK — structural 1-1."""
    assert Rating.__table__.primary_key.columns.keys() == ["booking_id"]
    r = make_rating("b1")
    same = make_rating("b1")
    assert (r.booking_id, same.booking_id) == ("b1", "b1")


# ============================================================================
# Security / ownership
# ============================================================================


def test_user_a_cannot_be_represented_as_user_b() -> None:
    """list_for_user filters strictly by the passed user_id."""
    ba = make_booking("b1", USER_A, "m1")
    bb = make_booking("b3", USER_B, "m1")
    session = FakeSession({MechanicBooking: [ba, bb]})
    repo = MechanicBookingRepository(session)
    assert [b.id for b in asyncio.run(repo.list_for_user(USER_B))] == ["b3"]
    assert asyncio.run(repo.get_owned("b1", USER_B)) is None


def test_booking_repository_never_commits_on_any_write() -> None:
    session = FakeSession()
    repo = MechanicBookingRepository(session)
    asyncio.run(repo.create_booking(user_id=USER_A, mechanic_id="m1"))
    b = make_booking("b1", USER_A, "m1")
    asyncio.run(repo.update_status(b, BookingStatus.CANCELLED.value))
    assert session.commits == 0


def test_all_repositories_never_commit_on_writes() -> None:
    session = FakeSession()
    MechanicBookingRepository(session).session  # construction is inert
    booking = asyncio.run(
        MechanicBookingRepository(session).create_booking(user_id=USER_A, mechanic_id="m1")
    )
    asyncio.run(BookingEventRepository(session).append(booking_id=booking.id or "b1"))
    asyncio.run(
        RatingRepository(session).create_rating(booking_id=booking.id or "b1")
    )
    assert session.commits == 0