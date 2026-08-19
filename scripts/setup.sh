#!/usr/bin/env bash
# Imports the Supabase credential + all workflows into a running n8n and activates them.
# Prereq: `docker compose up -d`, and create the n8n owner account once at http://localhost:5678
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

declare -A IDS=(
  [WF-02_Chatbot_Router]=wip-wf-02-router
  [WF-09_Mentor_Approval]=wip-wf-09-approval
  [WF-11_Leave_Request]=wip-wf-11-leave
  [WF-14_Reminder_Engine]=wip-wf-14-reminder
  [WF-16_Admin_Console]=wip-wf-16-admin
  [WF-19_Notification_Dispatcher]=wip-wf-19-dispatch
  [WF-21_Registration]=wip-wf-21-register
)

docker cp "$ROOT/workflows/_credentials.json" wip-n8n:/tmp/_credentials.json
docker exec wip-n8n n8n import:credentials --input=/tmp/_credentials.json

for f in "${!IDS[@]}"; do
  docker cp "$ROOT/workflows/$f.json" wip-n8n:/tmp/$f.json
  docker exec wip-n8n n8n import:workflow --input=/tmp/$f.json
  docker exec wip-n8n n8n update:workflow --id="${IDS[$f]}" --active=true
done

docker restart wip-n8n
echo "Done. Open http://localhost:8080"
