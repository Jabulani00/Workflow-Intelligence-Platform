-- ============================================================
-- WIP migration v2 — role-based users + automation support tables
-- Idempotent. Run against Supabase after 01-migration.sql.
-- ============================================================

-- ---------- Notifications (doc §34) ----------
CREATE TABLE IF NOT EXISTS public.notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id  UUID REFERENCES public.users(user_id),
    type     TEXT NOT NULL,
    channel  TEXT NOT NULL DEFAULT 'web',
    message  TEXT,
    status   TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','SENT','FAILED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- Reminder tracking (doc §33) ----------
ALTER TABLE public.weekly_reports ADD COLUMN IF NOT EXISTS last_reminder_sent TIMESTAMPTZ;
ALTER TABLE public.weekly_reports ADD COLUMN IF NOT EXISTS reminder_count INTEGER NOT NULL DEFAULT 0;

-- ---------- Registration extras ----------
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS position TEXT;

-- ---------- Four role-based users ----------
INSERT INTO public.users (full_name, preferred_name, email, whatsapp, role, department, position, status) VALUES
    ('Aisha Admin',    'Aisha',  'admin@wip.local',          '+27000000010', 'ADMIN',    'Operations', 'Administrator',  'ACTIVE'),
    ('Naledi Mentor',  'Naledi', 'naledi.mentor@wip.local',  '+27000000011', 'MENTOR',   'IT',         'Team Lead',      'ACTIVE'),
    ('Sipho Employee', 'Sipho',  'sipho@wip.local',          '+27000000012', 'EMPLOYEE', 'IT',         'IT Technician',  'ACTIVE'),
    ('Lerato Intern',  'Lerato', 'lerato@wip.local',         '+27000000013', 'EMPLOYEE', 'IT',         'Intern',         'ACTIVE')
ON CONFLICT (email) DO NOTHING;

-- Assign both employees to Naledi
UPDATE public.users e
SET mentor_id = m.user_id
FROM public.users m
WHERE m.email = 'naledi.mentor@wip.local'
  AND e.email IN ('sipho@wip.local', 'lerato@wip.local')
  AND e.mentor_id IS DISTINCT FROM m.user_id;
