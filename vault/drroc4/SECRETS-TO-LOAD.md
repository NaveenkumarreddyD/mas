# Secrets to load into Vault for drroc4 / drgitopsapp

Use Vault KV v2 paths. Do not commit real secret values to Git.

## Required before MAS GitOps sync

### IBM entitlement pull secret
Path: `secret/data/mas/drroc4/entitlement`

Keys:
- `image_pull_secret_b64` — base64-encoded Docker config JSON for `cp.icr.io`

### MAS/SLS license
Path: `secret/data/mas/drroc4/drgitopsapp/license`

Keys:
- `license_file` — MAS license file content, base64 or plain text as expected by the chart/AVP rendering path
- `license_id` — optional license ID if your process tracks it

### External Oracle JDBC
Path: `secret/data/mas/drroc4/drgitopsapp/jdbc-system`

Keys:
- `username` — current Ansible value was `maximo`
- `password` — current Ansible value must be stored here, not in Git
- `jdbc_url` — current Ansible URL pattern: `jdbc:oracle:thin:@//stl-dmasdb-21.lac1.biz:1521/DEMAS`
- `ca.crt` — only required if Oracle TLS/CA is enabled

### SLS config
Path: `secret/data/mas/drroc4/drgitopsapp/sls`

Keys:
- `registration_key`
- `url`
- `ca.crt`

### SLS Mongo credentials
Path: `secret/data/mas/drroc4/drgitopsapp/sls-mongo`

Keys:
- `username`
- `password`
- `ca.crt`

### MAS Mongo config
Path: `secret/data/mas/drroc4/drgitopsapp/mongo`

Keys:
- `username`
- `password`
- `host`
- `ca.crt`

### MAS superuser
Path: `secret/data/mas/drroc4/drgitopsapp/superuser`

Keys:
- `username`
- `password`

### Manage crypto keys
Path: `secret/data/mas/drroc4/drgitopsapp/manage-crypto`

Keys:
- `cryptoKey`
- `cryptoxKey`

For a fresh test instance, generate new values. For adoption of an existing database, use the existing keys.

### Public route certificates, only if manual cert management is enabled
Path: `secret/data/mas/drroc4/drgitopsapp/certs`

Keys:
- `tls.crt`
- `tls.key`
- `ca.crt`

## OpenShift secrets outside Vault

Create these in `openshift-gitops` if required:
- GitLab repo secret for `mas-gitops-config`
- GitLab repo secret for internal IBM source repo mirror `ibm-mas-gitops`
- `argocd-vault-plugin-credentials`
