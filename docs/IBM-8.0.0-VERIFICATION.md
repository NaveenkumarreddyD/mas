# IBM MAS GitOps 8.0.0 verification notes

This package was rebuilt to align with IBM MAS GitOps 8.0.0 example/config conventions:

- Config repo path: `mas/drroc4/drgitopsapp` = `<ACCOUNT_ID>/<CLUSTER_ID>/<INSTANCE_ID>`.
- SLS file uses `ibm_sls.sls_channel`, `sls_entitlement_file`, `ibm_entitlement_key`, and `sls_install_plan`.
- MAS Suite file uses `ibm_mas_suite.domain` instead of `mas_domain`.
- Workspace file uses `mas_workspace_id` and `mas_workspace_name`.
- Manage install file uses `ibm_suite_app_manage_install`, matching the IBM chart convention.
- Suite configs use the IBM `ibm_mas_suite_configs` list-of-configs pattern and `ibm-jdbc-config` for external Oracle JDBC.
- Manage app config uses direct chart values (`mas_app_id`, `mas_app_namespace`, `mas_app_ws_kind`, `mas_workspace_id`, `mas_appws_spec`) because the app-config chart does not use a top-level wrapper.

Caveats:

- IBM MAS GitOps 8.0.0 officially documents AWS Secrets Manager. Vault/AVP is a technical on-prem pattern and must be validated with IBM/support before production.
- Mongo/SLS exact values must be filled from your selected provider or generated SLS/Mongo outputs before first sync.
- `run_sync_hooks` is set to `false` for SLS/DRO/cert-manager/Manage install to avoid AWS Secrets Manager hooks in an on-prem Vault design. Confirm with IBM before production.
