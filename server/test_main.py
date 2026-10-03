import io
import json
import unittest

from main import generate_reply


class FakeResponse(io.BytesIO):
    pass


class BackendTests(unittest.TestCase):
    def test_mobile_request_returns_reply_without_exposing_key(self):
        seen = {}

        def open_request(request, timeout):
            seen["request"] = request
            return FakeResponse(
                json.dumps(
                    {"candidates": [{"content": {"parts": [{"text": "Hello from Luna"}]}}]}
                ).encode()
            )

        status, data = generate_reply(
            {
                "systemInstruction": {"parts": [{"text": "Be warm and concise."}]},
                "contents": [{"role": "user", "parts": [{"text": "Hello"}]}],
                "generationConfig": {"temperature": 0.45, "maxOutputTokens": 1000},
            },
            api_key="test-secret",
            opener=open_request,
        )

        self.assertEqual(status, 200)
        self.assertEqual(data, {"text": "Hello from Luna"})
        self.assertEqual(seen["request"].get_header("X-goog-api-key"), "test-secret")
        self.assertNotIn("test-secret", str(data))
        sent = json.loads(seen["request"].data)
        self.assertIn("general information", sent["systemInstruction"]["parts"][0]["text"])

    def test_missing_key_and_invalid_conversation_are_rejected(self):
        valid = {"contents": [{"role": "user", "parts": [{"text": "Hello"}]}]}
        self.assertEqual(generate_reply(valid, api_key="")[0], 503)
        self.assertEqual(generate_reply({"contents": []}, api_key="test-secret")[0], 400)
        self.assertEqual(
            generate_reply({**valid, "systemInstruction": "bad"}, api_key="test-secret", opener=lambda *_args, **_kwargs: FakeResponse(b'{"candidates": []}'))[0],
            503,
        )


if __name__ == "__main__":
    unittest.main()
