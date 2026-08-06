# Mecha Connect — Master Engineering Handbook (MEH) v1.0

> **Project**: Mecha Connect — AI-Powered Roadside Assistance & Vehicle Services Platform
>
> **Document**: Master Engineering Handbook v1.0
>
> **Status**: **IMPLEMENTATION-READY** — Final Engineering Document
>
> **Version**: 1.0.0
>
> **Classification**: Internal — All Engineers

---

## Table of Contents

1. [Engineering Overview](#1-engineering-overview)
2. [Organization Structure](#2-organization-structure)
3. [Repository Standards](#3-repository-standards)
4. [Git Standards](#4-git-standards)
5. [Pull Request Standards](#5-pull-request-standards)
6. [Coding Standards](#6-coding-standards)
7. [Backend Standards](#7-backend-standards)
8. [Flutter Standards](#8-flutter-standards)
9. [AI Engineering Standards](#9-ai-engineering-standards)
10. [API Standards](#10-api-standards)
11. [Database Standards](#11-database-standards)
12. [Security Standards](#12-security-standards)
13. [DevOps Standards](#13-devops-standards)
14. [Testing Standards](#14-testing-standards)
15. [Documentation Standards](#15-documentation-standards)
16. [Code Review Guidelines](#16-code-review-guidelines)
17. [Performance Standards](#17-performance-standards)
18. [Release Management](#18-release-management)
19. [Incident Management](#19-incident-management)
20. [Engineering Metrics](#20-engineering-metrics)
21. [Engineering Checklists](#21-engineering-checklists)
22. [Templates](#22-templates)
23. [Mermaid Diagrams](#23-mermaid-diagrams)
24. [Best Practices](#24-best-practices)
25. [Appendix](#25-appendix)

---

## 1. Engineering Overview

### 1.1 Mission

Mecha Connect's engineering organization exists to build the most **reliable, fast, and trustworthy** roadside assistance platform on the planet. Every line of code we write serves a user in distress. Our systems must work when it matters most — during emergencies, in network dead zones, under extreme load, and across diverse device capabilities.

We do not build features. We build **lifelines**.

### 1.2 Engineering Vision

```mermaid
mindmap
  root((Mecha Connect Engineering))
    Reliability
      Zero-downtime deployments
      Offline-first architecture
      Graceful degradation
    Speed
      Sub-500ms API responses
      Sub-2s cold start
      Real-time tracking
    Trust
      Transparent pricing
      Secure payments
      Audit trails
    Scale
      10M+ users
      100K+ mechanics
      Multi-region
    Intelligence
      AI-powered matching
      Predictive analytics
      Smart routing
```

### 1.3 Core Values

| Value | Definition | How We Measure |
|-------|-----------|----------------|
| **Reliability Above All** | Our platform must work when users need it most | Uptime > 99.95%, Offline mode success rate |
| **Speed is Safety** | Every millisecond counts in an emergency | P95 API < 500ms, App cold start < 2s |
| **Trust Through Transparency** | Users must see pricing, ETA, and mechanic quality clearly | Rating accuracy, Price estimate vs actual variance |
| **Ownership & Accountability** | Every engineer owns their code from dev to prod | MTTR < 1hr, Blameless postmortems |
| **Incremental Excellence** | Ship small, ship often, improve continuously | Deployment frequency, Cycle time |
| **Accessibility for All** | Our platform serves everyone, regardless of ability | WCAG 2.1 AA compliance, Screen reader support |
| **Data-Driven Decisions** | We measure everything, we optimize what matters | Feature adoption, Error rates, AI accuracy |

### 1.4 Engineering Principles

#### Principle 1: Offline-First by Default

Every feature in Mecha Connect must work without an internet connection for at least the core flow. Roadside emergencies happen in network dead zones. Our architecture assumes disconnection is the norm, not the exception.

**Rules:**
- All critical flows must have offline fallback
- Local state must sync when connectivity returns
- Conflict resolution must be deterministic
- Users must never lose data due to network issues

#### Principle 2: Fail Gracefully

When something breaks — and it will — the user should never see a crash or a blank screen. Every failure mode must have a designed fallback.

**Rules:**
- Every API call must have error handling
- Every screen must have loading, error, and empty states
- Critical flows must have degraded mode fallbacks
- Errors must be user-friendly, not technical

#### Principle 3: Build for Urgency

Our users are in stressful situations. Every interaction must be optimized for speed, clarity, and minimal cognitive load.

**Rules:**
- SOS must be accessible from any screen in 1 tap
- Service request must complete in under 3 taps
- Price information must be visible before confirmation
- Progress must be visible at all times

#### Principle 4: Security is Non-Negotiable

We handle sensitive user data, payment information, and real-time location data. Security is embedded in every layer of our stack.

**Rules:**
- All data in transit must use TLS 1.3
- All sensitive data at rest must be encrypted
- Payment data must never touch our servers directly
- Access control must follow least-privilege principle

#### Principle 5: Test Everything That Can Fail

If it can break, there must be a test for it. We maintain a comprehensive test pyramid covering unit, widget, integration, and end-to-end tests.

**Rules:**
- Unit test coverage must be > 90%
- Every bug fix must include a regression test
- Critical flows must have integration tests
- AI responses must have evaluation tests

### 1.5 Development Philosophy

```mermaid
flowchart LR
    A[Think] --> B[Design]
    B --> C[Implement]
    C --> D[Test]
    D --> E[Review]
    E --> F[Deploy]
    F --> G[Monitor]
    G --> H[Learn]
    H --> A

    style A fill:#1A73E8,color:#fff
    style B fill:#1A73E8,color:#fff
    style C fill:#1A73E8,color:#fff
    style D fill:#34A853,color:#fff
    style E fill:#FBBC04,color:#000
    style F fill:#EA4335,color:#fff
    style G fill:#EA4335,color:#fff
    style H fill:#1A73E8,color:#fff
```

**The Mecha Connect Development Loop:**

1. **Think**: Understand the problem, user need, and impact. Read existing documentation. Check for prior art.
2. **Design**: Write a brief design doc (1-2 pages). For complex features, write an RFC. Get early feedback.
3. **Implement**: Write code following our standards. Start with tests. Use TDD for critical paths.
4. **Test**: Run all tests locally. Verify on real devices. Check AI responses with evaluation suite.
5. **Review**: Create a PR. Address all review comments. Ensure CI passes.
6. **Deploy**: Merge to main. Deploy using our CI/CD pipeline. Monitor rollout.
7. **Monitor**: Watch dashboards, error rates, and user metrics. Check AI accuracy.
8. **Learn**: Document learnings. Update runbooks. Write postmortems for incidents.

### 1.6 Ownership Culture

Every engineer at Mecha Connect owns their code from inception to production. Ownership means:

- **You write it, you run it**: Engineers are responsible for deploying, monitoring, and debugging their code.
- **You break it, you fix it**: On-call rotations include feature owners. No silos.
- **You own the quality**: Testing, documentation, and performance are part of definition of done.
- **You own the outcome**: We measure impact, not output. Did your feature improve the metric?

**Ownership Levels:**

| Level | Scope | Responsibilities |
|-------|-------|-----------------|
| **Feature Owner** | Single feature/module | Implementation, tests, docs, monitoring dashboards |
| **Area Owner** | Group of related features | Architecture decisions, cross-team coordination, performance budgets |
| **Platform Owner** | Cross-cutting concern | Standards, tooling, shared libraries, migration planning |
| **Domain Owner** | Entire domain (Customer, Mechanic, Admin, AI) | Roadmap alignment, tech debt prioritization, team mentorship |

---

## 2. Organization Structure

### 2.1 Engineering Teams

```mermaid
flowchart TD
    CTO[CTO / VP Engineering]

    subgraph Platform[Platform Team]
        PE1[Principal Engineer]
        PE2[Staff Engineer - Infra]
        PE3[Staff Engineer - Security]
    end

    subgraph Customer[Customer App Team]
        CEM[Engineering Manager]
        CE1[Sr. Flutter Engineer]
        CE2[Flutter Engineer]
        CE3[Flutter Engineer]
    end

    subgraph Mechanic[Mechanic App Team]
        MEM[Engineering Manager]
        ME1[Sr. Flutter Engineer]
        ME2[Flutter Engineer]
    end

    subgraph Backend[Backend Services Team]
        BEM[Engineering Manager]
        BE1[Sr. Backend Engineer]
        BE2[Backend Engineer]
        BE3[Backend Engineer]
        BE4[Backend Engineer]
    end

    subgraph AI[AI & Data Team]
        AIEM[Engineering Manager]
        AI1[ML Engineer]
        AI2[AI Engineer]
        AI3[Data Engineer]
    end

    subgraph DevOps[DevOps & SRE Team]
        DEM[Engineering Manager]
        DE1[DevOps Engineer]
        DE2[SRE Engineer]
    end

    subgraph QA[QA Team]
        QAM[QA Manager]
        QA1[Sr. QA Engineer]
        QA2[QA Engineer]
        QA3[QA Engineer]
    end

    CTO --> Platform
    CTO --> Customer
    CTO --> Mechanic
    CTO --> Backend
    CTO --> AI
    CTO --> DevOps
    CTO --> QA

    Platform -.-> Customer
    Platform -.-> Mechanic
    Platform -.-> Backend
    Platform -.-> AI
    Platform -.-> DevOps
    Platform -.-> QA
```

### 2.2 Team Responsibilities

| Team | Primary Responsibilities | Key Technologies |
|------|------------------------|-----------------|
| **Customer App Team** | Customer mobile app, UX, state management, offline support | Flutter, BLoC, GoRouter, Drift |
| **Mechanic App Team** | Mechanic mobile app, real-time tracking, job management | Flutter, BLoC, Google Maps, WebSocket |
| **Backend Services Team** | API gateway, microservices, auth, payments, notifications | FastAPI, PostgreSQL, Redis, Celery |
| **AI & Data Team** | AI assistant, mechanic matching, analytics, LLM integration | OpenAI API, LangChain, RAG, Vector DB |
| **DevOps & SRE Team** | CI/CD, infrastructure, monitoring, incident response | Docker, K8s, GitHub Actions, Terraform |
| **QA Team** | Test strategy, automation, performance testing, AI evaluation | Flutter Test, Selenium, Locust, Pytest |
| **Platform Team** | Architecture, standards, security, shared libraries | Cross-cutting: all technologies |

### 2.3 Communication Flow

```mermaid
flowchart TD
    subgraph Async[Asynchronous Communication]
        GH[GitHub Issues/PRs]
        SL[Slack Channels]
        DOC[Documentation]
        ML[Mailing List]
    end

    subgraph Sync[Synchronous Communication]
        STAND[Daily Standup - 15min]
        SPRINT[Sprint Planning - 1hr]
        RETRO[Sprint Retro - 1hr]
        ARCH[Architecture Sync - Weekly]
        INC[Incident Calls - On Demand]
    end

    Async --> SL
    Async --> GH
    Async --> DOC

    Sync --> STAND
    Sync --> SPRINT
    Sync --> RETRO
    Sync --> ARCH
    Sync --> INC

    STAND --> |Blockers| INC
    ARCH --> |Major Decisions| RFC
    INC --> |Postmortems| DOC
```

**Channel Guide:**

| Channel | Purpose | Response SLA |
|---------|---------|--------------|
| `#eng-announcements` | Engineering-wide broadcasts (read-only) | N/A |
| `#eng-customer-app` | Customer app discussions | 4 hours |
| `#eng-mechanic-app` | Mechanic app discussions | 4 hours |
| `#eng-backend` | Backend services discussions | 4 hours |
| `#eng-ai` | AI/ML discussions | 4 hours |
| `#eng-devops` | CI/CD, infrastructure discussions | 1 hour (business hours) |
| `#eng-security` | Security alerts and discussions | 15 minutes |
| `#eng-incidents` | Active incident communication | Immediate |
| `#eng-random` | Non-work watercooler | N/A |
| `#eng-design-reviews` | Architecture/design review requests | 24 hours |

### 2.4 Decision Making

**Decision Levels:**

| Level | Decision Type | Who Decides | Process |
|-------|--------------|-------------|---------|
| **L1** | Day-to-day technical choices | Individual engineer | No process needed |
| **L2** | Feature-level architecture | Feature owner + EM | Brief design doc |
| **L3** | Cross-team architecture | Area owner + Platform team | RFC + review |
| **L4** | Platform-wide standards | Platform team + CTO | RFC + review + approval |
| **L5** | Technology/strategy | CTO + EM team | Proposal + discussion |

**Decision Making Principles:**

1. **Default to action**: When in doubt, make a small decision and iterate. Don't wait for perfect information.
2. **Write it down**: Every L3+ decision must be documented in an ADR (Architecture Decision Record).
3. **Disagree and commit**: Once a decision is made, everyone supports it, even if they disagreed during discussion.
4. **Revisit decisions**: ADRs have expiry dates. Revisit decisions when context changes.

### 2.5 Escalation Matrix

```mermaid
flowchart TD
    E1[Engineer encounters issue]
    E1 --> Q1{Can I resolve?}
    Q1 --> |Yes| E2[Resolve independently]
    Q1 --> |No| E3[Escalate to Tech Lead]
    E3 --> Q2{Tech Lead can resolve?}
    Q2 --> |Yes| E4[Tech Lead resolves]
    Q2 --> |No| E5[Escalate to Engineering Manager]
    E5 --> Q3{EM can resolve?}
    Q3 --> |Yes| E6[EM resolves]
    Q3 --> |No - Resource/Cross-team| E7[Escalate to CTO]
    Q3 --> |No - Incident| E8[Escalate to Incident Commander]

    style E2 fill:#34A853,color:#fff
    style E4 fill:#1A73E8,color:#fff
    style E6 fill:#FBBC04,color:#000
    style E7 fill:#EA4335,color:#fff
    style E8 fill:#EA4335,color:#fff
```

**Escalation SLAs:**

| Level | Response Time | Resolution Time |
|-------|--------------|-----------------|
| Engineer ? Tech Lead | 2 hours | 1 day |
| Tech Lead ? EM | 4 hours | 2 days |
| EM ? CTO | 1 day | 1 week |
| Incident Commander | 5 minutes | Varies by severity |

### 2.6 Meeting Structure

| Meeting | Frequency | Duration | Attendees | Purpose |
|---------|-----------|----------|-----------|---------|
| Daily Standup | Daily | 15 min | Team | What did you do? What will you do? Any blockers? |
| Sprint Planning | Biweekly | 60 min | Team + PM | Commit to sprint backlog |
| Sprint Review | Biweekly | 30 min | Team + Stakeholders | Demo completed work |
| Sprint Retro | Biweekly | 45 min | Team | What went well? What to improve? Actions |
| Architecture Sync | Weekly | 60 min | All engineers | Cross-team architecture discussion |
| Design Review | As needed | 30-60 min | Relevant engineers | Design doc review |
| 1:1 with Manager | Weekly | 30 min | Engineer + Manager | Career growth, feedback, concerns |
| All Hands | Monthly | 30 min | All engineers | Company updates, demos |

### 2.7 RFC Process

The RFC (Request for Comments) process is used for any significant engineering decision that affects multiple teams or the platform as a whole.

**When to Write an RFC:**

- Introducing a new technology or framework
- Changing an architecture pattern
- Adding a new service or major feature
- Changing API contracts across teams
- Changing CI/CD or deployment processes
- Security or compliance changes

**RFC Lifecycle:**

```mermaid
flowchart LR
    A[Draft] --> B[Review]
    B --> C[Final Comment Period]
    C --> D[Approved]
    C --> E[Rejected]
    C --> F[Withdrawn]
    D --> G[Implemented]
    G --> H[Closed]

    style A fill:#1A73E8,color:#fff
    style B fill:#FBBC04,color:#000
    style C fill:#FBBC04,color:#000
    style D fill:#34A853,color:#fff
    style E fill:#EA4335,color:#fff
    style G fill:#34A853,color:#fff
    style H fill:#5F6368,color:#fff
```

**RFC Timeline:**

| Phase | Duration | Description |
|-------|----------|-------------|
| Draft | Author's discretion | Write the RFC, gather initial feedback |
| Review | 5 business days | Open for comments from all engineers |
| Final Comment Period | 2 business days | Last call for objections |
| Decision | 1 business day | Approve, reject, or request changes |


---

## 16. Code Review Guidelines

### 16.1 Review Checklist (All Areas Combined)

| # | Item | Description |
|---|------|-------------|
| 1 | Purpose understood | Does the change address the stated problem? |
| 2 | Correctness | Is the logic correct for all edge cases? |
| 3 | Tests included | Unit, widget, integration, or E2E as appropriate |
| 4 | Test coverage | New code should have >= 80% coverage |
| 5 | No dead code | No commented-out code, unused imports, or orphaned files |
| 6 | Error handling | All error paths handled, no silent failures |
| 7 | Logging | Appropriate log levels (debug/info/warn/error) |
| 8 | No secrets | No API keys, passwords, tokens in code or commits |
| 9 | Documentation | Public APIs documented, README updated if needed |
| 10 | Linting | All linters pass with zero warnings |
| 11 | Type safety | No dynamic, any, or untyped casts |
| 12 | No TODOs | TODOs must have associated issues and be approved |
| 13 | Small scope | PR should be focused on one concern |
| 14 | Commit hygiene | Commits are logical, messages follow convention |

### 16.2 Performance Review

- [ ] No N+1 queries -- verify with query count logging
- [ ] No expensive operations inside loops
- [ ] Database queries use proper indexes (check EXPLAIN ANALYZE)
- [ ] API endpoints return only required fields (no over-fetching)
- [ ] Pagination implemented for list endpoints
- [ ] Caching considered for repeated computations
- [ ] No synchronous blocking calls in async code paths
- [ ] Asset sizes reviewed (images, fonts, bundles)
- [ ] Lazy loading used where appropriate
- [ ] Memory leaks checked (unsubscribed streams, disposed controllers)
- [ ] Build times within frame budget (Flutter: <16ms per frame)
- [ ] Network payloads compressed and minimal

### 16.3 Security Review

- [ ] Input validation on all user-facing endpoints
- [ ] Authentication checks on every protected route
- [ ] Authorization -- verify user has correct role/permissions
- [ ] No SQL injection (use parameterized queries only)
- [ ] No XSS vulnerabilities (sanitize output, use CSP headers)
- [ ] Rate limiting considered for public endpoints
- [ ] File upload restrictions (type, size, scan)
- [ ] Secrets never logged or exposed in error messages
- [ ] HTTPS enforced for all external communication
- [ ] Dependency scan passed (no known CVEs)
- [ ] Session management secure (timeout, rotation, HttpOnly cookies)
- [ ] CORS configured correctly

### 16.4 Architecture Review

- [ ] Follows project architecture patterns (Clean Architecture, layered)
- [ ] Separation of concerns maintained (no god classes/files)
- [ ] Dependency injection used correctly
- [ ] Single Responsibility Principle followed
- [ ] Interface/abstraction boundaries respected
- [ ] No circular dependencies between modules
- [ ] Feature is extensible without modifying existing code (Open/Closed)
- [ ] Configuration externalized (env vars, feature flags)
- [ ] Backward compatibility considered for API changes
- [ ] Error boundaries defined at module boundaries
- [ ] Event-driven vs request-response patterns used appropriately

### 16.5 AI Review

- [ ] Prompt templates versioned and tested
- [ ] Model responses validated with structured parsing (Pydantic)
- [ ] Fallback behavior defined for model failures
- [ ] Token usage tracked and within budget
- [ ] Latency budget respected (streaming vs non-streaming decision)
- [ ] Prompt injection protection in place
- [ ] PII/PHI filtered before sending to model
- [ ] Model output post-processed (formatting, safety filter)
- [ ] A/B testing framework considered for prompt changes
- [ ] Cost per inference calculated and approved
- [ ] Model version pinned, not floating
- [ ] Evaluation dataset updated for new prompts

### 16.6 Flutter Review

- [ ] Widget rebuilds minimized (const constructors, RepaintBoundary)
- [ ] No unnecessary setState -- use proper state management (BLoC/Riverpod)
- [ ] Platform channels used correctly (casting, error handling)
- [ ] Assets optimized (WebP, vector graphics, proper resolutions)
- [ ] Accessibility labels added
- [ ] Dark mode and theming handled
- [ ] Responsive layout tested on multiple screen sizes
- [ ] Navigation/routing follows project pattern
- [ ] Form validation implemented client-side
- [ ] Localization considered for user-facing strings
- [ ] No memory leaks in StreamSubscriptions, AnimationControllers
- [ ] Shader warm-up performed for smooth animations
- [ ] Platform-specific code isolated via platform checks or channels

### 16.7 Backend Review

- [ ] API endpoint follows RESTful conventions
- [ ] Request/response models use Pydantic validation
- [ ] Database session management correct (commit/rollback/close)
- [ ] Background tasks use proper task queue (Celery/Redis Queue)
- [ ] Async endpoints use async/await throughout
- [ ] Exception handling with custom exception classes
- [ ] Middleware chain understood and correct
- [ ] Rate limiting, throttling implemented where needed
- [ ] CORS, CSRF, security headers configured
- [ ] Health check endpoint included
- [ ] Metrics emitted for business KPIs and system health
- [ ] OpenAPI/Swagger docs updated

### 16.8 DevOps Review

- [ ] Dockerfile optimized (layer caching, minimal image size)
- [ ] No hardcoded environment-specific values
- [ ] CI pipeline passes all stages
- [ ] Infrastructure changes reviewed (terraform plan approved)
- [ ] Secrets managed via vault/secret store, not env files
- [ ] Resource limits set (CPU, memory for containers)
- [ ] Monitoring and alerting configured for new services
- [ ] Log aggregation set up (ELK, Loki, CloudWatch)
- [ ] Backup strategy in place for stateful services
- [ ] Rollback plan documented for the release

---

## 17. Performance Standards

### 17.1 Backend Performance

| Metric | Target | Measurement |
|--------|--------|-------------|
| API P95 Latency | < 500ms | Application monitoring (Datadog, Prometheus) |
| API P99 Latency | < 1000ms | Application monitoring |
| DB Query P95 | < 200ms | Database monitoring (pg_stat_statements, slow query log) |
| DB Query P99 | < 500ms | Database monitoring |
| Throughput | Handle 1000 req/s per instance | Load testing (k6, Locust) |
| Concurrent Users | 10,000 per service | Load testing |
| Startup Time | < 30 seconds | Container startup measurement |
| Response Size | < 1MB per response (default) | Network monitoring |
| Connection Pool | 80% utilization max | DB connection pool metrics |

### 17.2 Flutter Performance

| Metric | Target | Measurement |
|--------|--------|-------------|
| Frame Build Time | < 16ms per frame (60fps) | Flutter DevTools, Timeline |
| Frame Raster Time | < 16ms per frame | Flutter DevTools |
| Shader Compilation | < 200ms total, no jank | Skia shader warmup tracking |
| App Startup Time (cold) | < 3 seconds | Firebase Performance, custom timing |
| App Startup Time (warm) | < 1.5 seconds | Firebase Performance |
| APK/IPA Size | < 40MB release build | Build output measurement |
| Memory Usage (peak) | < 200MB on iOS, < 256MB on Android | DevTools Memory view |
| CPU Usage (idle) | < 5% | DevTools CPU profiler |
| Network Requests | Minimize, batch where possible | DevTools Network tab |
| Image Memory | Use cached network images, max 2MB each | DevTools |
| Widget Rebuilds | < 10 per frame for complex screens | DevTools Rebuild Counts |

**Shader Warm-up:** Include ShaderWarmUp in app initialization. Add all custom shaders used in animations to the warm-up list.

### 17.3 Database Performance

| Area | Target | Tool/Method |
|------|--------|-------------|
| Index Hit Ratio | > 99% | pg_stat_user_indexes |
| Cache Hit Ratio | > 95% | pg_buffercache, RDS monitoring |
| Connection Pool | max 80% utilization | PgBouncer metrics |
| Replication Lag | < 1 second | Streaming replication monitoring |
| WAL Generation | < 10GB/hour per TB data | WAL monitoring |
| Vacuum Frequency | autovacuum triggered at 20% dead tuples | pg_stat_user_tables |
| Long Running Queries | > 5s flagged, > 30s killed | pg_stat_activity + alerting |
| Read Replicas | serve read-only traffic, < 1s lag | Application routing |
| Partitioning | tables > 100GB auto-partitioned | Monthly/quarterly partitions |

### 17.4 AI Performance

| Metric | Target | Measurement |
|--------|--------|-------------|
| Inference Latency (small model) | < 1 second | Custom monitoring |
| Inference Latency (large model) | < 5 seconds | Custom monitoring |
| Streaming TTFB | < 500ms | Application monitoring |
| Token Generation Rate | > 50 tokens/second | Custom measurement |
| Prompt Processing | < 2 seconds for 4K tokens | Custom measurement |
| Cache Hit Rate (semantic cache) | > 40% | Cache monitoring |
| Rate Limit | Configurable per tier | API Gateway |
| Concurrent Requests | Scalable to 100+ per instance | Load testing |
| Cost per 1K tokens | Track and budget monthly | Cloud cost monitoring |
| Model Accuracy | > 90% on eval set | Evaluation pipeline |
| Hallucination Rate | < 5% | Evaluation pipeline |
| Fallback Rate | < 2% of requests | Monitoring |

### 17.5 Caching Strategy

| Layer | Cache Type | TTL | Invalidation |
|-------|-----------|-----|--------------|
| DNS | DNS cache | 60s-300s (TTL in record) | DNS record update |
| CDN | Static assets | 1 year (versioned URLs) | New deployment |
| API Gateway | Response cache | 60s | Cache-control headers |
| Application | In-memory (Redis) | 300s | Write-through + TTL |
| Application | Semantic cache (AI) | 3600s | Similarity threshold > 0.95 |
| Database | Query cache (Redis) | 60s | Table update triggers |
| Database | Buffer pool (Postgres) | Persistent | LRU eviction |
| Client | HTTP cache | Per-endpoint | ETag, Last-Modified |
| Client | Flutter image cache | 100 images (LRU) | Memory pressure |

**Caching Rules:**
- Always set Cache-Control headers on responses
- Use ETag for conditional requests
- Never cache user-specific or sensitive data in shared caches
- Implement cache stampede protection (lock/mutex for hot keys)
- Monitor cache hit/miss ratios and adjust TTLs

### 17.6 Memory & CPU

| Resource | Service | Limit | Request |
|----------|---------|-------|---------|
| CPU | API Server | 4 cores | 2 cores |
| Memory | API Server | 4GB | 2GB |
| CPU | Worker | 2 cores | 1 core |
| Memory | Worker | 4GB | 2GB |
| CPU | AI Service | 8 cores | 4 cores |
| Memory | AI Service | 16GB | 8GB |
| CPU | Database | 8 cores | 4 cores |
| Memory | Database | 32GB | 16GB |
| CPU | Redis | 4 cores | 2 cores |
| Memory | Redis | 8GB | 4GB |

**Notes:**
- Request = guaranteed minimum, Limit = maximum allowed burst
- Use HPA (Horizontal Pod Autoscaler) at 70% CPU utilization
- OOMKilled containers trigger immediate paging for on-call
- Memory leak detection runs in CI (stress tests + heap profiling)

### 17.7 Latency Targets Table

| Operation | P50 Target | P95 Target | P99 Target | Degraded Threshold |
|-----------|-----------|-----------|-----------|-------------------|
| Simple API (no DB) | < 50ms | < 100ms | < 300ms | > 500ms |
| API with DB read | < 100ms | < 300ms | < 500ms | > 1s |
| API with DB write | < 200ms | < 500ms | < 1000ms | > 2s |
| API with AI inference (small) | < 500ms | < 1s | < 2s | > 3s |
| API with AI inference (large) | < 2s | < 5s | < 10s | > 15s |
| Streaming AI (TTFB) | < 200ms | < 500ms | < 1s | > 2s |
| DB Query (indexed) | < 5ms | < 50ms | < 200ms | > 500ms |
| DB Query (full scan) | < 100ms | < 500ms | < 1s | > 2s |
| File Upload (10MB) | < 2s | < 5s | < 10s | > 15s |
| Page Load (Flutter cold) | < 2s | < 3s | < 5s | > 7s |
| Page Load (Flutter warm) | < 500ms | < 1s | < 2s | > 3s |
| Notification Push | < 500ms | < 2s | < 5s | > 10s |
| Search Query | < 200ms | < 500ms | < 1s | > 2s |

---

## 18. Release Management

### 18.1 Versioning (SemVer)

All releases follow Semantic Versioning 2.0.0: MAJOR.MINOR.PATCH

- MAJOR -- Breaking changes (API contract changes, database migrations requiring downtime, removal of features)
- MINOR -- New features, backward-compatible additions (new endpoints, new AI capabilities, non-breaking UI additions)
- PATCH -- Bug fixes, performance improvements, security patches (backward-compatible)

Pre-release labels: -alpha.X, -beta.X, -rc.X

Versioning process:
1. Feature branch: no version change
2. Development branch: {next}-dev (e.g., 2.1.0-dev)
3. Release candidate: {version}-rc.1 (e.g., 2.1.0-rc.1)
4. Stable release: {version} (e.g., 2.1.0)
5. Hotfix: bump PATCH on current MAJOR.MINOR (e.g., 2.1.1)

### 18.2 Release Checklist

- [ ] All code merged to main or release branch
- [ ] All CI checks pass (lint, test, build, security scan)
- [ ] Test coverage meets minimum threshold (>= 80%)
- [ ] Integration tests pass for all critical flows
- [ ] E2E tests pass (Smoke + Critical path)
- [ ] Performance benchmarks against baseline (no regression > 5%)
- [ ] Security scan passed (SAST, DAST, dependency scan)
- [ ] AI evaluation suite passed (accuracy, hallucination, latency)
- [ ] Changelog updated with all changes since last release
- [ ] Version bumped according to SemVer in all relevant files
- [ ] Git tag created (v{MAJOR}.{MINOR}.{PATCH})
- [ ] Release notes drafted (technical + product summaries)
- [ ] Feature flags reviewed -- toggles set correctly per environment
- [ ] Database migration scripts validated (up + down)
- [ ] Rollback plan documented and reviewed
- [ ] Deployment runbook updated if needed
- [ ] On-call team notified of upcoming release
- [ ] Stakeholders notified of release window

### 18.3 Deployment Checklist

- [ ] Pre-deployment smoke tests pass on staging
- [ ] Database migrations run and verified (zero downtime migration plan)
- [ ] Canary deployment configured (10% traffic initially)
- [ ] Health checks configured and responding
- [ ] Monitoring dashboards verified for new metrics
- [ ] Alert thresholds configured for new services
- [ ] Feature flags enabled/disabled as planned
- [ ] Cache warmed for expected traffic patterns
- [ ] CDN purged for updated static assets
- [ ] SSL certificates valid and auto-renewal configured
- [ ] DNS records updated (if applicable)
- [ ] Load balancer targets updated
- [ ] Auto-scaling policies verified
- [ ] Backup of database taken before deployment
- [ ] Deployment proceeds in stages (canary -> 25% -> 50% -> 100%)
- [ ] Rollback trigger conditions defined

### 18.4 Rollback Checklist

- [ ] Rollback decision criteria understood (error rate > 1%, latency > 2x baseline, P95 > threshold)
- [ ] Immediate rollback command available (revert git, re-deploy previous image, db rollback)
- [ ] Database rollback strategy defined (migration reversal or point-in-time recovery)
- [ ] Feature flags disabled as first line of defense (prefer flag toggle over full rollback)
- [ ] Previous deployment artifacts available (Docker images, build artifacts)
- [ ] Rollback tested in staging before every release
- [ ] Communication template ready for rollback notification
- [ ] Post-rollback validation steps documented
- [ ] Root cause analysis triggered after rollback stabilizes

### 18.5 Post-release Validation

- [ ] Monitor error rates for 30 minutes post-release
- [ ] Verify latency metrics within expected range
- [ ] Check business metrics (signups, orders, active users) for anomalies
- [ ] Review logs for unexpected error patterns
- [ ] Verify all services report healthy status
- [ ] Confirm feature flags working as expected (A/B test bucketing)
- [ ] Check third-party integrations are functioning
- [ ] Monitor database connection pool and query performance
- [ ] Review AI inference latency and accuracy metrics
- [ ] Send release summary to team channel
- [ ] Schedule release retrospective if needed

### 18.6 Feature Flags

Feature flags are managed via LaunchDarkly (preferred) or environment variables.

**Flag Lifecycle:**
1. **Create** -- Define flag name, description, owner, and rollout percentage
2. **Develop** -- Implement behind flag; default to off in production
3. **Test** -- Enable flag in staging for QA validation
4. **Canary** -- Enable for internal users (5-10%)
5. **Gradual Rollout** -- Increase percentage: 25% -> 50% -> 75% -> 100%
6. **Monitor** -- Watch metrics for regressions at each step
7. **Clean up** -- Remove flag code after 100% rollout is stable for 1 week

**Flag Naming Convention:** eature.{team}.{feature-name}

**Flag Types:**
- Release flags: toggle new features on/off
- Experiment flags: A/B test variants
- Permission flags: gradually expose to user groups
- Kill switches: emergency disable of features

### 18.7 Canary Releases

Canary releases follow a structured rollout progression:

| Stage | Traffic % | Duration | Validation Criteria |
|-------|----------|----------|-------------------|
| Stage 1 (Internal) | 5% | 10 min | No errors, latency normal, health checks pass |
| Stage 2 (Friends & Family) | 10% | 30 min | Error rate < 0.1%, latency < 1.5x baseline |
| Stage 3 (Gradual) | 25% | 1 hour | All metrics within 10% of baseline |
| Stage 4 (Broad) | 50% | 2 hours | Business metrics stable, no customer complaints |
| Stage 5 (Full) | 100% | -- | Declare success, remove canary routing |

If any validation criteria fails at any stage, auto-rollback triggers and the on-call engineer is paged.

---

## 19. Incident Management

### 19.1 Severity Levels (SEV1-SEV4)

| Level | Definition | Response Time | SLA | Examples |
|-------|-----------|--------------|-----|----------|
| SEV1 | Critical -- complete service outage, data loss, security breach | 15 min | Resolution < 4 hours | All API endpoints down, database corrupted, PII leak |
| SEV2 | High -- degraded service, major feature unavailable, >10% users affected | 30 min | Resolution < 8 hours | Search broken, payments failing for subset of users |
| SEV3 | Medium -- minor feature impact, <10% users affected, no revenue impact | 4 hours | Fix by next release | UI bug on specific device, non-critical endpoint slow |
| SEV4 | Low -- cosmetic issues, non-functional requests, documentation errors | Next business day | Fix within sprint | Typo in UI, outdated docs, minor styling issue |

### 19.2 On-call Rotation

- Primary on-call: 1 week rotation per team
- Secondary on-call: backup for primary, handles SEV3/SEV4 when primary is busy
- Escalation: Primary -> Secondary -> Engineering Manager -> VP Engineering
- Schedule: Published in PagerDuty/OpsGenie with calendar sync
- Handoff: Weekly sync meeting every Monday at 10:00 AM
- Timezone coverage: Follow-the-sun model (US/EU/APAC teams)
- No consecutive on-call weeks for any engineer

**On-call Responsibilities:**
- Acknowledge SEV1 within 15 minutes, SEV2 within 30 minutes
- Provide regular status updates (every 30 min for SEV1, hourly for SEV2)
- Document timeline and actions in the incident channel
- Escalate promptly when stuck for > 1 hour
- Hand off with clear notes at shift end for active incidents

### 19.3 Escalation Flow

`
User reports issue -> Automated alert (Datadog/PagerDuty)
        |
        v
Primary On-call Engineer acknowledges (15/30 min SLA)
        |
   Can resolve? --Yes--> Fix, verify, close incident
        |No
        v
Escalate to Secondary On-call (adds to incident channel)
        |
   Can resolve? --Yes--> Fix, verify, close incident
        |No
        v
Escalate to Engineering Manager (coordinates across teams)
        |
   Can resolve? --Yes--> Fix, verify, close incident
        |No
        v
Escalate to VP Engineering (executive awareness, cross-org resources)
        |
        v
Incident Command established for SEV1 events
`

### 19.4 Communication (Internal + External)

**Internal Communication:**
- Incident channel in Slack: #incidents for all updates
- Channel naming: #incident-{SEV}-{short-description}
- Regular status updates every 30 min (SEV1) or 60 min (SEV2)
- Status update format: "Time | Status | Impact | Next Step"
- Post-mortem scheduled within 48 hours of resolution

**External Communication (SEV1 only):**
- Status page updated immediately (status.mechaconnect.com)
- Customer-facing message drafted and approved by Product
- Communication cadence: initial notification < 15 min, updates every 30 min
- Channel: email notification, in-app banner, status page
- Template available in #incident-response pinned messages

**Status Update Template:**
`
Time: {UTC timestamp}
Status: {Investigating / Mitigating / Resolved / Monitoring}
Impact: {What feature / users are affected}
Next Step: {What is being done next}
ETA: {If known}
`

### 19.5 Postmortem Template

`markdown
# Postmortem: {Title}

## Incident Summary
- **Date:** YYYY-MM-DD
- **Duration:** HH:MM (start) to HH:MM (end)
- **Severity:** SEV{1-4}
- **Impact:** {Number of users affected, revenue impact, data loss}
- **Root Cause:** {One-line summary}

## Timeline
| Time (UTC) | Event |
|------------|-------|
| HH:MM | {Event description} |
| HH:MM | {Event description} |

## What Went Wrong
- {Technical detail 1}
- {Technical detail 2}

## What Went Well
- {Positive aspect 1}
- {Positive aspect 2}

## Action Items
- [ ] {Action item with owner and due date}
- [ ] {Action item with owner and due date}

## Lessons Learned
- {Lesson 1}
- {Lesson 2}

## Appendices
- {Links to logs, dashboards, commits, etc.}
`

### 19.6 Recovery Checklist

- [ ] Identify and isolate the root cause
- [ ] Apply immediate fix (rollback, feature flag, hotfix)
- [ ] Verify fix in staging or isolated environment
- [ ] Gradually restore traffic in canary fashion
- [ ] Monitor for 30+ minutes post-recovery
- [ ] Confirm all dependent services are healthy
- [ ] Verify data integrity (no corruption or loss)
- [ ] Clear any cached/buffered error states
- [ ] Alert stakeholders that recovery is complete
- [ ] Document timeline for postmortem

### 19.7 Incident Commander Role

For SEV1 incidents, an Incident Commander (IC) is designated.

**Responsibilities:**
1. **Triage** -- Assess severity, gather initial information
2. **Coordinate** -- Assign tasks to responders, track progress
3. **Communicate** -- Provide regular status updates to stakeholders
4. **Decide** -- Make go/no-go decisions on mitigations
5. **Escalate** -- Bring in additional resources as needed
6. **Document** -- Ensure timeline is recorded in real-time
7. **Handoff** -- Transfer IC role when shift ends with full context

**IC is NOT responsible for:**
- Actually debugging or fixing the issue (that is responders' job)
- Making product/feature decisions (Product Manager handles those)
- Writing the postmortem (IC reviews, but responders contribute)

**Selection criteria:** Senior engineer with broad system knowledge, rotated monthly.



---

## 11. Database Standards

### 11.1 Technology

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| Primary Database | PostgreSQL | 16 | Relational data, ACID transactions |
| Geospatial | PostGIS | 3.4 | Location-based queries, routing |
| Cache / Session | Redis | 7 | Caching, rate limiting, pub/sub |
| Vector Search | Pinecone | - | AI embeddings, semantic search |
| Migrations | Alembic | 1.13 | Schema version control |

All database services run in **Docker** for local development and **AWS RDS / ElastiCache / Pinecone** for production.

---

### 11.2 Naming Conventions

#### General Rules

| Element | Convention | Example |
|---------|-----------|---------|
| Database Name | `mechanect_{env}` | `mechanect_dev`, `mechanect_prod` |
| Table Names | `snake_case`, plural | `booking_requests`, `wallet_transactions` |
| Column Names | `snake_case` | `first_name`, `is_active`, `created_at` |
| Primary Key | `id` UUID v7 | `id UUID DEFAULT gen_random_uuid()` |
| Foreign Key | `{singular_table}_id` | `mechanic_id`, `booking_request_id` |
| Indexes | `idx_{table}_{column}` | `idx_users_email` |
| Unique Constraints | `uq_{table}_{column}` | `uq_users_email` |
| Composite Indexes | `idx_{table}_{col1}_{col2}` | `idx_booking_requests_status_created` |
| Partial Indexes | `idx_{table}_{col}_where_{condition}` | `idx_users_is_active_where_true` |
| Primary Key Constraint | `pk_{table}` | `pk_users` |
| Foreign Key Constraint | `fk_{table}_{ref_table}` | `fk_booking_requests_mechanics` |
| Check Constraint | `ck_{table}_{description}` | `ck_users_age_over_18` |
| Sequences | `seq_{table}_{column}` | `seq_invoice_numbers` |
| Enums | `snake_case` | `booking_status`, `payment_method` |

#### Enum Naming

All enums are stored as `TEXT` columns with `CHECK` constraints in PostgreSQL (not native `CREATE TYPE`) for migration simplicity.

```sql
-- Avoid: CREATE TYPE booking_status AS ENUM (...)
-- Prefer:
CHECK (status IN ('pending', 'accepted', 'in_progress', 'completed', 'cancelled'))
```

---

### 11.3 Migration Rules (Alembic)

#### Principles

1. **One change per migration** – Never bundle unrelated schema changes in a single migration.
2. **Never edit existing migrations** – Once committed and reviewed, migrations are immutable. If you need to change a migration that hasn't been deployed yet, create a new migration that reverses and reapplies.
3. **Down migrations are REQUIRED** – Every `upgrade()` must have a corresponding `downgrade()`.
4. **Migration naming** – Use `{YYYY}_{MM}_{DD}_{description}` format: `2025_01_15_create_users_table.py`.
5. **Always generate, never hand-write** – Use `alembic revision --autogenerate -m "description"` and then review.

#### Alembic Configuration

```ini
# alembic.ini
[alembic]
script_location = alembic
sqlalchemy.url = postgresql+asyncpg://postgres:postgres@localhost:5432/mechanect_dev
```

```python
# alembic/env.py
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context
from app.core.config import settings
from app.models import Base  # noqa: F401 - Required for autogenerate

config = context.config
config.set_main_option("sqlalchemy.url", settings.database_url)

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata

def run_migrations_offline() -> None:
    context.configure(url=settings.database_url, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online() -> None:
    connectable = create_async_engine(settings.database_url)
    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()
```

#### Migration Example

```python
"""2025_01_15_create_users_table

Revision ID: a1b2c3d4e5f6
Revises: None
Create Date: 2025-01-15 10:30:00.000000
"""
from alembic import op
import sqlalchemy as sa
import uuid

revision = "a1b2c3d4e5f6"
down_revision = None
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.UUID(), nullable=False, server_default=sa.text("gen_random_uuid()")),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column("phone_number", sa.String(20), nullable=False),
        sa.Column("first_name", sa.String(100), nullable=False),
        sa.Column("last_name", sa.String(100), nullable=False),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("role", sa.String(20), nullable=False, server_default="customer"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.text("true")),
        sa.Column("is_verified", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_users")),
        sa.UniqueConstraint("email", name=op.f("uq_users_email")),
        sa.UniqueConstraint("phone_number", name=op.f("uq_users_phone_number")),
    )
    op.create_index(op.f("idx_users_email"), "users", ["email"])
    op.create_index(op.f("idx_users_is_active"), "users", ["is_active"])

def downgrade() -> None:
    op.drop_index(op.f("idx_users_is_active"), table_name="users")
    op.drop_index(op.f("idx_users_email"), table_name="users")
    op.drop_table("users")
```

#### Migration Workflow

```mermaid
flowchart LR
    A[Model Change] --> B[alembic revision --autogenerate]
    B --> C[Review generated migration]
    C --> D{Correct?}
    D -->|Yes| E[Commit migration]
    D -->|No| F[Edit manually]
    F --> C
    E --> G[alembic upgrade head]
    G --> H[Verify with pgAdmin / psql]
```

---

### 11.4 Schema Design (CREATE TABLE)

#### users

```sql
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255) NOT NULL,
    phone_number    VARCHAR(20) NOT NULL,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    avatar_url      VARCHAR(500),
    role            VARCHAR(20) NOT NULL DEFAULT 'customer'
                    CHECK (role IN ('customer', 'mechanic', 'admin', 'super_admin')),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
    fcm_token       VARCHAR(500),
    last_login_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT uq_users_phone_number UNIQUE (phone_number)
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone_number ON users(phone_number);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_is_active ON users(is_active) WHERE is_active = TRUE;
```

#### mechanics

```sql
CREATE TABLE mechanics (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL,
    business_name   VARCHAR(255) NOT NULL,
    business_phone  VARCHAR(20) NOT NULL,
    business_email  VARCHAR(255),
    description     TEXT,
    services_offered TEXT[] NOT NULL DEFAULT '{}',
    service_area_radius_km INTEGER NOT NULL DEFAULT 25,
    latitude        DECIMAL(10, 7) NOT NULL,
    longitude       DECIMAL(10, 7) NOT NULL,
    location        GEOGRAPHY(Point, 4326) NOT NULL,
    is_available    BOOLEAN NOT NULL DEFAULT TRUE,
    is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
    rating          DECIMAL(3, 2) DEFAULT 0.00
                    CHECK (rating >= 0 AND rating <= 5),
    review_count    INTEGER NOT NULL DEFAULT 0,
    total_jobs      INTEGER NOT NULL DEFAULT 0,
    subscription_tier VARCHAR(20) NOT NULL DEFAULT 'free'
                      CHECK (subscription_tier IN ('free', 'basic', 'premium', 'enterprise')),
    stripe_account_id VARCHAR(255),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_mechanics_users
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT uq_mechanics_user_id UNIQUE (user_id)
);

CREATE INDEX idx_mechanics_location ON mechanics USING GIST(location);
CREATE INDEX idx_mechanics_is_available ON mechanics(is_available) WHERE is_available = TRUE;
CREATE INDEX idx_mechanics_rating ON mechanics(rating DESC);
CREATE INDEX idx_mechanics_subscription_tier ON mechanics(subscription_tier);
```

#### vehicles

```sql
CREATE TABLE vehicles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL,
    make            VARCHAR(100) NOT NULL,
    model           VARCHAR(100) NOT NULL,
    year            INTEGER NOT NULL
                    CHECK (year >= 1980 AND year <= EXTRACT(YEAR FROM NOW()) + 1),
    color           VARCHAR(50),
    license_plate   VARCHAR(20),
    vin             VARCHAR(17),
    is_primary      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_vehicles_users
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_vehicles_user_id ON vehicles(user_id);
CREATE INDEX idx_vehicles_make_model ON vehicles(make, model);
```

#### booking_requests

```sql
CREATE TABLE booking_requests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL,
    mechanic_id     UUID,
    vehicle_id      UUID NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                    CHECK (status IN (
                        'pending', 'searching', 'matched', 'accepted',
                        'in_progress', 'en_route', 'arrived',
                        'completed', 'cancelled', 'expired'
                    )),
    service_type    VARCHAR(50) NOT NULL
                    CHECK (service_type IN (
                        'towing', 'tire_change', 'jump_start', 'fuel_delivery',
                        'lockout', 'battery', 'flatbed', 'winching', 'other'
                    )),
    description     TEXT,
    pickup_latitude     DECIMAL(10, 7) NOT NULL,
    pickup_longitude    DECIMAL(10, 7) NOT NULL,
    pickup_location     GEOGRAPHY(Point, 4326) NOT NULL,
    dropoff_latitude    DECIMAL(10, 7),
    dropoff_longitude   DECIMAL(10, 7),
    dropoff_location    GEOGRAPHY(Point, 4326),
    customer_eta_minutes INTEGER,
    mechanic_eta_minutes INTEGER,
    distance_km         DECIMAL(10, 2),
    price_estimate      DECIMAL(10, 2),
    final_price         DECIMAL(10, 2),
    cancellation_reason TEXT,
    cancelled_by        VARCHAR(20)
                        CHECK (cancelled_by IN ('customer', 'mechanic', 'system')),
    ai_confidence_score DECIMAL(5, 4),
    ai_assigned         BOOLEAN NOT NULL DEFAULT FALSE,
    emergency_level     VARCHAR(20) DEFAULT 'normal'
                        CHECK (emergency_level IN ('low', 'normal', 'high', 'critical')),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_booking_requests_users
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_booking_requests_mechanics
        FOREIGN KEY (mechanic_id) REFERENCES mechanics(id) ON DELETE SET NULL,
    CONSTRAINT fk_booking_requests_vehicles
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
);

CREATE INDEX idx_booking_requests_status ON booking_requests(status);
CREATE INDEX idx_booking_requests_user_id ON booking_requests(user_id);
CREATE INDEX idx_booking_requests_mechanic_id ON booking_requests(mechanic_id);
CREATE INDEX idx_booking_requests_status_created
    ON booking_requests(status, created_at DESC);
CREATE INDEX idx_booking_requests_location
    ON booking_requests USING GIST(pickup_location);
CREATE INDEX idx_booking_requests_ai_assigned
    ON booking_requests(ai_assigned) WHERE ai_assigned = TRUE;
CREATE INDEX idx_booking_requests_emergency
    ON booking_requests(emergency_level, created_at DESC)
    WHERE emergency_level IN ('high', 'critical');
```

#### payments

```sql
CREATE TABLE payments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id      UUID NOT NULL,
    user_id         UUID NOT NULL,
    mechanic_id     UUID NOT NULL,
    amount          DECIMAL(10, 2) NOT NULL
                    CHECK (amount > 0),
    platform_fee    DECIMAL(10, 2) NOT NULL DEFAULT 0,
    mechanic_payout DECIMAL(10, 2) NOT NULL DEFAULT 0,
    currency        VARCHAR(3) NOT NULL DEFAULT 'USD',
    status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                    CHECK (status IN (
                        'pending', 'processing', 'completed',
                        'failed', 'refunded', 'partially_refunded'
                    )),
    payment_method  VARCHAR(20) NOT NULL
                    CHECK (payment_method IN (
                        'card', 'wallet', 'cash', 'apple_pay', 'google_pay'
                    )),
    stripe_payment_intent_id VARCHAR(255),
    stripe_transfer_id       VARCHAR(255),
    refund_amount    DECIMAL(10, 2) DEFAULT 0,
    refund_reason    TEXT,
    paid_at          TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_payments_booking
        FOREIGN KEY (booking_id) REFERENCES booking_requests(id) ON DELETE CASCADE,
    CONSTRAINT fk_payments_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_payments_mechanic
        FOREIGN KEY (mechanic_id) REFERENCES mechanics(id) ON DELETE CASCADE
);

CREATE INDEX idx_payments_booking_id ON payments(booking_id);
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_mechanic_id ON payments(mechanic_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_created_at ON payments(created_at DESC);
CREATE INDEX idx_payments_stripe_intent ON payments(stripe_payment_intent_id);
```

#### wallet_transactions

```sql
CREATE TABLE wallet_transactions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL,
    type            VARCHAR(20) NOT NULL
                    CHECK (type IN (
                        'deposit', 'withdrawal', 'payment_outgoing',
                        'payment_incoming', 'refund_incoming', 'refund_outgoing',
                        'bonus', 'fee', 'adjustment'
                    )),
    amount          DECIMAL(10, 2) NOT NULL,
    currency        VARCHAR(3) NOT NULL DEFAULT 'USD',
    balance_before  DECIMAL(10, 2) NOT NULL,
    balance_after   DECIMAL(10, 2) NOT NULL,
    reference_type  VARCHAR(50),
    reference_id    UUID,
    description     TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'completed'
                    CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_wallet_transactions_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_wallet_transactions_user_id ON wallet_transactions(user_id);
CREATE INDEX idx_wallet_transactions_type ON wallet_transactions(type);
CREATE INDEX idx_wallet_transactions_created_at ON wallet_transactions(created_at DESC);
CREATE INDEX idx_wallet_transactions_reference
    ON wallet_transactions(reference_type, reference_id);
```

#### notifications

```sql
CREATE TABLE notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL,
    type            VARCHAR(50) NOT NULL
                    CHECK (type IN (
                        'booking_matched', 'mechanic_assigned', 'status_update',
                        'payment_received', 'payment_failed', 'review_requested',
                        'promotion', 'system_alert', 'chat_message', 'reminder'
                    )),
    title           VARCHAR(255) NOT NULL,
    body            TEXT NOT NULL,
    data            JSONB DEFAULT '{}',
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    read_at         TIMESTAMPTZ,
    channel         VARCHAR(20) NOT NULL DEFAULT 'push'
                    CHECK (channel IN ('push', 'sms', 'email', 'in_app')),
    sent_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_notifications_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_unread
    ON notifications(user_id, created_at DESC)
    WHERE is_read = FALSE;
CREATE INDEX idx_notifications_type ON notifications(type);
```

#### reviews

```sql
CREATE TABLE reviews (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id      UUID NOT NULL,
    user_id         UUID NOT NULL,
    mechanic_id     UUID NOT NULL,
    rating          INTEGER NOT NULL
                    CHECK (rating >= 1 AND rating <= 5),
    title           VARCHAR(255),
    description     TEXT,
    tags            TEXT[] DEFAULT '{}',
    is_verified     BOOLEAN NOT NULL DEFAULT TRUE,
    is_flagged      BOOLEAN NOT NULL DEFAULT FALSE,
    flag_reason     TEXT,
    helpful_count   INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_reviews_booking
        FOREIGN KEY (booking_id) REFERENCES booking_requests(id) ON DELETE CASCADE,
    CONSTRAINT fk_reviews_user
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_reviews_mechanic
        FOREIGN KEY (mechanic_id) REFERENCES mechanics(id) ON DELETE CASCADE,
    CONSTRAINT uq_reviews_booking UNIQUE (booking_id)
);

CREATE INDEX idx_reviews_mechanic_id ON reviews(mechanic_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);
CREATE INDEX idx_reviews_created_at ON reviews(created_at DESC);
```

#### mechanic_documents

```sql
CREATE TABLE mechanic_documents (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mechanic_id     UUID NOT NULL,
    type            VARCHAR(50) NOT NULL
                    CHECK (type IN (
                        'business_license', 'insurance', 'certification',
                        'drivers_license', 'tin', 'background_check',
                        'w9', 'bank_verification'
                    )),
    status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'approved', 'rejected', 'expired')),
    file_url        VARCHAR(500) NOT NULL,
    file_type       VARCHAR(20) NOT NULL
                    CHECK (file_type IN ('pdf', 'jpg', 'png', 'doc', 'docx')),
    expires_at      TIMESTAMPTZ,
    reviewed_by     UUID,
    reviewed_at     TIMESTAMPTZ,
    rejection_reason TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_mechanic_documents_mechanic
        FOREIGN KEY (mechanic_id) REFERENCES mechanics(id) ON DELETE CASCADE,
    CONSTRAINT fk_mechanic_documents_reviewer
        FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_mechanic_documents_mechanic_id ON mechanic_documents(mechanic_id);
CREATE INDEX idx_mechanic_documents_status ON mechanic_documents(status);
CREATE INDEX idx_mechanic_documents_type ON mechanic_documents(type);
CREATE INDEX idx_mechanic_documents_expiring
    ON mechanic_documents(expires_at)
    WHERE status = 'approved' AND expires_at IS NOT NULL;
```

---

### 11.5 Indexes

#### Index Strategy Table

| Table | Index Name | Columns | Type | Filter | Purpose |
|-------|-----------|---------|------|--------|---------|
| users | idx_users_email | email | B-tree | - | Login lookup |
| users | idx_users_phone_number | phone_number | B-tree | - | SMS login/OTP |
| users | idx_users_role | role | B-tree | - | Admin queries |
| users | idx_users_is_active | is_active | B-tree (partial) | WHERE is_active = TRUE | Active user queries |
| mechanics | idx_mechanics_location | location | GIST | - | Geospatial search |
| mechanics | idx_mechanics_is_available | is_available | B-tree (partial) | WHERE is_available = TRUE | Available mechanics |
| mechanics | idx_mechanics_rating | rating | B-tree (DESC) | - | Top-rated ordering |
| booking_requests | idx_booking_status_created | status, created_at | B-tree (composite) | - | Status listing sorted by recency |
| booking_requests | idx_booking_pickup_location | pickup_location | GIST | - | Nearby booking discovery |
| booking_requests | idx_booking_ai_assigned | ai_assigned | B-tree (partial) | WHERE ai_assigned = TRUE | AI assignment queries |
| booking_requests | idx_booking_emergency | emergency_level, created_at | B-tree (partial) | WHERE emergency_level IN (\\'high\\', \\'critical\\') | Emergency prioritization |
| payments | idx_payments_created_at | created_at | B-tree (DESC) | - | Recent transactions |
| payments | idx_payments_stripe_intent | stripe_payment_intent_id | B-tree | - | Stripe reconciliation |
| wallet_transactions | idx_wallet_created_at | created_at | B-tree (DESC) | - | Transaction history |
| notifications | idx_notifications_unread | user_id, created_at | B-tree (partial) | WHERE is_read = FALSE | Unread badge count |
| reviews | idx_reviews_created_at | created_at | B-tree (DESC) | - | Recent reviews |
| mechanic_documents | idx_docs_expiring | expires_at | B-tree (partial) | WHERE status=\\'approved\\' AND expires_at IS NOT NULL | Expiration alerts |

#### Index Rules

1. **Every FK gets a B-tree index** – Always index foreign key columns.
2. **Every WHERE clause filter gets an index** – If you filter by it, index it.
3. **Composite indexes for multi-column filters** – Order columns by selectivity (most selective first).
4. **Partial indexes for sparse data** – When a column has mostly NULLs or only a few values matter.
5. **Covering indexes for hot queries** – Add INCLUDE columns to avoid table heap lookups.
6. **GIST indexes for geospatial** – Always use GIST for GEOGRAPHY and GEOMETRY columns.
7. **Avoid over-indexing** – Every index slows down writes. Monitor index usage with `pg_stat_user_indexes`.

```sql
-- Composite index example
CREATE INDEX idx_booking_status_created
    ON booking_requests(status, created_at DESC);

-- Partial index example
CREATE INDEX idx_users_is_active
    ON users(is_active)
    WHERE is_active = TRUE;

-- Covering index example
CREATE INDEX idx_users_email_covering
    ON users(email)
    INCLUDE (first_name, last_name, avatar_url, role);
```

---

### 11.6 Relationships

#### Foreign Key Constraints

| Child Table | FK Column | Parent Table | On Delete | On Update |
|-------------|-----------|-------------|-----------|-----------|
| mechanics | user_id | users | CASCADE | CASCADE |
| vehicles | user_id | users | CASCADE | CASCADE |
| booking_requests | user_id | users | CASCADE | CASCADE |
| booking_requests | mechanic_id | mechanics | SET NULL | CASCADE |
| booking_requests | vehicle_id | vehicles | CASCADE | CASCADE |
| payments | booking_id | booking_requests | CASCADE | CASCADE |
| payments | user_id | users | CASCADE | CASCADE |
| payments | mechanic_id | mechanics | CASCADE | CASCADE |
| wallet_transactions | user_id | users | CASCADE | CASCADE |
| notifications | user_id | users | CASCADE | CASCADE |
| reviews | booking_id | booking_requests | CASCADE | CASCADE |
| reviews | user_id | users | CASCADE | CASCADE |
| reviews | mechanic_id | mechanics | CASCADE | CASCADE |
| mechanic_documents | mechanic_id | mechanics | CASCADE | CASCADE |
| mechanic_documents | reviewed_by | users | SET NULL | CASCADE |

#### Cascade Rules

- **CASCADE** – Used for strong ownership (user owns their vehicles, mechanics own their documents).
- **SET NULL** – Used for optional relationships (booking can lose its mechanic reference if mechanic is deleted).
- **RESTRICT** – Used for critical financial relationships (prevent deleting a user with active payments).
- **NO ACTION** – Used for audit/reference tables where historical integrity matters.

---

### 11.7 Transactions

#### ACID Compliance Rules

1. **Every business operation that affects multiple tables MUST use a database transaction.**
2. **Async transactions** – Use `async with db.begin()` for FastAPI async endpoints.
3. **Keep transactions short** – Never hold a transaction open during external API calls, file uploads, or user interaction.
4. **Isolation level** – Use `READ COMMITTED` (PostgreSQL default). Use `SERIALIZABLE` only for financial operations where race conditions are unacceptable.
5. **Retry on serialization failures** – For `SERIALIZABLE` isolation, always retry the transaction on `40001` errors.
6. **Avoid long-running transactions** – Set `statement_timeout` for all transactions (default: 30s).
7. **Nested transactions** – Use savepoints (`SAVEPOINT`) rather than nested `BEGIN/COMMIT`.

#### Async Transaction Example (FastAPI + SQLAlchemy)

```python
from app.db.session import AsyncSessionLocal
from app.models import WalletTransaction, Payment
from app.schemas import PaymentCreate
from decimal import Decimal

async def process_payment(db: AsyncSession, payment_data: PaymentCreate) -> Payment:
    """Process payment with wallet debit in a single transaction."""
    async with db.begin():
        # 1. Create payment record
        payment = Payment(
            booking_id=payment_data.booking_id,
            user_id=payment_data.user_id,
            mechanic_id=payment_data.mechanic_id,
            amount=payment_data.amount,
            platform_fee=payment_data.amount * Decimal("0.10"),
            mechanic_payout=payment_data.amount * Decimal("0.90"),
            status="processing",
            payment_method=payment_data.payment_method,
        )
        db.add(payment)
        await db.flush()

        # 2. Debit wallet
        wallet_txn = WalletTransaction(
            user_id=payment_data.user_id,
            type="payment_outgoing",
            amount=payment_data.amount,
            balance_before=Decimal("100.00"),
            balance_after=Decimal("100.00") - payment_data.amount,
            reference_type="payment",
            reference_id=payment.id,
            description=f"Payment for booking {payment_data.booking_id}",
            status="completed",
        )
        db.add(wallet_txn)

    db.refresh(payment)
    return payment
```

---

### 11.8 Soft Delete

#### Approach

All tables use a `deleted_at` TIMESTAMPTZ column for soft delete:

```sql
ALTER TABLE users ADD COLUMN deleted_at TIMESTAMPTZ;
ALTER TABLE mechanics ADD COLUMN deleted_at TIMESTAMPTZ;
```

#### Rules

1. **Never run hard DELETE** on core entities (users, mechanics, booking_requests, payments).
2. **All queries MUST filter `deleted_at IS NULL`** at the application level.
3. **SQLAlchemy filter mixin** – Add a global `deleted_at IS NULL` filter on all queries.
4. **Hard DELETE allowed only** for: notifications, audit_log, temporary tables.
5. **Admin tools** – Provide an admin endpoint to soft-delete or restore records.
6. **Retention** – Hard delete soft-deleted records older than 90 days via a cron job.

#### SQLAlchemy Soft Delete Mixin

```python
from sqlalchemy import Column, DateTime, func
from sqlalchemy.orm import declared_attr, Query

class SoftDeleteMixin:
    """Adds soft delete capability to any model."""

    deleted_at = Column(DateTime(timezone=True), nullable=True, default=None)

    @declared_attr
    def __mapper_args__(cls):
        return {
            "polymorphic_load_on_none": True,
        }

    @classmethod
    def apply_soft_delete_filter(cls, query: Query) -> Query:
        return query.filter(cls.deleted_at.is_(None))


# Usage in repository layer:
async def get_active_users(db: AsyncSession) -> list[User]:
    query = select(User).where(User.deleted_at.is_(None))
    result = await db.execute(query)
    return result.scalars().all()
```

---

## 3. Repository Standards

### 3.1 Monorepo Overview

Mecha Connect uses a **Melos-managed monorepo** hosted under the repository name **`mecha-connect`**. All code—frontend applications, backend services, shared packages, infrastructure, documentation, and tooling—resides in a single repository to simplify dependency management, enforce consistent standards, and enable atomic cross-stack changes.

**Why monorepo?**
- Single source of truth for all code
- Atomic commits across frontend + backend
- Shared packages versioned together
- Unified CI/CD pipeline
- Simplified dependency management via Melos

### 3.2 Complete Folder Structure

```
mecha-connect/
|
|-- apps/
|   |-- customer_app/                 # Customer mobile app (Flutter)
|   |   |-- android/
|   |   |-- ios/
|   |   |-- lib/
|   |   |   |-- main.dart
|   |   |   |-- app.dart
|   |   |   |-- core/
|   |   |   |-- features/
|   |   |   |-- l10n/
|   |   |-- test/
|   |   |-- pubspec.yaml
|   |   |-- analysis_options.yaml
|   |
|   |-- mechanic_app/                 # Mechanic mobile app (Flutter)
|   |   |-- android/
|   |   |-- ios/
|   |   |-- lib/
|   |   |   |-- main.dart
|   |   |   |-- app.dart
|   |   |   |-- core/
|   |   |   |-- features/
|   |   |   |-- l10n/
|   |   |-- test/
|   |   |-- pubspec.yaml
|   |   |-- analysis_options.yaml
|   |
|   |-- admin_dashboard/              # Admin web dashboard (Flutter Web)
|   |   |-- lib/
|   |   |-- test/
|   |   |-- pubspec.yaml
|   |
|   |-- website/                      # Public marketing website (Next.js)
|   |   |-- src/
|   |   |   |-- pages/
|   |   |   |-- components/
|   |   |   |-- styles/
|   |   |-- public/
|   |   |-- package.json
|   |   |-- tsconfig.json
|   |
|   |-- customer_portal/              # Customer web portal (Flutter Web)
|       |-- lib/
|       |-- test/
|       |-- pubspec.yaml
|
|-- packages/
|   |-- shared_core/                  # Core types, constants, extensions
|   |   |-- lib/
|   |   |   |-- src/
|   |   |   |   |-- types/
|   |   |   |   |-- constants/
|   |   |   |   |-- extensions/
|   |   |   |   |-- utils/
|   |   |   |-- shared_core.dart
|   |   |-- test/
|   |   |-- pubspec.yaml
|   |
|   |-- shared_ui/                    # Shared UI components, themes, design system
|   |   |-- lib/
|   |   |   |-- src/
|   |   |   |   |-- atoms/
|   |   |   |   |-- molecules/
|   |   |   |   |-- organisms/
|   |   |   |   |-- templates/
|   |   |   |   |-- tokens/
|   |   |   |-- shared_ui.dart
|   |   |-- test/
|   |   |-- pubspec.yaml
|   |
|   |-- shared_api/                   # API client, models, interceptors
|   |   |-- lib/
|   |   |   |-- src/
|   |   |   |   |-- client/
|   |   |   |   |-- models/
|   |   |   |   |-- interceptors/
|   |   |   |   |-- endpoints/
|   |   |   |-- shared_api.dart
|   |   |-- test/
|   |   |-- pubspec.yaml
|   |
|   |-- feature_requests/             # Service request feature
|   |   |-- lib/
|   |   |-- test/
|   |   |-- pubspec.yaml
|   |
|   |-- feature_tracking/             # Real-time tracking feature
|   |   |-- lib/
|   |   |-- test/
|   |   |-- pubspec.yaml
|   |
|   |-- feature_payments/             # Payment processing feature
|   |   |-- lib/
|   |   |-- test/
|   |   |-- pubspec.yaml
|   |
|   |-- feature_chat/                 # In-app messaging feature
|   |   |-- lib/
|   |   |-- test/
|   |   |-- pubspec.yaml
|   |
|   |-- feature_notifications/        # Push notifications feature
|   |   |-- lib/
|   |   |-- test/
|   |   |-- pubspec.yaml
|   |
|   |-- feature_rating/               # Rating and review feature
|   |   |-- lib/
|   |   |-- test/
|   |   |-- pubspec.yaml
|   |
|   |-- feature_auth/                 # Authentication feature
|   |   |-- lib/
|   |   |-- test/
|   |   |-- pubspec.yaml
|   |
|   |-- feature_location/             # Location services feature
|       |-- lib/
|       |-- test/
|       |-- pubspec.yaml
|
|-- backend/
|   |-- api_gateway/                  # API Gateway (FastAPI)
|   |   |-- app/
|   |   |   |-- main.py
|   |   |   |-- routers/
|   |   |   |-- middleware/
|   |   |   |-- models/
|   |   |-- tests/
|   |   |-- requirements.txt
|   |   |-- Dockerfile
|   |
|   |-- services/
|   |   |-- auth_service/             # Authentication service (FastAPI)
|   |   |   |-- app/
|   |   |   |-- tests/
|   |   |   |-- requirements.txt
|   |   |   |-- Dockerfile
|   |   |
|   |   |-- booking_service/          # Booking & dispatch service (FastAPI)
|   |   |   |-- app/
|   |   |   |-- tests/
|   |   |   |-- requirements.txt
|   |   |   |-- Dockerfile
|   |   |
|   |   |-- payment_service/          # Payment processing service (FastAPI)
|   |   |   |-- app/
|   |   |   |-- tests/
|   |   |   |-- requirements.txt
|   |   |   |-- Dockerfile
|   |   |
|   |   |-- notification_service/     # Push/SMS/email notifications (FastAPI)
|   |   |   |-- app/
|   |   |   |-- tests/
|   |   |   |-- requirements.txt
|   |   |   |-- Dockerfile
|   |   |
|   |   |-- mechanic_service/         # Mechanic management service (FastAPI)
|   |   |   |-- app/
|   |   |   |-- tests/
|   |   |   |-- requirements.txt
|   |   |   |-- Dockerfile
|   |   |
|   |   |-- analytics_service/        # Analytics and reporting service (FastAPI)
|   |       |-- app/
|   |       |-- tests/
|   |       |-- requirements.txt
|   |       |-- Dockerfile
|   |
|   |-- ai_services/
|       |-- matching_engine/          # AI-powered mechanic matching service
|       |   |-- app/
|       |   |-- models/
|       |   |-- tests/
|       |   |-- requirements.txt
|       |   |-- Dockerfile
|       |
|       |-- assistant_service/        # AI assistant (RAG-based LLM)
|       |   |-- app/
|       |   |-- models/
|       |   |-- tests/
|       |   |-- requirements.txt
|       |   |-- Dockerfile
|       |
|       |-- price_estimator/          # Dynamic pricing engine
|       |   |-- app/
|       |   |-- models/
|       |   |-- tests/
|       |   |-- requirements.txt
|       |   |-- Dockerfile
|       |
|       |-- fraud_detection/          # Fraud detection pipeline
|           |-- app/
|           |-- models/
|           |-- tests/
|           |-- requirements.txt
|           |-- Dockerfile
|
|-- infrastructure/
|   |-- terraform/
|   |   |-- environments/
|   |   |   |-- dev/
|   |   |   |-- staging/
|   |   |   |-- prod/
|   |   |-- modules/
|   |   |   |-- networking/
|   |   |   |-- compute/
|   |   |   |-- database/
|   |   |   |-- kubernetes/
|   |   |   |-- monitoring/
|   |   |-- main.tf
|   |   |-- variables.tf
|   |   |-- outputs.tf
|   |
|   |-- kubernetes/
|   |   |-- namespaces/
|   |   |-- deployments/
|   |   |-- services/
|   |   |-- configmaps/
|   |   |-- secrets/
|   |   |-- helm/
|   |
|   |-- docker/
|   |   |-- Dockerfile.api_gateway
|   |   |-- Dockerfile.auth_service
|   |   |-- docker-compose.yml
|   |   |-- docker-compose.dev.yml
|   |
|   |-- monitoring/
|       |-- prometheus/
|       |-- grafana/
|       |-- alertmanager/
|       |-- loki/
|
|-- .github/
|   |-- workflows/
|   |   |-- ci.yml                   # Continuous Integration
|   |   |-- cd.yml                   # Continuous Deployment
|   |   |-- pr-check.yml             # PR validation checks
|   |   |-- security-scan.yml        # Security vulnerability scanning
|   |   |-- release.yml              # Release automation
|   |   |-- dependency-review.yml    # Dependency review on PRs
|   |   |-- codeql-analysis.yml      # CodeQL static analysis
|   |
|   |-- CODEOWNERS                    # Code ownership definitions
|   |-- PULL_REQUEST_TEMPLATE.md      # PR template
|   |-- dependabot.yml                # Dependency update configuration
|
|-- docs/
|   |-- adr/                          # Architecture Decision Records
|   |   |-- ADR-001-use-monorepo.md
|   |   |-- ADR-002-use-melos.md
|   |   |-- ADR-003-adopt-flutter.md
|   |   |-- README.md
|   |
|   |-- rfcs/                         # Request for Comments
|   |   |-- RFC-001-ai-matching.md
|   |   |-- RFC-002-offline-mode.md
|   |   |-- RFC-003-payment-flow.md
|   |   |-- README.md
|   |
|   |-- api/                          # API documentation
|   |   |-- openapi/
|   |   |-- postman/
|   |   |-- changelog.md
|   |
|   |-- architecture/                 # Architecture documentation
|   |   |-- system-architecture.md
|   |   |-- data-flow.md
|   |   |-- security-architecture.md
|   |   |-- deployment-architecture.md
|   |
|   |-- runbooks/                     # Operational runbooks
|       |-- incident-response.md
|       |-- database-migration.md
|       |-- scaling-playbook.md
|       |-- disaster-recovery.md
|
|-- tools/
|   |-- code_generators/              # Code generation scripts
|   |   |-- feature_generator.dart
|   |   |-- model_generator.dart
|   |
|   |-- scripts/                      # Utility scripts
|   |   |-- setup.sh
|   |   |-- lint_all.sh
|   |   |-- test_all.sh
|   |
|   |-- migration/                    # Data migration tools
|       |-- db_migration.py
|
|-- security/
|   |-- policies/
|   |-- audits/
|   |-- compliance/
|
|-- melos.yaml                        # Melos monorepo configuration
|-- pubspec.yaml                      # Root workspace pubspec (Flutter)
|-- .gitignore
|-- .pre-commit-config.yaml
|-- .editorconfig
|-- linter.yaml
|-- README.md
|-- CONTRIBUTING.md
|-- LICENSE
```

---

### 11.9 Auditing

#### Automatic Timestamps

Every table has `created_at` and `updated_at` columns that are managed automatically:

```sql
-- Trigger function for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language "plpgsql";

-- Apply to all tables
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mechanics_updated_at
    BEFORE UPDATE ON mechanics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

#### Audit Log Table

```sql
CREATE TABLE audit_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name      VARCHAR(255) NOT NULL,
    record_id       UUID NOT NULL,
    action          VARCHAR(20) NOT NULL
                    CHECK (action IN ('CREATE', 'UPDATE', 'DELETE', 'SOFT_DELETE', 'RESTORE')),
    old_values      JSONB,
    new_values      JSONB,
    changed_fields  TEXT[],
    performed_by    UUID,
    ip_address      INET,
    user_agent      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_audit_log_user
        FOREIGN KEY (performed_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_audit_log_table_record ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_log_created_at ON audit_log(created_at DESC);
CREATE INDEX idx_audit_log_performed_by ON audit_log(performed_by);
```

#### Application-Level Auditing

```python
import json
from app.models import AuditLog
from app.db.session import AsyncSession

async def log_change(
    db: AsyncSession,
    table_name: str,
    record_id: str,
    action: str,
    old_values: dict | None,
    new_values: dict | None,
    performed_by: str | None = None,
    ip_address: str | None = None,
    user_agent: str | None = None,
) -> None:
    audit_entry = AuditLog(
        table_name=table_name,
        record_id=record_id,
        action=action,
        old_values=old_values,
        new_values=new_values,
        changed_fields=list(
            set(list(new_values.keys()) if new_values else []) |
            set(list(old_values.keys()) if old_values else [])
        ) if old_values or new_values else None,
        performed_by=performed_by,
        ip_address=ip_address,
        user_agent=user_agent,
    )
    db.add(audit_entry)
```

---

### 11.10 Performance

#### Query Optimization Rules

1. **Always run EXPLAIN ANALYZE before deploying a new query.**
2. **Never SELECT * – Always specify required columns.**
3. **Use connection pooling** – Configure PgBouncer or use SQLAlchemy\\'s built-in pooling.
4. **Use read replicas** for reporting, analytics, and read-heavy endpoints.
5. **Set appropriate `work_mem`** for sort/hash operations.
6. **Vacuum and analyze** regularly (auto-vacuum enabled).
7. **Use LIMIT on all list queries** – Never return unbounded result sets.
8. **Index bitmap scans** for complex multi-column filters.
9. **Avoid LIKE '%text%'** – Use pg_trgm GIN indexes for fuzzy text search.
10. **Use EXISTS instead of COUNT(*)** for existence checks.

#### Connection Pooling Configuration

```python
# app/db/session.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from app.core.config import settings

engine = create_async_engine(
    settings.database_url,
    pool_size=20,
    max_overflow=10,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=False,
)

AsyncSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
```

#### Read Replica Strategy

```python
# app/db/session.py
read_engine = create_async_engine(
    settings.database_read_url,
    pool_size=30,
    max_overflow=15,
    pool_pre_ping=True,
    pool_recycle=3600,
)

ReadSessionLocal = async_sessionmaker(read_engine, class_=AsyncSession, expire_on_commit=False)
```

```python
# Usage in endpoints
@router.get("/bookings")
async def list_bookings(
    db: AsyncSession = Depends(get_read_session),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(BookingRequest).where(BookingRequest.user_id == current_user.id)
    )
    return result.scalars().all()
```

---

## 12. Security Standards

### 12.1 Authentication

#### JWT-Based Authentication

Mecha Connect uses **asymmetric JWT** (RS256) for authentication:

- **Access Token**: Short-lived (15 minutes), contains user ID, role, and session ID.
- **Refresh Token**: Long-lived (7 days), rotating, stored in HTTP-only secure cookie.
- **Public/Private Key Pair**: Generated per environment, stored in Vault.

```python
# app/core/security.py
from datetime import datetime, timedelta, timezone
from jose import jwt, JWTError
from app.core.config import settings
import uuid

ALGORITHM = "RS256"

def create_access_token(user_id: str, role: str) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": user_id,
        "role": role,
        "iat": now,
        "exp": now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
        "type": "access",
        "jti": str(uuid.uuid4()),
    }
    return jwt.encode(payload, settings.JWT_PRIVATE_KEY, algorithm=ALGORITHM)

def create_refresh_token(user_id: str) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": user_id,
        "iat": now,
        "exp": now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        "type": "refresh",
        "jti": str(uuid.uuid4()),
    }
    return jwt.encode(payload, settings.JWT_PRIVATE_KEY, algorithm=ALGORITHM)

def decode_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, settings.JWT_PUBLIC_KEY, algorithms=[ALGORITHM])
        return payload
    except JWTError as e:
        raise AuthenticationError(f"Invalid token: {e}")
```

#### Token Refresh Flow

```mermaid
sequenceDiagram
    participant C as Client
    participant API as FastAPI
    participant DB as Database

    C->>API: POST /auth/login (email, password)
    API->>DB: Verify credentials
    DB-->>API: User found
    API-->>C: { access_token, refresh_token (httpOnly cookie) }

    Note over C,API: Access token expires after 15 min

    C->>API: GET /protected (access_token in header)
    API-->>C: 401 Unauthorized (token expired)

    C->>API: POST /auth/refresh (refresh_token cookie)
    API->>API: Verify refresh token
    API->>DB: Rotate old refresh token
    API-->>C: { access_token, new refresh_token }

    C->>API: GET /protected (new access_token)
    API-->>C: 200 OK
```

```python
@router.post("/auth/refresh")
async def refresh_token(
    request: Request,
    response: Response,
    db: AsyncSession = Depends(get_db),
):
    refresh_token = request.cookies.get("refresh_token")
    if not refresh_token:
        raise HTTPException(status_code=401, detail="Refresh token required")

    payload = decode_token(refresh_token)
    if payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid token type")

    stored = await db.execute(
        select(RefreshToken).where(
            RefreshToken.jti == payload["jti"],
            RefreshToken.is_revoked == False,
        )
    )
    if not stored.scalar_one_or_none():
        raise HTTPException(status_code=401, detail="Token revoked or reused")

    await revoke_refresh_token(db, payload["jti"])

    user_id = payload["sub"]
    new_access = create_access_token(user_id=user_id, role=...)
    new_refresh = create_refresh_token(user_id=user_id)

    db.add(RefreshToken(jti=decode_token(new_refresh)["jti"], user_id=user_id))

    response.set_cookie(
        key="refresh_token",
        value=new_refresh,
        httponly=True,
        secure=True,
        samesite="strict",
        max_age=7 * 24 * 3600,
    )

    return {"access_token": new_access, "token_type": "bearer"}
```

---

## 20. Engineering Metrics

### 20.1 Velocity

| Aspect | Value |
|--------|-------|
| Definition | Story points or tickets completed per sprint |
| Target | 80-120% of committed velocity per sprint |
| Measurement | Sum of completed story points at sprint end (Jira filter: resolved = true, sprint = current) |
| Frequency | Per sprint (bi-weekly) |
| Owner | Engineering Manager |
| Tool | Jira Sprint Report, Velocity Chart |

Velocity is a planning tool, not a performance metric. Use historical velocity (last 3-5 sprints) for capacity planning.

### 20.2 Cycle Time

| Aspect | Value |
|--------|-------|
| Definition | Time from first commit to deployment to production |
| Target | < 24 hours for PATCH, < 3 days for MINOR, < 2 weeks for MAJOR |
| Measurement | Git log: first commit timestamp to merge-to-main timestamp + deployment time |
| Frequency | Per PR |
| Owner | Individual engineer + Team |
| Tool | Git analytics (Linear, CodeClimate, custom dashboard) |

**Breakdown:**
- Coding time: first commit to PR opened
- Review time: PR opened to first review (target: < 4 hours)
- Rework time: review comments to final approval
- Merge-to-deploy: merge to production deployment (target: < 1 hour)

### 20.3 Lead Time

| Aspect | Value |
|--------|-------|
| Definition | Time from ticket creation to deployment to production |
| Target | < 1 week for PATCH, < 2 weeks for MINOR, < 1 month for MAJOR |
| Measurement | Jira: created date to resolution date for tickets in Done |
| Frequency | Per sprint |
| Owner | Product + Engineering |
| Tool | Jira Control Chart, Cycle Time scatter plot |

Lead time includes all stages: backlog refinement, sprint planning, development, review, testing, deployment.

### 20.4 Deployment Frequency

| Aspect | Value |
|--------|-------|
| Definition | Number of production deployments per time period |
| Target | Multiple times per day (CI/CD maturity: daily or more) |
| Measurement | Count of successful production deployments per week |
| Frequency | Weekly review |
| Owner | DevOps / Release Manager |
| Tool | CI/CD pipeline metrics, Release dashboard |

### 20.5 MTTR (Mean Time to Recovery)

| Aspect | Value |
|--------|-------|
| Definition | Average time from incident detection to full recovery |
| Target | < 30 minutes for SEV1, < 2 hours for SEV2 |
| Measurement | Incident end time minus incident start time, averaged over last 10 incidents |
| Frequency | Per incident, reviewed monthly |
| Owner | SRE / On-call team |
| Tool | PagerDuty / OpsGenie incident analytics |

**How to improve MTTR:**
- Automate rollback procedures
- Improve monitoring and alerting quality
- Run regular chaos engineering exercises
- Document runbooks for common failure scenarios
- Practice incident response with game days

### 20.6 Defect Rate

| Aspect | Value |
|--------|-------|
| Definition | Percentage of tickets that are bugs found in production |
| Target | < 5% of all tickets opened as production bugs |
| Measurement | (Bug tickets from production) / (Total tickets) * 100 |
| Frequency | Per sprint |
| Owner | QA + Engineering Manager |
| Tool | Jira issue type breakdown, bug tracking dashboard |

**Severity breakdown:**
- SEV1/SEV2 defects: target 0 per release
- SEV3 defects: target < 3 per release
- Escaped defects (missed by testing): target < 1 per release

### 20.7 Coverage

| Aspect | Value |
|--------|-------|
| Definition | Percentage of code covered by automated tests |
| Target | >= 80% line coverage for all new code, >= 70% overall |
| Measurement | Code coverage tooling (Coveralls, CodeCov, SonarQube) |
| Frequency | Per PR, per sprint |
| Owner | Individual engineer |
| Tool | Coverage reporting in CI pipeline |

**Coverage by layer:**
- Unit tests: >= 85%
- Integration tests: >= 70% of critical paths
- Widget/UI tests: >= 60% of screens
- E2E tests: all critical user journeys

### 20.8 AI Accuracy

| Aspect | Value |
|--------|-------|
| Definition | Percentage of AI model outputs that meet quality criteria |
| Target | > 90% accuracy on evaluation dataset |
| Measurement | Automated eval pipeline comparing model outputs to ground truth |
| Frequency | Per model deployment, daily monitoring |
| Owner | AI/ML Team |
| Tool | Custom eval framework, MLflow, Weights & Biases |

**AI-specific metrics to track:**
| Metric | Description | Target |
|--------|-------------|--------|
| Accuracy | Exact match or acceptable match | > 90% |
| Hallucination Rate | Fabricated information in output | < 5% |
| Relevance | Output addresses the user query | > 95% |
| Latency P95 | Time to generate response | < 3s |
| Cost per Request | $ per inference | Within budget |
| User Satisfaction | User feedback / thumbs up/down | > 85% |
| Fallback Rate | When model fails, uses fallback | < 2% |
| Toxicity Score | Harmful content detection | < 0.1% |

---

## 21. Engineering Checklists

### 21.1 New Feature Checklist

- [ ] Feature request filed and approved (linked JIRA/Linear ticket)
- [ ] RFC written and reviewed (if significant architectural change)
- [ ] Acceptance criteria defined and reviewed with Product
- [ ] Design mockups reviewed (Figma) and approved
- [ ] Technical design document created (if needed)
- [ ] Database schema changes reviewed and migration planned
- [ ] API contracts defined and agreed with consumers
- [ ] Feature flag created and implemented
- [ ] Unit tests written (>= 85% coverage for new code)
- [ ] Integration tests written
- [ ] E2E tests written for critical user journey
- [ ] Performance impact assessed (latency, throughput)
- [ ] Security review completed
- [ ] Documentation updated (API docs, README, user guide)
- [ ] Analytics events added for business metrics
- [ ] Accessibility review completed
- [ ] Error handling and logging implemented
- [ ] Rollback plan documented
- [ ] QA sign-off obtained
- [ ] Product owner sign-off obtained

### 21.2 Bug Fix Checklist

- [ ] Bug report verified and reproducible
- [ ] Root cause identified and documented
- [ ] Unit test written that reproduces the bug
- [ ] Fix applied and all existing tests pass
- [ ] Bug-specific test preserved to prevent regression
- [ ] Integration/E2E test added if bug affects critical path
- [ ] Edge cases considered (empty state, error state, boundary conditions)
- [ ] Logging improved if bug was hard to diagnose
- [ ] Monitoring/alerting added if bug could recur silently
- [ ] No new technical debt introduced
- [ ] Changelog entry added (for user-facing bugs)
- [ ] Bug closed and linked to fix commit

### 21.3 Release Checklist

- [ ] All PRs merged to release branch
- [ ] CI/CD pipeline green (lint, test, build, security)
- [ ] Test coverage threshold met
- [ ] Changelog updated and reviewed
- [ ] Version bumped in all required files
- [ ] Git tag created
- [ ] Release notes written and reviewed
- [ ] Database migrations tested (up and down)
- [ ] Feature flags configured correctly
- [ ] Canary deployment planned
- [ ] Monitoring dashboards reviewed
- [ ] On-call team notified
- [ ] Rollback plan documented
- [ ] Stakeholders notified
- [ ] Deployment window confirmed

### 21.4 Security Checklist

- [ ] Input validation on all user inputs
- [ ] Authentication on all protected routes
- [ ] Authorization checks for all permission-sensitive operations
- [ ] Rate limiting on public endpoints
- [ ] HTTPS enforced (HSTS header)
- [ ] CSP headers configured
- [ ] CORS configured correctly
- [ ] SQL injection prevention (parameterized queries)
- [ ] No secrets in code or logs
- [ ] Dependency scan clean (no critical CVEs)
- [ ] SAST scan clean
- [ ] DAST scan clean (for web endpoints)
- [ ] File upload validation (type, size, scan)
- [ ] Session management (secure cookies, timeout, rotation)
- [ ] Audit logging for security-relevant events

### 21.5 Performance Checklist

- [ ] N+1 queries checked and resolved
- [ ] Database indexes reviewed (EXPLAIN ANALYZE on new queries)
- [ ] API response size minimized (field selection, pagination)
- [ ] Caching strategy implemented (where applicable)
- [ ] Async/non-blocking code verified
- [ ] Resource cleanup confirmed (connections, streams, file handles)
- [ ] Memory usage profiled (no leaks)
- [ ] CPU usage profiled (no hot loops)
- [ ] Bundle/asset size optimized
- [ ] Lazy loading implemented (where appropriate)
- [ ] Network requests minimized and batched
- [ ] CDN strategy applied (static assets)
- [ ] Load testing results reviewed
- [ ] Performance budget not exceeded

### 21.6 Documentation Checklist

- [ ] Public API documented (OpenAPI/Swagger)
- [ ] README updated (if applicable)
- [ ] Inline code comments clear (why, not what)
- [ ] Architecture Decision Record updated (if applicable)
- [ ] User-facing documentation updated
- [ ] Runbook/deployment guide updated (if applicable)
- [ ] Changelog entry added
- [ ] Internal wiki/Notion updated
- [ ] On-call runbook updated (if applicable)
- [ ] README badges updated (coverage, build status)
- [ ] API example requests/responses documented
- [ ] Environment variables documented
- [ ] Setup instructions verified (for new team members)

### 21.7 AI Feature Checklist

- [ ] Prompt template versioned and stored in codebase
- [ ] Model output parsed with structured parsing (Pydantic)
- [ ] Fallback behavior defined (model failure, timeout, invalid output)
- [ ] Token usage tracked and budgeted
- [ ] Latency budget respected (streaming toggle available)
- [ ] Prompt injection protection implemented
- [ ] PII/PHI filter applied to inputs
- [ ] Output safety filter applied (toxicity, hallucination)
- [ ] A/B test framework integrated
- [ ] Cost per inference calculated
- [ ] Model version pinned, not floating
- [ ] Evaluation dataset updated
- [ ] Monitoring dashboard created (accuracy, latency, cost)
- [ ] User feedback loop implemented
- [ ] Rate limiting applied

### 21.8 Flutter Feature Checklist

- [ ] State management pattern followed (BLoC/Riverpod)
- [ ] Widget rebuilds minimized (const constructors)
- [ ] Platform-specific code isolated (platform channels)
- [ ] Responsive layout tested on multiple screen sizes
- [ ] Accessibility labels added
- [ ] Dark mode and theming implemented
- [ ] Localization-ready (strings in ARB files)
- [ ] Form validation implemented
- [ ] Error handling with user-friendly messages
- [ ] Loading states and empty states handled
- [ ] Animations performant (no jank, shader warm-up)
- [ ] Unit tests for business logic
- [ ] Widget tests for UI components
- [ ] Integration tests for critical flows
- [ ] App size optimized (tree-shaking, asset compression)
- [ ] Platform-specific testing (iOS and Android)

### 21.9 Backend Feature Checklist

- [ ] RESTful conventions followed
- [ ] Pydantic models used for request/response validation
- [ ] Database session management correct
- [ ] Background tasks use proper queue (Celery)
- [ ] Async endpoints use async/await throughout
- [ ] Custom exception classes and error handlers
- [ ] Logging with proper levels (debug/info/warn/error)
- [ ] Metrics emitted for business and system health
- [ ] Health check endpoint included
- [ ] OpenAPI/Swagger docs generated and accurate
- [ ] CORS, CSRF, security headers configured
- [ ] Rate limiting applied
- [ ] Database migrations reviewed
- [ ] Integration tests for all endpoints
- [ ] Performance benchmarked (latency, throughput)

---

## 22. Templates

### 22.1 Issue Template (Bug Report)

`markdown
---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

## Description
{A clear and concise description of the bug}

## Steps to Reproduce
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

## Expected Behavior
{What you expected to happen}

## Actual Behavior
{What actually happened}

## Screenshots / Screen Recordings
{If applicable, add screenshots to help explain your problem}

## Environment
- Device: {e.g., iPhone 15, Pixel 8}
- OS: {e.g., iOS 18.0, Android 14}
- App Version: {e.g., 2.1.0}
- Browser (if web): {e.g., Chrome 120}

## Logs / Stack Trace
`
{Paste relevant logs here}
`

## Severity
- [ ] SEV1 (Critical - service outage)
- [ ] SEV2 (High - major feature broken)
- [ ] SEV3 (Medium - minor feature broken)
- [ ] SEV4 (Low - cosmetic issue)

## Additional Context
{Add any other context about the problem here}
`

### 22.2 Bug Template

`markdown
## Bug Summary
{One-line summary}

## Product Area
{Which module/feature}

## Build / Version
{Where it was found}

## Root Cause
{Filled in after diagnosis}

## Fix
{Filled in after fix applied}

## Verification Steps
1. {How to verify the fix}
2. {Step 2}
3. {Step 3}

## Related Issues / PRs
- #{issue-number}
- PR #{pr-number}
`

### 22.3 Feature Request

`markdown
---
name: Feature Request
about: Suggest an idea for this project
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

## Problem Statement
{What problem does this feature solve?}

## Proposed Solution
{What do you want to happen?}

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Alternatives Considered
{What alternatives have you considered?}

## User Impact
{Who will benefit from this feature?}

## Business Value
{How does this align with business goals?}

## Additional Context
{Add any other context, mockups, or references}
`

### 22.4 RFC Template (Full Markdown)

`markdown
# RFC: {Title}

- **Status:** {Draft / Review / Final Comment / Approved / Rejected}
- **Author:** {Name}
- **Date:** {YYYY-MM-DD}
- **PR:** #{PR-number}

## Summary
{One paragraph summary}

## Motivation
{Why is this change needed? What problem does it solve?}

## Design
{Detailed technical design}

### Architecture
{Diagrams, component breakdown, data flow}

### API Changes
{New/modified endpoints, request/response schemas}

### Database Changes
{New tables, columns, indexes, migrations}

### UI Changes
{Screenshots or descriptions of UI modifications}

## Alternatives Considered
{What other approaches were evaluated and why were they rejected?}

## Open Questions
{Questions that need resolution during the review period}

## Risks and Mitigations
{Risks and how they will be addressed}

## Migration Plan
{How will existing users/data be migrated?}

## Rollback Plan
{How to revert if things go wrong}

## Timeline
{Estimated implementation timeline}

## References
{Links to relevant docs, issues, PRs}
`

### 22.5 ADR Template (Full Markdown)

`markdown
# ADR-{NNNN}: {Title}

- **Status:** {Proposed / Accepted / Deprecated / Superseded}
- **Date:** {YYYY-MM-DD}
- **Deciders:** {List of decision makers}
- **Related ADRs:** {ADR-NNNN, ADR-NNNN}

## Context
{What is the issue motivating this decision?}

## Decision
{What decision was made and why?}

## Consequences
{What becomes easier or harder as a result?}

## Pros of the Decision
- {Pro 1}
- {Pro 2}

## Cons of the Decision
- {Con 1}
- {Con 2}

## Alternatives Considered
| Option | Description | Why Rejected |
|--------|-------------|-------------|
| {Option 1} | {Brief description} | {Reason rejected} |
| {Option 2} | {Brief description} | {Reason rejected} |

## References
{Links to relevant docs, tools, articles}
`

### 22.6 PR Template

Refer to **Section 5 - Pull Request Standards** for the complete PR template and guidelines.

### 22.7 Sprint Template

`markdown
# Sprint {Number}: {Theme/Name}

**Duration:** {Start Date} - {End Date} ({N} weeks)

## Sprint Goal
{One sentence describing what this sprint aims to achieve}

## Team Capacity
- Total available hours: {N}
- Planned velocity: {N} story points
- Team members: {List of members}

## Sprint Backlog

### Must Have (P0)
- [ ] {Ticket} - {Description}
- [ ] {Ticket} - {Description}

### Should Have (P1)
- [ ] {Ticket} - {Description}
- [ ] {Ticket} - {Description}

### Nice to Have (P2)
- [ ] {Ticket} - {Description}

## Risks
- {Risk 1}
- {Risk 2}

## Dependencies
- {Dependency 1}
- {Dependency 2}
`

### 22.8 Retrospective Template

`markdown
# Sprint {Number} Retrospective

**Date:** {YYYY-MM-DD}
**Facilitator:** {Name}
**Participants:** {List}

## Sprint Stats
- Completed: {N} story points / {N} committed
- Bugs found in production: {N}
- Cycle time (average): {N} hours
- Deployment frequency: {N} times

## What Went Well
- {Point 1}
- {Point 2}
- {Point 3}

## What Could Be Improved
- {Point 1}
- {Point 2}
- {Point 3}

## Action Items
| Action Item | Owner | Due Date |
|-------------|-------|----------|
| {Action} | {Owner} | {Date} |
| {Action} | {Owner} | {Date} |

## Start / Stop / Continue
- **Start:** {Something to start doing}
- **Stop:** {Something to stop doing}
- **Continue:** {Something to continue doing}

## Team Health
- Morale: {1-5}
- Communication: {1-5}
- Productivity: {1-5}

## Happiness Metric
{How happy is the team on a scale of 1-5 with commentary}
`

### 22.9 Meeting Notes Template

`markdown
# {Meeting Title}

**Date:** {YYYY-MM-DD}
**Time:** {HH:MM} - {HH:MM}
**Location:** {Physical room / Zoom link}
**Facilitator:** {Name}
**Attendees:** {List}

## Agenda
1. {Agenda item 1}
2. {Agenda item 2}
3. {Agenda item 3}

## Discussion Notes

### {Agenda Item 1}
- {Discussion point}
- {Decision made}

### {Agenda Item 2}
- {Discussion point}
- {Decision made}

## Action Items
| Owner | Item | Due Date |
|-------|------|----------|
| {Name} | {Action} | {Date} |

## Next Meeting
**Date:** {YYYY-MM-DD}
**Agenda Preview:** {Topics for next time}

---
*Notes by {Note taker name}*
`

### 22.10 Design Review Template

`markdown
# Design Review: {Feature/Component Name}

**Date:** {YYYY-MM-DD}
**Reviewer:** {Name}
**Author:** {Name}

## Overview
{Brief description of the design being reviewed}

## Design Documents
- {Link to Figma / design doc / RFC}
- {Link to technical specification}

## Review Checklist

### Functional Correctness
- [ ] Does the design solve the stated problem?
- [ ] Are all edge cases handled?
- [ ] Is error handling addressed?

### Technical Soundness
- [ ] Does the design follow existing patterns?
- [ ] Is the architecture clean and maintainable?
- [ ] Are dependencies properly managed?

### Performance
- [ ] Are there performance concerns?
- [ ] Is caching considered where appropriate?
- [ ] Are database queries optimized?

### Security
- [ ] Are there security implications?
- [ ] Is input/output sanitization handled?
- [ ] Are authentication/authorization checks in place?

### UX
- [ ] Is the user experience intuitive?
- [ ] Are loading/empty/error states handled?
- [ ] Is accessibility considered?

## Feedback
{Reviewer's feedback, organized by category}

## Decisions
| Decision | Rationale |
|----------|-----------|
| {Decision} | {Rationale} |

## Approval
- [ ] Approved (no changes needed)
- [ ] Approved with conditions (changes requested, minor)
- [ ] Changes required (re-review needed)
- [ ] Rejected (design needs fundamental rework)
`



#### Biometric Auth on Mobile

- iOS: Uses `LocalAuthentication` framework (Face ID / Touch ID).
- Android: Uses `BiometricPrompt` API.
- Mobile stores a **device-specific key** in Keychain (iOS) / Keystore (Android) to sign a server challenge for re-authentication.
- Biometric auth only works for **re-authentication** (not initial login).

#### OTP Verification

- Uses **Twilio Verify API** for SMS OTP.
- OTP length: 6 digits. Expiry: 5 minutes.
- Max 5 attempts before lockout (10 min cooldown).
- Rate limit: 1 OTP per 60 seconds per phone.

```python
# app/services/otp.py
from twilio.rest import Client
from app.core.config import settings

twilio_client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)

async def send_otp(phone_number: str) -> dict:
    verification = twilio_client.verify.v2.services(
        settings.TWILIO_VERIFY_SID
    ).verifications.create(to=phone_number, channel="sms")
    return {"sid": verification.sid, "status": verification.status}

async def verify_otp(phone_number: str, code: str) -> bool:
    verification_check = twilio_client.verify.v2.services(
        settings.TWILIO_VERIFY_SID
    ).verification_checks.create(to=phone_number, code=code)
    return verification_check.status == "approved"
```

---

### 12.2 Authorization (RBAC)

#### Role Hierarchy

```
SuperAdmin (role_level: 100)
    |
    +-- Admin (role_level: 50)
    |       |
    |       +-- Mechanic (role_level: 20)
    |       |
    |       +-- Customer (role_level: 10)
```

| Role | Level | Description |
|------|-------|-------------|
| `customer` | 10 | End user requesting roadside assistance |
| `mechanic` | 20 | Service provider accepting jobs |
| `admin` | 50 | Internal operations staff, support |
| `super_admin` | 100 | Engineering leadership, system config |

#### Permission Matrix

| Resource | Customer | Mechanic | Admin | SuperAdmin |
|----------|----------|----------|-------|------------|
| Create booking | + | - | + | + |
| View own bookings | + | + | + | + |
| View all bookings | - | - | + | + |
| Cancel booking | + | - | + | + |
| Create review | + | - | - | - |
| View earnings | - | + | + | + |
| Manage users | - | - | + | + |
| Manage mechanics | - | - | + | + |
| Manage payments | - | - | + | + |
| View audit log | - | - | + | + |
| System config | - | - | - | + |
| Manage admins | - | - | - | + |

#### FastAPI Dependency for Role Checking

```python
# app/api/deps.py
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.security import decode_token
from app.models import User

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> User:
    payload = decode_token(credentials.credentials)
    if payload.get("type") != "access":
        raise HTTPException(status_code=401, detail="Invalid token type")
    user = await db.get(User, payload["sub"])
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="User not found or inactive")
    return user


def require_role(required_role: str):
    ROLE_LEVELS = {"customer": 10, "mechanic": 20, "admin": 50, "super_admin": 100}

    async def role_checker(current_user: User = Depends(get_current_user)) -> User:
        user_level = ROLE_LEVELS.get(current_user.role, 0)
        required_level = ROLE_LEVELS.get(required_role, 0)
        if user_level < required_level:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Role '{required_role}' or higher required. "
                       f"Current role: '{current_user.role}'",
            )
        return current_user

    return role_checker


def require_any_role(*roles: str):
    async def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"One of {roles} required. Current role: '{current_user.role}'",
            )
        return current_user

    return role_checker
```

```python
# Usage in endpoints
@router.get("/me")
async def get_profile(user: User = Depends(get_current_user)):
    return user

@router.get("/admin/bookings")
async def list_all_bookings(
    user: User = Depends(require_role("admin")),
    db: AsyncSession = Depends(get_db),
):
    bookings = await db.execute(select(BookingRequest))
    return bookings.scalars().all()

@router.post("/mechanics/onboard")
async def onboard_mechanic(
    user: User = Depends(require_any_role("admin", "super_admin")),
    db: AsyncSession = Depends(get_db),
):
    ...
```

---

### 12.3 Secrets Management

#### Never Commit Secrets

- **No secrets in code** – API keys, database URLs, JWT keys never appear in source files.
- **No secrets in Dockerfiles** – Use build args or Docker secrets.
- **No secrets in CI logs** – GitHub Actions automatically masks secrets.
- **No hardcoded test secrets** – Use environment variables in CI.

#### Environment Variables

```bash
# .env.example (committed to repo - contains placeholder values)
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/mechanect_dev
REDIS_URL=redis://localhost:6379/0
JWT_PRIVATE_KEY_PATH=/run/secrets/jwt_private.pem
JWT_PUBLIC_KEY_PATH=/run/secrets/jwt_public.pem
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
PINECONE_API_KEY=
SENTRY_DSN=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_S3_BUCKET=
```

#### Pydantic Settings

```python
# app/core/config.py
from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    app_name: str = "Mecha Connect"
    environment: str = "development"
    debug: bool = False

    database_url: str
    database_read_url: str | None = None
    redis_url: str = "redis://localhost:6379/0"

    jwt_private_key: str = ""
    jwt_public_key: str = ""
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 7

    stripe_secret_key: str = ""
    stripe_webhook_secret: str = ""
    twilio_account_sid: str = ""
    twilio_auth_token: str = ""

    aws_access_key_id: str = ""
    aws_secret_access_key: str = ""
    aws_s3_bucket: str = ""

    pinecone_api_key: str = ""
    sentry_dsn: str = ""

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "case_sensitive": False,
    }

@lru_cache
def get_settings() -> Settings:
    return Settings()
```

#### Vault / Secret Manager

- **Production**: AWS Secrets Manager for all secrets.
- **Staging**: AWS Secrets Manager with a separate path (`/staging/`).
- **Local development**: `.env` file (gitignored).
- **CI/CD**: GitHub Actions secrets.
- **Rotation**: Automatic rotation enabled for database credentials (30 days).

#### .gitignore Rules

```gitignore
.env
.env.local
.env.*.local
*.pem
!public.pem
secrets/
aws-credentials/
```

---

### 12.4 Encryption

| Scope | Algorithm | Standard |
|-------|-----------|----------|
| Transit | TLS 1.3 | HTTPS, WSS |
| Data at Rest (DB) | AES-256 | PostgreSQL TDE / EBS encryption |
| Passwords | bcrypt (cost=12) | passlib.context.CryptContext |
| PII fields | AES-256-GCM | Field-level encryption |
| JWTs | RS256 | Asymmetric signing |
| API Keys | bcrypt (stored hash only) | - |

#### Password Hashing

```python
# app/core/security.py
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)
```

#### Field-Level Encryption for PII

```python
# app/core/encryption.py
from cryptography.fernet import Fernet
from app.core.config import settings

fernet = Fernet(settings.FIELD_ENCRYPTION_KEY)

def encrypt_field(value: str) -> str:
    return fernet.encrypt(value.encode()).decode()

def decrypt_field(encrypted_value: str) -> str:
    return fernet.decrypt(encrypted_value.encode()).decode()
```

```python
# Custom SQLAlchemy type
from sqlalchemy import String, TypeDecorator

class EncryptedString(TypeDecorator):
    impl = String

    def process_bind_param(self, value, dialect):
        if value is not None:
            return encrypt_field(value)
        return value

    def process_result_value(self, value, dialect):
        if value is not None:
            return decrypt_field(value)
        return value

# Usage in model
class User(Base):
    __tablename__ = "users"
    phone_number = Column(EncryptedString(255), nullable=False)
    email = Column(EncryptedString(255), nullable=False)
```

---

### 12.5 Rate Limiting

#### Strategy

| Scope | Limit | Window | Applied To |
|-------|-------|--------|------------|
| Per user | 100 req/min | 1 min | All authenticated endpoints |
| Per IP | 20 req/min | 1 min | Auth endpoints (login, register) |
| Per endpoint | 5 req/min | 1 min | OTP send |
| Per endpoint | 10 req/5min | 5 min | Password reset |
| Global | 1000 req/min | 1 min | Entire API |

#### Implementation with Redis + FastAPI

```python
# app/core/rate_limit.py
import time
from fastapi import Request, HTTPException, Depends
from redis import asyncio as aioredis
from app.core.config import settings

redis_client = aioredis.from_url(settings.redis_url, decode_responses=True)

async def rate_limit(
    request: Request,
    key: str,
    max_requests: int,
    window_seconds: int,
) -> None:
    now = time.time()
    window_start = now - window_seconds

    pipeline = redis_client.pipeline()
    pipeline.zremrangebyscore(key, 0, window_start)
    pipeline.zcard(key)
    pipeline.zadd(key, {f"{request.client.host}:{now}": now})
    pipeline.expire(key, window_seconds)

    _, count, _, _ = await pipeline.execute()

    if count >= max_requests:
        raise HTTPException(
            status_code=429,
            detail=f"Rate limit exceeded. Max {max_requests} requests per {window_seconds}s.",
            headers={"Retry-After": str(window_seconds)},
        )


class RateLimiter:
    def __init__(self, max_requests: int, window_seconds: int, key_prefix: str = "rl"):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.key_prefix = key_prefix

    async def __call__(self, request: Request):
        user_id = getattr(request.state, "user_id", None)
        if user_id:
            key = f"{self.key_prefix}:user:{user_id}"
        else:
            key = f"{self.key_prefix}:ip:{request.client.host}"
        await rate_limit(request, key, self.max_requests, self.window_seconds)


# Usage
@router.post("/auth/login")
async def login(
    credentials: LoginRequest,
    _: None = Depends(RateLimiter(max_requests=20, window_seconds=60)),
    db: AsyncSession = Depends(get_db),
):
    ...

@router.post("/auth/send-otp")
async def send_otp(
    phone: OTPRequest,
    _: None = Depends(RateLimiter(max_requests=5, window_seconds=60)),
):
    ...
```

### 3.3 Folder Naming Conventions

| Type | Convention | Example | Valid | Invalid |
|------|-----------|---------|-------|---------|
| Directories | `snake_case` | `feature_payments/` | `auth_service/` | `auth-service/`, `AuthService/` |
| Dart files | `snake_case.dart` | `user_repository.dart` | `payment_handler.dart` | `userRepository.dart`, `UserRepo.dart` |
| Python files | `snake_case.py` | `auth_middleware.py` | `booking_router.py` | `authMiddleware.py` |
| Test files (Dart) | `{name}_test.dart` | `auth_bloc_test.dart` | `user_repository_test.dart` | `test_auth.dart` |
| Test files (Python) | `test_{name}.py` | `test_auth_service.py` | `test_booking_router.py` | `auth_test.py` |
| Test directories | `tests/` or `test/` | `tests/` | `test/` | `testing/`, `__tests__/` |
| Configuration files | `snake_case.ext` | `analysis_options.yaml` | `docker-compose.yml` | `analysisOptions.yaml` |
| Script files | `snake_case.ext` | `setup.sh` | `deploy_prod.sh` | `deploy-prod.sh` |

### 3.4 File Naming Conventions

**Rules:**
- One logical unit per file (one class, one widget, one function module)
- Maximum 400 lines per file (enforced via linter)
- If a file exceeds 400 lines, it must be refactored into multiple files

| Type | Convention | Example | Notes |
|------|-----------|---------|-------|
| BLoC/Cubit | `{feature}_bloc.dart` | `auth_bloc.dart` | Contains both Bloc and Event/State |
| Repository | `{entity}_repository.dart` | `user_repository.dart` | |
| Model/DTO | `{model}_model.dart` | `service_request_model.dart` | |
| Widget | `{widget_name}_widget.dart` | `primary_button_widget.dart` | |
| Page/Screen | `{page_name}_page.dart` | `login_page.dart` | |
| Route | `{feature}_router.dart` | `auth_router.dart` | |
| Provider | `{feature}_provider.dart` | `auth_provider.dart` | Riverpod providers |
| Service | `{domain}_service.dart` | `payment_service.dart` | Dart service classes |
| Middleware | `{purpose}_middleware.py` | `auth_middleware.py` | Python backend |
| Router | `{domain}_router.py` | `booking_router.py` | FastAPI routers |
| Schema | `{entity}_schema.py` | `user_schema.py` | Pydantic schemas |
| Migration | `{version}_{description}.py` | `0002_add_mechanic_table.py` | Alembic migrations |
| Test assertions | `{name}_assertions.dart` | `login_assertions.dart` | Shared test helpers |
| Mock | `{name}_mock.dart` | `auth_service_mock.dart` | Mock implementations |

### 3.5 Asset Organization

```
apps/customer_app/assets/
|-- images/
|   |-- illustrations/
|   |   |-- empty_state_illustration.svg
|   |   |-- error_illustration.svg
|   |   |-- welcome_illustration.svg
|   |-- logos/
|   |   |-- mecha_connect_logo.svg
|   |   |-- mecha_connect_logo_horizontal.svg
|   |-- backgrounds/
|   |   |-- splash_bg.png
|   |   |-- auth_bg.png
|   |-- placeholders/
|       |-- user_avatar_placeholder.png
|       |-- vehicle_placeholder.png
|
|-- icons/
|   |-- navigation/
|   |   |-- ic_home.svg
|   |   |-- ic_search.svg
|   |   |-- ic_profile.svg
|   |   |-- ic_notifications.svg
|   |-- actions/
|   |   |-- ic_call.svg
|   |   |-- ic_message.svg
|   |   |-- ic_share.svg
|   |   |-- ic_sos.svg
|   |-- status/
|       |-- ic_success.svg
|       |-- ic_warning.svg
|       |-- ic_error.svg
|       |-- ic_info.svg
|
|-- animations/
|   |-- lottie/
|   |   |-- loading_spinner.json
|   |   |-- success_checkmark.json
|   |   |-- car_animation.json
|   |-- rive/
|       |-- onboarding_animation.riv
|
|-- fonts/
    |-- Inter/
    |-- JetBrainsMono/
```

**Asset Naming Conventions:**

| Type | Convention | Example |
|------|-----------|---------|
| Images | `{type}_{description}.ext` | `illustration_empty_state.svg` |
| Icons | `ic_{category}_{name}.ext` | `ic_navigation_home.svg` |
| Animations | `{description}.json` | `loading_spinner.json` |
| Fonts | `{FontName}-{Weight}.ttf` | `Inter-Regular.ttf` |

### 3.6 Documentation Structure

```
docs/
|-- adr/                              # Architecture Decision Records
|   |-- ADR-001-use-flutter-for-mobile.md
|   |-- ADR-002-use-fastapi-for-backend.md
|   |-- ADR-003-adopt-melos-monorepo.md
|   |-- ADR-004-use-postgresql-for-primary-db.md
|   |-- ADR-005-adopt-bloc-state-management.md
|   |-- README.md
|
|-- rfcs/                             # Request for Comments
|   |-- RFC-001-real-time-tracking.md
|   |-- RFC-002-offline-first-architecture.md
|   |-- RFC-003-ai-mechanic-matching.md
|   |-- RFC-004-payment-processing-flow.md
|   |-- README.md
|
|-- api/                              # API documentation
|   |-- openapi/
|   |   |-- openapi_v1.yaml
|   |   |-- openapi_v2.yaml
|   |-- postman/
|   |   |-- mecha_connect_collection.json
|   |-- changelog.md
|
|-- architecture/
|   |-- system-architecture.md
|   |-- data-flow-diagrams.md
|   |-- security-architecture.md
|   |-- deployment-architecture.md
|
|-- runbooks/
|   |-- incident-response.md
|   |-- database-backup-restore.md
|   |-- scaling-event-procedure.md
|   |-- service-restart-procedure.md
|   |-- secrets-rotation.md
|
|-- onboarding/
    |-- environment-setup.md
    |-- first-commit-guide.md
    |-- local-development.md
    |-- debugging-guide.md
```

**ADR Naming:** `ADR-{number}-{title-with-hyphens}.md` — e.g., `ADR-003-adopt-melos-monorepo.md`
**RFC Naming:** `RFC-{number}-{title-with-hyphens}.md` — e.g., `RFC-002-offline-first-architecture.md`

### 3.7 Module Boundaries & Dependency Rules

```mermaid
flowchart TD
    subgraph Apps["Applications Layer"]
        CA[Customer App]
        MA[Mechanic App]
        AD[Admin Dashboard]
        CP[Customer Portal]
    end

    subgraph Features["Feature Packages Layer"]
        FR[feature_requests]
        FT[feature_tracking]
        FP[feature_payments]
        FC[feature_chat]
        FN[feature_notifications]
        FRG[feature_rating]
        FA[feature_auth]
        FL[feature_location]
    end

    subgraph Core["Core Shared Packages Layer"]
        SC[shared_core]
        SUI[shared_ui]
        SAP[shared_api]
    end

    subgraph Backend["Backend Services Layer"]
        AG[API Gateway]
        AS[auth_service]
        BS[booking_service]
        PS[payment_service]
        NS[notification_service]
        MS[mechanic_service]
        ANS[analytics_service]
        AI[AI Services]
    end

    CA --> Features
    MA --> Features
    AD --> Features
    CP --> Features

    Features --> Core

    CA -.-> AG
    MA -.-> AG
    AD -.-> AG
    CP -.-> AG

    AG --> Backend

    SC -.-> SUI
    SC -.-> SAP

    style CA fill:#1A73E8,color:#fff
    style MA fill:#34A853,color:#fff
    style AD fill:#FBBC04,color:#000
    style CP fill:#EA4335,color:#fff
    style Core fill:#5F6368,color:#fff
    style Features fill:#8E24AA,color:#fff
    style Backend fill:#0D47A1,color:#fff
```

**Dependency Rules (enforced by Melos):**

1. **Apps -> Features -> Core**: Applications depend on feature packages, which depend on core shared packages.
2. **No Reverse Dependencies**: Core packages must never depend on feature packages.
3. **No Circular Dependencies**: Package A -> Package B -> Package A is prohibited.
4. **Feature Isolation**: Feature packages must not depend on other feature packages.
5. **Backend Isolation**: Backend services communicate only through the API Gateway.

**Valid Dependency Examples:**
- `customer_app` -> `feature_auth` -> `shared_core` OK
- `mechanic_app` -> `feature_tracking` -> `shared_ui` OK
- `feature_payments` -> `shared_api` OK

**Invalid Dependency Examples:**
- `shared_core` -> `feature_auth` FAIL (Core depends on feature)
- `feature_payments` -> `feature_requests` FAIL (Feature-to-feature dependency)
- `shared_ui` -> `customer_app` FAIL (UI depends on app)

### 3.8 Melos Configuration

**`melos.yaml`:**

```yaml
name: mecha_connect
repository: https://github.com/mecha-connect/mecha-connect

packages:
  - apps/*
  - packages/*
  - backend/**
  - tools/**

scripts:
  analyze:
    run: melos exec -c 4 -- flutter analyze
    description: Run flutter analyze on all Flutter packages.
  clean:
    run: |
      melos exec -- flutter clean
      melos clean
    description: Clean all build artifacts.
  get:
    run: melos bootstrap
    description: Bootstrap all packages.
  test:
    run: melos exec -c 4 -- flutter test
    description: Run all Flutter tests in parallel.
  test:coverage:
    run: melos exec -c 4 -- flutter test --coverage
    description: Run tests with coverage.
  lint:
    run: melos exec -c 4 -- dart analyze
    description: Run static analysis on all Dart packages.
  format:
    run: melos exec -- dart format .
    description: Format all Dart code.
  outdated:
    run: melos exec -- flutter pub outdated
    description: Check for outdated dependencies.
  build:all:
    run: melos exec -c 2 -- flutter build apk --debug
    description: Build all apps (debug mode).
  build:runner:
    run: melos exec -- dart run build_runner build --delete-conflicting-outputs
    description: Run code generation for all packages.
  clean:full:
    run: |
      melos clean
      melos exec -- flutter clean
      rm -rf .dart_tool
      rm -rf build
    description: Deep clean of all generated files.

ide:
  intellij:
    enabled: true

command:
  bootstrap:
    usePubspecOverrides: true
    environment:
      sdk: ">=3.2.0 <4.0.0"
  version:
    conventional: true
    changelog: true
    message: "chore: publish %version%"
    bumpStrategy: conventional
```

---

### 12.6 OWASP Top 10 Mitigation

| # | OWASP Risk | Mecha Connect Mitigation |
|---|-----------|-------------------------|
| A01 | **Broken Access Control** | RBAC with FastAPI dependencies; every endpoint checks role level; row-level ownership checks |
| A02 | **Cryptographic Failures** | TLS 1.3, AES-256 at rest, bcrypt for passwords, field-level encryption for PII |
| A03 | **Injection (SQL, NoSQL, OS)** | SQLAlchemy ORM (parameterized queries), input validation with Pydantic, no raw SQL |
| A04 | **Insecure Design** | RFC process for major features, security review checklist in PR template, threat modeling |
| A05 | **Security Misconfiguration** | Infrastructure as Code (Terraform), automated security scanning, hardened Docker images |
| A06 | **Vulnerable Components** | Dependabot automated dependency updates, weekly SCA scans, software bill of materials (SBOM) |
| A07 | **Authentication Failures** | JWT with short-lived tokens, automatic token rotation, rate limiting on auth endpoints, account lockout |
| A08 | **Data Integrity Failures** | Signed JWTs (RS256), webhook signature verification, audit log for all data changes |
| A09 | **Logging & Monitoring Failures** | Centralized logging (Loki), alerting on security events, structured JSON logs with correlation IDs |
| A10 | **SSRF** | Validate all URLs with allowlist, disable external network access for internal services |

---

### 12.7 Dependency Management

#### Scanning Strategy

| Tool | Frequency | Purpose |
|------|-----------|---------|
| Dependabot | Daily | Automated PRs for dependency updates |
| Snyk / Trivy | Every PR | Vulnerability scanning in CI |
| pip-audit | Every build | Python dependency vulnerabilities |
| flutter pub outdated | Weekly | Flutter/Dart dependency check |

#### Dependabot Configuration

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "pip"
    directory: "/backend"
    schedule:
      interval: "daily"
      time: "09:00"
      timezone: "America/New_York"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
      - "python"

  - package-ecosystem: "pub"
    directory: "/mobile"
    schedule:
      interval: "weekly"
      day: "monday"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
      - "flutter"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
      - "ci"
```

#### SCA Policy

- **Critical**: Must fix within 24 hours. Automated PR merged after CI passes.
- **High**: Must fix within 7 days. PR created automatically.
- **Medium**: Must fix by next sprint.
- **Low**: Fixed when convenient; reviewed monthly.

---

### 12.8 Secure Coding Rules

#### Input Validation

1. **All input validated by Pydantic schemas** – Type checks, length limits, regex patterns, value ranges.
2. **Never trust client data** – Validate on both client and server.
3. **Sanitize file uploads** – Validate MIME type, scan for malware, limit file size (max 10MB).
4. **Strict enum validation** – Use Python `Enum` types for all status/method fields.

```python
from pydantic import BaseModel, EmailStr, Field, field_validator
import re

class CreateUserRequest(BaseModel):
    email: EmailStr
    phone_number: str = Field(..., min_length=10, max_length=20)
    first_name: str = Field(..., min_length=1, max_length=100)
    last_name: str = Field(..., min_length=1, max_length=100)
    password: str = Field(..., min_length=8, max_length=128)

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        if not re.match(r"^\+?[1-9]\d{9,15}$", v):
            raise ValueError("Invalid phone number format")
        return v

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        if not re.search(r"[A-Z]", v):
            raise ValueError("Password must contain uppercase letter")
        if not re.search(r"[a-z]", v):
            raise ValueError("Password must contain lowercase letter")
        if not re.search(r"\d", v):
            raise ValueError("Password must contain digit")
        return v
```

#### SQL Injection Prevention

- **NEVER use raw SQL strings** – Always use SQLAlchemy ORM or parameterized queries.

```python
# BAD - SQL injection vulnerability
query = f"SELECT * FROM users WHERE email = '{email}'"
result = await db.execute(text(query))

# GOOD - Parameterized query
query = text("SELECT * FROM users WHERE email = :email")
result = await db.execute(query, {"email": email})

# BEST - SQLAlchemy ORM
result = await db.execute(select(User).where(User.email == email))
```

#### CSRF Protection

- API uses token-based auth (Bearer JWT), so CSRF is inherently mitigated.
- All state-changing requests require POST, PUT, PATCH, or DELETE (not GET).

#### XSS Prevention

- API returns JSON only – No HTML rendering from API responses.
- Flutter renders content safely – Dart/Flutter does not execute HTML/JavaScript.
- Content-Type headers always set to `application/json`.
- CSP headers on Flutter web deployment.

---

### 12.9 Incident Reporting

#### Severity Levels

| Level | Name | Definition | Response Time | SLA |
|-------|------|-----------|---------------|-----|
| SEV-1 | Critical | Platform down, data breach, payment system failure | 15 min | 2 hours |
| SEV-2 | High | Feature severely degraded, major bug | 30 min | 4 hours |
| SEV-3 | Medium | Non-critical bug, minor feature broken | 4 hours | 24 hours |
| SEV-4 | Low | Cosmetic issue, documentation error | 24 hours | Next sprint |

#### Reporting Process

```mermaid
flowchart LR
    A[Incident Detected] --> B{SEV-1 or SEV-2?}
    B -->|Yes| C[Page on-call engineer]
    B -->|No| D[Create Jira ticket]
    C --> E[Assess & mitigate]
    E --> F{Fixed?}
    F -->|Yes| G[Post-mortem within 48h]
    F -->|No| H[Escalate to team lead]
    H --> I[Engineering manager]
    D --> K[Triage in daily standup]
    G --> L[Update runbook]
    L --> M[Close incident]
```

#### Disclosure Timeline

| Event | Timeframe |
|-------|-----------|
| Internal notification to security team | Within 15 min of detection |
| Initial assessment complete | Within 1 hour |
| Mitigation deployed | SEV-1: 2 hours, SEV-2: 4 hours |
| Customer notification (if needed) | Within 4 hours |
| Post-mortem completed | Within 48 hours |
| Public disclosure (if applicable) | Within 30 days |

---

## 13. DevOps Standards

### 13.1 Docker Standards

#### Dockerfile Best Practices

1. **Multi-stage builds** – Separate build and runtime stages to minimize image size.
2. **Pin base image versions** – Never use `:latest` tag.
3. **Minimal base images** – Use `python:3.12-slim` or `alpine` where possible.
4. **Run as non-root** – Always create and use a non-root user.
5. **Layer ordering** – Install system deps first, then Python deps, then app code (maximize cache hits).
6. **Health checks** – Define HEALTHCHECK instruction.
7. **`.dockerignore`** – Exclude `__pycache__`, `.git`, `node_modules`, `.env`, etc.
8. **Security scanning** – Scan images with Trivy before pushing.

#### FastAPI Dockerfile

```dockerfile
# backend/Dockerfile
FROM python:3.12-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

FROM python:3.12-slim AS runtime

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r mecha && useradd -r -g mecha mecha

COPY --from=builder /root/.local /home/mecha/.local
COPY . .

RUN chown -R mecha:mecha /app

USER mecha

ENV PATH="/home/mecha/.local/bin:${PATH}" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl --fail http://localhost:8000/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

#### Flutter Web Dockerfile

```dockerfile
# mobile/Dockerfile (Flutter web)
FROM dart:3.4 AS builder

WORKDIR /app

RUN git clone https://github.com/flutter/flutter.git --depth 1 -b stable /flutter
ENV PATH="/flutter/bin:${PATH}"

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release

FROM nginx:alpine AS runtime

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:80/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
```

```nginx
# nginx.conf
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml;

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://backend:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### .dockerignore

```dockerignore
**/.git
**/.gitignore
**/__pycache__
**/*.pyc
**/.env
**/.env.*
**/node_modules
**/.idea
**/.vscode
**/*.md
**/tests
**/test
**/coverage
**/.coverage
**/.pytest_cache
**/.dart_tool
**/.packages
**/build
**/.flutter-plugins
**/.flutter-plugins-dependencies
```

---

### 13.2 Docker Compose

```yaml
# docker-compose.yml
version: "3.9"

x-common-vars: &common-vars
  ENVIRONMENT: development
  DATABASE_URL: postgresql+asyncpg://postgres:postgres@db:5432/mechanect_dev
  REDIS_URL: redis://redis:6379/0
  JWT_PRIVATE_KEY_PATH: /run/secrets/jwt_private.pem
  JWT_PUBLIC_KEY_PATH: /run/secrets/jwt_public.pem

services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      <<: *common-vars
    env_file:
      - .env
    volumes:
      - ./backend:/app
      - ./secrets:/run/secrets:ro
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
      migrations:
        condition: service_completed_successfully
    healthcheck:
      test: ["CMD", "curl", "--fail", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    networks:
      - mecha_network

  migrations:
    build:
      context: ./backend
      dockerfile: Dockerfile
    environment:
      <<: *common-vars
    env_file:
      - .env
    volumes:
      - ./secrets:/run/secrets:ro
    depends_on:
      db:
        condition: service_healthy
    command: alembic upgrade head
    networks:
      - mecha_network

  db:
    image: postgis/postgis:16-3.4
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: mechanect_dev
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - mecha_network

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - mecha_network

  web:
    build:
      context: ./mobile
      dockerfile: Dockerfile
    ports:
      - "80:80"
    depends_on:
      - backend
    networks:
      - mecha_network

volumes:
  postgres_data:
  redis_data:

networks:
  mecha_network:
    driver: bridge
```

---

### 13.3 GitHub Actions

#### CI Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint-backend:
    name: Lint Backend
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./backend
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: "pip"
      - run: pip install -r requirements-dev.txt
      - run: ruff check .
      - run: ruff format --check .
      - run: mypy app

  lint-mobile:
    name: Lint Mobile
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./mobile
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.22"
          cache: true
      - run: flutter pub get
      - run: dart format --set-exit-if-changed .
      - run: flutter analyze

  test-backend:
    name: Test Backend
    runs-on: ubuntu-latest
    needs: [lint-backend]
    services:
      postgres:
        image: postgis/postgis:16-3.4
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: mechanect_test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    defaults:
      run:
        working-directory: ./backend
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: "pip"
      - run: pip install -r requirements-dev.txt
      - run: alembic upgrade head
        env:
          DATABASE_URL: postgresql+asyncpg://postgres:postgres@localhost:5432/mechanect_test
      - run: pytest --cov=app --cov-report=xml --cov-report=term --junitxml=test-results.xml
        env:
          DATABASE_URL: postgresql+asyncpg://postgres:postgres@localhost:5432/mechanect_test
          REDIS_URL: redis://localhost:6379/0
      - uses: codecov/codecov-action@v4
        with:
          files: ./backend/coverage.xml

  test-mobile:
    name: Test Mobile
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./mobile
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.22"
          cache: true
      - run: flutter pub get
      - run: flutter test --coverage --machine > test-results.json
      - uses: codecov/codecov-action@v4
        with:
          files: ./mobile/coverage/lcov.info

  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: "fs"
          scan-ref: "."
          format: "sarif"
          output: "trivy-results.sarif"
          severity: "CRITICAL,HIGH"
      - name: Upload Trivy results to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: "trivy-results.sarif"

  build:
    name: Build Docker Images
    runs-on: ubuntu-latest
    needs: [test-backend, test-mobile]
    steps:
      - uses: actions/checkout@v4
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      - name: Build backend
        uses: docker/build-push-action@v5
        with:
          context: ./backend
          file: ./backend/Dockerfile
          tags: mechanect/backend:ci-${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
      - name: Build web
        uses: docker/build-push-action@v5
        with:
          context: ./mobile
          file: ./mobile/Dockerfile
          tags: mechanect/web:ci-${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

#### CD Workflow (Staging)

```yaml
# .github/workflows/deploy-staging.yml
name: Deploy to Staging

on:
  push:
    branches: [develop]

jobs:
  deploy:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v4
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2
      - name: Build and push images
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/mechanect-staging/backend:$IMAGE_TAG ./backend
          docker build -t $ECR_REGISTRY/mechanect-staging/web:$IMAGE_TAG ./mobile
          docker push $ECR_REGISTRY/mechanect-staging/backend:$IMAGE_TAG
          docker push $ECR_REGISTRY/mechanect-staging/web:$IMAGE_TAG
      - name: Deploy to ECS
        run: |
          aws ecs update-service --cluster mechanect-staging --service backend-service --force-new-deployment
          aws ecs update-service --cluster mechanect-staging --service web-service --force-new-deployment
      - name: Verify deployment
        run: |
          sleep 30
          curl --fail https://staging.api.mechaconnect.com/health
```

---

## 4. Git Standards

### 4.1 Git Workflow

Mecha Connect uses **Trunk-Based Development (TBD)** with short-lived feature branches. All development happens on branches created from `main`, and changes are merged back to `main` frequently (multiple times per day) via pull requests.

```mermaid
gitGraph
    commit id: "initial"
    commit id: "chore: setup monorepo"
    branch feature/feat-sos-button
    commit id: "feat(customer): add SOS button"
    commit id: "test(customer): add SOS tests"
    checkout main
    merge feature/feat-sos-button id: "PR #42" type: squash
    branch feature/fix-payment-timeout
    commit id: "fix(payment): increase timeout"
    checkout main
    merge feature/fix-payment-timeout id: "PR #43" type: squash
    branch hotfix/1.0.1-critical-auth-fix
    commit id: "fix(auth): patch auth bypass"
    checkout main
    merge hotfix/1.0.1-critical-auth-fix id: "hotfix" tag: "v1.0.1"
    branch feature/feat-in-app-chat
    commit id: "feat(chat): add message model"
    commit id: "feat(chat): add chat UI"
    checkout main
    merge feature/feat-in-app-chat id: "PR #44" type: squash
```

**Core Principles:**
- `main` is always deployable
- Feature branches live for no more than 2 days
- Branches are merged via squash merge into `main`
- Releases are tagged from `main`

### 4.2 Branch Naming Convention

**Format:** `{type}/{description}`

**Rules:** kebab-case only, max 50 characters, no trailing slashes, no special characters except hyphens.

| Type | Prefix | Pattern | Examples |
|------|--------|---------|----------|
| Feature | `feature/` | `feature/{short-description}` | `feature/sos-button`, `feature/in-app-chat` |
| Fix | `fix/` | `fix/{short-description}` | `fix/payment-timeout`, `fix/auth-null-pointer` |
| Hotfix | `hotfix/{version}-` | `hotfix/{version}-{description}` | `hotfix/1.0.1-auth-bypass` |
| Release | `release/` | `release/v{major}.{minor}.{patch}` | `release/v1.0.0`, `release/v1.1.0` |
| Chore | `chore/` | `chore/{short-description}` | `chore/update-dependencies` |
| Docs | `docs/` | `docs/{short-description}` | `docs/api-guide`, `docs/adr-003` |
| Refactor | `refactor/` | `refactor/{short-description}` | `refactor/payment-module` |
| Test | `test/` | `test/{short-description}` | `test/payment-service` |
| Experiment | `exp/` | `exp/{short-description}` | `exp/ai-matching-v2` |

### 4.3 Commit Message Convention (Conventional Commits)

**Format:** `<type>(<scope>): <description>`

**Rules:** Max 72 chars subject, imperative present tense, lowercase, no period.

**Types:**

| Type | Usage | Version Bump | Example |
|------|-------|-------------|---------|
| `feat` | A new feature | MINOR | `feat(auth): add biometric login` |
| `fix` | A bug fix | PATCH | `fix(payment): handle timeout gracefully` |
| `chore` | Maintenance tasks | None | `chore: update dependencies` |
| `docs` | Documentation changes | None | `docs: add API authentication guide` |
| `style` | Formatting, linting | None | `style: format dart files` |
| `refactor` | Code restructuring | None | `refactor: extract payment validator` |
| `perf` | Performance improvements | PATCH | `perf: cache user profile queries` |
| `test` | Adding/updating tests | None | `test: add booking service unit tests` |
| `build` | Build system changes | None | `build: update gradle configuration` |
| `ci` | CI/CD changes | None | `ci: add security scan workflow` |
| `revert` | Revert a previous commit | None | `revert: feat(auth): add biometric login` |

**Scopes:**

| Scope | Package/Service | Example |
|-------|----------------|---------|
| `customer` | `apps/customer_app` | `feat(customer): add sos button` |
| `mechanic` | `apps/mechanic_app` | `fix(mechanic): fix eta display` |
| `admin` | `apps/admin_dashboard` | `feat(admin): add user search` |
| `shared-core` | `packages/shared_core` | `feat(shared-core): add vehicle types` |
| `shared-ui` | `packages/shared_ui` | `fix(shared-ui): fix button alignment` |
| `shared-api` | `packages/shared_api` | `feat(shared-api): add rating endpoint` |
| `auth` | `backend/services/auth_service` | `fix(auth): patch token validation` |
| `booking` | `backend/services/booking_service` | `feat(booking): add priority dispatch` |
| `payment` | `backend/services/payment_service` | `fix(payment): handle stripe decline` |
| `notification` | `backend/services/notification_service` | `feat(notification): add sms fallback` |
| `mechanic-svc` | `backend/services/mechanic_service` | `fix(mechanic-svc): fix availability query` |
| `analytics` | `backend/services/analytics_service` | `feat(analytics): add churn prediction` |
| `ai-matching` | `backend/ai_services/matching_engine` | `perf(ai-matching): optimize embedding lookup` |
| `ai-assistant` | `backend/ai_services/assistant_service` | `feat(ai-assistant): add faq context` |
| `infra` | `infrastructure/` | `ci(infra): add terraform plan to CI` |
| `docs` | `docs/` | `docs: add incident response runbook` |

**Examples:**

```
feat(customer): add SOS button to home screen

Implement an emergency SOS button that triggers immediate service request.
Includes haptic feedback and confirmation dialog.

Closes #142
```

```
fix(payment): handle stripe webhook timeout gracefully

Add retry logic with exponential backoff for Stripe webhook calls.
Log timeout events for monitoring.

Fixes #238
```

```
chore: upgrade flutter to 3.16.0 and update dependencies
```

```
ci: add dependency review workflow
```

```
refactor(payment): extract payment validation logic into shared utility
```

```
docs: add offline-first architecture ADR
```

```
perf(shared-core): cache user preferences lookup
```

### 4.4 Merge Strategy

**Squash Merge** is the default and only allowed merge strategy for feature/fix branches into `main`.

```mermaid
flowchart LR
    subgraph Before[Merge Before Squash]
        direction TB
        M1[main: A] --> M2[main: B]
        F1[feature/feat-x: C] --> F2[feature/feat-x: D]
        M2 --> F1
    end

    subgraph After[Squash Merge Result]
        S1[main: A] --> S2[main: B]
        S2 --> S3[main: E]
    end

    Before --> |Squash Merge| After

    style S3 fill:#34A853,color:#fff
```

**Why Squash Merge?**
- Keeps `main` history clean and linear
- Groups all feature work into a single logical commit
- Makes reverts atomic (`git revert <squash-commit>`)

**Process:**
1. Developer creates feature branch from `main`
2. Developer makes multiple commits on the feature branch
3. PR is opened and reviewed
4. PR is approved
5. **Squash & Merge** is used to merge into `main`
6. Feature branch is deleted after merge

### 4.5 Rebase Policy

**Daily Rebase:** Every developer must rebase their feature branch onto `main` at least once per day.

```
git checkout feature/my-feature
git fetch origin
git rebase origin/main
```

**Why rebase daily?**
- Minimizes merge conflicts (smaller, more frequent rebases)
- Ensures your branch is always building against the latest `main`
- Catches integration issues early
- Makes the final squash merge clean

**Never Rebase Shared Branches:**
- `main` — NEVER rebase. Only merge.
- `release/*` — NEVER rebase. Only hotfix merges.
- `hotfix/*` — NEVER rebase once pushed.

### 4.6 Release Branches

```mermaid
flowchart TD
    subgraph Dev[Development Phase]
        A[feat commits to main]
    end

    subgraph Stabilize[Release Stabilization]
        B[Create release/vX.Y.Z from main]
        C[Add polish commits]
        D[Fix regressions]
    end

    subgraph Release[Release Phase]
        E[Merge release back to main]
        F[Tag vX.Y.Z on main]
        G[Deploy to production]
    end

    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G

    style B fill:#FBBC04,color:#000
    style F fill:#34A853,color:#fff
    style G fill:#1A73E8,color:#fff
```

**Release Steps:**

| Step | Action | Responsible |
|------|--------|-------------|
| 1 | Create `release/v{major}.{minor}.{patch}` from `main` | Release Manager |
| 2 | Deploy release branch to staging | DevOps |
| 3 | Run full regression test suite | QA Team |
| 4 | Run performance tests and security scan | QA + DevOps |
| 5 | Fix any regressions on release branch | Feature Owners |
| 6 | Deploy to production canary (10%) | DevOps |
| 7 | Monitor for 30 minutes | SRE |
| 8 | Deploy to remaining 90% | DevOps |
| 9 | Merge release branch back to `main` | Release Manager |
| 10 | Tag `v{major}.{minor}.{patch}` on main | Release Manager |

### 4.7 Hotfix Branches

```mermaid
flowchart TD
    A[Production incident detected]
    A --> B[Create hotfix branch from main]
    B --> C[Apply critical fix]
    C --> D[Deploy hotfix to production]
    D --> E[Tag v{major}.{minor}.{patch+1}]
    E --> F[Merge hotfix back to main]

    style A fill:#EA4335,color:#fff
    style D fill:#EA4335,color:#fff
```

**Hotfix Rules:**
1. Hotfix branches are created from the latest production tag, not from `main`
2. Only one commit per hotfix (squash all changes)
3. Hotfix must be reviewed by at least 2 engineers (emergency: 1 if Sev0)
4. Hotfix goes through CI but can bypass full QA regression if Sev0
5. Hotfix must be merged back to `main` immediately after deployment
6. A postmortem must be written within 24 hours
7. Hotfix version increments only the patch number: `v1.0.0` -> `v1.0.1`

### 4.8 Tagging

**Format:** `v{major}.{minor}.{patch}`

| Tag Type | Pattern | Bumped By | Example |
|----------|---------|-----------|---------|
| Production Release | `v{major}.{minor}.{patch}` | Release | `v1.0.0`, `v1.1.0` |
| Hotfix | `v{major}.{minor}.{patch+1}` | Patch increment | `v1.0.1`, `v1.1.2` |
| Release Candidate | `v{major}.{minor}.{patch}-rc.{n}` | Each RC | `v1.0.0-rc.1` |
| Alpha | `v{major}.{minor}.{patch}-alpha.{n}` | Each alpha | `v2.0.0-alpha.1` |
| Beta | `v{major}.{minor}.{patch}-beta.{n}` | Each beta | `v2.0.0-beta.1` |

**Commands:**
```bash
git tag -a v1.0.0 -m "Release v1.0.0 - Initial production release"
git push origin v1.0.0

git tag -a v1.0.1 -m "Hotfix v1.0.1 - Critical auth patch"
git push origin v1.0.1
```

#### PR Check Workflow

```yaml
# .github/workflows/pr-check.yml
name: PR Check

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  pr-checks:
    name: PR Requirements
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check PR title format
        run: |
          if ! echo "${{ github.event.pull_request.title }}" | grep -qE '^(feat|fix|chore|docs|refactor|test|ci|perf)(\(.+\))?: .{10,}'; then
            echo "ERROR: PR title must follow format: type(scope): description (min 10 chars)"
            exit 1
          fi
      - name: Check branch name
        run: |
          BRANCH="${{ github.head_ref }}"
          if ! echo "$BRANCH" | grep -qE '^(feature|bugfix|hotfix|chore|docs)/MECHA-[0-9]+-.+'; then
            echo "ERROR: Branch name must follow format: type/MECHA-XXX-description"
            exit 1
          fi
      - name: Check PR has description
        run: |
          BODY="${{ github.event.pull_request.body }}"
          if [ -z "$BODY" ] || [ ${#BODY} -lt 30 ]; then
            echo "ERROR: PR description must be at least 30 characters"
            exit 1
          fi
```

---

### 13.4 Environment Variables

#### Environment Matrix

| Variable | Dev | Staging | Prod |
|----------|-----|---------|------|
| `ENVIRONMENT` | development | staging | production |
| `DEBUG` | true | false | false |
| `LOG_LEVEL` | DEBUG | INFO | WARNING |
| `DATABASE_URL` | localhost | RDS staging | RDS prod (HA) |
| `DATABASE_READ_URL` | localhost | RDS read replica | RDS read replicas |
| `REDIS_URL` | localhost | ElastiCache staging | ElastiCache prod cluster |
| `SENTRY_DSN` | "" | Sentry staging | Sentry prod |
| `CORS_ORIGINS` | http://localhost:80 | https://staging.* | https://*.mechaconnect.com |

#### Naming Convention: `MECHA_{SERVICE}_{KEY}`

```bash
# Backend
MECHA_BACKEND_DATABASE_URL=postgresql+asyncpg://...
MECHA_BACKEND_REDIS_URL=redis://...
MECHA_BACKEND_JWT_PRIVATE_KEY_PATH=/run/secrets/jwt_private.pem
MECHA_BACKEND_JWT_PUBLIC_KEY_PATH=/run/secrets/jwt_public.pem
MECHA_BACKEND_STRIPE_SECRET_KEY=sk_live_...
MECHA_BACKEND_SENTRY_DSN=https://...

# AI Service
MECHA_AI_PINECONE_API_KEY=...
MECHA_AI_OPENAI_API_KEY=sk-...

# Mobile
MECHA_MOBILE_API_BASE_URL=https://api.mechaconnect.com
MECHA_MOBILE_SENTRY_DSN=https://...
MECHA_MOBILE_STRIPE_PUBLISHABLE_KEY=pk_live_...
```

---

### 13.5 Secrets

#### GitHub Secrets

| Secret Name | Used By | Purpose |
|-------------|---------|---------|
| `AWS_ACCESS_KEY_ID` | CD workflows | Deploy to AWS ECS |
| `AWS_SECRET_ACCESS_KEY` | CD workflows | Deploy to AWS ECS |
| `SENTRY_AUTH_TOKEN` | CI workflows | Upload source maps |
| `SLACK_WEBHOOK_URL` | CI workflows | Deployment notifications |

#### Environment-Specific Secrets

| Secret | Dev | Staging | Prod |
|--------|-----|---------|------|
| Database password | postgres (default) | AWS Secrets Manager | AWS Secrets Manager (auto-rotate) |
| JWT private key | Local .pem file | AWS Secrets Manager | AWS Secrets Manager (HSM-backed) |
| Stripe API key | Test keys | Test keys | Live keys (restricted access) |
| OpenAI API key | Dev key (quota limited) | Staging key | Production key |

#### Rotation Policy

| Secret Type | Rotation Frequency | Method |
|-------------|-------------------|--------|
| Database passwords | 90 days | AWS RDS auto-rotation |
| JWT signing keys | 365 days | Manual rotation with key overlap |
| API keys | As needed | Manual via provider dashboard |
| TLS certificates | 60 days | Let's Encrypt / ACM auto-renewal |

---

### 13.6 Deployment Strategy

#### Blue-Green Deployment

Mecha Connect uses **blue-green deployment** on AWS ECS with Fargate:

```mermaid
flowchart LR
    subgraph Blue [Blue (Current)]
        B1[ECS Service v1]
        B2[ALB Target Group Blue]
    end
    subgraph Green [Green (New)]
        G1[ECS Service v2]
        G2[ALB Target Group Green]
    end
    R[Route53] --> ALB[Application Load Balancer]
    ALB --> B2
    ALB -->|Switch after validation| G2
```

#### Deployment Steps

1. **Build & push** new Docker image to ECR.
2. **Deploy green** – Launch new ECS service alongside existing blue.
3. **Run health checks** – Verify /health, /ready, integration tests.
4. **Switch traffic** – Update ALB listener rule to point to green target group.
5. **Monitor** – Watch metrics for 10 minutes (error rate, latency, 5xx).
6. **Drain blue** – After monitoring, scale down blue service.
7. **Rollback** – If issues detected, switch ALB back to blue immediately.

#### Zero-Downtime Deployment

- **Rolling update** with `minimum_healthy_percent=100` and `maximum_percent=200`.
- **Graceful shutdown** – FastAPI handles SIGTERM, drains existing connections.
- **PreStop hook** – Runs `sleep 30` to allow DNS/ALB propagation before container stops.

#### Health Checks & Probes

```python
# app/api/v1/health.py
from fastapi import APIRouter, Response
from app.db.session import AsyncSessionLocal
from app.redis import redis_client

router = APIRouter()

@router.get("/health")
async def health_check():
    return {"status": "healthy", "version": "1.0.0", "timestamp": datetime.now(timezone.utc).isoformat()}

@router.get("/ready")
async def readiness_check():
    checks = {"database": False, "redis": False}

    try:
        async with AsyncSessionLocal() as session:
            await session.execute(text("SELECT 1"))
        checks["database"] = True
    except Exception as e:
        checks["database_error"] = str(e)

    try:
        await redis_client.ping()
        checks["redis"] = True
    except Exception as e:
        checks["redis_error"] = str(e)

    all_healthy = all(checks.values())
    status_code = 200 if all_healthy else 503
    return Response(
        content=json.dumps({"status": "ready" if all_healthy else "not_ready", "checks": checks}),
        status_code=status_code,
        media_type="application/json",
    )
```

---

### 13.7 Monitoring

#### Prometheus Metrics

```python
# app/core/metrics.py
from prometheus_client import Counter, Histogram, Gauge, generate_latest
from fastapi import Request, Response
import time

request_count = Counter(
    "http_requests_total", "Total HTTP requests",
    ["method", "endpoint", "status"],
)

error_count = Counter(
    "http_errors_total", "Total HTTP errors",
    ["method", "endpoint", "status_code"],
)

request_duration = Histogram(
    "http_request_duration_seconds", "HTTP request duration in seconds",
    ["method", "endpoint"],
    buckets=[0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0],
)

db_query_duration = Histogram(
    "db_query_duration_seconds", "Database query duration",
    ["query_type", "table"],
    buckets=[0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1.0],
)

active_users = Gauge("active_users_total", "Total active users")
active_mechanics = Gauge("active_mechanics_total", "Total available mechanics")
pending_bookings = Gauge("pending_bookings_total", "Total pending bookings")


@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start = time.time()
    response = await call_next(request)
    duration = time.time() - start

    request_count.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code,
    ).inc()

    request_duration.labels(
        method=request.method,
        endpoint=request.url.path,
    ).observe(duration)

    if response.status_code >= 400:
        error_count.labels(
            method=request.method,
            endpoint=request.url.path,
            status_code=response.status_code,
        ).inc()

    return response


@router.get("/metrics")
async def get_metrics():
    return Response(content=generate_latest(), media_type="text/plain")
```

#### Grafana Dashboards

| Dashboard | Panels | Refresh |
|-----------|--------|---------|
| **API Overview** | Request rate, error rate, P50/P95/P99 latency, active users, bookings/hour | 1 min |
| **Database** | Connections, query time, cache hit ratio, deadlocks, replication lag | 30s |
| **Redis** | Memory usage, hit rate, connected clients, command rate | 30s |
| **AI Service** | Request rate, response time, token usage, fallback rate | 1 min |
| **Infrastructure** | CPU/Memory per service, disk I/O, network traffic, container restarts | 30s |
| **Business** | New users/day, bookings/day, revenue/day, mechanic signups | 5 min |
| **SRE** | Error budget, SLI/SLO compliance, alert firing count | 1 min |

#### Key Metrics

| Metric | Target | Alert Threshold | Priority |
|--------|--------|----------------|----------|
| API P50 latency | < 200ms | > 500ms | P2 |
| API P99 latency | < 1s | > 3s | P1 |
| Error rate | < 0.1% | > 0.5% | P1 |
| Database connections | < 80% of max | > 90% | P2 |
| Database replication lag | < 1s | > 5s | P1 |
| Redis memory | < 70% | > 85% | P2 |
| Booking match time | < 30s | > 60s | P1 |
| Payment success rate | > 99% | < 98% | P1 |
| Uptime (monthly) | > 99.9% | < 99.5% | P1 |

---

### 13.8 Logging

#### Structured JSON Logging

```python
# app/core/logging.py
import logging
import json
from datetime import datetime, timezone
from pythonjsonlogger import jsonlogger

class CustomJsonFormatter(jsonlogger.JsonFormatter):
    def add_fields(self, log_record, record, message_dict):
        super().add_fields(log_record, record, message_dict)
        log_record["timestamp"] = datetime.now(timezone.utc).isoformat()
        log_record["environment"] = settings.environment
        log_record["service"] = "backend"
        log_record["level"] = record.levelname
        if not log_record.get("correlation_id"):
            log_record["correlation_id"] = getattr(record, "correlation_id", "")

def setup_logging() -> None:
    handler = logging.StreamHandler()
    formatter = CustomJsonFormatter(
        fmt="%(timestamp)s %(level)s %(name)s %(message)s %(correlation_id)s"
    )
    handler.setFormatter(formatter)

    root_logger = logging.getLogger()
    root_logger.addHandler(handler)
    root_logger.setLevel(getattr(logging, settings.log_level.upper(), logging.INFO))

    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
```

**Log output example:**
```json
{
  "timestamp": "2025-01-15T10:30:00.123Z",
  "level": "INFO",
  "name": "app.api.v1.bookings",
  "message": "Booking created successfully",
  "correlation_id": "abc-123-def-456",
  "environment": "production",
  "service": "backend",
  "booking_id": "550e8400-e29b-41d4-a716-446655440000",
  "duration_ms": 245
}
```

#### Correlation ID Middleware

```python
@app.middleware("http")
async def correlation_id_middleware(request: Request, call_next):
    correlation_id = request.headers.get("X-Correlation-ID", str(uuid.uuid4()))
    request.state.correlation_id = correlation_id
    response = await call_next(request)
    response.headers["X-Correlation-ID"] = correlation_id
    return response
```

#### Log Retention Policy

| Environment | Retention | Storage | Access |
|-------------|-----------|---------|--------|
| Development | 7 days | Local files | All developers |
| Staging | 30 days | Loki / S3 | Engineering team |
| Production | 90 days (hot) + 1 year (cold archive) | Loki to S3 Glacier | On-call, SRE, Security |

---

### 13.9 Backups

#### PostgreSQL Backup Strategy

| Backup Type | Frequency | Retention | Method |
|-------------|-----------|-----------|--------|
| Full backup | Daily | 30 days | pg_dump to S3 |
| WAL archiving | Continuous | 7 days | WAL-G to S3 |
| Snapshot (RDS) | Daily | 7 days | AWS RDS automated snapshots |

```bash
#!/bin/bash
# Daily full backup script
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
S3_BUCKET="s3://mechanect-backups/prod/postgres"

pg_dump --host=$DB_HOST --port=$DB_PORT --username=$DB_USER \
    --dbname=$DB_NAME --format=custom --file="/backups/mechanect_${TIMESTAMP}.dump" \
    --verbose --no-owner --compress=9

gpg --encrypt --recipient backup-team "/backups/mechanect_${TIMESTAMP}.dump"

aws s3 cp "/backups/mechanect_${TIMESTAMP}.dump.gpg" "$S3_BUCKET/"

find /backups -name "*.dump*" -mtime +7 -delete
```

#### Redis Backup

| Backup Type | Frequency | Retention | Method |
|-------------|-----------|-----------|--------|
| RDB snapshot | Every 60 min | 7 days | SAVE / BGSAVE to S3 |
| AOF rewrite | Every 30 min | 24 hours | Automatic AOF rewrite |

#### Disaster Recovery

| Scenario | RTO | RPO | Recovery Method |
|----------|-----|-----|-----------------|
| Single AZ failure | 5 min | 0 | Multi-AZ failover |
| Region failure | 30 min | 5 min | Cross-region replica promotion |
| Data corruption | 1 hour | 24 hours | Restore from last good backup |
| Accidental table drop | 30 min | < 5 min | Point-in-time recovery (WAL) |
| Full region outage | 4 hours | 15 min | DR region spin-up from backups |

#### RTO/RPO Targets

| Tier | RTO | RPO |
|------|-----|-----|
| Critical (payments, auth, bookings) | < 15 min | < 1 min |
| High (profiles, notifications) | < 1 hour | < 5 min |
| Medium (reviews, documents, analytics) | < 4 hours | < 1 hour |
| Low (audit logs, history) | < 24 hours | < 24 hours |

---

### 13.10 Infrastructure (Terraform)

#### Resource Naming Convention

```
{provider}-{environment}-{resource-type}-{name}
```

Examples:
- `aws-prod-rds-mechanect`
- `aws-staging-ecs-backend-service`
- `aws-dev-s3-backups`

#### Environment Isolation

| Environment | AWS Account | VPC | Terraform Workspace |
|-------------|-------------|-----|---------------------|
| Development | Shared dev account | vpc-dev-001 | dev |
| Staging | Shared dev account | vpc-staging-001 | staging |
| Production | Prod account (separate) | vpc-prod-001 | prod |

#### Terraform State Management

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "mechanect-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

```hcl
# main.tf (partial)
provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway = true
  enable_dns_hostnames = true

  tags = {
    Environment = var.environment
    Project     = "MechaConnect"
    ManagedBy   = "Terraform"
  }
}

module "rds" {
  source = "terraform-aws-modules/rds/aws"
  version = "6.6.0"

  identifier = "${var.environment}-mechanect-db"

  engine               = "postgres"
  engine_version       = "16.3"
  family               = "postgres16"
  major_engine_version = "16"
  instance_class       = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_encrypted     = true
  storage_type          = "gp3"

  db_name  = "mechanect_${var.environment}"
  username = "mechanect_admin"
  password = random_password.db_password.result
  port     = 5432

  multi_az               = var.environment == "prod"
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = var.environment == "prod" ? 30 : 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  deletion_protection = var.environment == "prod"
}
```

---

## 14. Testing Standards

### 14.1 Test Pyramid

```mermaid
graph TD
    subgraph Test Pyramid
        E2E["E2E Tests (5%)
        Critical user flows
        Playwright / Flutter Drive"]

        INT["Integration Tests (15%)
        API endpoints, DB queries
        Third-party integrations"]

        WIDGET["Widget Tests (20%)
        Flutter widget rendering
        User interaction states"]

        UNIT["Unit Tests (60%)
        Business logic, services, repositories
        BLoC/Cubit, Utils, Validators"]
    end

    UNIT --> WIDGET
    WIDGET --> INT
    INT --> E2E
```

| Layer | Target | Tools | Run Frequency | Environment |
|-------|--------|-------|---------------|-------------|
| Unit | 60% of tests | pytest, flutter_test, mocktail, bloc_test | Every commit / CI | No dependencies |
| Widget | 20% of tests | flutter_test, widget_test | Every PR / CI | No dependencies |
| Integration | 15% of tests | pytest-asyncio, FastAPI TestClient, flutter_driver | Every PR / CI | Test DB, Redis |
| E2E | 5% of tests | Playwright, Flutter Drive | Nightly / Release | Full staging env |

---

### 14.2 Unit Testing

#### Dart (Flutter)

**Tools:** `flutter_test` + `mocktail` + `bloc_test`

**What to test:**
- BLoC/Cubit events, states, and transitions
- Repository data mapping and error handling
- Service business logic (price calculation, validation)
- Utility functions (formatters, validators, converters)
- Model serialization/deserialization (fromJson/toJson)

```dart
// test/repositories/booking_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mechanect/repositories/booking_repository.dart';
import 'package:mechanect/models/booking.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late BookingRepository repository;

  setUp(() {
    mockApiClient = MockApiClient();
    repository = BookingRepository(apiClient: mockApiClient);
  });

  group('BookingRepository', () {
    test('createBooking returns Booking on success', () async {
      final request = CreateBookingRequest(
        vehicleId: 'vehicle-1',
        serviceType: 'tire_change',
        latitude: 40.7128,
        longitude: -74.0060,
      );
      final expectedBooking = Booking(
        id: 'booking-1',
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
      );

      when(() => mockApiClient.post(
        '/bookings',
        body: any(named: 'body'),
      )).thenAnswer((_) async => expectedBooking.toJson());

      final result = await repository.createBooking(request);

      expect(result, isA<Booking>());
      expect(result.id, 'booking-1');
      expect(result.status, BookingStatus.pending);
      verify(() => mockApiClient.post(
        '/bookings',
        body: any(named: 'body'),
      )).called(1);
    });

    test('createBooking throws ApiException on failure', () async {
      final request = CreateBookingRequest(...);
      when(() => mockApiClient.post(
        '/bookings',
        body: any(named: 'body'),
      )).thenThrow(ApiException(statusCode: 400, message: 'Invalid vehicle'));

      expect(
        () => repository.createBooking(request),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
```

```dart
// test/bloc/booking_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:mechanect/blocs/booking/booking_bloc.dart';

class MockBookingRepository extends Mock implements BookingRepository {}

void main() {
  late MockBookingRepository mockRepository;
  late BookingBloc bloc;

  setUp(() {
    mockRepository = MockBookingRepository();
    bloc = BookingBloc(bookingRepository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('BookingBloc', () {
    blocTest<BookingBloc, BookingState>(
      'emits [loading, success] when create is successful',
      build: () {
        when(() => mockRepository.createBooking(any()))
            .thenAnswer((_) async => Booking(id: '1', status: BookingStatus.pending));
        return bloc;
      },
      act: (bloc) => bloc.add(const CreateBooking(...)),
      expect: () => [
        BookingState.initial().copyWith(status: BookingStatus.loading),
        BookingState.initial().copyWith(
          status: BookingStatus.success,
          booking: Booking(id: '1', status: BookingStatus.pending),
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.createBooking(any())).called(1);
      },
    );

    blocTest<BookingBloc, BookingState>(
      'emits [loading, failure] when create throws',
      build: () {
        when(() => mockRepository.createBooking(any()))
            .thenThrow(Exception('Service unavailable'));
        return bloc;
      },
      act: (bloc) => bloc.add(const CreateBooking(...)),
      expect: () => [
        BookingState.initial().copyWith(status: BookingStatus.loading),
        BookingState.initial().copyWith(
          status: BookingStatus.failure,
          errorMessage: 'Service unavailable',
        ),
      ],
    );
  });
}
```

#### Python (FastAPI Backend)

**Tools:** `pytest` + `pytest-asyncio` + `pytest-cov` + `httpx`

**What to test:**
- Service layer business logic
- Repository data access patterns
- Schema validation (Pydantic)
- Helper/utility functions

```python
# tests/unit/test_services/test_booking_service.py
import pytest
from decimal import Decimal
from app.services.booking_service import BookingService
from app.schemas.booking import BookingCreate

pytestmark = pytest.mark.asyncio

class TestBookingService:
    async def test_calculate_price_tire_change(self):
        service = BookingService()
        price = await service.calculate_price(
            service_type="tire_change",
            distance_km=Decimal("5.0"),
            vehicle_type="sedan",
        )
        assert price == Decimal("49.99")

    async def test_calculate_price_towing_long_distance(self):
        service = BookingService()
        price = await service.calculate_price(
            service_type="towing",
            distance_km=Decimal("50.0"),
            vehicle_type="suv",
        )
        assert price == Decimal("199.99")

    async def test_calculate_price_negative_distance_raises_error(self):
        service = BookingService()
        with pytest.raises(ValueError, match="Distance must be positive"):
            await service.calculate_price(
                service_type="tire_change",
                distance_km=Decimal("-1.0"),
                vehicle_type="sedan",
            )

    async def test_estimate_eta_within_service_area(self):
        service = BookingService()
        eta = await service.estimate_eta(
            mechanic_lat=40.7128, mechanic_lng=-74.0060,
            customer_lat=40.7200, customer_lng=-74.0100,
        )
        assert 5 <= eta <= 15


# tests/unit/test_utils/test_validators.py
from app.utils.validators import validate_phone, validate_email

class TestValidators:
    def test_valid_phone_number(self):
        assert validate_phone("+12125551234") is True

    def test_invalid_phone_number_short(self):
        assert validate_phone("123") is False

    def test_valid_email(self):
        assert validate_email("user@example.com") is True

    def test_invalid_email(self):
        assert validate_email("not-an-email") is False
```

---

### 14.3 Widget Testing (Flutter)

**What to test:**
- Widget renders correctly with given data
- Widget responds to user interaction (tap, scroll, input)
- Widget displays correct states (loading, error, empty, success)
- Widget navigates correctly

```dart
// test/widgets/booking_card_widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mechanect/widgets/booking_card.dart';
import 'package:mechanect/models/booking.dart';

void main() {
  group('BookingCard', () {
    testWidgets('displays booking details correctly', (tester) async {
      final booking = Booking(
        id: 'booking-1',
        serviceType: 'Tire Change',
        status: BookingStatus.inProgress,
        createdAt: DateTime(2025, 1, 15, 10, 30),
        mechanicName: 'John Smith',
        price: 49.99,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(booking: booking, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Tire Change'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('\$49.99'), findsOneWidget);
      expect(find.text('John Smith'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      final booking = Booking(id: '1', status: BookingStatus.pending, createdAt: DateTime.now());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(booking: booking, onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.byType(BookingCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('displays error state correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(
              booking: null, onTap: () {},
              errorMessage: 'Failed to load booking',
            ),
          ),
        ),
      );

      expect(find.text('Failed to load booking'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows skeleton loader when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(isLoading: true, onTap: () {}),
          ),
        ),
      );

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.text('Tire Change'), findsNothing);
    });
  });
}
```

---

### 14.4 Integration Testing

#### Flutter Integration Tests

```dart
// integration_test/booking_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanect/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Booking Flow', () {
    testWidgets('complete booking flow from home to confirmation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'Test1234!');
      await tester.tap(find.byKey(const Key('submit_login')));
      await tester.pumpAndSettle();

      expect(find.text('Mecha Connect'), findsOneWidget);

      // Request assistance
      await tester.tap(find.byKey(const Key('request_assistance_button')));
      await tester.pumpAndSettle();

      // Select service
      await tester.tap(find.text('Tire Change'));
      await tester.pumpAndSettle();

      // Confirm location
      await tester.tap(find.byKey(const Key('confirm_location_button')));
      await tester.pumpAndSettle();

      // Wait for mechanic matching
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Mechanic Found!'), findsOneWidget);

      // Accept
      await tester.tap(find.byKey(const Key('accept_booking_button')));
      await tester.pumpAndSettle();

      expect(find.text('Booking Confirmed'), findsOneWidget);
    });
  });
}
```

#### API Integration Tests

```python
# tests/integration/test_api_bookings.py
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app

pytestmark = pytest.mark.asyncio

class TestBookingAPI:
    @pytest.fixture(autouse=True)
    async def setup_db(self):
        async with AsyncSessionLocal() as session:
            user = User(
                email="test@example.com", phone_number="+12125551234",
                first_name="Test", last_name="User",
                password_hash="hashed", role="customer",
            )
            session.add(user)
            await session.flush()

            vehicle = Vehicle(
                user_id=user.id, make="Toyota", model="Camry",
                year=2020, license_plate="ABC123", is_primary=True,
            )
            session.add(vehicle)
            await session.commit()

            self.user_id = str(user.id)
            self.vehicle_id = str(vehicle.id)

    @pytest.fixture(autouse=True)
    async def auth_token(self):
        from app.core.security import create_access_token
        self.token = create_access_token(user_id=self.user_id, role="customer")

    async def test_create_booking_success(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.post(
                "/api/v1/bookings",
                json={
                    "vehicle_id": self.vehicle_id,
                    "service_type": "tire_change",
                    "latitude": 40.7128,
                    "longitude": -74.0060,
                },
                headers={"Authorization": f"Bearer {self.token}"},
            )

            assert response.status_code == 201
            data = response.json()
            assert data["status"] == "pending"
            assert data["service_type"] == "tire_change"
            assert "id" in data

    async def test_get_booking_by_id(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            create_resp = await client.post(
                "/api/v1/bookings",
                json={
                    "vehicle_id": self.vehicle_id,
                    "service_type": "tire_change",
                    "latitude": 40.7128,
                    "longitude": -74.0060,
                },
                headers={"Authorization": f"Bearer {self.token}"},
            )
            booking_id = create_resp.json()["id"]

            response = await client.get(
                f"/api/v1/bookings/{booking_id}",
                headers={"Authorization": f"Bearer {self.token}"},
            )

            assert response.status_code == 200
            assert response.json()["id"] == booking_id

    async def test_create_booking_unauthenticated(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.post(
                "/api/v1/bookings",
                json={
                    "vehicle_id": self.vehicle_id,
                    "service_type": "tire_change",
                    "latitude": 40.7128,
                    "longitude": -74.0060,
                },
            )
            assert response.status_code == 403

    async def test_create_booking_invalid_vehicle(self):
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            response = await client.post(
                "/api/v1/bookings",
                json={
                    "vehicle_id": "00000000-0000-0000-0000-000000000000",
                    "service_type": "tire_change",
                    "latitude": 40.7128,
                    "longitude": -74.0060,
                },
                headers={"Authorization": f"Bearer {self.token}"},
            )
            assert response.status_code == 404


# tests/api/conftest.py
import pytest
from app.core.security import create_access_token

@pytest.fixture
def customer_token():
    return create_access_token(user_id="test-customer-id", role="customer")

@pytest.fixture
def mechanic_token():
    return create_access_token(user_id="test-mechanic-id", role="mechanic")

@pytest.fixture
def admin_token():
    return create_access_token(user_id="test-admin-id", role="admin")

@pytest.fixture
def auth_headers(customer_token):
    return {"Authorization": f"Bearer {customer_token}"}

@pytest.fixture
def admin_headers(admin_token):
    return {"Authorization": f"Bearer {admin_token}"}
```

---

### 14.5 Database Integration Tests

```python
# tests/integration/test_db_bookings.py
import pytest
from sqlalchemy import select, func
from app.models import BookingRequest, User, Vehicle

pytestmark = pytest.mark.asyncio

class TestBookingDatabase:
    async def test_create_booking_persists(self, test_db):
        async with test_db() as session:
            booking = BookingRequest(
                user_id=self.user_id, vehicle_id=self.vehicle_id,
                service_type="tire_change", status="pending",
                pickup_latitude=40.7128, pickup_longitude=-74.0060,
            )
            session.add(booking)
            await session.commit()
            await session.refresh(booking)

            assert booking.id is not None
            assert booking.status == "pending"
            assert booking.created_at is not None

    async def test_cascade_delete_user_deletes_bookings(self, test_db):
        async with test_db() as session:
            user = User(
                email="cascade@test.com", phone_number="+12125559876",
                first_name="Cascade", last_name="Test",
                password_hash="hash", role="customer",
            )
            session.add(user)
            await session.flush()

            vehicle = Vehicle(user_id=user.id, make="Honda", model="Civic", year=2021)
            session.add(vehicle)
            await session.flush()

            booking = BookingRequest(
                user_id=user.id, vehicle_id=vehicle.id,
                service_type="jump_start", pickup_latitude=40.0, pickup_longitude=-75.0,
            )
            session.add(booking)
            await session.commit()

            await session.delete(user)
            await session.commit()

            result = await session.execute(
                select(func.count(BookingRequest.id)).where(BookingRequest.user_id == user.id)
            )
            assert result.scalar() == 0

    async def test_booking_timestamps_update(self, test_db):
        async with test_db() as session:
            booking = BookingRequest(
                user_id=self.user_id, vehicle_id=self.vehicle_id,
                service_type="towing", pickup_latitude=40.0, pickup_longitude=-75.0,
            )
            session.add(booking)
            await session.commit()

            original_updated = booking.updated_at
            booking.status = "accepted"
            await session.commit()
            await session.refresh(booking)

            assert booking.updated_at > original_updated
```

---

### 14.6 AI Testing

#### Evaluation Tests

```python
# tests/ai/test_evaluations.py
import pytest
from app.ai.models import BookingMatcher
from app.ai.evaluations import MatchEvaluator

pytestmark = pytest.mark.asyncio

class TestBookingMatching:
    async def test_relevant_mechanic_match_priority(self):
        matcher = BookingMatcher()
        evaluator = MatchEvaluator()

        booking = {
            "service_type": "tire_change",
            "latitude": 40.7128, "longitude": -74.0060,
            "emergency_level": "normal",
        }

        mechanics = [
            {"id": "m1", "services": ["tire_change", "jump_start"], "distance_km": 2.0, "rating": 4.8},
            {"id": "m2", "services": ["towing"], "distance_km": 1.0, "rating": 4.5},
            {"id": "m3", "services": ["tire_change"], "distance_km": 5.0, "rating": 4.2},
        ]

        matches = await matcher.match_mechanics(booking, mechanics)
        scores = await evaluator.score_matches(booking, matches)

        assert matches[0]["mechanic_id"] == "m1"
        assert scores["precision_at_1"] == 1.0

    async def test_emergency_booking_speed_priority(self):
        matcher = BookingMatcher()
        booking = {"emergency_level": "critical", "latitude": 40.7128, "longitude": -74.0060}
        mechanics = [
            {"id": "fast", "distance_km": 1.0, "rating": 3.5},
            {"id": "slow", "distance_km": 10.0, "rating": 5.0},
        ]

        matches = await matcher.match_mechanics(booking, mechanics)
        assert matches[0]["mechanic_id"] == "fast"

    async def test_fallback_when_no_mechanic_available(self):
        matcher = BookingMatcher()
        matches = await matcher.match_mechanics({}, [])
        assert matches == []
        assert matcher.last_fallback_reason == "no_mechanics_available"
```

#### Guardrail Tests

```python
# tests/ai/test_guardrails.py
import pytest
from app.ai.guardrails import ContentGuardrail, SafetyGuardrail

class TestAIGuardrails:
    def test_content_profanity_detected(self):
        guardrail = ContentGuardrail()
        assert guardrail.contains_profanity("This is a good service") is False

    def test_safety_guardrail_blocks_dangerous_requests(self):
        guardrail = SafetyGuardrail()
        assert guardrail.is_safe_request("Help me fix my tire") is True
        assert guardrail.is_safe_request("How do I disable airbags?") is False

    def test_pii_detected(self):
        guardrail = ContentGuardrail()
        assert guardrail.contains_pii("My SSN is 123-45-6789") is True
        assert guardrail.contains_pii("I need a tow truck") is False
```

#### Latency Tests

```python
# tests/ai/test_latency.py
import pytest
import time
from app.ai.models import BookingMatcher

class TestAILatency:
    @pytest.mark.performance
    async def test_matching_response_time_under_threshold(self):
        matcher = BookingMatcher()
        booking = {"service_type": "tire_change", "latitude": 40.7128, "longitude": -74.0060}
        mechanics = [{"id": f"m{i}", "distance_km": float(i), "rating": 4.0} for i in range(100)]

        start = time.time()
        await matcher.match_mechanics(booking, mechanics)
        duration = time.time() - start

        assert duration < 0.5, f"Matching took {duration:.3f}s (threshold: 0.5s)"

    @pytest.mark.performance
    async def test_embedding_generation_latency(self):
        from app.ai.embeddings import EmbeddingGenerator
        generator = EmbeddingGenerator()

        start = time.time()
        embedding = await generator.generate("Flat tire on highway 95")
        duration = time.time() - start

        assert duration < 0.2
        assert len(embedding) == 1536
```

---

### 14.7 Coverage Targets

| Layer | Minimum Coverage | Stretch Goal | Measurement Tool |
|-------|-----------------|--------------|------------------|
| Unit tests (Python) | 90% | 95% | pytest-cov |
| Unit tests (Dart) | 90% | 95% | flutter test --coverage |
| Widget tests | 80% | 90% | flutter test --coverage |
| Integration tests | 70% of critical flows | 85% | pytest-cov / flutter test |
| AI evaluation tests | 100% of guardrails | - | Manual review |
| Overall | 85% | 92% | Combined reports |

```yaml
# .codecov.yml
codecov:
  require_ci_to_pass: true
  max_report_age: 24h

coverage:
  status:
    project:
      default:
        target: 85%
        threshold: 2%
        base: auto
        flags:
          - backend
          - mobile
      backend:
        target: 90%
        flags:
          - backend
      mobile:
        target: 85%
        flags:
          - mobile
    patch:
      default:
        target: 80%
        threshold: 5%

flags:
  backend:
    paths:
      - backend/app/
    carryforward: true
  mobile:
    paths:
      - mobile/lib/
    carryforward: true

ignore:
  - "**/migrations/"
  - "**/tests/"
  - "**/*.g.dart"
  - "**/*.freezed.dart"
```

---

### 14.8 Quality Gates

#### CI Quality Gates

| Gate | Tool | Threshold | Action on Failure |
|------|------|-----------|-------------------|
| Lint | ruff / flutter analyze | Zero warnings | Block PR |
| Format | ruff format / dart format | Zero diffs | Auto-format or block |
| Type check | mypy / dart analyze | Zero errors | Block PR |
| Unit coverage | pytest-cov / flutter test | 85%+ overall | Block PR (warning) |
| Security scan | Trivy / Snyk | Zero critical/high | Block PR |
| Tests pass | pytest / flutter test | 100% pass | Block PR |
| Build | Docker build | Success | Block PR |

#### PR Merge Requirements

- Require status checks to pass: Lint Backend, Lint Mobile, Test Backend, Test Mobile, Security Scan, Build
- Require branches to be up to date
- Require at least one approval
- Dismiss stale reviews

---

### 14.9 Regression Testing

#### Full Test Suite on Every PR

Every pull request triggers:
- All unit tests (backend + mobile)
- All widget tests
- All integration tests
- Security scans
- Performance benchmarks (non-blocking)

#### Critical Flow Regression

These flows are always tested before any production release:

1. **User Registration & Login** – Email, phone, OTP, social auth
2. **Booking Lifecycle** – Create, Match, Accept, In Progress, Complete
3. **Payment Processing** – Card payment, wallet payment, refund
4. **Mechanic Assignment** – AI matching, manual assignment
5. **Push Notifications** – Booking updates, payment receipts
6. **Emergency Flow** – High/Critical priority booking handling
7. **Location Tracking** – Real-time mechanic location updates
8. **Offline Mode** – Queued requests, retry logic

#### Visual Regression Testing

```dart
// test/widgets/visual_regression_test.dart
import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanect/widgets/booking_card.dart';

void main() {
  goldenTest(
    'BookingCard renders correctly',
    fileName: 'booking_card_default',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'pending state',
          child: BookingCard(
            booking: Booking(id: '1', status: BookingStatus.pending),
            onTap: () {},
          ),
        ),
        GoldenTestScenario(
          name: 'in progress state',
          child: BookingCard(
            booking: Booking(id: '2', status: BookingStatus.inProgress),
            onTap: () {},
          ),
        ),
        GoldenTestScenario(
          name: 'completed state',
          child: BookingCard(
            booking: Booking(id: '3', status: BookingStatus.completed),
            onTap: () {},
          ),
        ),
        GoldenTestScenario(
          name: 'error state',
          child: BookingCard(errorMessage: 'Something went wrong', onTap: () {}),
        ),
      ],
    ),
  );
}
```

---

## 15. Documentation Standards

### 15.1 README

Every repository MUST have a `README.md` at the root with the following structure:

#### README Template

```markdown
# Mecha Connect -- {Service Name}

> {One-line description of the service}

## Overview

{2-3 paragraph description of the service, its purpose, and how it fits into
the Mecha Connect ecosystem.}

## Architecture

\`\`\`
+-------------+     +-------------+     +-------------+
|  Flutter App |---->|   API GW    |---->|  {Service}  |
+-------------+     +-------------+     +------+------+
                                               |
                                        +------+------+
                                        |  PostgreSQL  |
                                        +-------------+
\`\`\`

## Quick Start

### Prerequisites

- Python 3.12+
- Docker & Docker Compose

### Local Development

```bash
git clone https://github.com/mechaconnect/{repo}.git
cd {repo}

cp .env.example .env

docker-compose up -d db redis

pip install -r requirements-dev.txt

alembic upgrade head

uvicorn app.main:app --reload
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | postgresql+asyncpg://... | Database connection string |
| `REDIS_URL` | redis://localhost:6379/0 | Redis connection string |
| `LOG_LEVEL` | INFO | Logging level |

## API Documentation

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Testing

```bash
pytest
pytest --cov=app --cov-report=html
```

## Deployment

See [DevOps Standards](#13-devops-standards) in the MEH.

## Contributing

See [CONTRIBUTING.md](../03_development/CONTRIBUTING.md).
```

---

### 15.2 ADR (Architecture Decision Records)

#### When to Write an ADR

Write an ADR for any significant architectural decision that:
- Introduces a new technology, framework, or library
- Changes the system architecture
- Affects cross-cutting concerns (auth, data flow, deployment)
- Has long-term implications or is irreversible

#### ADR Template

```markdown
# ADR-{NNN}: {Short Decision Title}

## Status

[Proposed | Accepted | Deprecated | Superseded]

If superseded, link to superseding ADR: ADR-{NNN+1}

## Context

{Describe the problem, forces, and constraints that led to this decision.
Include technical, business, and organizational context.}

## Decision

{Describe the decision clearly. What are we doing? What are we NOT doing?}

## Consequences

### Positive
- {Benefit 1}
- {Benefit 2}

### Negative
- {Trade-off 1}
- {Trade-off 2}

### Neutral
- {Observation 1}

## Alternatives Considered

| Alternative | Pros | Cons |
|-------------|------|------|
| {Alt 1} | {Pros} | {Cons} |
| {Alt 2} | {Pros} | {Cons} |

## References

- [Link to RFC, issue, or related document]
- [Link to code or PR]
```

#### Example ADR

```markdown
# ADR-001: PostgreSQL for Primary Database

## Status

Accepted

## Context

Mecha Connect requires a primary database that supports ACID transactions,
geospatial queries (for mechanic location matching), JSON fields (for flexible
notification data), and high reliability for payment processing. We considered
MongoDB and CockroachDB as alternatives.

## Decision

We will use PostgreSQL 16 with PostGIS as our primary database.

## Consequences

### Positive
- Strong ACID compliance for financial transactions
- PostGIS provides native geospatial support for location-based matching
- Mature ecosystem with excellent async support (SQLAlchemy + asyncpg)

### Negative
- Vertical scaling only (no auto-sharding like CockroachDB)
- Requires careful connection pool management

### Neutral
- Team has strong PostgreSQL experience; no new learning curve

## Alternatives Considered

| Alternative | Pros | Cons |
|-------------|------|------|
| MongoDB | Flexible schema, horizontal scaling | No ACID for payments, weaker geospatial |
| CockroachDB | Horizontal scaling, PostgreSQL compatible | Higher operational complexity, newer |

## References

- [PostgreSQL 16 Release Notes](https://www.postgresql.org/docs/16/release-16.html)
- [PostGIS Manual](https://postgis.net/documentation/)
```

---

### 15.3 RFC (Request for Comments)

#### RFC Template

```markdown
# RFC-{NNN}: {Title}

## Status

[Draft | In Review | Final Comment | Approved | Rejected | Implemented]

## Motivation

{Why is this change needed? What problem does it solve? What metrics will
improve?}

## Design

### Overview

{High-level description of the proposed solution}

### Detailed Design

{Technical details, diagrams, API contracts, data models}

#### API Changes

```json
{
  "endpoint": "POST /api/v1/bookings",
  "request": {
    "vehicle_id": "uuid",
    "service_type": "string",
    "latitude": "number",
    "longitude": "number"
  },
  "response": {
    "id": "uuid",
    "status": "string",
    "eta_minutes": "number"
  }
}
```

#### Data Model Changes

```sql
ALTER TABLE booking_requests ADD COLUMN ai_confidence_score DECIMAL(5,4);
```

### Migration Plan

1. Deploy database migration (non-locking)
2. Deploy backend with backward-compatible API
3. Verify metrics, rollback if needed
4. Deploy mobile app update
5. Remove deprecated fields (next release)

## Alternatives Considered

| Approach | Pros | Cons |
|----------|------|------|
| {Approach A} | {Pros} | {Cons} |
| {Approach B} | {Pros} | {Cons} |

## Implementation Plan

### Phases

| Phase | Description | Duration |
|-------|-------------|----------|
| 1 | Backend implementation + tests | 3 days |
| 2 | Mobile implementation | 2 days |
| 3 | Staging deployment + validation | 1 day |
| 4 | Production rollout | 1 day |

## Open Questions

- {Question 1}
- {Question 2}

## References

- {Link to related issues, PRs, or documents}
```

---

### 15.4 API Documentation

#### OpenAPI / Swagger

- **Auto-generated** from FastAPI route decorators and Pydantic schemas.
- **Available at**: `/docs` (Swagger UI) and `/redoc` (ReDoc).
- **Every endpoint must include**:
  - Summary and description
  - Request body schema (Pydantic model)
  - Response model with examples
  - Error response schemas (4xx, 5xx)
  - Tag for grouping

```python
from pydantic import BaseModel, Field
from typing import Optional

class CreateBookingRequest(BaseModel):
    """Request schema for creating a new booking."""
    vehicle_id: str = Field(..., description="UUID of the user\\'s vehicle")
    service_type: str = Field(..., description="Type of service requested")
    latitude: float = Field(..., ge=-90, le=90, description="Pickup latitude")
    longitude: float = Field(..., ge=-180, le=180, description="Pickup longitude")
    description: Optional[str] = Field(None, max_length=500, description="Issue description")


@router.post(
    "/bookings",
    response_model=BookingResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new booking request",
    description="Creates a roadside assistance booking. Returns the booking with estimated ETA.",
    tags=["Bookings"],
    responses={
        201: {"description": "Booking created successfully"},
        400: {"description": "Invalid request data"},
        404: {"description": "Vehicle not found"},
        429: {"description": "Rate limit exceeded"},
    },
)
async def create_booking(
    request: CreateBookingRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new roadside assistance booking.

    This endpoint:
    - Validates the vehicle belongs to the user
    - Creates a booking with 'pending' status
    - Triggers AI mechanic matching
    - Returns estimated ETA
    """
    ...
```

#### Postman Collections

- **Postman collection** stored in `docs/postman/mechanect-collection.json`
- **Environment files** for dev, staging, and prod
- Collection includes:
  - All endpoints with examples
  - Auth pre-request scripts (auto-refresh token)
  - Test scripts for response validation

```json
{
  "info": {
    "name": "Mecha Connect API",
    "description": "API collection for Mecha Connect roadside assistance platform"
  },
  "variable": [
    { "key": "base_url", "value": "http://localhost:8000" },
    { "key": "token", "value": "" }
  ],
  "auth": {
    "type": "bearer",
    "bearer": [{ "key": "token", "value": "{{token}}", "type": "string" }]
  },
  "item": [
    {
      "name": "Auth",
      "item": [
        {
          "name": "Login",
          "request": {
            "method": "POST",
            "url": "{{base_url}}/api/v1/auth/login",
            "body": {
              "mode": "raw",
              "raw": "{\"email\": \"user@example.com\", \"password\": \"Test1234!\"}",
              "options": { "raw": { "language": "json" } }
            }
          }
        }
      ]
    }
  ]
}
```

---

### 15.5 Architecture Documentation

#### C4 Model

Mecha Connect uses the **C4 model** for architecture documentation:

| Level | Name | Audience | Artifact |
|-------|------|----------|----------|
| Level 1 | System Context | All stakeholders | System context diagram |
| Level 2 | Container | Engineering team | Container diagram (services, DBs, caches) |
| Level 3 | Component | Developers | Component diagram per service |
| Level 4 | Code | Developers | UML class diagrams / ERDs |

#### System Context Diagram (Level 1)

```mermaid
graph TD
    U[User] -->|Uses| A[Mecha Connect Mobile App]
    A -->|API calls| B[Mecha Connect API]
    B -->|Sends| C[Push Notification]
    B -->|SMS / OTP| D[Twilio]
    B -->|Payments| E[Stripe]
    B -->|AI Matching| F[AI Service]
    F -->|Embeddings| G[Pinecone]
    F -->|LLM| H[OpenAI]
    B -->|Maps| I[Google Maps / Mapbox]
    J[Admin] -->|Dashboard| K[Mecha Connect Admin Portal]
    K --> B
```

#### Container Diagram (Level 2)

```mermaid
graph TD
    subgraph "Mobile"
        A[Flutter App]
    end
    subgraph "Web"
        B[Flutter Web]
    end
    subgraph "Backend"
        C[FastAPI Service]
        D[AI Service - FastAPI]
    end
    subgraph "Data Stores"
        E[(PostgreSQL + PostGIS)]
        F[(Redis)]
        G[(Pinecone)]
    end
    subgraph "External"
        H[Stripe]
        I[Twilio]
        J[OpenAI]
    end

    A --> C
    B --> C
    C --> E
    C --> F
    D --> F
    D --> G
    D --> J
    C --> H
    C --> I
    C --> D
```

#### Architecture Decision Records

All significant architecture decisions are documented as ADRs in `docs/adr/`:

```
docs/adr/
  0001-use-postgresql.md
  0002-use-jwt-auth.md
  0003-use-redis-for-caching.md
  0004-use-pinecone-for-vectors.md
  0005-blue-green-deployment.md
```

---

### 15.6 Code Comments

#### Rules

1. **Public API docs required** – All public functions, classes, and methods MUST have docstrings.
2. **Complex logic comments** – Any non-obvious algorithm, business rule, or workaround MUST be explained.
3. **No obvious comments** – Do not comment `i += 1  # increment i`.
4. **TODO comments** – Must include ticket number: `# TODO(MECHA-1234): Implement retry logic`.
5. **Docstring format** – Use Google-style docstrings for Python, Dartdoc for Dart.

#### Python Docstrings (Google Style)

```python
def calculate_booking_price(
    service_type: str,
    distance_km: Decimal,
    vehicle_type: str,
    emergency_level: str = "normal",
) -> Decimal:
    """Calculate the price for a roadside assistance booking.

    The pricing model considers:
    - Base price by service type
    - Distance surcharge (per km beyond free radius)
    - Vehicle type multiplier (SUV, truck cost more)
    - Emergency level multiplier (critical = 2x)

    Args:
        service_type: Type of service (tire_change, towing, etc.)
        distance_km: Distance from mechanic to customer in km
        vehicle_type: Type of vehicle (sedan, suv, truck)
        emergency_level: Emergency priority level

    Returns:
        The calculated price as a Decimal

    Raises:
        ValueError: If distance_km is negative or service_type is invalid
    """
```

#### Dart Docstrings

```dart
/// Calculates the estimated time of arrival for a mechanic.
///
/// Uses the Haversine formula to calculate distance between two coordinates,
/// then divides by average speed based on road type and traffic conditions.
///
/// Parameters:
///   - [mechanicLat]: Latitude of the mechanic's current location
///   - [mechanicLng]: Longitude of the mechanic's current location
///   - [customerLat]: Latitude of the customer's location
///   - [customerLng]: Longitude of the customer's location
///
/// Returns the ETA in minutes as an integer.
///
/// Throws [ArgumentError] if coordinates are out of valid range.
int calculateEta({
  required double mechanicLat,
  required double mechanicLng,
  required double customerLat,
  required double customerLng,
}) {
  // Haversine formula implementation
  ...
}
```

---

### 15.7 Changelog

We follow [Keep a Changelog](https://keepachangelog.com/) format.

#### Changelog Template

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New feature description (#PR-number)

### Changed
- Change in existing functionality (#PR-number)

### Deprecated
- Feature to be removed in future (#PR-number)

### Removed
- Feature removed (#PR-number)

### Fixed
- Bug fix description (#PR-number)

### Security
- Security fix description (#PR-number)

---

## [1.2.0] - 2025-01-15

### Added
- AI-powered mechanic matching with confidence scoring (#142)
- Push notifications for booking status updates (#138)
- Wallet balance display on home screen (#135)
- Mechanic subscription tiers (free, basic, premium) (#130)

### Changed
- Increased file upload limit from 5MB to 10MB (#145)
- Optimized booking list query with composite indexes (#140)

### Fixed
- Fixed crash on Android 12 when requesting location permissions (#143)
- Fixed incorrect currency symbol in payment receipts (#139)

### Security
- Updated JWT signing algorithm from HS256 to RS256 (#141)
- Added rate limiting on OTP endpoint (#137)

---

## [1.1.0] - 2024-12-20

### Added
- Review and rating system for mechanics (#120)
- Vehicle management (add, edit, delete vehicles) (#115)

### Fixed
- Fixed race condition in booking cancellation (#118)

---

## [1.0.0] - 2024-12-01

### Added
- Initial release of Mecha Connect
- User registration and authentication
- Booking creation and management
- Mechanic matching and assignment
- Payment processing with Stripe
- Real-time location tracking
```

---

### 15.8 Release Notes

#### Release Notes Template

```markdown
# Mecha Connect v{version} Release Notes

**Release Date**: {YYYY-MM-DD}

## Overview

{Brief summary of what this release includes - 1-2 paragraphs}

## What's New

### {Feature Name}
{Description of the feature, why it was built, and how it benefits users}

### {Feature Name}
{Description}

## Breaking Changes

{if any}

### {Breaking Change}

- **What changed**: {Description}
- **Why**: {Reason}
- **Migration guide**: {Steps to update}
- **Impacted endpoints**: {List of endpoints}
- **Timeline**: {When old behavior will be removed}

## Improvements

- {Improvement 1}
- {Improvement 2}

## Bug Fixes

- {Issue #}: {Description}
- {Issue #}: {Description}

## Performance

- {Improvement metric}: {Before vs After}

## Security

- {Security fix description}

## Dependency Updates

| Package | Old Version | New Version | Reason |
|---------|-------------|-------------|--------|
| fastapi | 0.109.0 | 0.110.0 | Security patch |
| flutter | 3.19.0 | 3.22.0 | Performance improvements |

## Deployment Notes

### Database Migrations
- {Migration file}: {Description}

### Configuration Changes
- {Config key}: {Old value} -> {New value}

### Rollback Plan
1. Revert backend to previous Docker image
2. Run down migration: `alembic downgrade -1`
3. Verify system health

## Known Issues

- {Issue #}: {Description and workaround}

## Contributors

- @{github_username} - {Contribution}
- @{github_username} - {Contribution}

---

Full changelog: [CHANGELOG.md](../03_development/CHANGELOG.md)
```
---

## 23. Mermaid Diagrams

### 23.1 Engineering Workflow

```mermaid
flowchart LR
    A[Idea / Bug Report] --> B[RFC / Issue]
    B --> C[Backlog Refinement]
    C --> D[Sprint Planning]
    D --> E[Development]
    E --> F[Code Review]
    F --> G[QA Testing]
    G --> H{Pass?}
    H -- Yes --> I[Staging Deploy]
    H -- No --> E
    I --> J[Release Candidate]
    J --> K[Canary Deploy]
    K --> L{Healthy?}
    L -- Yes --> M[Production Deploy]
    L -- No --> J
    M --> N[Post-release Monitor]
    N --> O{Issues?}
    O -- Yes --> P[Hotfix / Rollback]
    O -- No --> Q[Done]
    P --> N
```

### 23.2 Git Workflow (Detailed)

```mermaid
gitGraph
    commit id: "init"
    branch develop
    commit id: "setup"
    branch feature/ai-chat
    commit id: "add chat prompt"
    commit id: "add response parser"
    checkout develop
    branch feature/user-auth
    commit id: "add auth service"
    commit id: "add login page"
    checkout feature/ai-chat
    commit id: "add tests"
    checkout develop
    merge feature/ai-chat
    checkout feature/user-auth
    commit id: "add token refresh"
    checkout develop
    merge feature/user-auth
    branch release/v2.1.0
    commit id: "bump version"
    commit id: "final fixes"
    checkout main
    merge release/v2.1.0 tag: "v2.1.0"
    checkout develop
    merge main
```

### 23.3 Release Flow

```mermaid
flowchart TD
    subgraph Preparation
        A[Code Freeze] --> B[Version Bump]
        B --> C[Changelog Update]
        C --> D[Release Branch]
    end
    subgraph Validation
        D --> E[CI Pipeline]
        E --> F[Integration Tests]
        F --> G[Regression Tests]
        G --> H[Performance Tests]
        H --> I[Security Scan]
    end
    subgraph Deployment
        I --> J{All Green?}
        J -- Yes --> K[Staging Deploy]
        J -- No --> D
        K --> L[Canary 5%]
        L --> M{Stable?}
        M -- Yes --> N[Canary 25%]
        M -- No --> O[Rollback]
        N --> P{Stable?}
        P -- Yes --> Q[Canary 50%]
        P -- No --> O
        Q --> R{Stable?}
        R -- Yes --> S[Full 100%]
        R -- No --> O
    end
    subgraph Post-Release
        S --> T[Monitor 30min]
        T --> U{Issues?}
        U -- Yes --> O
        U -- No --> V[Declare Success]
    end
```

### 23.4 CI/CD Flow

```mermaid
flowchart LR
    A[Git Push] --> B[CI Trigger]
    subgraph CI
        B --> C[Lint]
        C --> D[Unit Tests]
        D --> E[Build]
        E --> F[Integration Tests]
        F --> G[Security Scan]
        G --> H[Docker Build]
    end
    subgraph CD
        H --> I[Push to Registry]
        I --> J[Deploy to Staging]
        J --> K[Smoke Tests]
        K --> L{Pass?}
        L -- Yes --> M[Deploy to Production]
        L -- No --> N[Alert Team]
    end
    M --> O[Health Checks]
    O --> P{Healthy?}
    P -- Yes --> Q[Success]
    P -- No --> R[Auto-rollback]
```

### 23.5 Repository Structure

```mermaid
graph TD
    Repo[Mecha Connect Monorepo] --> BE[backend/]
    Repo --> FE[flutter_app/]
    Repo --> AI[ai/]
    Repo --> INFRA[infrastructure/]
    Repo --> DOCS[docs/]
    Repo --> SCRIPTS[scripts/]
    Repo --> ROOT[config files]
    BE --> BE_SRC[src/]
    BE_SRC --> API[api/]
    BE_SRC --> CORE[core/]
    BE_SRC --> MODELS[models/]
    BE_SRC --> SERVICES[services/]
    BE_SRC --> DB[db/]
    FE --> FE_LIB[lib/]
    FE_LIB --> FEATURES[features/]
    FE_LIB --> CORE2[core/]
    FE_LIB --> WIDGETS[widgets/]
    AI --> AI_SRC[src/]
    AI_SRC --> PROMPTS[prompts/]
    AI_SRC --> EVAL[eval/]
    AI_SRC --> MODELS2[models/]
    INFRA --> TF[terraform/]
    INFRA --> K8S[k8s/]
    INFRA --> CI[ci/]
```

### 23.6 Code Review Process

```mermaid
flowchart TD
    A[Author Opens PR] --> B[CI Checks Run]
    B --> C{All Green?}
    C -- No --> D[Fix and Push]
    D --> B
    C -- Yes --> E[Assign Reviewers]
    E --> F[Reviewer Assigned]
    F --> G[Review Code]
    G --> H{Changes Needed?}
    H -- Yes --> I[Request Changes]
    I --> J[Author Addresses]
    J --> K[Re-request Review]
    K --> G
    H -- No --> L[Approve]
    L --> M[PR Merged]
    M --> N[Delete Branch]
```

### 23.7 Bug Lifecycle

```mermaid
flowchart TD
    A[Bug Report Filed] --> B[Triage]
    B --> C{Valid Bug?}
    C -- No --> D[Close / Not a Bug]
    C -- Yes --> E[Assign Severity]
    E --> F{Severity Level}
    F -- SEV1 --> G[Immediate Fix]
    F -- SEV2 --> H[Next Release]
    F -- SEV3/4 --> I[Backlog]
    G --> J[Hotfix Branch]
    J --> K[Fix + Test]
    K --> L[Review]
    L --> M[Deploy]
    M --> N[Verify in Production]
    N --> O[Close Bug]
    H --> P[Sprint Planning]
    P --> Q[Fix in Sprint]
    Q --> K
    I --> R[Prioritize]
    R --> P
```

### 23.8 Feature Lifecycle

```mermaid
flowchart LR
    A[Idea] --> B[Feature Request]
    B --> C[Product Review]
    C --> D{Approved?}
    D -- No --> E[Rejected / Parked]
    D -- Yes --> F[RFC (if needed)]
    F --> G[Design Review]
    G --> H[Backlog]
    H --> I[Sprint Planning]
    I --> J[Development]
    J --> K[Code Review]
    K --> L[QA Testing]
    L --> M[Staging]
    M --> N[Release]
    N --> O[Monitor]
    O --> P[Feature Flag Cleanup]
    P --> Q[Documentation]
```

### 23.9 AI Development Workflow

```mermaid
flowchart TD
    A[Define Problem] --> B[Collect Dataset]
    B --> C[Create Eval Set]
    C --> D[Design Prompt Template]
    D --> E[Implement in Code]
    E --> F[Add Pydantic Parser]
    F --> G[Add Fallback Logic]
    G --> H[Unit Test]
    H --> I[Run Eval Suite]
    I --> J{Accuracy > 90%?}
    J -- No --> D
    J -- Yes --> K[Latency Test]
    K --> L{Latency < Budget?}
    L -- No --> M[Optimize]
    M --> K
    L -- Yes --> N[Add Monitoring]
    N --> O[Deploy with Feature Flag]
    O --> P[A/B Test]
    P --> Q[Gradual Rollout]
    Q --> R[Monitor & Iterate]
```

### 23.10 Flutter Architecture

```mermaid
flowchart TD
    subgraph Presentation Layer
        UI[Screens / Widgets]
        BLoC[BLoC / Riverpod Providers]
    end
    subgraph Domain Layer
        UC[Use Cases]
        REPO_INTERFACE[Repository Interfaces]
        ENTITIES[Entities]
    end
    subgraph Data Layer
        REPO_IMPL[Repository Implementations]
        DS[Data Sources - Remote/Local]
        MODELS[DTO Models]
    end
    UI --> BLoC
    BLoC --> UC
    UC --> REPO_INTERFACE
    REPO_INTERFACE --> REPO_IMPL
    REPO_IMPL --> DS
    DS --> API[API Client]
    DS --> DB2[Local Database]
    DS --> CACHE[Cache]
```

### 23.11 Backend Architecture

```mermaid
flowchart TD
    subgraph Client
        APP[Mobile App]
        WEB[Web App]
    end
    subgraph API Gateway
        GW[Load Balancer / API Gateway]
        GW --> AUTH[Auth Service]
        GW --> RATE[Rate Limiter]
    end
    subgraph Services
        API_SVC[API Server - FastAPI]
        WKR[Worker - Celery]
        AI_SVC[AI Service]
        NOTIF[Notification Service]
    end
    subgraph Data
        PG[(PostgreSQL)]
        RD[(Redis)]
        S3[(Object Storage)]
        ES[(Elasticsearch)]
    end
    subgraph Infrastructure
        MON[Monitoring - Prometheus/Grafana]
        LOG[Logging - ELK/Loki]
        K8S[Kubernetes]
    end
    GW --> API_SVC
    API_SVC --> WKR
    API_SVC --> AI_SVC
    API_SVC --> NOTIF
    API_SVC --> PG
    API_SVC --> RD
    WKR --> PG
    AI_SVC --> RD
    K8S --> GW
    K8S --> API_SVC
    K8S --> AI_SVC
    MON --> API_SVC
    LOG --> API_SVC
```

### 23.12 DevOps Flow

```mermaid
flowchart LR
    subgraph Code
        DEV[Developer] --> GIT[Git Push]
    end
    subgraph CI
        GIT --> CICD[GitHub Actions]
        CICD --> LINT[Lint]
        CICD --> TEST[Test]
        CICD --> BUILD[Build]
        CICD --> SCAN[Security Scan]
        CICD --> DOCKER[Docker Image]
    end
    subgraph Registry
        DOCKER --> REG[Container Registry]
    end
    subgraph CD
        REG --> DEPLOY[Deploy to K8s]
        DEPLOY --> CANARY[Canary]
        CANARY --> FULL[Full Rollout]
    end
    subgraph Monitor
        FULL --> PROM[Prometheus]
        PROM --> ALERT[Alerting]
        ALERT --> PAGER[PagerDuty]
    end
```

### 23.13 Testing Workflow

```mermaid
flowchart TD
    subgraph Local
        A[Write Code] --> B[Run Unit Tests]
        B --> C{Pass?}
        C -- No --> A
        C -- Yes --> D[Run Widget Tests]
        D --> E{Pass?}
        E -- No --> A
        E -- Yes --> F[Push to Remote]
    end
    subgraph CI
        F --> G[CI Pipeline]
        G --> H[Unit Tests]
        H --> I[Integration Tests]
        I --> J[Widget Tests]
        J --> K[Build]
        K --> L[Smoke Tests]
        L --> M{All Pass?}
        M -- No --> N[Fail Build]
        M -- Yes --> O[Deploy to Staging]
    end
    subgraph Staging
        O --> P[QA Manual Tests]
        P --> Q[E2E Tests]
        Q --> R{Pass?}
        R -- No --> A
        R -- Yes --> S[Ready for Production]
    end
```

### 23.14 Incident Response

```mermaid
flowchart TD
    A[Alert Triggers] --> B{SEV Level?}
    B -- SEV1 --> C[Page Primary On-call]
    B -- SEV2 --> D[Notify Primary On-call]
    B -- SEV3/4 --> E[Add to Backlog]
    C --> F[On-call Acknowledges]
    F --> G[Assess Impact]
    G --> H[Declare Incident]
    H --> I[Create Incident Channel]
    I --> J[Assign Incident Commander]
    J --> K[Responders Investigate]
    K --> L{Root Cause Found?}
    L -- No --> K
    L -- Yes --> M[Apply Mitigation]
    M --> N[Verify Recovery]
    N --> O{Recovered?}
    O -- No --> M
    O -- Yes --> P[Monitor for 30min]
    P --> Q{Stable?}
    Q -- Yes --> R[Resolve Incident]
    Q -- No --> M
    R --> S[Schedule Postmortem]
```

### 23.15 Documentation Workflow

```mermaid
flowchart LR
    A[Need Identified] --> B[Determine Type]
    B --> C{Documentation Type}
    C -- API --> D[Update OpenAPI Spec]
    C -- Architecture --> E[Write ADR]
    C -- Feature --> F[Write RFC]
    C -- User Guide --> G[Update Wiki/Notion]
    C -- Runbook --> H[Update Ops Manual]
    D --> I[Review with Team]
    E --> I
    F --> I
    G --> I
    H --> I
    I --> J{Approved?}
    J -- No --> K[Revise]
    K --> I
    J -- Yes --> L[Publish]
    L --> M[Notify Team]
```

### 23.16 Deployment Workflow

```mermaid
flowchart TD
    A[Merge to Main] --> B[CI Pipeline]
    B --> C[Build Artifacts]
    C --> D[Run Tests]
    D --> E{Pass?}
    E -- No --> F[Notify Team]
    E -- Yes --> G[Push Docker Image]
    G --> H[Tag Release]
    H --> I[Update K8s Manifests]
    I --> J[ArgoCD Sync]
    J --> K[Deploy to Staging]
    K --> L[Smoke Tests]
    L --> M{Pass?}
    M -- No --> N[Rollback Staging]
    M -- Yes --> O[Deploy to Prod Canary]
    O --> P[Metrics Check]
    P --> Q{Healthy?}
    Q -- No --> R[Rollback Canary]
    Q -- Yes --> S[Gradual Rollout]
    S --> T[Full Prod]
    T --> U[Post-deploy Monitor]
```

---

## 24. Best Practices

### 24.1 Google Engineering Practices

Key principles from Google's engineering culture applied to Mecha Connect:

- **Code Review First** -- Every change must be reviewed. No direct pushes to main.
- **Testing Culture** -- Write tests before code (TDD where practical). All code must have tests.
- **Psychological Safety** -- Review code, not the person. Ask questions, don't assign blame.
- **51% Rule** -- If a design change has a 51% chance of being better, do it. Iterate fast.
- **Bias for Action** -- Prefer shipping a good-enough solution over waiting for perfect.
- **Documentation as Code** -- Docs live in the repo, reviewed like code, versioned with releases.
- **Error Budgets** -- SLOs define acceptable error rates. Use error budget for release decisions.
- **SRE Principles** -- Measure everything, automate toil, design for reliability.

Reference: Google's Engineering Practices documentation at https://google.github.io/eng-practices/

### 24.2 Microsoft Engineering Practices

Key principles from Microsoft's engineering approach:

- **One Engineering System (1ES)** -- Unified toolchain, standards, and processes across all teams.
- **Accessibility First** -- All features must meet Microsoft Accessibility standards (WCAG 2.1 AA).
- **Security Development Lifecycle (SDL)** -- Threat modeling, static analysis, dynamic analysis for every feature.
- **Live Site First** -- Production incidents take priority over feature work. Live site culture.
- **Dogfooding** -- Use your own product before customers do. Internal previews mandatory.
- **Telemetry-driven** -- Every feature ships with instrumentation. Decisions based on data.
- **Inclusive Design** -- Design for users of all abilities. Consider localization and cultural differences.

Reference: Microsoft Engineering at https://learn.microsoft.com/en-us/engineering/

### 24.3 Amazon Engineering Practices (Working Backwards)

Amazon's Working Backwards methodology applied:

- **Press Release First** -- Write the press release and FAQ before writing any code. What will customers say?
- **Customer Persona** -- Define the target customer. Write in their voice.
- **PR/FAQ Structure:**
  1. Headline (what is the feature in one sentence?)
  2. Customer Problem (what is the customer need?)
  3. Solution (how does it work?)
  4. FAQ (handle objections, edge cases, technical concerns)
- **Six-Pager** -- For significant features, write a 6-page narrative document. No bullet points.
- **Two-Pizza Teams** -- Teams should be small enough to be fed with two pizzas (< 10 people).
- **Single-Threaded Ownership** -- One leader, one team, one metric for each initiative.
- **Flywheel Thinking** -- Every feature should strengthen the overall product flywheel.

### 24.4 Netflix Engineering Practices (Chaos Engineering)

Netflix-inspired resilience practices:

- **Chaos Monkey** -- Randomly terminate production instances to ensure systems survive failures.
- **Chaos Kong** -- Simulate AWS region failures. Test multi-region resilience.
- **Chaos Gorilla** -- Simulate entire availability zone failures.
- **Simian Army** -- Suite of tools: Latency Monkey, Conformity Monkey, Security Monkey.
- **Principles:**
  - **Build for Failure** -- Assume everything fails. Design graceful degradation.
  - **Defense in Depth** -- Multiple layers of resilience (retries, circuit breakers, bulkheads).
  - **Stateless Services** -- Prefer stateless services. State belongs in data stores.
  - **Immutable Infrastructure** -- Never modify running servers. Replace them.
  - **Self-healing** -- Automatically detect and recover from failures.
- **Application at Mecha Connect:**
  - Run chaos engineering experiments monthly in staging
  - Test circuit breakers for all external service calls
  - Verify bulkhead isolation between services
  - Practice failure injection for AI service endpoints

### 24.5 OpenAI Engineering Practices

AI-specific engineering practices from OpenAI's development approach:

- **Prompt Engineering** -- Treat prompts as code. Version control, test, review, deploy.
- **Structured Outputs** -- Always use structured parsing (Pydantic, JSON mode) for model outputs.
- **Streaming First** -- Prefer streaming for user-facing AI features. Better UX, faster TTFB.
- **Evaluation-Driven Development** -- Define eval sets before writing prompts. Measure every change.
- **Gradual Deploy with Guardrails** -- Deploy AI features behind feature flags with kill switches.
- **Red Teaming** -- Deliberately try to break AI features. Probe for prompt injection, toxicity, bias.
- **Cost Awareness** -- Every AI feature should have budget tracking. Monitor cost per inference.
- **Model Version Pinning** -- Never float to latest. Pin to specific model versions and test upgrades.
- **Caching** -- Implement semantic caching for repeated queries. Reduces cost and latency.
- **Feedback Loops** -- Capture user feedback (thumbs up/down). Use to improve prompts and eval sets.

### 24.6 Flutter Best Practices Summary

1. **State Management** -- Use BLoC or Riverpod consistently across the app. No mixing patterns.
2. **Widget Tree** -- Keep widget trees shallow. Extract widgets into methods or separate classes.
3. **const Constructors** -- Use const constructors everywhere possible to reduce rebuilds.
4. **Build Methods** -- Keep build methods pure. No side effects, no async calls.
5. **Immutability** -- Use immutable models with copyWith for state changes.
6. **Asset Optimization** -- Use WebP/AVIF for images. Provide multiple resolution variants.
7. **Navigation** -- Use GoRouter for declarative routing. Type-safe navigation.
8. **Dependency Injection** -- Use GetIt or Riverpod for DI. Avoid Service Locator anti-pattern.
9. **Error Handling** -- Use custom error widgets. Always handle loading/error/empty states.
10. **Performance** -- Use DevTools profiler regularly. Profile on low-end devices.
11. **Platform Channels** -- Isolate platform-specific code. Test both iOS and Android.
12. **Localization** -- Use ARB files for strings. Never hardcode user-facing text.
13. **Accessibility** -- Add semantic labels to all interactive widgets. Support screen readers.
14. **Testing** -- Write unit tests for business logic, widget tests for UI, integration tests for flows.

### 24.7 Python Best Practices Summary

1. **PEP 8** -- Follow PEP 8 style guide. Use Black for formatting (line length 88).
2. **Type Hints** -- Use type hints everywhere. Run mypy in strict mode.
3. **Pydantic** -- Use Pydantic v2 for all data validation and settings management.
4. **Async/Await** -- Use async/await for I/O-bound operations. Never block the event loop.
5. **Error Handling** -- Use custom exception classes. Catch specific exceptions, not broad except.
6. **Logging** -- Use structured logging with proper levels. Never use print().
7. **Dependency Management** -- Use Poetry or pip-tools. Pin dependencies in lock file.
8. **Project Structure** -- Follow src-layout: src/package_name/ structure.
9. **Testing** -- Use pytest with fixtures. Aim for > 85% coverage.
10. **Documentation** -- Use Google-style docstrings. Generate docs with Sphinx or MkDocs.
11. **Configuration** -- Use Pydantic Settings for env vars. Never hardcode configuration.
12. **Performance** -- Profile with cProfile. Use slots for memory optimization. Use Cython/Numba for hot paths.

### 24.8 FastAPI Best Practices Summary

1. **Project Structure** -- Separate routers, schemas, services, models, dependencies into modules.
2. **Dependencies** -- Use Depends() for DI. Keep dependency functions clean and testable.
3. **Pydantic Models** -- Use Pydantic v2 for request/response models. Use model_config for strict mode.
4. **Error Handling** -- Use custom exception handlers. Return structured error responses (RFC 7807).
5. **Middleware** -- Add middleware for CORS, request ID, timing, logging.
6. **Background Tasks** -- Use BackgroundTasks for lightweight tasks. Use Celery for heavy tasks.
7. **Security** -- Use OAuth2 with JWT. Implement rate limiting, CSRF protection.
8. **Async Database** -- Use SQLAlchemy async + asyncpg for database operations.
9. **OpenAPI** -- Keep auto-generated docs clean with proper descriptions, examples, and tags.
10. **Testing** -- Use TestClient for integration tests. Override dependencies in tests.
11. **Lifecycle** -- Use lifespan handlers for startup/shutdown tasks (DB connection, Redis, AI model loading).
12. **Pagination** -- Use a standard pagination pattern (limit/offset or cursor-based).

### 24.9 AI Best Practices Summary

1. **Prompt Versioning** -- Store prompts as versioned files in the repository. Track changes like code.
2. **Structured Output** -- Use Pydantic models to parse and validate all AI outputs.
3. **Evaluation** -- Build eval datasets before writing prompts. Measure accuracy, latency, cost.
4. **Fallbacks** -- Always implement fallback logic (model unavailable, timeout, invalid output).
5. **Monitoring** -- Track token usage, latency, accuracy, cost, hallucination rate in production.
6. **Caching** -- Implement semantic caching for repeated queries. Measure cache hit rate.
7. **Guardrails** -- Implement input/output guardrails. Filter PII, toxicity, prompt injection.
8. **A/B Testing** -- Test prompt variations with statistical significance before full rollout.
9. **Cost Optimization** -- Use smaller models where possible. Batch requests. Cache aggressively.
10. **Model Selection** -- Match model size to task complexity. Use inexpensive models for simple tasks.
11. **Streaming** -- Use streaming for user-facing features. Better perceived performance.
12. **Red Teaming** -- Regularly test AI features for edge cases, adversarial inputs, bias.
13. **User Feedback** -- Collect explicit and implicit feedback. Use to improve models and prompts.

### 24.10 Security Best Practices Summary

1. **OWASP Top 10** -- Address all OWASP Top 10 vulnerabilities (2021 edition).
2. **Authentication** -- Use OAuth 2.0 / OpenID Connect. Never roll your own auth.
3. **Authorization** -- Implement RBAC (Role-Based Access Control). Verify on every request.
4. **Input Validation** -- Validate all input server-side. Use Pydantic for schema validation.
5. **Output Encoding** -- Encode output to prevent XSS. Use CSP headers.
6. **SQL Injection** -- Use parameterized queries exclusively. Never concatenate SQL strings.
7. **Secrets Management** -- Use a vault (AWS Secrets Manager, HashiCorp Vault). Never in code.
8. **Encryption** -- Encrypt data at rest (AES-256) and in transit (TLS 1.3).
9. **Dependency Scanning** -- Scan dependencies for CVEs in CI. Fail builds on critical findings.
10. **SAST/DAST** -- Run static and dynamic analysis in CI pipeline.
11. **Rate Limiting** -- Apply rate limiting to all public endpoints.
12. **Logging & Monitoring** -- Log security events. Monitor for suspicious activity.
13. **Incident Response** -- Have a documented security incident response plan.
14. **Training** -- Conduct regular security training for all engineers.

---

## 25. Appendix

### 25.1 Complete Folder Structure

```
mecha-connect/
|
|-- backend/                          # Python FastAPI backend
|   |-- src/
|   |   |-- api/                      # API endpoints (routers)
|   |   |   |-- v1/
|   |   |       |-- auth.py
|   |   |       |-- users.py
|   |   |       |-- requests.py
|   |   |       |-- vehicles.py
|   |   |       |-- payments.py
|   |   |       |-- ai_chat.py
|   |   |-- core/                     # Core configuration
|   |   |   |-- config.py
|   |   |   |-- database.py
|   |   |   |-- dependencies.py
|   |   |   |-- exceptions.py
|   |   |   |-- middleware.py
|   |   |   |-- security.py
|   |   |-- models/                   # SQLAlchemy models
|   |   |   |-- user.py
|   |   |   |-- request.py
|   |   |   |-- vehicle.py
|   |   |   |-- payment.py
|   |   |-- schemas/                  # Pydantic schemas
|   |   |   |-- user.py
|   |   |   |-- request.py
|   |   |   |-- vehicle.py
|   |   |   |-- payment.py
|   |   |   |-- ai.py
|   |   |-- services/                 # Business logic
|   |   |   |-- auth_service.py
|   |   |   |-- user_service.py
|   |   |   |-- request_service.py
|   |   |   |-- payment_service.py
|   |   |   |-- ai_service.py
|   |   |   |-- notification_service.py
|   |   |-- db/                       # Database utilities
|   |   |   |-- migrations/
|   |   |   |-- seeds/
|   |   |-- tasks/                    # Celery tasks
|   |   |   |-- notification_tasks.py
|   |   |   |-- cleanup_tasks.py
|   |-- tests/
|   |   |-- conftest.py
|   |   |-- test_api/
|   |   |-- test_services/
|   |   |-- test_models/
|   |-- alembic.ini
|   |-- pyproject.toml
|   |-- Dockerfile
|
|-- flutter_app/                      # Flutter mobile app
|   |-- lib/
|   |   |-- main.dart
|   |   |-- app.dart
|   |   |-- core/
|   |   |   |-- constants/
|   |   |   |-- theme/
|   |   |   |-- router/
|   |   |   |-- network/
|   |   |   |-- storage/
|   |   |   |-- utils/
|   |   |-- features/
|   |   |   |-- auth/
|   |   |   |   |-- data/
|   |   |   |   |-- domain/
|   |   |   |   |-- presentation/
|   |   |   |-- home/
|   |   |   |-- requests/
|   |   |   |-- vehicles/
|   |   |   |-- payments/
|   |   |   |-- ai_chat/
|   |   |   |-- profile/
|   |   |-- widgets/
|   |-- assets/
|   |   |-- images/
|   |   |-- fonts/
|   |   |-- l10n/
|   |-- test/
|   |   |-- unit/
|   |   |-- widget/
|   |   |-- integration/
|   |-- pubspec.yaml
|   |-- Dockerfile
|
|-- ai/                               # AI-specific services
|   |-- src/
|   |   |-- prompts/
|   |   |   |-- chat_prompt_v1.txt
|   |   |   |-- summary_prompt_v2.txt
|   |   |-- services/
|   |   |   |-- llm_service.py
|   |   |   |-- embedding_service.py
|   |   |   |-- cache_service.py
|   |   |-- models/
|   |   |-- eval/
|   |   |   |-- datasets/
|   |   |   |-- metrics/
|   |   |   |-- runner.py
|   |   |-- guardrails/
|   |-- tests/
|   |-- pyproject.toml
|   |-- Dockerfile
|
|-- infrastructure/                   # IaC and config
|   |-- terraform/
|   |   |-- environments/
|   |   |   |-- dev/
|   |   |   |-- staging/
|   |   |   |-- production/
|   |   |-- modules/
|   |       |-- networking/
|   |       |-- compute/
|   |       |-- database/
|   |       |-- kubernetes/
|   |-- k8s/
|   |   |-- backend-deployment.yaml
|   |   |-- backend-service.yaml
|   |   |-- flutter-deployment.yaml
|   |   |-- ai-service-deployment.yaml
|   |   |-- ingress.yaml
|   |   |-- configmap.yaml
|   |-- ci/
|   |   |-- .github/
|   |       |-- workflows/
|   |           |-- ci.yml
|   |           |-- cd.yml
|   |           |-- security-scan.yml
|   |-- docker/
|       |-- Dockerfile.backend
|       |-- Dockerfile.flutter
|       |-- Dockerfile.ai
|       |-- docker-compose.yml
|
|-- docs/
|   |-- adr/
|   |-- rfc/
|   |-- api/
|   |-- runbooks/
|   |-- handbook/
|
|-- scripts/
|   |-- setup-dev.sh
|   |-- migrate.sh
|   |-- seed.sh
|   |-- backup.sh
|
|-- .github/
|   |-- ISSUE_TEMPLATE/
|   |-- PULL_REQUEST_TEMPLATE.md
|   |-- CODEOWNERS
|   |-- dependabot.yml
|
|-- .vscode/
|   |-- settings.json
|   |-- extensions.json
|
|-- .env.example
|-- .gitignore
|-- .pre-commit-config.yaml
|-- README.md
|-- CONTRIBUTING.md
|-- LICENSE
|-- pyproject.toml
```

### 25.2 Sample Commits

**Example 1: Simple bug fix**
```
fix: prevent null pointer in user profile loading

When a user profile has no avatar URL set, the profile screen
would crash with a NullPointerException. Added a null check
before attempting to load the avatar image.

Fixes #427
```

**Example 2: New feature**
```
feat(ai-chat): add streaming response support

- Migrate chat endpoint from non-streaming to SSE streaming
- Add Server-Sent Events response handler on Flutter side
- Update OpenAPI spec with streaming response schema
- Add streaming timeout of 30 seconds with graceful fallback
- Update eval suite to test streaming latency budget

Closes #312
```

**Example 3: Refactoring**
```
refactor(backend): extract payment processing into service layer

- Move payment logic from api/v1/payments.py to services/payment_service.py
- Add unit tests for payment validation and processing
- Keep API router thin (only routing and DI)
- No behavior changes

Part of #289
```

**Example 4: Performance improvement**
```
perf(db): add composite index on requests(status, created_at)

Added (status, created_at) index to reduce query time for
pending request listing from 800ms to 12ms (P95).

Migration: V004_add_requests_status_created_at_index
```

**Example 5: Documentation**
```
docs(api): add pagination examples to OpenAPI spec

Added query parameter examples for limit and offset
to all list endpoints. Including sample responses
with pagination metadata.
```

**Example 6: CI/CD change**
```
ci: add dependency vulnerability scan to CI pipeline

- Add pip-audit step to GitHub Actions workflow
- Configure to fail build on critical/high CVEs
- Add weekly scheduled scan for full audit
- Update README with security badge
```

**Example 7: AI-focused change**
```
feat(ai): add semantic caching for chat responses

- Implement semantic cache using embeddings + cosine similarity
- Cache hit threshold: similarity > 0.95
- Add cache hit/miss metrics to monitoring
- TTL: 1 hour for cached responses
- Fallback to fresh inference on cache miss

Reduces AI cost by ~35% for common queries.
```

### 25.3 Sample PR (Full Example)

```markdown
## Description

Add streaming AI chat responses to improve user experience.
Previously, users had to wait for the full response before
seeing any output. Now, responses stream token-by-token
using Server-Sent Events.

## Type of Change

- [ ] Bug fix
- [x] New feature
- [ ] Refactor
- [ ] Performance improvement
- [ ] Documentation
- [ ] CI/CD

## Related Issues

Closes #312
Related RFC: RFC-014-AI-Chat-Streaming

## Testing

- [x] Unit tests added for streaming handler
- [x] Integration tests for SSE endpoint
- [x] E2E tests for chat streaming on Flutter
- [x] Performance test: streaming latency < 200ms TTFB

## Performance Impact

- P95 TTFB: 150ms (target < 500ms)
- P95 total response time: 3.2s for 500-token response
- Memory: +15MB per concurrent streaming connection
- No regression on non-streaming endpoints

## Security Considerations

- Rate limiting applied to chat endpoint (10 req/min/user)
- Input sanitization: PII filter runs before sending to model
- Output safety filter runs on streamed chunks
- No new attack surface introduced

## Checklist

- [x] My code follows the project's coding standards
- [x] I have added tests that prove my fix/feature works
- [x] All existing tests pass
- [x] Documentation has been updated
- [x] Feature flag added for gradual rollout
- [x] Monitoring metrics added (TTFB, token rate, errors)
- [x] Rollback plan: disable feature flag

## Screenshots / Recordings

[Screen recording showing streaming chat vs old non-streaming]

## Additional Notes

This feature requires the AI service to be deployed with
streaming support enabled. The feature flag `chat-streaming`
controls rollout.
```

### 25.4 Sample ADR (Full Example)

```markdown
# ADR-0007: Use FastAPI for Backend API Framework

- **Status:** Accepted
- **Date:** 2024-06-15
- **Deciders:** Engineering Team, Tech Lead
- **Related ADRs:** ADR-0003 (Python as Primary Language)

## Context

We needed to select a web framework for the Mecha Connect backend API.
The framework must support async I/O, have strong typing, generate
OpenAPI documentation automatically, and integrate well with our
AI service stack.

Options considered:
1. FastAPI
2. Django + Django REST Framework
3. Flask
4. Starlette (bare)

## Decision

Use FastAPI as the primary backend framework.

## Consequences

**Positive:**
- Automatic OpenAPI documentation generation
- Native async support (critical for AI streaming endpoints)
- Pydantic integration for request/response validation
- Excellent performance
- Large ecosystem and community support
- Dependency injection system simplifies testing

**Negative:**
- Requires team to learn FastAPI-specific patterns
- Smaller ecosystem than Django
- Less mature admin interface

## Alternatives Considered

| Option | Description | Why Rejected |
|--------|-------------|-------------|
| Django + DRF | Full-featured framework | Heavy; sync ORM; slower iteration |
| Flask + Flask-RESTful | Lightweight, flexible | Lacks automatic docs, no native async |
| Starlette | Async-native, minimal | Too low-level; too much manual boilerplate |

## References

- FastAPI Documentation: https://fastapi.tiangolo.com/
- Our API Standards: Section 10 of this handbook
```

### 25.5 Sample RFC (Full Example)

```markdown
# RFC-014: AI Chat Streaming

- **Status:** Approved
- **Author:** Jane Smith
- **Date:** 2024-07-01
- **PR:** #298

## Summary

Add Server-Sent Events (SSE) streaming to the AI chat endpoint,
allowing responses to be displayed token-by-token as they are
generated, rather than waiting for the full response.

## Motivation

User research showed that 73% of users abandon the chat feature
when response time exceeds 5 seconds. Average chat response time
is 4.2 seconds. Streaming provides immediate feedback, improving
perceived performance and user satisfaction.

## Design

### Backend Changes
1. New endpoint: GET /api/v1/chat/stream
2. Response format: SSE (text/event-stream)
3. Stream timeout: 30 seconds (configurable)
4. Fallback: Non-streaming endpoint used if client doesn't support SSE

### Flutter Changes
1. Use dart:io HttpClient for SSE connection
2. Parse SSE events: data: {token}\n\n
3. Display tokens progressively in chat bubble

### API Changes
GET /api/v1/chat/stream
Authorization: Bearer <token>
Content-Type: text/event-stream

Event: token
Data: "Hello"

Event: token
Data: " world"

Event: done
Data: ""

### Database Changes: None

### UI Changes
- Chat bubble content updates in real-time during streaming
- Streaming indicator shown while connected
- Stop button to abort streaming

## Alternatives Considered
1. WebSocket -- More complex, harder to scale
2. Long-polling -- Higher latency, more server load
3. gRPC streaming -- Requires gRPC-web proxy

## Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| Stream timeout mid-response | Client handles incomplete response gracefully |
| High memory for concurrent streams | Limit concurrent streams per user (3 max) |
| Network interruption | Auto-reconnect with last token context |

## Migration Plan
1. Deploy streaming endpoint behind feature flag
2. Flutter app update with SSE support
3. Enable streaming for 10% beta users
4. Gradual rollout to 100%

## Rollback Plan
Disable the chat-streaming feature flag. All clients fall back to the non-streaming endpoint.

## Timeline
| Phase | Duration | Description |
|-------|----------|-------------|
| Backend implementation | 3 days | SSE endpoint, streaming service |
| Flutter implementation | 2 days | SSE client, UI updates |
| Integration testing | 1 day | End-to-end streaming tests |
| Canary rollout | 3 days | 10% -> 50% -> 100% |

## References
- SSE Specification: https://html.spec.whatwg.org/
- Our Performance Standards: Section 17
- ADR-0007: FastAPI Framework Decision
```

### 25.6 Sample Changelog

```markdown
# Changelog

All notable changes to Mecha Connect will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## [2.1.0] - 2024-08-15

### Added
- AI Chat Streaming: chat responses now stream token-by-token
- Vehicle History: view complete service history for your vehicle
- Push Notifications: real-time alerts for request status changes
- Semantic Caching: AI responses cached for repeated queries

### Changed
- Redesigned home screen with quick-action buttons
- Improved chat UI with typing indicators and timestamps
- Performance: reduced API P95 latency from 420ms to 280ms
- Updated FastAPI from 0.100 to 0.110

### Fixed
- Fixed crash on profile screen when avatar URL is empty (#427)
- Fixed payment timeout issue for large invoices (#431)
- Fixed notification delivery delay
- Fixed dark mode color inconsistencies

### Security
- Updated dependencies to patch CVE-2024-XXXX
- Added rate limiting to all AI endpoints
- Enhanced PII filtering on chat inputs

## [2.0.0] - 2024-06-01

### Added
- Complete app rewrite in Flutter
- AI-powered roadside assistance chat
- Real-time request tracking with maps
- Multi-language support (EN, ES, FR)
- Dark mode support

### Changed
- Migrated from React Native to Flutter
- Redesigned all screens with Material Design 3
- New backend architecture with FastAPI

## [1.0.0] - 2024-03-01

Initial release.
```

### 25.7 Sample Release Notes

```markdown
# Mecha Connect v2.1.0 Release Notes

**Release Date:** August 15, 2024
**Version:** 2.1.0

## What's New

### AI Chat Streaming
Chat responses now appear in real-time as they are generated.
No more waiting for the full response. Tap the stop button
to interrupt the AI mid-response.

### Vehicle History
View the complete service history for any vehicle you own.
See past requests, invoices, and mechanic notes all in one place.

### Push Notifications
Get instant notifications when your roadside assistance request
status changes, a mechanic is assigned, or payment is processed.

## Improvements
- API response times improved by 33%
- Better Chat UI with new typing indicators and message timestamps
- Redesigned Home Screen with quick-access buttons

## Bug Fixes
- Fixed profile crash on Android 14
- Fixed payment timeout for invoices over $500
- Fixed dark mode text contrast issues
- Fixed notification delays

## Technical Details
- 27 PRs merged since v2.0.0
- 15 bug fixes
- Test coverage: 84% (up from 78%)
- P95 API latency reduced from 420ms to 280ms

## Installation
Update your app from the App Store or Google Play Store.
```

### 25.8 Glossary

| Term | Definition |
|------|-----------|
| ADR | Architecture Decision Record |
| API Gateway | Entry point for API requests; handles auth, rate limiting, routing |
| BLoC | Business Logic Component -- Flutter state management pattern |
| Canary | Gradual rollout to a subset of users to validate stability |
| CD | Continuous Deployment -- automated deployment to production |
| CI | Continuous Integration -- automated build and test on every push |
| CORS | Cross-Origin Resource Sharing |
| CSP | Content Security Policy |
| CVE | Common Vulnerabilities and Exposures |
| DAST | Dynamic Application Security Testing |
| DI | Dependency Injection |
| E2E | End-to-End test |
| Feature Flag | Toggle that enables/disables a feature without deployment |
| HPA | Horizontal Pod Autoscaler |
| IaC | Infrastructure as Code |
| IC | Incident Commander |
| JWT | JSON Web Token |
| K8s | Kubernetes |
| MTTR | Mean Time to Recovery |
| N+1 Query | Performance issue querying each item in a collection individually |
| OAuth 2.0 | Authorization framework for token-based access |
| OOMKilled | Container killed due to out-of-memory |
| P50/P95/P99 | Percentile latency metrics |
| PII | Personally Identifiable Information |
| PR | Pull Request |
| RBAC | Role-Based Access Control |
| RFC | Request for Comments |
| SAST | Static Application Security Testing |
| SemVer | Semantic Versioning |
| SEV | Severity level for incidents |
| SLO | Service Level Objective |
| SSE | Server-Sent Events |
| TTFB | Time to First Byte |
| WAL | Write-Ahead Log |

### 25.9 References

**Engineering Practices:**
- Google Engineering Practices: https://google.github.io/eng-practices/
- Microsoft Engineering: https://learn.microsoft.com/en-us/engineering/
- Amazon Working Backwards: https://www.aboutamazon.com/
- Netflix Tech Blog: https://netflixtechblog.com/
- OpenAI Best Practices: https://platform.openai.com/docs/guides

**Technical References:**
- FastAPI Documentation: https://fastapi.tiangolo.com/
- Flutter Documentation: https://docs.flutter.dev/
- Python PEP 8: https://peps.python.org/pep-0008/
- SQLAlchemy: https://docs.sqlalchemy.org/
- PostgreSQL: https://www.postgresql.org/docs/
- Docker: https://docs.docker.com/
- Kubernetes: https://kubernetes.io/docs/
- Terraform: https://developer.hashicorp.com/terraform/docs

**Security:**
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- OWASP Cheat Sheet Series: https://cheatsheetseries.owasp.org/

**Standards:**
- Semantic Versioning: https://semver.org/
- Keep a Changelog: https://keepachangelog.com/
- Conventional Commits: https://www.conventionalcommits.org/
- OpenAPI Specification: https://spec.openapis.org/
- Mermaid Documentation: https://mermaid.js.org/

### 25.10 Useful Resources

**Tools:**
| Tool | Purpose |
|------|---------|
| VS Code | Primary IDE |
| Git | Version control |
| Postman | API testing |
| DBeaver | Database GUI |
| Docker Desktop | Container management |
| Python | Backend language |
| Flutter | Mobile framework |
| Black | Python formatter |
| Ruff | Python linter |
| mypy | Python type checker |
| pytest | Python testing |
| Flutter DevTools | Flutter debugging |
| Terraform | Infrastructure as Code |
| PagerDuty | Incident management |
| Datadog | Monitoring |
| Prometheus | Metrics |
| Grafana | Dashboards |
| ELK Stack | Logging |
| ArgoCD | GitOps CD |
| GitHub Actions | CI/CD |
| LaunchDarkly | Feature flags |
| k6 / Locust | Load testing |
| SonarQube | Code quality |

**Books for Engineers:**
1. Clean Code by Robert C. Martin
2. Designing Data-Intensive Applications by Martin Kleppmann
3. The Pragmatic Programmer by Andy Hunt and Dave Thomas
4. System Design Interview by Alex Xu
5. Building Microservices by Sam Newman
6. Site Reliability Engineering by Google SRE Team
7. Accelerate by Nicole Forsgren, Jez Humble, Gene Kim
8. AI Engineering by Chip Huyen
9. Flutter Complete Reference by Alberto Miola
10. Python in a Nutshell by Alex Martelli

---

*End of Master Engineering Handbook v1.0*

*This document is maintained by the Engineering Team.*
*Last updated: August 2024*
*Review cycle: Quarterly*

---

## 5. Pull Request Standards

### 5.1 PR Template

Every PR in Mecha Connect must include the following information:

```markdown
# Description

[Provide a clear, concise description of the changes. Include motivation and context.]

Fixes #(issue)

## Type of Change

- [ ] feat: New feature
- [ ] fix: Bug fix
- [ ] chore: Maintenance
- [ ] docs: Documentation
- [ ] refactor: Code refactoring
- [ ] perf: Performance improvement
- [ ] test: Adding tests
- [ ] ci: CI/CD changes

## Screenshots / Recordings

[If applicable, add screenshots or screen recordings to demonstrate the change]

## Testing

- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Checklist

- [ ] Code follows Mecha Connect coding standards
- [ ] Self-review completed
- [ ] No new warnings or errors
- [ ] Documentation updated (if needed)
- [ ] Security implications considered
- [ ] Performance impact assessed
- [ ] Accessibility requirements met
- [ ] Localization strings added
- [ ] Dark mode supported

## Breaking Changes

[If any, list breaking changes and migration steps]

## Deployment Notes

[Any special deployment instructions, database migrations, environment variables, etc.]
```

### 5.2 PR Size Guidelines

| Size | Lines Changed | Review Time | Notes |
|------|--------------|-------------|-------|
| Tiny | < 30 | Immediate | Typo fixes, small refactors |
| Small | 30-100 | < 30 min | Single bug fix, small feature |
| Medium | 100-300 | < 1 hour | One feature, well-scoped |
| Large | 300-1000 | < 2 hours | Multi-file changes, complex feature |
| X-Large | > 1000 | Split required | Must be broken into smaller PRs |

### 5.3 Review Checklist

**Functionality:**
- [ ] Does the code do what it is supposed to do?
- [ ] Are there edge cases not handled?
- [ ] Does the change handle loading, error, and empty states?
- [ ] Does it work offline (if applicable)?

**Code Quality:**
- [ ] Does the code follow Mecha Connect standards?
- [ ] Is the code well-structured and readable?
- [ ] Are there unnecessary dependencies?
- [ ] Are there duplicate code patterns that should be reused?

**Testing:**
- [ ] Are there unit tests for business logic?
- [ ] Are there widget tests for UI components?
- [ ] Do the tests actually test the right things?
- [ ] Is the test coverage adequate for this change?

### 5.4 Approval Rules

```mermaid
flowchart TD
    PR[PR Created] --> Size{PR Size}
    Size --> |< 100 lines| R1[1 Approval Required]
    Size --> |100-300 lines| R2[2 Approvals Required]
    Size --> |> 300 lines| R3[2 Approvals + EM Review]

    R1 --> Checks{CI Passes?}
    R2 --> Checks
    R3 --> Checks

    Checks --> |Yes| Merge[Ready to Merge]
    Checks --> |No| Fix[Fix Issues]
    Fix --> PR
```

| PR Type | Approvals | Who |
|---------|-----------|-----|
| Tiny (< 30 lines) | 1 | Any engineer |
| Small (30-100 lines) | 1 | Senior engineer |
| Medium (100-300 lines) | 2 | Senior + any engineer |
| Large (300-1000 lines) | 2 | Senior + engineering manager |
| Hotfix | 1 (expedited) | Senior engineer |
| Release PR | 2 | EM + CTO |

### 5.5 Review SLA

| Severity | Time to First Review | Time to Merge |
|----------|---------------------|---------------|
| Hotfix | 15 minutes | 30 minutes |
| Bug Fix | 4 hours | 24 hours |
| Feature | 24 hours | 48 hours |
| Chore/Docs | 48 hours | 72 hours |

### 5.6 Merge Conditions

A PR can only be merged when ALL of the following are true:
1. Required approvals obtained
2. All CI checks pass (lint, test, build, security scan)
3. No merge conflicts with main
4. Branch is up to date with main
5. All review comments resolved
6. PR follows the template
7. No WIP or draft status

### 5.7 Code Ownership

Code ownership is defined in CODEOWNERS:

```
* @mecha-connect/engineering-leads
/apps/customer_app/ @mecha-connect/customer-app-team
/apps/mechanic_app/ @mecha-connect/mechanic-app-team
/apps/admin_dashboard/ @mecha-connect/backend-team
/backend/ @mecha-connect/backend-team
/backend/ai-services/ @mecha-connect/ai-team
/infrastructure/ @mecha-connect/devops-team
/docs/ @mecha-connect/engineering-leads
/.github/ @mecha-connect/devops-team
/packages/shared_core/ @mecha-connect/platform-team
/packages/shared_ui/ @mecha-connect/platform-team
/packages/shared_api/ @mecha-connect/platform-team
```

---

## 6. Coding Standards

### 6.1 General Rules

1. **Readability over cleverness**: Write code for humans first, computers second.
2. **Consistency is king**: Follow existing patterns. Do not introduce new styles.
3. **Single Responsibility**: One file, one class, one function — one job.
4. **DRY but not at cost of readability**: Duplication is sometimes better than wrong abstraction.
5. **Fail fast**: Validate inputs early, return errors immediately.
6. **Minimize dependencies**: Think twice before adding a new package.
7. **Type everything**: No dynamic, no Any, no Object without strong justification.
8. **Immutability**: Prefer immutable state. Use final, const, immutable structures.
9. **Null safety**: Use language null safety features. No null pointer exceptions.
10. **YAGNI**: You Arent Gonna Need It. Do not build for hypothetical future requirements.

### 6.2 Python Standards (Backend)

**Version:** Python 3.12+

**Formatting:** PEP 8, line length 100, 4-space indentation, double quotes

**Imports Order:**
```python
# 1. Standard library
import json
from datetime import datetime
from typing import Optional

# 2. Third-party
import httpx
from fastapi import APIRouter, Depends
from pydantic import BaseModel

# 3. Local
from mecha_connect.core.config import settings
```

**Type Hints:** Always use type hints for parameters, return types, and class attributes.

**Naming Conventions:**

| Element | Convention | Example |
|---------|-----------|---------|
| Module | snake_case | auth_service.py |
| Class | PascalCase | AuthService |
| Function | snake_case | get_user_by_id |
| Variable | snake_case | user_id |
| Constant | UPPER_CASE | MAX_LOGIN_ATTEMPTS |
| Private | _prefix | _validate_token |

### 6.3 Dart / Flutter Standards

**Version:** Dart 3.x+, Flutter 3.x+

**Formatting:** Effective Dart, line length 80, 2-space indentation

**Imports Order:**
```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter SDK
import 'package:flutter/material.dart';

// 3. Third-party
import 'package:bloc/bloc.dart';

// 4. Shared packages
import 'package:shared_core/shared_core.dart';

// 5. Feature packages
import 'package:feature_auth/feature_auth.dart';

// 6. Relative imports
import '../bloc/auth_bloc.dart';
```

**Naming Conventions:**

| Element | Convention | Example |
|---------|-----------|---------|
| File | snake_case | auth_bloc.dart |
| Class | PascalCase | AuthBloc |
| Function | camelCase | getUserById |
| Variable | camelCase | userId |
| Constant | camelCase | defaultTimeout |
| Private | _prefix | _validateToken |

### 6.4 Comments

- **Public APIs**: Every public function needs a doc comment
- **Complex logic**: Document non-obvious algorithms
- **Why, not what**: Explain reasoning, not mechanics
- **Workarounds**: Document why workaround exists and removal condition

**Never:**
- Comment obvious code
- Leave TODO without issue reference
- Keep commented-out code

### 6.5 Formatting & Linting

**Dart:** dart format (non-negotiable), trailing commas required
**Python:** black + isort (non-negotiable)

**analysis_options.yaml must include:**
- prefer_const_constructors
- avoid_dynamic_calls
- avoid_print
- prefer_final_locals
- use_build_context_synchronously

---

## 7. Backend Standards

### 7.1 Technology Stack

| Layer | Technology |
|-------|-----------|
| Framework | FastAPI |
| ASGI Server | Uvicorn + Gunicorn |
| ORM | SQLAlchemy 2.0 (async) |
| Migrations | Alembic |
| Validation | Pydantic v2 |
| Background Tasks | Celery + Redis |
| Caching | Redis |
| Database | PostgreSQL 16 + PostGIS |

### 7.2 FastAPI Service Structure

Each backend service follows this structure:

```
auth-service/
+-- src/
¦   +-- main.py
¦   +-- config.py
¦   +-- api/
¦   ¦   +-- v1/
¦   ¦       +-- router.py
¦   ¦       +-- auth.py
¦   ¦       +-- users.py
¦   +-- core/
¦   ¦   +-- security.py
¦   ¦   +-- exceptions.py
¦   ¦   +-- middleware.py
¦   +-- models/
¦   +-- schemas/
¦   +-- services/
¦   +-- repositories/
+-- tests/
+-- alembic/
+-- Dockerfile
+-- requirements.txt
```

### 7.3 Repository & Service Patterns

**Repository Layer** handles data access. **Service Layer** handles business logic.
- Repository returns ORM models
- Service returns Pydantic schemas
- Services depend on repositories (injected via FastAPI Depends)
- Repositories never raise HTTP exceptions

### 7.4 Error Handling

Custom exception hierarchy with global handler:
- MechaConnectError (base)
- NotFoundError (404)
- ValidationError (422)
- UnauthorizedError (401)

Standard error response:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Phone number must be 10 digits",
    "details": { "field": "phone" },
    "request_id": "req_abc123"
  }
}
```

### 7.5 Async Programming

- All I/O must be async (DB, Redis, HTTP)
- Use asyncio.gather for parallel operations
- Never block the event loop
- Use AsyncSession for SQLAlchemy

### 7.6 Caching

Cache strategy: Redis with TTL-based invalidation.
| Data | Cache Duration |
|------|---------------|
| User profile | 1 hour |
| Mechanic profile | 5 minutes |
| Service pricing | 1 day |
| Booking status | 30 seconds |

---

## 8. Flutter Standards

### 8.1 Architecture

Feature-first Clean Architecture with BLoC:
- **Presentation**: Screens, Widgets, Blocs
- **Domain**: Entities, Repository interfaces (pure Dart)
- **Data**: DataSources, Repository implementations, DTOs
- **Core**: Theme, Network, Database, Location, Analytics

Layer rules: Presentation ? Domain ? Data ? Core (dependencies flow inward).

### 8.2 Widget Philosophy

- Prefer StatelessWidget (use BLoC for state)
- One widget, one file
- Composition over inheritance
- const constructors everywhere
- Build methods are declarative, contain no business logic

### 8.3 State Management (BLoC)

- Events and states use freezed for immutability
- BlocProvider at route level
- BlocConsumer for UI with separate listener and builder
- Never expose BLoC state directly to widgets (use state.when/map)

### 8.4 Routing (GoRouter)

- Declarative routing with GoRouter
- ShellRoute for authenticated shell (bottom nav)
- Auth guard via redirect callback
- Deep linking support

### 8.5 Themes

- Material 3 (useMaterial3: true)
- Light + Dark themes defined in shared_core
- Dynamic color on Android 12+
- Consistent color scheme across all apps

### 8.6 Localization

- Flutter Intl / ARB files
- English (en) and Hindi (hi) at minimum
- Strings organized by feature/module
- Access via context.l10n extension

### 8.7 Responsive Design

- ResponsiveLayout widget switching mobile/tablet/desktop
- Mobile: 4-col grid, Tablet: 8-col, Desktop: 12-col
- Adaptive widgets for platform-specific behavior

---

## 9. AI Engineering Standards

### 9.1 Architecture

The AI Assistant uses a pipeline architecture:
Query ? Guardrail Check ? Context Builder ? RAG Retriever ? Prompt Builder ? LLM ? Guardrail Check ? Response Formatter

### 9.2 Prompt Engineering

- System prompt defines role, capabilities, limitations
- User context injected dynamically (vehicles, booking, history)
- Knowledge base results from RAG included
- Few-shot examples for complex tasks
- Guardrails prevent hallucination, off-topic, or emergency mishandling

### 9.3 RAG (Retrieval Augmented Generation)

- Vector Store: Pinecone with text-embedding-3-small
- Chunk size: 500 chars, overlap: 50 chars
- Similarity threshold: 0.7
- Knowledge base: platform docs, vehicle troubleshooting, safety info

### 9.4 Guardrails

- Input guardrails: block PII requests, harmful content, injection attempts
- Output guardrails: prevent pricing hallucination, false guarantees, unsafe advice
- Safety triggers: emergencies redirect to human support + SOS

### 9.5 Fallback Logic

- Retry with exponential backoff (3 attempts)
- Fallback message when LLM unavailable
- Degraded mode: FAQ matching only when LLM is down
- Rate limiting: 10 messages/minute per user

---

## 10. API Standards

### 10.1 REST Guidelines

- Base URL: https://api.mechaconnect.com/v1
- kebab-case for endpoints, snake_case for fields
- Plural nouns for collections, singular for singletons

### 10.2 Standard Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /v1/bookings | List bookings (paginated) |
| POST | /v1/bookings | Create booking |
| GET | /v1/bookings/{id} | Get booking details |
| PATCH | /v1/bookings/{id} | Update booking |
| POST | /v1/bookings/{id}/cancel | Cancel booking |
| GET | /v1/users/{id}/vehicles | List user vehicles |

### 10.3 Pagination & Filtering

- Cursor-based pagination (preferred): cursor + limit
- Offset-based (admin): page + per_page
- Filters: field=value, field.gte=value, field.in=val1,val2

### 10.4 Standard Response Format

**Success:** { "data": { ... } }
**List:** { "data": [...], "pagination": { "next_cursor": "...", "has_more": true } }
**Error:** { "error": { "code": "...", "message": "...", "details": {}, "request_id": "..." } }

### 10.5 Authentication

- Bearer JWT tokens in Authorization header
- Public endpoints: login, register, OTP, health, services catalog
- JWT payload: sub, role, iat, exp, jti

### 10.6 Rate Limiting

| Endpoint | Rate |
|----------|------|
| Public | 10 req/min |
| Authenticated | 100 req/min |
| SOS | 5 req/min |
| AI Assistant | 10 req/min |
| Admin | 200 req/min |

Response headers: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset

---

## 11. Database Standards

### 11.1 Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Primary Database | PostgreSQL 16 + PostGIS | ACID, geospatial queries, JSON support |
| Caching | Redis 7 | Session, cache, rate limiting |
| Vector Database | Pinecone | AI embedding storage and search |
| Migration Tool | Alembic | Schema migrations |
| Connection Pool | PgBouncer | Connection pooling for Postgres |

### 11.2 Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Tables | snake_case, plural | users, booking_requests |
| Columns | snake_case | created_at, service_type |
| Primary Keys | id UUID | id UUID PRIMARY KEY DEFAULT gen_random_uuid() |
| Foreign Keys | {table}_id | user_id, mechanic_id |
| Indexes | idx_{table}_{column} | idx_bookings_status |
| Unique Constraints | uq_{table}_{column} | uq_users_phone |

### 11.3 Migration Rules (Alembic)

- One migration per logical change
- Never edit a committed migration
- Always include a downgrade migration
- Test both upgrade and downgrade
- Migration naming: {YYYY}_{MM}_{DD}_{description}

### 11.4 Core Schema (PostgreSQL)

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(15) UNIQUE NOT NULL,
    email VARCHAR(255),
    name VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'customer',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE mechanics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    specialization TEXT[],
    rating DECIMAL(2,1) DEFAULT 0.0,
    is_online BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,
    service_area_lat DECIMAL(10,7),
    service_area_lng DECIMAL(10,7),
    service_area_radius_km DECIMAL(5,1),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE booking_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    mechanic_id UUID REFERENCES mechanics(id),
    vehicle_id UUID NOT NULL,
    service_type VARCHAR(20) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'requested',
    location_lat DECIMAL(10,7) NOT NULL,
    location_lng DECIMAL(10,7) NOT NULL,
    description TEXT,
    price_estimate DECIMAL(10,2),
    price_actual DECIMAL(10,2),
    payment_status VARCHAR(20) DEFAULT 'pending',
    rating INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    make VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INTEGER NOT NULL,
    color VARCHAR(50),
    license_plate VARCHAR(20),
    vin VARCHAR(50),
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES booking_requests(id),
    user_id UUID NOT NULL REFERENCES users(id),
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    payment_method VARCHAR(50),
    gateway_name VARCHAR(50),
    gateway_transaction_id VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 11.5 Indexes

```sql
CREATE INDEX idx_bookings_status ON booking_requests(status);
CREATE INDEX idx_bookings_user_id ON booking_requests(user_id);
CREATE INDEX idx_bookings_mechanic_id ON booking_requests(mechanic_id);
CREATE INDEX idx_bookings_created_at ON booking_requests(created_at);
CREATE INDEX idx_mechanics_is_online ON mechanics(is_online) WHERE is_online = true;
CREATE INDEX idx_mechanics_specialization ON mechanics USING GIN(specialization);
CREATE INDEX idx_vehicles_user_id ON vehicles(user_id);
CREATE INDEX idx_payments_booking_id ON payments(booking_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_users_phone ON users(phone);
```

### 11.6 Soft Delete

Use is_active boolean flag instead of hard DELETE. All queries must filter WHERE is_active = true.

### 11.7 Auditing

Every table includes created_at and updated_at. Use a separate audit_log table for important mutations:

```sql
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name VARCHAR(100) NOT NULL,
    record_id UUID NOT NULL,
    action VARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
    old_values JSONB,
    new_values JSONB,
    changed_by UUID REFERENCES users(id),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 11.8 Performance Rules

- All queries must use indexes for WHERE, JOIN, and ORDER BY
- Use EXPLAIN ANALYZE on queries before deploying
- Connection pooling via PgBouncer (pool_size=10-20 per service)
- Read replicas for analytics/reporting queries
- Regular VACUUM ANALYZE schedule
- Monitor slow query log (threshold: 200ms)

---

## 12. Security Standards

### 12.1 Authentication

- JWT-based authentication with RS256 signing
- Access token: 15 minute expiry, Refresh token: 7 day expiry
- Token rotation on refresh (old token invalidated)
- Biometric auth supported on mobile (optional, app-level)
- OTP verification for phone-based auth

### 12.2 Authorization (RBAC)

Four roles: Customer, Mechanic, Admin, SuperAdmin
- Customers: own resource access only
- Mechanics: own resource + job-related access
- Admins: full read on all resources, write on most
- SuperAdmin: full access including admin management

### 12.3 Secrets Management

- Never commit secrets to git (gitignored by default)
- All secrets in environment variables or vault
- Development: .env files (gitignored)
- Staging/Production: managed secret store
- Rotation: 90 days for service keys, 180 days for database credentials

### 12.4 Encryption

- Transit: TLS 1.3 for all external and internal communication
- At rest: AES-256 for database encryption, encrypted EBS volumes
- Passwords: bcrypt (cost factor 12) or argon2id
- PII: field-level encryption for phone numbers, email addresses

### 12.5 OWASP Top 10 Mitigations

| OWASP Risk | Mitigation |
|-----------|-----------|
| Broken Access Control | RBAC, per-resource authorization checks |
| Cryptographic Failures | TLS 1.3, strong encryption standards |
| Injection | Parameterized queries, input validation |
| Insecure Design | RFC/ADR process, security review |
| Security Misconfiguration | Infrastructure as Code, automated scanning |
| Vulnerable Components | Dependabot, regular updates, SCA |
| Auth Failures | Rate limiting, account lockout, MFA |
| Data Integrity Failures | Digital signatures, audit logging |
| Logging Failures | Structured logging, centralized monitoring |
| SSRF | Network segmentation, allowlist egress |

### 12.6 Secure Coding Rules

1. All user input must be validated (Pydantic on backend, form validation on frontend)
2. SQL queries must use parameterized statements (never string interpolation)
3. No hardcoded secrets, API keys, or credentials
4. Output encoding for all user-generated content
5. CSRF tokens for all state-changing operations
6. Set security headers (CSP, HSTS, X-Frame-Options, X-Content-Type-Options)

---

## 13. DevOps Standards

### 13.1 Docker

- Multi-stage builds for optimized image size
- Alpine-based images where possible
- Non-root user in containers
- Health checks defined in Dockerfile
- Specific version tags (never :latest)

### 13.2 Docker Compose (Local Development)

```yaml
version: "3.9"
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: mecha_connect
      POSTGRES_USER: mecha
      POSTGRES_PASSWORD: mecha_dev
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  api-gateway:
    build: ./backend/api-gateway
    ports:
      - "8000:8000"
    depends_on:
      - postgres
      - redis

volumes:
  postgres_data:
```

### 13.3 CI/CD (GitHub Actions)

**CI Pipeline:** Lint ? Test ? Build ? Security Scan ? Upload Artifacts
**CD Pipeline:** Deploy to Staging ? Integration Tests ? Deploy to Production (approval gate)

Key workflows:
- ci.yml: runs on every PR and push to main
- cd.yml: runs on merge to main, deploys to staging; production requires manual approval
- security-scan.yml: weekly scan of dependencies and SAST

### 13.4 Environment Variables

Naming: MECHA_{SERVICE}_{KEY}
Environments: dev, staging, prod
Each environment has a separate configuration file/vault path.

### 13.5 Deployment Strategy

- Blue-green deployment with zero downtime
- Health checks on /v1/health endpoint
- Readiness probe: checks DB and Redis connectivity
- Liveness probe: checks process health
- Rollback: immediate switch to previous deployment

### 13.6 Monitoring

- Metrics: Prometheus (CPU, memory, request rate, error rate, latency)
- Dashboards: Grafana (service overview, business KPIs, infrastructure)
- Alerts: PagerDuty for P1/P2 incidents, Slack for P3/P4
- Key metrics: P95 latency, error rate (target < 1%), request rate, active users

### 13.7 Backups

- PostgreSQL: pg_dump daily, WAL archiving continuous
- Retention: daily backups for 30 days, weekly for 12 months
- Redis: RDB snapshots every hour
- DR: Cross-region replication for critical data
- RTO: 4 hours, RPO: 1 hour

---

## 14. Testing Standards

### 14.1 Test Pyramid

```mermaid
flowchart TD
    subgraph E2E[E2E Tests - 5%]
        E2E1[Critical user journeys]
    end
    subgraph Integration[Integration Tests - 15%]
        I1[API integration]
        I2[Database integration]
        I3[AI evaluation]
    end
    subgraph Widget[Widget Tests - 20%]
        W1[Component rendering]
        W2[User interaction]
    end
    subgraph Unit[Unit Tests - 60%]
        U1[BLoC logic]
        U2[Repository logic]
        U3[Service logic]
        U4[Utility functions]
    end

    Unit --> Widget --> Integration --> E2E
```

### 14.2 Unit Testing

**Dart:** flutter_test + mocktail + bloc_test
- Test BLoC events and states
- Test repository implementations
- Test utility functions and validators
- Mock all external dependencies

**Python:** pytest + pytest-asyncio
- Test service methods
- Test repository queries
- Test Pydantic validations
- Mock database and external services

### 14.3 Widget Testing

- Test widget renders correctly
- Test user interaction (tap, input)
- Test state changes reflected in UI
- Test loading, error, and empty states

### 14.4 Integration Testing

- Flutter integration tests for critical flows (SOS, booking, payment)
- API integration tests (startup test server, test full request/response)
- Database integration tests (CRUD operations, migrations)

### 14.5 Coverage Targets

- Unit: 90%+ (business logic)
- Widget: 80%+ (UI components)
- Integration: 70%+ (critical flows)
- Overall project: 85%+

### 14.6 Quality Gates

CI fails if:
- Any test fails
- Coverage below thresholds
- Lint errors found
- Security vulnerabilities detected (critical/high)

---

## 15. Documentation Standards

### 15.1 README

Every app and package must have a README.md with:
- Overview / Description
- Architecture diagram
- Quick start guide
- Environment variables
- Available scripts (Makefile or just commands)
- Testing instructions
- Deployment notes
- Links to related documentation

### 15.2 ADR (Architecture Decision Records)

When to write: significant architectural decisions, technology choices, pattern changes.
Format: ADR-NNNN-title-in-kebab-case.md
Content: Title, Status, Context, Decision, Consequences, Alternatives

### 15.3 RFC (Request for Comments)

When to write: cross-team changes, new services, breaking API changes, new technologies.
Format: RFC-NNNN-title-in-kebab-case.md
Content: Title, Status, Motivation, Design, Alternatives, Implementation Plan, Open Questions

### 15.4 API Documentation

- Auto-generated OpenAPI from FastAPI (available at /docs, /redoc, /openapi.json)
- Postman collection maintained for manual testing
- All endpoints documented with request/response examples

### 15.5 Changelog

Maintained in CHANGELOG.md following Keep a Changelog format:
- Added, Changed, Deprecated, Removed, Fixed, Security sections
- Unreleased section at top
- Versioned releases with dates
- Links to compare changes on GitHub

### 15.6 Code Comments

- Public API functions: doc comments required
- Complex algorithms: explain the approach, not the syntax
- TODOs must reference an issue number
- No commented-out code


