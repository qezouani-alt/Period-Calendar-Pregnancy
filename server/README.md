# AI backend

The mobile app never stores or sends a Gemini/Google API key. Deploy a server-side
HTTPS endpoint that stores the key in its own secret manager and accepts a JSON
request with `systemInstruction`, `contents`, and `generationConfig`.

Return either `{ "text": "..." }` or a Gemini-compatible response body. Configure
the released app with its public endpoint only:

```bash
flutter build ios --dart-define=AI_BACKEND_URL=https://api.example.com/ai
```

`AI_BACKEND_URL` is an endpoint, not a secret. Do not put provider credentials in
`.env`, Flutter assets, source control, or `--dart-define` values.
