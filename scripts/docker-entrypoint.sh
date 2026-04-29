#!/bin/sh
set -eu

PORT="${MCPO_PORT:-8005}"

if [ -n "${MCPO_API_KEY:-}" ]; then
  exec mcpo --port "$PORT" --api-key "$MCPO_API_KEY" -- node dist/index.js
fi

exec mcpo --port "$PORT" -- node dist/index.js
