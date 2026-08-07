-- Mecha Connect — PostgreSQL 15 target schema (Sprint 2)
-- Source of truth: DATABASE_BLUEPRINT.md (derived from frozen mock model)
-- At RC1 all data is in-memory; this schema mirrors the entity fields the UI already depends on.

-- Conventions: UUID PKs, TIMESTAMPTZ, NUMERIC(12,2) money (INR), NUMERIC(5,2) percent,
-- VARCHAR statuses + CHECK constraints, created_at/updated_at on mutable tables.

CREATE TABLE users (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                  TEXT NOT NULL,
    email                 TEXT UNIQUE NOT NULL,
    phone                 TEXT UNIQUE NOT NULL,
    password_hash         TEXT,
    date_of_birth         DATE,
    gender                TEXT,
    membership_tier       TEXT NOT NULL DEFAULT 'free',
    joined_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    emergency_contact_name     TEXT,
    emergency_contact_relation TEXT,
    emergency_contact_phone    TEXT,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (membership_tier IN ('free', 'pro'))
);

CREATE TABLE vehicles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    brand           TEXT NOT NULL,
    model           TEXT NOT NULL,
    registration    TEXT NOT NULL,
    fuel_type       TEXT NOT NULL,
    insurance_expiry DATE,
    puc_expiry      DATE,
    service_due_km  INT,
    service_due_date DATE,
    is_default      BOOLEAN NOT NULL DEFAULT false,
    health_score    SMALLINT CHECK (health_score BETWEEN 0 AND 100),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE addresses (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id),
    label       TEXT NOT NULL,
    address     TEXT NOT NULL,
    latitude    NUMERIC(9,6),
    longitude   NUMERIC(9,6),
    is_default  BOOLEAN NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (label IN ('home', 'office', 'other'))
);

CREATE TABLE wallet (
    user_id       UUID PRIMARY KEY REFERENCES users(id),
    balance       NUMERIC(12,2) NOT NULL DEFAULT 0,
    reward_points INT NOT NULL DEFAULT 0
);

CREATE TABLE wallet_transactions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id),
    title       TEXT,
    subtitle    TEXT,
    amount      NUMERIC(12,2) NOT NULL,
    type        TEXT NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ref_order_id TEXT,
    CHECK (type IN ('debit', 'credit'))
);

CREATE TABLE reward_ledger (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id),
    title       TEXT,
    subtitle    TEXT,
    points      INT NOT NULL,
    type        TEXT NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (type IN ('earned', 'referral', 'redeemed', 'achievement'))
);

