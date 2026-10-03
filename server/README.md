# Luna AI service

The iOS app calls `POST /ai` with `systemInstruction`, `contents`, and
`generationConfig`. This service forwards the conversation to Gemini and returns
`{"text":"..."}`. It holds `GEMINI_API_KEY` on the server. Never put that key in
Flutter source, assets, or a `--dart-define` value.

## Check locally

Use a private environment variable for the key, then run:

```sh
python3 server/main.py
curl http://localhost:8080/health
```

`/health` returns 200 only when the key is present. The service uses
`gemini-3.1-flash-lite` by default; override it with `GEMINI_MODEL` if needed.

Run the isolated server tests with:

```sh
python3 -m unittest discover -s server -v
```

## Cloudflare deployment for App Review

The production Worker is `luna-ai` at
`https://luna-ai.elqznysf.workers.dev/ai`. Its source is
`server/cloudflare_worker.mjs`. Add `GEMINI_API_KEY` as an encrypted **Secret**
under Worker Settings → Runtime variables and secrets → Production. Do not
add the key as plain text or put it into Flutter. The Worker defaults to
`gemini-3.1-flash-lite`; `GEMINI_MODEL` is an optional nonsecret override.

Check `GET https://luna-ai.elqznysf.workers.dev/health` for HTTP 200, then send
a harmless test question to `/ai` and confirm a nonempty `text` response. The
Flutter client and build script use the production Worker by default. Build iOS
with:

```sh
./scripts/build_ios_release.sh --no-codesign
```

Set `AI_BACKEND_URL` only if deploying a different HTTPS `/ai` endpoint. Keep
the Worker available throughout App Review and monitor usage to protect the
Gemini quota. The Python service and Dockerfile remain available for a different
host, if needed.
