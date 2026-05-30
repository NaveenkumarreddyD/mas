#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
fail=0

check_file() { [[ -f "$ROOT/$1" ]] || { echo "MISSING: $1"; fail=1; }; }

check_file "mas/drroc4/ibm-mas-cluster-base.yaml"
check_file "mas/drroc4/ibm-operator-catalog.yaml"
check_file "mas/drroc4/redhat-cert-manager.yaml"
check_file "mas/drroc4/ibm-dro.yaml"
check_file "mas/drroc4/drgitopsapp/ibm-mas-instance-base.yaml"
check_file "mas/drroc4/drgitopsapp/ibm-sls.yaml"
check_file "mas/drroc4/drgitopsapp/ibm-mas-suite.yaml"
check_file "mas/drroc4/drgitopsapp/ibm-mas-suite-configs.yaml"
check_file "mas/drroc4/drgitopsapp/ibm-mas-workspaces.yaml"
check_file "mas/drroc4/drgitopsapp/ibm-mas-masapp-manage-install.yaml"
check_file "mas/drroc4/drgitopsapp/ibm-mas-masapp-configs.yaml"

# Detect old/wrong generated keys from earlier draft package, limiting checks to files where they would be wrong.
if grep -RniE "ibm_mas_masapp_manage_install|mas_domain:" "$ROOT/mas/drroc4/drgitopsapp"; then
  echo "ERROR: Found old/non-IBM-8.0.0 key names above."
  fail=1
fi
if grep -RniE "^[[:space:]]{2,}workspace_id:|^[[:space:]]{2,}workspace_name:" "$ROOT/mas/drroc4/drgitopsapp"; then
  echo "ERROR: Found old workspace_id/workspace_name keys above; use mas_workspace_id/mas_workspace_name."
  fail=1
fi
if grep -RniE "^[[:space:]]{2,}channel:" "$ROOT/mas/drroc4/drgitopsapp/ibm-sls.yaml"; then
  echo "ERROR: Found old ibm_sls.channel key above; use sls_channel."
  fail=1
fi

grep -q 'sls_channel:' "$ROOT/mas/drroc4/drgitopsapp/ibm-sls.yaml" || { echo "ERROR: missing sls_channel"; fail=1; }
grep -q 'domain:' "$ROOT/mas/drroc4/drgitopsapp/ibm-mas-suite.yaml" || { echo "ERROR: missing ibm_mas_suite.domain"; fail=1; }
grep -q 'mas_workspace_id:' "$ROOT/mas/drroc4/drgitopsapp/ibm-mas-workspaces.yaml" || { echo "ERROR: missing mas_workspace_id"; fail=1; }
grep -q 'ibm_suite_app_manage_install:' "$ROOT/mas/drroc4/drgitopsapp/ibm-mas-masapp-manage-install.yaml" || { echo "ERROR: missing ibm_suite_app_manage_install"; fail=1; }
grep -q 'mas_appws_spec:' "$ROOT/mas/drroc4/drgitopsapp/ibm-mas-masapp-configs.yaml" || { echo "ERROR: missing mas_appws_spec"; fail=1; }

if command -v python3 >/dev/null 2>&1; then
  python3 - "$ROOT" <<'PYVALID'
import sys, pathlib, yaml
root=pathlib.Path(sys.argv[1])
for p in root.glob('**/*.yaml'):
    with p.open() as f:
        try:
            yaml.safe_load(f)
        except Exception as e:
            print(f"YAML ERROR: {p}: {e}")
            raise SystemExit(1)
print("YAML parse check: OK")
PYVALID
fi

if grep -Rni "CHANGE_ME" "$ROOT"; then
  echo "INFO: CHANGE_ME placeholders remain and must be replaced before deployment."
fi

exit "$fail"
