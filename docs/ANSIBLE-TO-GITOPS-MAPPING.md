# Ansible input to MAS GitOps mapping for drroc4 / drgitopsapp

This package was updated from the Ansible install inputs shared in the conversation. Real secrets were intentionally not included.

## Naming

Existing Ansible/current install used:

```text
MAS_INSTANCE_ID=drmasapp
MAS_WORKSPACE_ID=drmaswks
```

For the new GitOps install, this package uses a different instance/workspace to avoid collision/confusion with the existing running MAS install:

```text
MAS instance ID: drgitopsapp
Workspace ID: drgitopswks
Expected namespaces: mas-drgitopsapp-core, mas-drgitopsapp-manage
```

## YAML values mapped

```text
MAS_CHANNEL=8.11.x -> ibm-mas-suite.yaml / mas_channel
MAS_APP_CHANNEL=8.7.x -> ibm-mas-masapp-manage-install.yaml / manage_channel
MAS_APPWS_COMPONENTS=base=latest,utilities=latest,spatial=latest -> manage_components
MAS_ANNOTATIONS=mas.ibm.com/operationalMode=nonproduction -> mas_operational_mode: nonproduction
MONGODB_STORAGE_CLASS=isilon -> pending Mongo config confirmation
DRO_STORAGE_CLASS=isilon -> DRO/storage confirmation if needed
MAS_APP_SETTINGS_DB2_SCHEMA=maximo -> manage_db_schema
MAS_APP_SETTINGS_TABLESPACE=MAX_DATA -> manage_db_tablespace
MAS_APP_SETTINGS_INDEXSPACE=MAX_INDEX -> manage_db_index_tablespace
MAS_JDBC_URL=jdbc:oracle:thin:@//stl-dmasdb-21.lac1.biz:1521/DEMAS -> Vault jdbc-system/jdbc_url
MAS_JDBC_USER=maximo -> Vault jdbc-system/username
```

## Not included in Git

```text
IBM_ENTITLEMENT_KEY
MAS_JDBC_PASSWORD
SLS license file content
TLS private keys
MAS superuser password
Manage crypto keys
Vault tokens
GitLab tokens
```

## Db2U omitted

The Ansible input uses `CONFIGURE_EXTERNAL_DB=true` and an Oracle JDBC URL, so active `ibm-db2u.yaml` and `ibm-db2u-databases.yaml` are intentionally omitted.
