// Shared proxy helper (repo-root copy, used when Vercel deploys from the repo root).
// Forwards a JSON POST to the n8n webhook whose base is in N8N_BASE_URL.
async function proxy(req, res, path) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ reply: 'Method not allowed' });
  }
  const base = process.env.N8N_BASE_URL;
  if (!base) {
    return res.status(500).json({
      reply: 'Server not configured. Set N8N_BASE_URL (your public n8n URL) in the Vercel project environment variables.'
    });
  }
  const url = base.replace(/\/+$/, '') + path;
  try {
    const upstream = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(req.body || {})
    });
    const text = await upstream.text();
    res.status(upstream.status);
    res.setHeader('Content-Type', upstream.headers.get('content-type') || 'application/json');
    return res.send(text);
  } catch (e) {
    return res.status(502).json({
      reply: 'Backend unreachable (' + e.message + '). Check that n8n is publicly reachable at N8N_BASE_URL.'
    });
  }
}
module.exports = { proxy };