CREATE TABLE notification_settings (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    push    BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE categories (
    id         TEXT PRIMARY KEY,
    name       TEXT NOT NULL,
    icon       TEXT,
    sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE brands (
    id   TEXT PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE products (
    id                TEXT PRIMARY KEY,
    brand_id          TEXT REFERENCES brands(id),
    category_id       TEXT REFERENCES categories(id),
    name              TEXT NOT NULL,
    price             NUMERIC(12,2) NOT NULL,
    mrp               NUMERIC(12,2) NOT NULL,
    rating            NUMERIC(3,2) DEFAULT 4.0,
    rating_count      INT DEFAULT 0,
    stock             INT NOT NULL DEFAULT 0,
    image_url         TEXT,
    icon              TEXT,
    description       TEXT,
    warranty          TEXT,
    delivery_estimate TEXT,
    popularity        INT DEFAULT 0,
    age_days          INT DEFAULT 0,
    is_featured       BOOLEAN NOT NULL DEFAULT false,
    is_best_seller    BOOLEAN NOT NULL DEFAULT false,
    is_trending       BOOLEAN NOT NULL DEFAULT false,
    is_flash_deal     BOOLEAN NOT NULL DEFAULT false,
    is_recommended    BOOLEAN NOT NULL DEFAULT false,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE product_specifications (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id TEXT NOT NULL REFERENCES products(id),
    label      TEXT NOT NULL,
    value      TEXT NOT NULL,
    sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE product_vehicle_types (
    product_id   TEXT NOT NULL REFERENCES products(id),
    vehicle_type TEXT NOT NULL,
    PRIMARY KEY (product_id, vehicle_type)
);

CREATE TABLE product_compatibility (
    product_id       TEXT NOT NULL REFERENCES products(id),
    compatible_with  TEXT NOT NULL,
    PRIMARY KEY (product_id, compatible_with)
);

CREATE TABLE product_reviews (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id          TEXT NOT NULL REFERENCES products(id),
    author              TEXT,
    rating              NUMERIC(3,2),
    comment             TEXT,
    reviewed_at         DATE,
    is_verified_purchase BOOLEAN DEFAULT true,
    helpful_count       INT DEFAULT 0
);

CREATE TABLE offers (
    id            TEXT PRIMARY KEY,
    title         TEXT,
    subtitle      TEXT,
    code          TEXT,
    category_id   TEXT REFERENCES categories(id),
    gradient_start TEXT,
    gradient_end  TEXT
);

CREATE TABLE coupons (
    id              TEXT PRIMARY KEY,
    code            TEXT UNIQUE,
    title           TEXT,
    description     TEXT,
    type            TEXT,
    value           NUMERIC(5,2),
    max_discount    NUMERIC(12,2),
    min_order_value NUMERIC(12,2),
    valid_from      TIMESTAMPTZ,
    valid_until     TIMESTAMPTZ,
    CHECK (type IN ('percent', 'freeDelivery'))
);

CREATE TABLE orders (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID NOT NULL REFERENCES users(id),
    external_id    TEXT UNIQUE,
    address        TEXT NOT NULL,
    payment_method TEXT NOT NULL,
    subtotal       NUMERIC(12,2),
    discount       NUMERIC(12,2),
    delivery       NUMERIC(12,2),
    tax            NUMERIC(12,2),
    grand_total    NUMERIC(12,2),
    status         TEXT NOT NULL DEFAULT 'Pending',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE order_items (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id     UUID NOT NULL REFERENCES orders(id),
    product_id   TEXT,
    product_name TEXT,
    brand        TEXT,
    quantity     INT,
    unit_price   NUMERIC(12,2),
    line_total   NUMERIC(12,2),
    image        TEXT
);

CREATE TABLE order_entries (
    id          TEXT PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES users(id),
    name        TEXT,
    brand       TEXT,
    quantity    INT,
    price       NUMERIC(12,2),
    type        TEXT NOT NULL,
    status      TEXT NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    source      TEXT,
    CHECK (type IN ('parts', 'mechanic', 'fuel', 'aiReport')),
    CHECK (status IN ('Pending', 'Delivered', 'Completed', 'In Progress', 'Cancelled'))
);

CREATE TABLE mechanics (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    rating          NUMERIC(3,2),
    review_count    INT,
    experience_years INT,
    distance_km     NUMERIC(6,2),
    eta_minutes     INT,
    is_available    BOOLEAN DEFAULT true,
    price_starting  NUMERIC(12,2),
    phone           TEXT,
    about           TEXT,
    is_verified     BOOLEAN DEFAULT false
);

CREATE TABLE mechanic_skills ( mechanic_id TEXT NOT NULL REFERENCES mechanics(id), skill TEXT NOT NULL, PRIMARY KEY (mechanic_id, skill) );
CREATE TABLE mechanic_languages ( mechanic_id TEXT NOT NULL REFERENCES mechanics(id), language TEXT NOT NULL, PRIMARY KEY (mechanic_id, language) );
CREATE TABLE mechanic_working_hours ( mechanic_id TEXT NOT NULL REFERENCES mechanics(id), day TEXT NOT NULL, open TEXT, close TEXT, PRIMARY KEY (mechanic_id, day) );

CREATE TABLE mechanic_services (
    id                 TEXT PRIMARY KEY,
    name               TEXT NOT NULL,
    icon               TEXT,
    price              NUMERIC(12,2),
    estimated_minutes  INT,
    description        TEXT
);

CREATE TABLE mechanic_service_offered (
    mechanic_id TEXT NOT NULL REFERENCES mechanics(id),
    service_id  TEXT NOT NULL REFERENCES mechanic_services(id),
    PRIMARY KEY (mechanic_id, service_id)
);

CREATE TABLE mechanic_categories (
    id          TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    icon        TEXT,
    color       TEXT,
    bg_color    TEXT,
    description TEXT,
    sort_order  INT DEFAULT 0
);

CREATE TABLE mechanic_reviews (
    id           TEXT PRIMARY KEY,
    mechanic_id  TEXT NOT NULL REFERENCES mechanics(id),
    reviewer_name TEXT,
    rating       NUMERIC(3,2),
    comment      TEXT,
    reviewed_at  DATE,
    vehicle      TEXT
);

CREATE TABLE mechanic_bookings (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id),
    mechanic_id  TEXT NOT NULL REFERENCES mechanics(id),
    service_id   TEXT REFERENCES mechanic_services(id),
    vehicle_id   UUID REFERENCES vehicles(id),
    status       TEXT NOT NULL,
    address      TEXT,
    lat          NUMERIC(9,6),
    lng          NUMERIC(9,6),
    scheduled_at TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE booking_events (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id  UUID NOT NULL REFERENCES mechanic_bookings(id),
    status      TEXT,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    payload     JSONB
);

CREATE TABLE ratings (
    booking_id UUID PRIMARY KEY REFERENCES mechanic_bookings(id),
    rating     NUMERIC(3,2),
    review     TEXT
);

CREATE TABLE fuel_orders (
    id                TEXT PRIMARY KEY,
    user_id           UUID NOT NULL REFERENCES users(id),
    fuel_type         TEXT NOT NULL,
    quantity          NUMERIC(6,2) NOT NULL,
    vehicle_type      TEXT,
    vehicle_name      TEXT,
    vehicle_number    TEXT,
    station_id        TEXT,
    station_name      TEXT,
    brand             TEXT,
    price_per_litre   NUMERIC(6,2),
    delivery_label    TEXT,
    delivery_address  TEXT,
    lat               NUMERIC(9,6),
    lng               NUMERIC(9,6),
    status            TEXT NOT NULL,
    payment_method    TEXT,
    partner_id        TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE price_estimates (
    fuel_order_id   TEXT PRIMARY KEY REFERENCES fuel_orders(id),
    fuel_cost       NUMERIC(12,2),
    delivery_charge NUMERIC(12,2),
    platform_fee    NUMERIC(12,2),
    taxes           NUMERIC(12,2),
    grand_total     NUMERIC(12,2),
    eta_minutes     INT
);

CREATE TABLE fuel_stations (
    id             TEXT PRIMARY KEY,
    name           TEXT,
    brand          TEXT,
    rating         NUMERIC(3,2),
    rating_count   INT,
    distance_km    NUMERIC(6,2),
    eta_minutes    INT,
    price_per_litre NUMERIC(6,2),
    availability   TEXT,
    is_open        BOOLEAN,
    address        TEXT,
    latitude       NUMERIC(9,6),
    longitude      NUMERIC(9,6),
    CHECK (availability IN ('available', 'low', 'outOfStock'))
);

CREATE TABLE fuel_partners (
    id             TEXT PRIMARY KEY,
    name           TEXT,
    phone          TEXT,
    rating         NUMERIC(3,2),
    rating_count   INT,
    distance_km    NUMERIC(6,2),
    eta_minutes    INT,
    is_available   BOOLEAN,
    vehicle_number TEXT,
    vehicle_model  TEXT
);

CREATE TABLE tracking_events (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id           TEXT NOT NULL REFERENCES fuel_orders(id),
    status             TEXT,
    partner_lat        NUMERIC(9,6),
    partner_lng        NUMERIC(9,6),
    distance_remaining NUMERIC(6,2),
    eta_minutes        INT,
    occurred_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE invoices (
    invoice_id      TEXT PRIMARY KEY,
    order_id        TEXT UNIQUE NOT NULL REFERENCES fuel_orders(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    fuel_type       TEXT,
    quantity        NUMERIC(6,2),
    price_per_litre NUMERIC(6,2),
    fuel_cost       NUMERIC(12,2),
    delivery_charge NUMERIC(12,2),
    platform_fee    NUMERIC(12,2),
    taxes           NUMERIC(12,2),
    grand_total     NUMERIC(12,2),
    partner_name    TEXT,
    vehicle_number  TEXT
);

CREATE TABLE conversations (
    id         TEXT PRIMARY KEY,
    user_id    UUID NOT NULL REFERENCES users(id),
    title      TEXT NOT NULL,
    is_pinned  BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE chat_messages (
    id              TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL REFERENCES conversations(id),
    role            TEXT NOT NULL,
    content         TEXT,
    timestamp       TIMESTAMPTZ NOT NULL DEFAULT now(),
    response        JSONB,
    CHECK (role IN ('user', 'assistant'))
);

CREATE TABLE diagnoses (
    id                 TEXT PRIMARY KEY,
    user_id            UUID NOT NULL REFERENCES users(id),
    vehicle_name       TEXT,
    vehicle_type       TEXT,
    problem            TEXT,
    symptoms           JSONB,
    possible_causes    JSONB,
    severity           TEXT,
    estimated_cost     NUMERIC(12,2),
    recommended_action TEXT,
    should_drive       BOOLEAN,
    recommended_service TEXT,
    confidence         SMALLINT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
