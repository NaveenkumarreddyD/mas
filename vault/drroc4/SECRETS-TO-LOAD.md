# Vault secrets required for MAS + Manage drroc4/drmasapp

Use Vault KV v2 with mount path `secret`.

The MAS GitOps config uses these placeholder paths:

## 1. IBM entitlement image pull secret

Path:

```text
secret/data/mas/drroc4/entitlement
```

Keys:

```json
{
  "image_pull_secret_b64": "CHANGE_ME_BASE64_DOCKERCONFIGJSON"
}
```

The value must be base64 of Docker config JSON, not the raw entitlement token.

## 2. MAS license file for SLS

Path:

```text
secret/data/mas/drroc4/drmasapp/license
```

Keys:

```json
{
  "license_file": "CHANGE_ME_BASE64_OR_EXPECTED_LICENSE_CONTENT"
}
```

Confirm whether the IBM chart expects base64 file content or plain value for your exact GitOps 8.0.0 chart.

## 3. MAS superuser

Path:

```text
secret/data/mas/drroc4/drmasapp/superuser
```

Keys:

```json
{
  "username": "CHANGE_ME",
  "password": "CHANGE_ME"
}
```

## 4. SLS registration

Path:

```text
secret/data/mas/drroc4/drmasapp/sls
```

Keys:

```json
{
  "registration_key": "CHANGE_ME"
}
```

## 5. MAS route certificates

Path:

```text
secret/data/mas/drroc4/drmasapp/certs
```

Keys:

```json
{
  "tls.crt": "CHANGE_ME_CERT_PEM",
  "tls.key": "CHANGE_ME_PRIVATE_KEY_PEM",
  "ca.crt": "CHANGE_ME_CA_BUNDLE_PEM"
}
```

## 6. JDBC system config

Path:

```text
secret/data/mas/drroc4/drmasapp/jdbc-system
```

Keys:

```json
{
  "username": "CHANGE_ME_DB_USER",
  "password": "CHANGE_ME_DB_PASSWORD",
  "jdbc_url": "CHANGE_ME_JDBC_URL",
  "ca.crt": "CHANGE_ME_DB_CA_CERT"
}
```

This must be finalized from the existing `JDBCCfg` export.

## 7. Optional wsapp JDBC config

Only if the existing/current JDBCCfg confirms Manage should use wsapp-level JDBC:

```text
secret/data/mas/drroc4/drmasapp/jdbc-wsapp-drmaswks-manage
```

Keys:

```json
{
  "username": "CHANGE_ME_DB_USER",
  "password": "CHANGE_ME_DB_PASSWORD",
  "jdbc_url": "CHANGE_ME_JDBC_URL",
  "ca.crt": "CHANGE_ME_DB_CA_CERT"
}
```

## 8. Manage crypto keys

Path:

```text
secret/data/mas/drroc4/drmasapp/manage-crypto
```

Keys:

```json
{
  "cryptoKey": "CHANGE_ME",
  "cryptoxKey": "CHANGE_ME"
}
```

For migration/adoption, these must match the existing Manage database encryption keys. Do not generate new keys if you are connecting to an existing database.

## 9. Optional Mongo/SLS/SMTP/LDAP secrets

Add only after current `MongoCfg`, `SlsCfg`, SMTP, LDAP/IdP requirements are confirmed.
