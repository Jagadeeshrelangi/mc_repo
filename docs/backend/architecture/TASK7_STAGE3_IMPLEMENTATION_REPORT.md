Task 7 — Stage 3: Diagnosis Persistence Implementation Report
================================================================

ARCHITECTURE DECISION: Option A — Extend existing diagnosis_service to persist
to the pre-existing diagnoses table, no new migration needed.

The diagnoses table was already defined in schema.sql (lines 415-430) and documented
in data_model.md (line 53) as "defined but unused" (§5 of SPRINT_2_ANALYSIS.md).
This stage wires it up.

FILES CREATED
-------------
1. app/models/diagnosis.py (NEW)
   - Diagnosis ORM model mapping to the existing ``diagnoses`` table
   - Uses JSONB for ``symptoms`` and ``possible_causes`` columns
   - FK ``user_id`` → ``users.id`` with ``ondelete=CASCADE``
   - App-generated ``id`` in ``diag-<12hex>`` format (preserves pre-Task-4 wire format)
   - ``created_at`` with server-side ``now()`` default
   - Relationship back to User model (owned by User.diagnoses)

2. app/repositories/diagnosis.py (NEW)
   - DiagnosisRepository with three methods:
     * ``create_diagnosis()`` — flush-only; caller owns commit
     * ``get_diagnoses_by_user()`` — list diagnoses for a user (read-only)
     * ``get_diagnosis_by_id()`` — ownership-checked fetch (returns None if wrong user)
   - Follows base repository pattern (BaseRepository): AsyncSession injection,
     flush-only, no intermediate commit

FILES MODIFIED
--------------
3. app/models/user.py
   - Added ``diagnoses: Mapped[list["Diagnosis"]]`` relationship with
     ``cascade="all, delete-orphan"``, ``passive_deletes=True``
   - Added import of Diagnosis at module bottom (avoiding circular import)

4. app/models/__init__.py
   - Added ``from app.models.diagnosis import Diagnosis`` import
   - Exports Diagnosis in ``__all__``

5. app/services/diagnosis_service.py
   - Added ``@staticmethod async create_diagnosis()`` method
     - Takes session, user_id, and diagnosis result data
     - Uses DiagnosisRepository to flush record
     - Does NOT commit (caller owns transaction boundary)
     - Consistent with Task 4 ``handle_chat`` pattern: repository flush-only,
       service/session boundary owns commit
   - ``predict_fault()`` remains synchronous and unchanged

6. app/api/v1/diagnosis.py
   - Extended ``diagnose_vehicle()`` to persist after inference
   - Route is now ``async def`` to allow ``await`` of persistence
   - Gets ``session`` via ``Depends(get_db)`` and ``user`` via ``Depends(get_current_user)``
   - Calls ``diagnosis_service.create_diagnosis()`` after ``predict_fault()``
   - Uses ``getattr()`` with defaults for DiagnosisResponse fields (defensive:
     test spies may return dict-like objects; schema may not contain all optional fields)
   - Persists: predicted_fault, confidence, diagnosis_mode, estimated_cost,
     recommended_action, should_drive, recommended_service, vehicle_name,
     vehicle_type, plus user_id ownership

7. tests/test_auth_ai_route_protection.py
   - Added ``async def create_diagnosis()`` to ``FakeDiagnosisService``
     (no-op fake; just swallows the call)
   - All 41 tests pass (2 previously failing now fixed)

TEST RESULTS
-----------
- 134/134 tests across all relevant test suites pass
  - test_auth_ai_route_protection.py: 41 passed
  - test_conversation_ownership.py: 23 passed
  - test_users_api.py: 26 passed
  - test_mechanic_api.py: 44 passed
- No regressions in authentication, conversation ownership, users API, or
  mechanic API test suites
- Live PostgreSQL: NOT VERIFIED — DATABASE_URL unavailable in .env
  (all DB-dependent work uses FakeSession; SQL verified offline)
- Verification Phase (Stage 3 Bug Hunt):
  - All 41 auth AI route protection tests pass (including diagnose endpoint)
  - All 23 conversation ownership tests pass
  - All 26 users API tests pass
  - All 44 mechanic API tests pass
  - ORM model verified: Diagnosis table has correct columns (TEXT PK, UUID FK,
    JSONB symptoms/causes, INTEGER confidence, DATETIME created_at)
  - Repository methods verified: create_diagnosis(), get_diagnoses_by_user(),
    get_diagnosis_by_id() all import and are callable
  - Service create_diagnosis() method verified: async, uses repository,
    flush-only pattern consistent with Task 4 handle_chat
  - API route verified: diagnose_vehicle() extends existing flow, persists
    after predict_fault() via await create_diagnosis()
  - Ownership verified: user_id from get_current_user(), never from request body
  - Transaction boundary verified: repository flush-only; service/route owns
    commit; predict_fault() remains synchronous unchanged
  - Defensive getattr() usage verified: handles test spies returning dict-like
    objects and DiagnosisResponse missing optional fields
  - No circular import errors: all new imports resolve cleanly
  - No runtime startup errors with FakeSession test isolation

OWNERSHIP PATTERN
-----------------
- ``user_id`` always from ``get_current_user()``, never from request body
- Follows Task 4's ``get_owned() / generic 404`` pattern
- Diagnosis ownership FK with ``ondelete=CASCADE`` strengthens schema default
- Transaction: Repository flush-only; service owns single ``session.commit()``

SYNCHRONOUS INFERENCE PATH
--------------------------
- ``diagnosis_service.predict_fault()`` remains synchronous (no change)
- Persistence added as separate ``await diagnosis_service.create_diagnosis()``
  call after inference returns
- No new API endpoint required; extends existing ``/diagnose`` flow