# Infrastructure — Mecha Connect (Sprint 2)

> Target infrastructure for the backend. At RC1 only the Flutter build/deploy
> story is real; backend containerization/CI is planned.

## 1. Runtime Stack

| Component | Choice | Notes |
|---|---|---|
| API | FastAPI + Uvicorn | modular monolith (not microservices) |
| Database | PostgreSQL 15 | primary store |
| Cache / session | Redis | cache + JWT refresh session store |
| Vector search | FAISS | knowledge-base retrieval |
| File system | knowledge base files | RAG sources |

## 2. Deployment (target)

- Multi-stage **Dockerfile**; separate containers for app, db, redis
  (`docker-compose.yml`).
- **CI/CD:** GitHub Actions — automated testing → automated deploy to
  Railway/Render.
- Frontend CI (planned): `dart analyze` + `flutter test` + build APK/appbundle
  → Play Store internal testing → closed alpha → open beta → production.

## 3. Environment Configuration

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | PostgreSQL DSN |
| `REDIS_URL` | Redis connection |
| `JWT_SECRET_KEY` | Token signing |
| `GEMINI_API_KEY` | Gemini access |
| `FIREBASE_CREDENTIALS_PATH` | Firebase service account |

Secrets are never committed; they come from env / secret stores only
(see root `SECURITY.md`).

## 4. Monitoring

- **Logging:** structured JSON logs; request/response logging; error tracking;
  performance metrics.
- **Health checks:** `/health` (basic), `/health/db`, `/health/redis`,
  `/health/ai`.

## 5. Caching Strategy

Redis for: session storage (JWT refresh), rate-limiting counters, frequently
accessed data, background-job queue. Cache keys: `user:{id}`,
`mechanic:{id}`, `products:{category}`, `nearby_mechanics:{lat}:{lng}`.

## 6. Background Jobs (target)

Celery with Redis broker/result backend; retry with exponential backoff; dead
letter queue. Tasks: send_email, send_notification, process_payment,
update_order_status, generate_invoice. (Constraint noted in the Sprint 2
blueprint: use FastAPI BackgroundTasks where Celery is overkill.)
