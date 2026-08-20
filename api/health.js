module.exports = async (req, res) => {
  const base = process.env.N8N_BASE_URL;
  if (!base) return res.status(500).json({ ok: false, reason: 'N8N_BASE_URL not set' });
  try {
    const r = await fetch(base.replace(/\/+$/, '') + '/healthz', { method: 'GET' });
    return res.status(r.ok ? 200 : 502).json({ ok: r.ok });
  } catch (e) {
    return res.status(502).json({ ok: false, reason: e.message });
  }
};
