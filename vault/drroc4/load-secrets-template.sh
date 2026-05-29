#!/usr/bin/env bash
set -euo pipefail

# Template only. Do not commit a filled-in version of this script.
# Export values in your shell/session, then run.
#
# Required examples:
#   export IBM_ENTITLEMENT_KEY='...'
#   export MAS_SUPERUSER_PASSWORD='...'
#   export JDBC_USERNAME='...'
#   export JDBC_PASSWORD='...'
#   export JDBC_URL='...'
#   export MANAGE_CRYPTO_KEY='...'
#   export MANAGE_CRYPTOX_KEY='...'

: "${IBM_ENTITLEMENT_KEY:?missing IBM_ENTITLEMENT_KEY}"
: "${MAS_SUPERUSER_PASSWORD:?missing MAS_SUPERUSER_PASSWORD}"
: "${JDBC_USERNAME:?missing JDBC_USERNAME}"
: "${JDBC_PASSWORD:?missing JDBC_PASSWORD}"
: "${JDBC_URL:?missing JDBC_URL}"
: "${MANAGE_CRYPTO_KEY:?missing MANAGE_CRYPTO_KEY}"
: "${MANAGE_CRYPTOX_KEY:?missing MANAGE_CRYPTOX_KEY}"

ENC="$(printf 'cp:%s' "${IBM_ENTITLEMENT_KEY}" | base64 | tr -d '\n')"
DOCKERCFG="$(printf '{"auths":{"cp.icr.io":{"auth":"%s"}}}' "${ENC}" | base64 | tr -d '\n')"

vault kv put secret/mas/drroc4/entitlement \
  image_pull_secret_b64="${DOCKERCFG}"

vault kv put secret/mas/drroc4/drmasapp/superuser \
  username="superuser" \
  password="${MAS_SUPERUSER_PASSWORD}"

vault kv put secret/mas/drroc4/drmasapp/jdbc-system \
  username="${JDBC_USERNAME}" \
  password="${JDBC_PASSWORD}" \
  jdbc_url="${JDBC_URL}" \
  ca.crt="${JDBC_CA_CRT:-}"

vault kv put secret/mas/drroc4/drmasapp/manage-crypto \
  cryptoKey="${MANAGE_CRYPTO_KEY}" \
  cryptoxKey="${MANAGE_CRYPTOX_KEY}"

echo "Loaded starter secrets. License, TLS certs, and SLS registration still need to be loaded separately."
