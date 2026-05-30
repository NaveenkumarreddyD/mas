#!/usr/bin/env bash
set -euo pipefail

# Template only. Do not commit a filled-in version of this script.
# Export values in your shell/session, then run.
# This script loads the Vault keys referenced by the drroc4/drgitopsapp config.

: "${IBM_ENTITLEMENT_KEY:?missing IBM_ENTITLEMENT_KEY}"
: "${MAS_LICENSE_ID:?missing MAS_LICENSE_ID}"
: "${MAS_LICENSE_FILE:?missing MAS_LICENSE_FILE path to license.dat}"
: "${MAS_SUPERUSER_USERNAME:=superuser}"
: "${MAS_SUPERUSER_PASSWORD:?missing MAS_SUPERUSER_PASSWORD}"
: "${JDBC_USERNAME:?missing JDBC_USERNAME}"
: "${JDBC_PASSWORD:?missing JDBC_PASSWORD}"
: "${JDBC_URL:?missing JDBC_URL}"
: "${MANAGE_CRYPTO_KEY:?missing MANAGE_CRYPTO_KEY}"
: "${MANAGE_CRYPTOX_KEY:?missing MANAGE_CRYPTOX_KEY}"
: "${MAS_TLS_CRT:?missing MAS_TLS_CRT path}"
: "${MAS_TLS_KEY:?missing MAS_TLS_KEY path}"
: "${MAS_CA_CRT:?missing MAS_CA_CRT path}"

ENC="$(printf 'cp:%s' "${IBM_ENTITLEMENT_KEY}" | base64 | tr -d '\n')"
DOCKERCFG="$(printf '{"auths":{"cp.icr.io":{"auth":"%s"}}}' "${ENC}" | base64 | tr -d '\n')"
LICENSE_CONTENT="$(base64 "${MAS_LICENSE_FILE}" | tr -d '\n')"
TLS_CRT="$(cat "${MAS_TLS_CRT}")"
TLS_KEY="$(cat "${MAS_TLS_KEY}")"
CA_CRT="$(cat "${MAS_CA_CRT}")"

vault kv put secret/mas/drroc4/entitlement \
  image_pull_secret_b64="${DOCKERCFG}"

vault kv put secret/mas/drroc4/drgitopsapp/license \
  license_id="${MAS_LICENSE_ID}" \
  license_file="${LICENSE_CONTENT}"

vault kv put secret/mas/drroc4/drgitopsapp/superuser \
  username="${MAS_SUPERUSER_USERNAME}" \
  password="${MAS_SUPERUSER_PASSWORD}"

vault kv put secret/mas/drroc4/drgitopsapp/jdbc-system \
  username="${JDBC_USERNAME}" \
  password="${JDBC_PASSWORD}" \
  jdbc_url="${JDBC_URL}"

vault kv put secret/mas/drroc4/drgitopsapp/manage-crypto \
  cryptoKey="${MANAGE_CRYPTO_KEY}" \
  cryptoxKey="${MANAGE_CRYPTOX_KEY}"

vault kv put secret/mas/drroc4/drgitopsapp/certs \
  tls.crt="${TLS_CRT}" \
  tls.key="${TLS_KEY}" \
  ca.crt="${CA_CRT}"

if [[ -n "${SLS_REGISTRATION_KEY:-}" ]]; then
  vault kv put secret/mas/drroc4/drgitopsapp/sls registration_key="${SLS_REGISTRATION_KEY}"
fi

echo "Loaded Vault secrets for mas/drroc4/drgitopsapp."
