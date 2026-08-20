# WIP Chatbot — Frontend (Vercel)

A polished conversational UI for the WIP platform. It's a **static page** plus **serverless
proxy functions** that forward to your n8n webhooks — so the browser never talks to n8n
directly (no CORS, and your n8n URL stays server-side).

```
vercel-app/            ← set this as the Vercel "Root Directory"
├── index.html         ← the chatbot UI (environment-aware), served at /
├── api/               ← Vercel serverless functions (proxies to n8n)
│   ├── _lib.js        ← shared proxy helper (not a route)
│   ├── chat.js  approval.js  admin.js  register.js  health.js
├── vercel.json
└── package.json
```

## How it talks to the backend

| Where it runs | Frontend calls | Then |
|---------------|----------------|------|
| **Local** (`localhost`) | `http://localhost:5678/webhook/*` directly | needs the Docker stack running (CORS is enabled on the webhooks) |
| **Vercel** | `/api/*` (same origin) | the function forwards to `${N8N_BASE_URL}/webhook/*` |

The UI auto-detects which one it is — no build step needed.

## Deploy to Vercel from GitHub

1. Push this repo to GitHub (already done for the parent project).
2. On **vercel.com → Add New → Project → Import** your GitHub repo.
3. **Root Directory:** set to `vercel-app`.
4. **Framework Preset:** _Other_ (it's static + functions — no build command needed).
5. **Environment Variables:** add
   - `N8N_BASE_URL` = your **public** n8n base URL (see below), e.g. `https://your-n8n.example.com`
6. **Deploy.**

### N8N_BASE_URL — n8n must be publicly reachable
Vercel runs in the cloud, so it can't reach `localhost`. Point `N8N_BASE_URL` at a public n8n:
- a tunnel for testing — `cloudflared tunnel --url http://localhost:5678` (URL changes each run), or
- a hosted n8n — **n8n Cloud**, Railway, Render, Fly.io, or a VPS (stable URL, recommended).

After changing `N8N_BASE_URL`, redeploy (or it applies on the next deploy).

## Run locally

Either open it through the project's Docker stack (nginx serves this folder at
**http://localhost:8080**), or use the Vercel CLI:

```bash
npm i -g vercel
cd vercel-app
vercel dev            # serves the UI + /api functions locally on http://localhost:3000
```
For `vercel dev`, create `vercel-app/.env` with `N8N_BASE_URL=http://localhost:5678`.

## Security note
When you expose n8n publicly, its webhooks (`/webhook/admin`, etc.) become callable by
anyone who knows the paths. For production, protect them — a shared secret header checked in
each workflow, an auth layer in front of n8n, or an IP allowlist.
