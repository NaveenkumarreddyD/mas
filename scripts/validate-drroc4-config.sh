#!/usr/bin/env bash
set -euo pipefail

fail=0

echo "Checking required files..."
required=(
  "mas/drroc4/ibm-mas-cluster-base.yaml"
  "mas/drroc4/ibm-operator-catalog.yaml"
  "mas/drroc4/redhat-cert-manager.yaml"
  "mas/drroc4/ibm-dro.yaml"
  "mas/drroc4/drgitopsapp/ibm-mas-instance-base.yaml"
  "mas/drroc4/drgitopsapp/ibm-sls.yaml"
  "mas/drroc4/drgitopsapp/ibm-mas-suite.yaml"
  "mas/drroc4/drgitopsapp/ibm-mas-suite-configs.yaml"
  "mas/drroc4/drgitopsapp/ibm-mas-workspaces.yaml"
  "mas/drroc4/drgitopsapp/ibm-mas-masapp-manage-install.yaml"
  "mas/drroc4/drgitopsapp/ibm-mas-masapp-configs.yaml"
  "bootstrap/drroc4/03-account-root-drroc4.yaml"
  "vault/drroc4/SECRETS-TO-LOAD.md"
)

for f in "${required[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "MISSING: $f"
    fail=1
  fi
done

echo "Checking no old instance names remain in active MAS config..."
if grep -RniE "drroc4-mas|drmasapp" mas/drroc4 bootstrap/drroc4 vault/drroc4 README.md 2>/dev/null; then
  echo "ERROR: found old instance name in active/config files"
  fail=1
fi

echo "Checking no active Db2U config files..."
if [[ -f "mas/drroc4/drgitopsapp/ibm-db2u.yaml" || -f "mas/drroc4/drgitopsapp/ibm-db2u-databases.yaml" ]]; then
  echo "ERROR: active Db2U files found"
  fail=1
fi

echo "Checking region id..."
if ! grep -R "id: lac1" mas/drroc4/ibm-mas-cluster-base.yaml mas/drroc4/drgitopsapp/ibm-mas-instance-base.yaml >/dev/null; then
  echo "ERROR: expected region id lac1 in base files"
  fail=1
fi

echo "Checking AWS references in active MAS config..."
if grep -RniE "arn:aws|secretsmanager|us-east-1|amazon|route53|cloudwatch|efs|\becr\b|rds|docdb|rosa|sts|iam" mas/drroc4 2>/dev/null; then
  echo "ERROR: AWS reference found in active MAS config"
  fail=1
fi

echo "Checking placeholders..."
if grep -Rni "CHANGE_ME" mas/drroc4 bootstrap/drroc4 openshift-gitops vault docs scripts README.md 2>/dev/null; then
  echo "INFO: CHANGE_ME placeholders still exist. Replace before production sync."
fi

if [[ "$fail" -ne 0 ]]; then
  echo "Validation failed."
  exit 1
fi

echo "Validation complete. Structural checks passed."
