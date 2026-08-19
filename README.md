# WIP — Workflow Intelligence Platform

> **Work. Report. Approve. Done.**

A working local build of the WIP platform from the master doc, on **n8n** with
**Supabase (hosted Postgres)** as the source of truth, plus a **web chat interface**.

n8n and the web UI run in Docker on your machine; application data lives in your Supabase
project. A local Postgres also runs, but only to hold n8n's own workflow metadata.

---

## 1. What's running

| Service        | URL / Port                     | Purpose                                     |
|----------------|--------------------------------|---------------------------------------------|
| Web chat UI    | http://localhost:8080          | Talk to the workflows from a browser        |
| n8n            | http://localhost:5678          | Automation engine + workflow editor         |
| Supabase       | your project (see `.env`-style secrets) | **App source of truth**            |
| Local Postgres | localhost:5432                 | n8n's own metadata only                     |

**n8n owner login:** created on first launch — email + a password of your choice
(dev build used `marketmat73@gmail.com`; the password lives only in your local n8n, never in git).

**Supabase** app-DB connection is stored inside n8n as the `WIP Postgres` credential
(session pooler, SSL). Its shape is in `workflows/_credentials.example.json`.

---

## 2. Start / stop

```bash
docker compose up -d      # start
docker compose down       # stop (keeps data)
docker compose down -v    # stop and WIPE local volumes
```

Data survives restarts (Docker volumes `postgres_data`, `n8n_data`).

---

## 3. Web interface

Open **http://localhost:8080**. Choose who you're acting as, then type or click a command
chip. The page calls the n8n webhooks directly (CORS enabled), which run against Supabase.
The side panel does mentor approvals. Edit `web/index.html` and refresh — nginx serves it live.

---

## 4. Workflows (all imported + active)

| # | Workflow            | Endpoint / Trigger                    | What it does                                  |
|---|---------------------|----------------------------------------|-----------------------------------------------|
| WF-02 | Chatbot Router  | `POST /webhook/chatbot`               | NL command → DB action → reply (no AI needed) |
| WF-09 | Mentor Approval | `POST /webhook/approval`              | Assigned mentor approves/rejects a report     |
| WF-11 | Leave Request   | `POST /webhook/leave`                 | Structured leave request → notifies mentor    |
| WF-16 | Admin Console   | `POST /webhook/admin`                 | **ADMIN-only** reporting + registration review |
| WF-21 | Registration    | `POST /webhook/register`              | Public self-registration (PENDING)            |
| WF-14 | Reminder Engine | Schedule (weekdays 16:00)             | Flags employees with no weekly report         |

### Examples
```bash
# Employee
curl -sX POST localhost:5678/webhook/chatbot -H "Content-Type: application/json" \
  -d '{"email":"sipho@wip.local","message":"Clock me in"}'

# Leave
curl -sX POST localhost:5678/webhook/leave -H "Content-Type: application/json" \
  -d '{"email":"sipho@wip.local","leave_type":"ANNUAL","start_date":"2026-08-24","end_date":"2026-08-26"}'

# Mentor approval
curl -sX POST localhost:5678/webhook/approval -H "Content-Type: application/json" \
  -d '{"mentor_email":"naledi.mentor@wip.local","employee_email":"sipho@wip.local","action":"APPROVE"}'

# Admin (team report, then approve a registration)
curl -sX POST localhost:5678/webhook/admin -H "Content-Type: application/json" \
  -d '{"admin_email":"admin@wip.local","action":"TEAM_SUMMARY","department":"IT"}'
curl -sX POST localhost:5678/webhook/admin -H "Content-Type: application/json" \
  -d '{"admin_email":"admin@wip.local","action":"APPROVE_REGISTRATION","target_email":"kabelo@wip.local"}'

# Registration
curl -sX POST localhost:5678/webhook/register -H "Content-Type: application/json" \
  -d '{"full_name":"New Hire","email":"newhire@wip.local","department":"IT"}'
```

