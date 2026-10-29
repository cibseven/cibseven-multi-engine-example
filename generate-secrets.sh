#!/usr/bin/env bash
# Generates new JWT secrets for both engines in .env
# (155 alphanumeric characters – the same as CIB seven Run generates itself on first start).
set -euo pipefail
cd "$(dirname "$0")"

gen() { LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 155; }

image=$(grep -E '^CIBSEVEN_IMAGE=' .env 2>/dev/null | cut -d= -f2- || true)

cat > .env <<EOF
# Image: Community Edition 2.2.0 (CIB seven Run).
# Enterprise: artifacts.cibseven.org/docker-ee/cibseven:run-2.2.0-ee (run docker login artifacts.cibseven.org first)
CIBSEVEN_IMAGE=${image:-cibseven/cibseven:run-2.2.0}

# JWT secrets, one per engine (at least 155 characters, Base64-decodable).
ENGINE_A_JWT_SECRET=$(gen)
ENGINE_B_JWT_SECRET=$(gen)
EOF

echo ".env rewritten. Next: docker compose up -d --force-recreate --wait"
