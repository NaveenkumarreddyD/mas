# MAS GitOps Config - drroc4 / drgitopsapp / Vault Pattern

This repository content is for the `drroc4` branch of `mas-gitops-config`.

## Target naming

```text
account id:       mas
region id:        lac1
cluster id:       drroc4
MAS instance id:  drgitopsapp
expected core ns: mas-drgitopsapp-core
expected manage:  mas-drgitopsapp-manage
```

## Active IBM MAS GitOps config tree

```text
mas/drroc4/
├── ibm-mas-cluster-base.yaml
├── ibm-operator-catalog.yaml
├── redhat-cert-manager.yaml
├── ibm-dro.yaml
└── drgitopsapp/
    ├── ibm-mas-instance-base.yaml
    ├── ibm-sls.yaml
    ├── ibm-mas-suite.yaml
    ├── ibm-mas-suite-configs.yaml
    ├── ibm-mas-workspaces.yaml
    ├── ibm-mas-masapp-manage-install.yaml
    └── ibm-mas-masapp-configs.yaml
```

## Important caveat

IBM MAS GitOps 8.0.0 documentation says AWS Secrets Manager is the currently supported secrets backend. This package uses HashiCorp Vault style AVP placeholders for a fully on-prem pattern. Treat Vault as a customer-owned technical implementation and validate support with IBM before production.

## Do not commit real secrets

This repo contains only placeholders and examples. Do not commit:

- Vault root token
- Vault unseal keys
- GitLab deploy tokens
- IBM entitlement key
- MAS license contents
- TLS private keys
- DB passwords
- Manage crypto keys
