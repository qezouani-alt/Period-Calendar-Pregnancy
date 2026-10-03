"""Small HTTPS-hosted proxy for Luna and AI Chef.

Deploy behind an HTTPS URL and provide GEMINI_API_KEY as a server secret.
The Flutter app sends no provider credentials to this service.
"""

import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


MAX_REQUEST_BYTES = 32_768
MODEL = os.environ.get("GEMINI_MODEL", "gemini-3.1-flash-lite")
BASE_INSTRUCTION = (
    "You are a supportive women's-health education companion. Give general "
    "information, not diagnosis, treatment, prescriptions, or emergency care. "
    "For possible emergencies, advise urgent local medical care."
)


def generate_reply(payload, *, api_key, opener=urlopen):
    if not api_key:
        return 503, {"error": {"message": "AI service is not configured."}}
    if not isinstance(payload, dict):
        return 400, {"error": {"message": "Invalid request."}}

    contents = payload.get("contents")
    if not isinstance(contents, list) or not 1 <= len(contents) <= 13:
        return 400, {"error": {"message": "Invalid conversation."}}
    for item in contents:
        if not isinstance(item, dict) or item.get("role") not in ("user", "model"):
            return 400, {"error": {"message": "Invalid conversation."}}
        parts = item.get("parts")
        if (
            not isinstance(parts, list)
            or len(parts) != 1
            or not isinstance(parts[0], dict)
            or not isinstance(parts[0].get("text"), str)
            or not parts[0]["text"].strip()
        ):
            return 400, {"error": {"message": "Invalid conversation."}}
    if contents[-1]["role"] != "user":
        return 400, {"error": {"message": "Last message must be from the user."}}

    system_instruction = payload.get("systemInstruction")
    requested_instruction = (
        system_instruction.get("parts", [])
        if isinstance(system_instruction, dict)
        else []
    )
    instruction = ""
    if isinstance(requested_instruction, list) and requested_instruction:
        first = requested_instruction[0]
        if isinstance(first, dict) and isinstance(first.get("text"), str):
            instruction = first["text"][:8000]

    outgoing = {
        "systemInstruction": {
            "parts": [{"text": f"{BASE_INSTRUCTION}\n\n{instruction}"}]
        },
        "contents": contents,
        "generationConfig": {"temperature": 0.45, "maxOutputTokens": 1000},
    }
    request = Request(
        f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent",
        data=json.dumps(outgoing).encode("utf-8"),
        headers={"Content-Type": "application/json", "x-goog-api-key": api_key},
        method="POST",
    )
    try:
        with opener(request, timeout=35) as response:
            data = json.load(response)
    except HTTPError as error:
        # Do not relay provider errors verbatim: they may include account details.
        if error.code == 429:
            return 429, {"error": {"message": "AI limit reached. Try again later."}}
        if error.code in (401, 403):
            return 503, {"error": {"message": "AI service is not configured."}}
        return 503, {"error": {"message": "AI service is temporarily unavailable."}}
    except (URLError, TimeoutError, ValueError):
        return 503, {"error": {"message": "AI service is temporarily unavailable."}}

    candidates = data.get("candidates", []) if isinstance(data, dict) else []
    first_candidate = candidates[0] if candidates else None
    content = first_candidate.get("content") if isinstance(first_candidate, dict) else None
    parts = content.get("parts", []) if isinstance(content, dict) else []
    answer = "".join(
        part.get("text", "") for part in parts if isinstance(part, dict)
    ).strip()
    if not answer:
        return 503, {"error": {"message": "AI service returned an empty response."}}
    return 200, {"text": answer}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            if os.environ.get("GEMINI_API_KEY"):
                self._send(200, {"status": "ok"})
            else:
                self._send(503, {"status": "not configured"})
        else:
            self._send(404, {"error": {"message": "Not found."}})

    def do_POST(self):
        if self.path != "/ai":
            self._send(404, {"error": {"message": "Not found."}})
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            length = 0
        if not 0 < length <= MAX_REQUEST_BYTES:
            self._send(413, {"error": {"message": "Request is too large."}})
            return
        try:
            payload = json.loads(self.rfile.read(length))
        except (UnicodeDecodeError, ValueError):
            self._send(400, {"error": {"message": "Invalid JSON."}})
            return
        status, data = generate_reply(payload, api_key=os.environ.get("GEMINI_API_KEY"))
        self._send(status, data)

    def _send(self, status, data):
        body = json.dumps(data).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        # Request paths and health conversations should not enter server logs.
        pass


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()
