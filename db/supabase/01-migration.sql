-- ============================================================
-- WIP — Workflow Intelligence Platform
-- Supabase migration (run against the hosted Postgres).
-- Idempotent: safe to run more than once.
-- gen_random_uuid() is built into Supabase Postgres (v15+), no extension needed.
-- ============================================================

-- ---------- Reference / people ----------
CREATE TABLE IF NOT EXISTS public.users (
    user_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name      TEXT        NOT NULL,
    preferred_name TEXT,
    email          TEXT        UNIQUE NOT NULL,
    phone          TEXT,
    whatsapp       TEXT,
    role           TEXT        NOT NULL DEFAULT 'EMPLOYEE'
                       CHECK (role IN ('EMPLOYEE','MENTOR','ADMIN')),
    mentor_id      UUID        REFERENCES public.users(user_id),
    department     TEXT,
    status         TEXT        NOT NULL DEFAULT 'ACTIVE'
                       CHECK (status IN ('PENDING','UNDER_REVIEW','APPROVED','ACTIVE','REJECTED','DEACTIVATED')),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- Attendance ----------
CREATE TABLE IF NOT EXISTS public.attendance (
    attendance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES public.users(user_id),
    work_date     DATE NOT NULL DEFAULT CURRENT_DATE,
    clock_in      TIMESTAMPTZ,
    clock_out     TIMESTAMPTZ,
    total_minutes INTEGER,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, work_date)
);

-- ---------- Daily work ----------
CREATE TABLE IF NOT EXISTS public.daily_work_entries (
    entry_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES public.users(user_id),
    work_date   DATE NOT NULL DEFAULT CURRENT_DATE,
    category    TEXT,
    description TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- Weekly reports ----------
CREATE TABLE IF NOT EXISTS public.weekly_reports (
    report_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES public.users(user_id),
    iso_year     INTEGER NOT NULL,
    iso_week     INTEGER NOT NULL,
    status       TEXT NOT NULL DEFAULT 'DRAFT'
                     CHECK (status IN ('DRAFT','INCOMPLETE','SUBMITTED','UNDER_REVIEW',
                                       'CORRECTION_REQUIRED','APPROVED','REJECTED','LOCKED')),
    submitted_at TIMESTAMPTZ,
    approved_by  UUID REFERENCES public.users(user_id),
    approved_at  TIMESTAMPTZ,
    version      INTEGER NOT NULL DEFAULT 1,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, iso_year, iso_week)
);

-- ---------- Leave ----------
CREATE TABLE IF NOT EXISTS public.leave_requests (
    leave_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES public.users(user_id),
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
CREATE TABLE IF NOT EXISTS public.audit_logs (
    audit_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id  UUID REFERENCES public.users(user_id),
    action    TEXT NOT NULL,
    record_id UUID,
    metadata  JSONB,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- Seed demo users ----------
INSERT INTO public.users (full_name, preferred_name, email, whatsapp, role, department, status)
VALUES
    ('Demo Employee', 'Demo', 'demo@wip.local', '+27000000001', 'EMPLOYEE', 'IT', 'ACTIVE'),
    ('Demo Mentor',   'Mentor', 'mentor@wip.local', '+27000000002', 'MENTOR', 'IT', 'ACTIVE')
ON CONFLICT (email) DO NOTHING;

UPDATE public.users e
SET mentor_id = m.user_id
FROM public.users m
WHERE e.email = 'demo@wip.local' AND m.email = 'mentor@wip.local'
  AND e.mentor_id IS DISTINCT FROM m.user_id;

-- ------------------------------------------------------------
-- NOTE on Row Level Security (doc §38):
-- The n8n workflows connect as the Postgres owner role, which BYPASSES RLS,
-- so these tables work immediately. If you later expose them directly to the
-- browser via PostgREST (anon/service keys), enable RLS and add policies:
--   ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;  -- etc.
-- ------------------------------------------------------------
