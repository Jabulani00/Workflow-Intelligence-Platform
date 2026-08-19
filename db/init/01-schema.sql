-- ============================================================
-- WIP — Workflow Intelligence Platform
-- Core database schema (Supabase = hosted Postgres; this is local)
-- Runs automatically the first time the postgres volume is created.
-- ============================================================

-- n8n keeps its own tables here (see DB_POSTGRESDB_SCHEMA=n8n)
CREATE SCHEMA IF NOT EXISTS n8n;

-- Application data lives in `public`.
CREATE EXTENSION IF NOT EXISTS "pgcrypto";  -- gen_random_uuid()

-- ---------- Reference / people ----------
CREATE TABLE IF NOT EXISTS users (
    user_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name      TEXT        NOT NULL,
    preferred_name TEXT,
    email          TEXT        UNIQUE NOT NULL,
    phone          TEXT,
    whatsapp       TEXT,
    role           TEXT        NOT NULL DEFAULT 'EMPLOYEE'
                       CHECK (role IN ('EMPLOYEE','MENTOR','ADMIN')),
    mentor_id      UUID        REFERENCES users(user_id),
    department     TEXT,
    status         TEXT        NOT NULL DEFAULT 'ACTIVE'
                       CHECK (status IN ('PENDING','UNDER_REVIEW','APPROVED','ACTIVE','REJECTED','DEACTIVATED')),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- Attendance ----------
CREATE TABLE IF NOT EXISTS attendance (
    attendance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(user_id),
    work_date     DATE NOT NULL DEFAULT CURRENT_DATE,
    clock_in      TIMESTAMPTZ,
    clock_out     TIMESTAMPTZ,
    total_minutes INTEGER,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, work_date)
);

-- ---------- Daily work ----------
CREATE TABLE IF NOT EXISTS daily_work_entries (
    entry_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(user_id),
    work_date   DATE NOT NULL DEFAULT CURRENT_DATE,
    category    TEXT,
    description TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- Weekly reports ----------
CREATE TABLE IF NOT EXISTS weekly_reports (
    report_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(user_id),
    iso_year     INTEGER NOT NULL,
    iso_week     INTEGER NOT NULL,
    status       TEXT NOT NULL DEFAULT 'DRAFT'
                     CHECK (status IN ('DRAFT','INCOMPLETE','SUBMITTED','UNDER_REVIEW',
                                       'CORRECTION_REQUIRED','APPROVED','REJECTED','LOCKED')),
    submitted_at TIMESTAMPTZ,
    approved_by  UUID REFERENCES users(user_id),
    approved_at  TIMESTAMPTZ,
    version      INTEGER NOT NULL DEFAULT 1,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, iso_year, iso_week)
);

-- ---------- Leave ----------
CREATE TABLE IF NOT EXISTS leave_requests (
    leave_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(user_id),
    leave_type TEXT NOT NULL
                   CHECK (leave_type IN ('ANNUAL','SICK','FAMILY','STUDY','OTHER')),
    start_date DATE NOT NULL,
    end_date   DATE NOT NULL,
    reason     TEXT,
    status     TEXT NOT NULL DEFAULT 'SUBMITTED'
                   CHECK (status IN ('DRAFT','SUBMITTED','UNDER_REVIEW','APPROVED','REJECTED','CANCELLED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- Audit ----------
CREATE TABLE IF NOT EXISTS audit_logs (
    audit_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id  UUID REFERENCES users(user_id),
    action    TEXT NOT NULL,
    record_id UUID,
    metadata  JSONB,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- Seed a demo user so the workflows work immediately ----------
INSERT INTO users (full_name, preferred_name, email, whatsapp, role, department, status)
VALUES
    ('Demo Employee', 'Demo', 'demo@wip.local', '+27000000001', 'EMPLOYEE', 'IT', 'ACTIVE'),
    ('Demo Mentor',   'Mentor', 'mentor@wip.local', '+27000000002', 'MENTOR', 'IT', 'ACTIVE')
ON CONFLICT (email) DO NOTHING;

-- Link the employee to the mentor
UPDATE users e
SET mentor_id = m.user_id
FROM users m
WHERE e.email = 'demo@wip.local' AND m.email = 'mentor@wip.local';
