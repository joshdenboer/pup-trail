// Draws a family pet sprite in the Pup Trail art style. Only signed-in parents may call it.
// Env vars (Netlify → Site configuration → Environment variables): OPENAI_API_KEY
const SUPABASE_URL = 'https://luukbxyfdeltcaesuwdw.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_JfH9pQrb13OYt_BSuy9USg_g6zKNLfH';
const KIND_WORDS = { dog: 'dog', cat: 'cat', other: 'pet animal' };

exports.handler = async (event) => {
  const json = (code, body) => ({ statusCode: code, headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  if (event.httpMethod !== 'POST') return json(405, { error: 'POST only' });
  if (!process.env.OPENAI_API_KEY) return json(500, { error: 'OPENAI_API_KEY is not set on the Netlify site' });

  // must be a signed-in parent (Supabase session token)
  const auth = event.headers.authorization || event.headers.Authorization || '';
  const who = await fetch(SUPABASE_URL + '/auth/v1/user', { headers: { apikey: SUPABASE_ANON_KEY, Authorization: auth } });
  if (who.status !== 200) return json(401, { error: 'Sign in as a parent first' });

  let body; try { body = JSON.parse(event.body || '{}'); } catch { return json(400, { error: 'bad json' }); }
  const name = String(body.name || '').slice(0, 14).trim();
  const kind = ['dog', 'cat', 'other'].includes(body.kind) ? body.kind : 'dog';
  const desc = String(body.description || '').slice(0, 200).trim();
  if (!desc) return json(400, { error: 'Describe the pet first' });

  const prompt = `A ${KIND_WORDS[kind]}: ${desc}. ` +
    `Realistic animal proportions and coloring, full body side view walking to the right, mid-stride, friendly happy expression, ` +
    `stylized 2D video game sprite with clean bold outlines and flat cel shading, kid-friendly Nintendo style, centered, ` +
    `transparent background, no shadow, no text, no words.`;

  const r = await fetch('https://api.openai.com/v1/images/generations', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + process.env.OPENAI_API_KEY },
    body: JSON.stringify({ model: 'gpt-image-2.5-flare', prompt, size: '1024x1024', quality: 'low', background: 'transparent', output_format: 'png', n: 1 })
  });
  const data = await r.json();
  if (!r.ok) return json(502, { error: (data.error && data.error.message) || 'image service error' });
  return json(200, { b64: data.data[0].b64_json, name, kind });
};