WF-16 actions: `TEAM_SUMMARY`, `OUTSTANDING_REPORTS`, `LIST_PENDING`,
`APPROVE_REGISTRATION`, `REJECT_REGISTRATION`. Non-admins get `⛔ Access denied`.

---

## 5. Seeded users (roles)

| Email                       | Role     | Mentor  | Notes            |
|-----------------------------|----------|---------|------------------|
| `admin@wip.local`           | ADMIN    | —       | Aisha            |
| `naledi.mentor@wip.local`   | MENTOR   | —       | Naledi           |
| `mentor@wip.local`          | MENTOR   | —       | original demo    |
| `sipho@wip.local`           | EMPLOYEE | Naledi  | Sipho            |
| `lerato@wip.local`          | EMPLOYEE | Naledi  | Lerato           |
| `demo@wip.local`            | EMPLOYEE | mentor  | original demo    |

---

## 6. Database

App tables in **Supabase** (`public`): `users`, `attendance`, `daily_work_entries`,
`weekly_reports`, `leave_requests`, `notifications`, `audit_logs`.

Migrations (idempotent, run in order):
- `db/supabase/01-migration.sql` — core tables + first demo users
- `db/supabase/02-automation.sql` — notifications, reminder columns, role users

Run a migration against Supabase:
```bash
docker cp db/supabase/01-migration.sql wip-postgres:/tmp/m.sql
docker exec -e PGPASSWORD='<db-password>' wip-postgres \
  psql -h aws-0-<region>.pooler.supabase.com -p 5432 \
  -U postgres.<project-ref> -d postgres -f /tmp/m.sql
```

`db/init/01-schema.sql` is the original local-only schema, kept for offline use.

---

## 7. First-time setup on a new machine

```bash
git clone <your-repo-url> && cd <repo>
cp .env.example .env                              # adjust if you like
cp workflows/_credentials.example.json workflows/_credentials.json
#   → edit _credentials.json with your Supabase pooler host/user/password
docker compose up -d
#   → open http://localhost:5678 once and create the owner account
./scripts/setup.sh          #  (Windows: ./scripts/setup.ps1)
```
`scripts/setup` imports the Supabase credential + all workflows and activates them.
Then run the two SQL migrations against your Supabase project (section 6).

---

## 8. Security / GitHub notes

- **Never committed** (see `.gitignore`): `WIP.env.txt`, `.env`, `workflows/_credentials.json`.
- The secrets originally shared in `WIP.env.txt` (Supabase keys + DB password) should be
  **rotated** in the Supabase dashboard, then updated in your local `_credentials.json`.
- Workflow JSONs contain **no secrets** — they reference the credential by id only.
- `allowUnauthorizedCerts` is set on the Supabase connection (standard for the pooler cert).

---

## 9. How this maps to the master doc

| Doc concept                          | Here                                             |
|--------------------------------------|--------------------------------------------------|
| Supabase / Postgres source of truth  | your Supabase project                            |
| Token-saving chatbot (§16)           | WF-02 keyword detection — AI only when needed    |
| Clock in/out, daily work (§20–21)    | WF-02 → `attendance`, `daily_work_entries`       |
| Weekly submission + approval (§26–29)| WF-02 submit → WF-09 approve + lock              |
| Leave / sick (§23–24)                | WF-11 + WF-02 `REPORT_SICK` → `leave_requests`   |
| Registration + admin approval (§4–6) | WF-21 → WF-16                                     |
| Roles & permissions (§3, §38)        | ADMIN/MENTOR/EMPLOYEE enforced in workflow SQL   |
| Reminder engine (§33)                | WF-14 (scheduled) → `notifications`              |
| Notifications (§34)                  | `notifications` table                            |
| Audit (§39)                          | `audit_logs` (registration/approval events)      |

### Natural next steps
Gemini AI node for free-text intent, WhatsApp/email delivery of notifications,
document upload to Supabase Storage, monthly admin exports (Excel/PDF).
