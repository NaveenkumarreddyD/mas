# MAS secrets checklist for drroc4/drgitopsapp

| Secret | Vault path | Required before sync | Notes |
|---|---|---:|---|
| IBM entitlement | `secret/data/mas/drroc4/entitlement` | Yes | `image_pull_secret_b64` |
| MAS license | `secret/data/mas/drroc4/drgitopsapp/license` | Yes | Confirm expected format |
| MAS superuser | `secret/data/mas/drroc4/drgitopsapp/superuser` | Yes | username/password |
| SLS registration | `secret/data/mas/drroc4/drgitopsapp/sls` | Maybe | depends on SLS flow |
| Route TLS | `secret/data/mas/drroc4/drgitopsapp/certs` | Yes if using custom certs | tls.crt/tls.key/ca.crt |
| JDBC system | `secret/data/mas/drroc4/drgitopsapp/jdbc-system` | Yes | Must match actual DB |
| Manage crypto | `secret/data/mas/drroc4/drgitopsapp/manage-crypto` | Yes | Must match existing DB if reusing |
| Mongo | TBD | Maybe | export current MongoCfg first |
| SMTP/LDAP/IDP | TBD | Maybe | only if configured in MAS |
