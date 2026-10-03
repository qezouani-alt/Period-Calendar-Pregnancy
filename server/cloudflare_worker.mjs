// Luna's Cloudflare Worker. Add GEMINI_API_KEY as a Worker secret in the dashboard.
const defaultModel = 'gemini-3.1-flash-lite';
const maxRequestBytes = 32768;
const baseInstruction =
  "You are a supportive women's-health education companion. Give general " +
  'information, not diagnosis, treatment, prescriptions, or emergency care. ' +
  'For possible emergencies, advise urgent local medical care.';

function jsonResponse(status, value) {
  return new Response(JSON.stringify(value), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
    },
  });
}

function validConversation(contents) {
  return Array.isArray(contents) &&
    contents.length >= 1 &&
    contents.length <= 13 &&
    contents.at(-1)?.role === 'user' &&
    contents.every(item =>
      item &&
      (item.role === 'user' || item.role === 'model') &&
      Array.isArray(item.parts) &&
      item.parts.length === 1 &&
      typeof item.parts[0]?.text === 'string' &&
      item.parts[0].text.trim().length > 0
    );
}

export async function generateReply(payload, env, fetchProvider = fetch) {
  if (!env.GEMINI_API_KEY) {
    return jsonResponse(503, { error: { message: 'AI service is not configured.' } });
  }
  if (!payload || typeof payload !== 'object' || !validConversation(payload.contents)) {
    return jsonResponse(400, { error: { message: 'Invalid conversation.' } });
  }

  const requestedInstruction = payload.systemInstruction?.parts?.[0]?.text;
  const instruction = typeof requestedInstruction === 'string'
    ? requestedInstruction.slice(0, 8000)
    : '';
  const outgoing = {
    systemInstruction: { parts: [{ text: `${baseInstruction}\n\n${instruction}` }] },
    contents: payload.contents,
    generationConfig: { temperature: 0.45, maxOutputTokens: 1000 },
  };
  const model = env.GEMINI_MODEL || defaultModel;
  let provider;
  try {
    provider = await fetchProvider(
      `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`,
      {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'x-goog-api-key': env.GEMINI_API_KEY,
        },
        body: JSON.stringify(outgoing),
        signal: AbortSignal.timeout(35000),
      },
    );
  } catch {
    return jsonResponse(503, { error: { message: 'AI service is temporarily unavailable.' } });
  }
  if (provider.status === 429) {
    return jsonResponse(429, { error: { message: 'AI limit reached. Try again later.' } });
  }
  if (!provider.ok) {
    return jsonResponse(503, { error: { message: 'AI service is temporarily unavailable.' } });
  }
  let data;
  try {
    data = await provider.json();
  } catch {
    return jsonResponse(503, { error: { message: 'AI service returned an invalid response.' } });
  }
  const parts = data?.candidates?.[0]?.content?.parts;
  const answer = Array.isArray(parts)
    ? parts.map(part => typeof part?.text === 'string' ? part.text : '').join('').trim()
    : '';
  return answer
    ? jsonResponse(200, { text: answer })
    : jsonResponse(503, { error: { message: 'AI service returned an empty response.' } });
}

export default {
  async fetch(request, env) {
    const path = new URL(request.url).pathname;
    if (request.method === 'GET' && path === '/health') {
      return env.GEMINI_API_KEY
        ? jsonResponse(200, { status: 'ok' })
        : jsonResponse(503, { status: 'not configured' });
    }
    if (request.method !== 'POST' || path !== '/ai') {
      return jsonResponse(404, { error: { message: 'Not found.' } });
    }
    const raw = await request.text();
    if (new TextEncoder().encode(raw).length > maxRequestBytes) {
      return jsonResponse(413, { error: { message: 'Request is too large.' } });
    }
    let payload;
    try {
      payload = JSON.parse(raw);
    } catch {
      return jsonResponse(400, { error: { message: 'Invalid JSON.' } });
    }
    return generateReply(payload, env);
  },
};
