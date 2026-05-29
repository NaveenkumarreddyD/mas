# Deployment steps - drroc4 MAS GitOps with Vault

## Phase 0 - Confirm prerequisites

1. OpenShift GitOps is already installed in `openshift-gitops`.
2. Internal IBM source mirror exists:
   `https://CHANGE_ME_GITLAB/mas-gitops/ibm-mas-gitops.git`
3. IBM source mirror has tag/branch `8.0.0`.
4. Config repo branch is `drroc4`.
5. Vault is installed and unsealed.
6. AVP is configured in OpenShift GitOps.
7. Real secrets are loaded into Vault.
8. All `CHANGE_ME` placeholders are replaced.

## Phase 1 - Commit config

Copy this content to your `mas-gitops-config` repo on branch `drroc4`.

```bash
git checkout drroc4
git add .
git commit -m "Add drroc4 drmasapp MAS GitOps config"
git push origin drroc4
```

## Phase 2 - Configure repo access

Create real versions of the example repo secrets and apply them manually:

```bash
oc apply -f bootstrap/drroc4/01-gitlab-config-repo-secret.yaml
oc apply -f bootstrap/drroc4/02-ibm-source-repo-secret.yaml
```

Do not commit real token files.

## Phase 3 - Configure AVP

Apply the non-secret AVP config:

```bash
oc apply -f openshift-gitops/avp/02-cmp-plugin-configmap.yaml
oc apply -f openshift-gitops/avp/03-tokenreview-rbac.yaml
```

Create and apply the real AVP credentials secret:

```bash
oc apply -f openshift-gitops/avp/01-argocd-vault-plugin-credentials.yaml
```

Patch the ArgoCD CR using the fragment in:

```text
openshift-gitops/avp/04-argocd-cr-patch-fragment.yaml
```

Validate the repo-server rollout.

## Phase 4 - Configure Vault

Use:

```text
vault/drroc4/vault-policy-mas-drroc4.hcl
vault/drroc4/setup-vault-kubernetes-auth-template.sh
vault/drroc4/SECRETS-TO-LOAD.md
```

Load all required secrets.

## Phase 5 - Apply MAS GitOps bootstrap

```bash
oc apply -f bootstrap/drroc4/00-mas-appproject.yaml
oc apply -f bootstrap/drroc4/03-account-root-drroc4.yaml
```

## Phase 6 - Watch ArgoCD

```bash
oc get applications -n openshift-gitops
oc get applicationsets -n openshift-gitops
```

## Phase 7 - Validate MAS

Expected namespaces after sync:

```text
mas-drmasapp-core
mas-drmasapp-manage
```

Commands:

```bash
oc get suite -A
oc get workspace -A
oc get manageworkspace -A
oc get pods -n mas-drmasapp-core
oc get pods -n mas-drmasapp-manage
oc get route -A | grep -i drmasapp
```

## Do not deploy yet if

- Any `CHANGE_ME` remains in active YAML.
- Vault placeholders cannot be resolved by AVP.
- Existing JDBCCfg has not been exported and mapped.
- Manage crypto keys are unknown for an existing database.
- MAS/Manage/SLS/catalog channels are not confirmed.
