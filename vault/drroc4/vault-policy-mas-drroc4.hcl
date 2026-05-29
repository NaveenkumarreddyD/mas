# Read-only policy for ArgoCD Vault Plugin to render MAS GitOps manifests.
# KV v2 uses both metadata and data paths.

path "secret/data/mas/drroc4/*" {
  capabilities = ["read"]
}

path "secret/metadata/mas/drroc4/*" {
  capabilities = ["read", "list"]
}
