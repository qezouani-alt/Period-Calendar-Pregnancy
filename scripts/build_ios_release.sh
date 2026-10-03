#!/usr/bin/env bash
set -euo pipefail

AI_BACKEND_URL="${AI_BACKEND_URL:-https://luna-ai.elqznysf.workers.dev/ai}"

if [[ ! "$AI_BACKEND_URL" =~ ^https://[^[:space:]]+/ai$ ]]; then
  echo 'Set AI_BACKEND_URL to the deployed HTTPS /ai endpoint before building.' >&2
  exit 1
fi

flutter build ios --release --dart-define="AI_BACKEND_URL=$AI_BACKEND_URL" "$@"
