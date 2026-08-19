# Imports the Supabase credential + all workflows into a running n8n and activates them.
# Prereq: `docker compose up -d`, and create the n8n owner account once at http://localhost:5678
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$ids = [ordered]@{
  "WF-02_Chatbot_Router"  = "wip-wf-02-router"
  "WF-09_Mentor_Approval" = "wip-wf-09-approval"
  "WF-11_Leave_Request"   = "wip-wf-11-leave"
  "WF-14_Reminder_Engine" = "wip-wf-14-reminder"
  "WF-16_Admin_Console"   = "wip-wf-16-admin"
  "WF-21_Registration"    = "wip-wf-21-register"
}
docker cp "$root/workflows/_credentials.json" wip-n8n:/tmp/_credentials.json
docker exec wip-n8n n8n import:credentials --input=/tmp/_credentials.json
foreach ($f in $ids.Keys) {
  docker cp "$root/workflows/$f.json" wip-n8n:/tmp/$f.json
  docker exec wip-n8n n8n import:workflow --input=/tmp/$f.json
  docker exec wip-n8n n8n update:workflow --id=$($ids[$f]) --active=true
}
docker restart wip-n8n
Write-Host "Done. Open http://localhost:8080"
