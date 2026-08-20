# ============================================================
# Exposes your local n8n (port 5678) to the internet so Twilio
# can deliver inbound WhatsApp messages to WF-20.
#
# SECURITY: while this runs, your n8n webhooks are publicly reachable
# at the printed URL. Keep the URL private and press Ctrl+C to stop
# the tunnel when you're done testing.
# ============================================================

Write-Host "Starting a public tunnel to http://localhost:5678 ..." -ForegroundColor Cyan
Write-Host ""
Write-Host "When a URL appears (e.g. https://something.loca.lt), do this in Twilio:" -ForegroundColor Yellow
Write-Host "  Console -> Messaging -> Try it out -> Send a WhatsApp message -> Sandbox settings"
Write-Host "  Set 'When a message comes in' to:   <URL>/webhook/wa-inbound   (Method: POST)"
Write-Host "  Save. Then text your sandbox from WhatsApp:  clock me in"
Write-Host ""

# Uses localtunnel (no install needed beyond Node). Alternatives below.
npx --yes localtunnel --port 5678

# --- Alternatives (often more reliable than localtunnel) ---
# ngrok (needs a free account + authtoken):
#     ngrok http 5678
# cloudflared quick tunnel (no account):
#     cloudflared tunnel --url http://localhost:5678
