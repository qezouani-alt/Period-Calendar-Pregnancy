import assert from 'node:assert/strict';
import test from 'node:test';
import worker, { generateReply } from './cloudflare_worker.mjs';

const requestBody = {
  systemInstruction: { parts: [{ text: 'Be warm and concise.' }] },
  contents: [{ role: 'user', parts: [{ text: 'Hello' }] }],
};

test('Luna request returns a reply while keeping the key out of the response', async () => {
  let sent;
  const response = await generateReply(requestBody, { GEMINI_API_KEY: 'test-secret' },
    async (_url, options) => {
      sent = options;
      return new Response(JSON.stringify({
        candidates: [{ content: { parts: [{ text: 'Hello from Luna' }] } }],
      }), { status: 200 });
    });
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { text: 'Hello from Luna' });
  assert.equal(sent.headers['x-goog-api-key'], 'test-secret');
  assert.match(JSON.parse(sent.body).systemInstruction.parts[0].text, /general information/);
});

test('unconfigured and malformed requests are rejected', async () => {
  const unconfigured = await worker.fetch(
    new Request('https://example.workers.dev/health'), {},
  );
  assert.equal(unconfigured.status, 503);
  const malformed = await generateReply({ contents: [] }, { GEMINI_API_KEY: 'test-secret' });
  assert.equal(malformed.status, 400);
});
