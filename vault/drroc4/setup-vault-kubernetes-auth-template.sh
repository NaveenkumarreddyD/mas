#!/usr/bin/env bash
set -euo pipefail

# Run this from a machine with vault CLI and oc CLI access.
# Replace CHANGE_ME values first.

VAULT_K8S_AUTH_PATH="${VAULT_K8S_AUTH_PATH:-kubernetes}"
ARGOCD_NAMESPACE="${ARGOCD_NAMESPACE:-openshift-gitops}"
ARGOCD_REPO_SERVER_SA="${ARGOCD_REPO_SERVER_SA:-openshift-gitops-repo-server}"
VAULT_ROLE="${VAULT_ROLE:-mas-gitops-drroc4}"
VAULT_POLICY="${VAULT_POLICY:-mas-gitops-drroc4}"

oc get namespace "${ARGOCD_NAMESPACE}" >/dev/null

vault auth enable -path="${VAULT_K8S_AUTH_PATH}" kubernetes || true

# Use a reviewer JWT from the repo-server service account.
# Validate token projection behavior in your OpenShift version before production.
TOKEN_REVIEWER_JWT="$(oc create token "${ARGOCD_REPO_SERVER_SA}" -n "${ARGOCD_NAMESPACE}" --duration=24h)"
KUBE_HOST="$(oc whoami --show-server)"
KUBE_CA_CERT="$(mktemp)"
oc get configmap kube-root-ca.crt -n "${ARGOCD_NAMESPACE}" -o jsonpath='{.data.ca\.crt}' > "${KUBE_CA_CERT}"

vault write "auth/${VAULT_K8S_AUTH_PATH}/config" \
  token_reviewer_jwt="${TOKEN_REVIEWER_JWT}" \
  kubernetes_host="${KUBE_HOST}" \
  kubernetes_ca_cert=@"${KUBE_CA_CERT}"

vault policy write "${VAULT_POLICY}" vault/drroc4/vault-policy-mas-drroc4.hcl

vault write "auth/${VAULT_K8S_AUTH_PATH}/role/${VAULT_ROLE}" \
  bound_service_account_names="${ARGOCD_REPO_SERVER_SA}" \
  bound_service_account_namespaces="${ARGOCD_NAMESPACE}" \
  policies="${VAULT_POLICY}" \
  ttl="1h"

rm -f "${KUBE_CA_CERT}"

echo "Vault Kubernetes auth configured for role ${VAULT_ROLE}"
