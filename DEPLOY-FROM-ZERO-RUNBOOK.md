# MAS on GitOps + Vault — From-Zero Execution Run Sheet

A linear, follow-top-to-bottom procedure to bring up a MAS instance (Core + Manage) on a fresh cluster via ArgoCD + AVP + HashiCorp Vault. Every step has a **✓ verify** gate — do not proceed until it passes. Worked example uses `account=mas`, `cluster=drroc4`, `instance=drgitopsapp`, `workspace=drgitopswks`; substitute your own.

Two parts: **Phase 0–5 = hub setup (once per management cluster)**, **Phase 6–16 = per instance (repeat per cluster/instance)**. If your hub is already bootstrapped, jump to Phase 6.

Legend: `▶` action · `✓` verify gate · `✗` if it fails.

---

## Inputs checklist (gather before you start)

The only three things nobody can generate for you (same as Ansible):

| Input | Example var | Source |
|---|---|---|
| IBM entitlement key | `IBM_ENTITLEMENT_KEY` | IBM Container Library |
| MAS license file | `MAS_LICENSE_FILE=./license.dat` | IBM / Rational License Key Center |
| External DB creds + CA | `JDBC_USERNAME/PASSWORD/URL`, `JDBC_CA_CRT=./oracle-ca.pem` | your DBA |

Everything else (superuser pw, Manage crypto keys, sls-mongo creds) is generated-once by the loader; Mongo creds/CA are derived from the in-cluster Mongo; SLS registration is harvested after SLS comes up.

Plus: `oc` logged in as cluster-admin, the three repos cloned locally, and the per-cluster `envs/<cluster>.env` filled (no `CHANGE_ME` left — see Phase 6).

---

## PHASE 0 — Vault server reachable

▶ Confirm Vault is up and you have an admin/root token.
```bash
export VAULT_TOKEN='<root-or-admin>'
oc exec -n vault vault-0 -- sh -c 'export VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN='"$VAULT_TOKEN"'; vault status'
```
✓ `Sealed false`, all HA pods joined.
✗ Unsealed? Unseal each pod. No Vault yet? Deploy it via the platform app-of-apps (Phase 2) first, then init/unseal.

---

## PHASE 1 — ArgoCD hub: git trust + repo creds

```bash
oc apply -f platform-gitops/bootstrap/00-gitlab-ca-configmap.yaml
oc apply -f platform-gitops/bootstrap/01-argocd-cluster-admin-rbac.yaml
oc apply -f <your filled repo-creds secret>      # from repo-creds/gitlab-group-repo-creds.example.yaml
oc rollout restart deploy/openshift-gitops-repo-server -n openshift-gitops
```
✓ `oc get pods -n openshift-gitops | grep repo-server` → `1/1 Running`.
✓ In ArgoCD, the config repo shows **Successful** under Settings → Repositories.
✗ Repo "Failed": CA configmap not mounted or creds wrong — re-check the secret and that the CA bundle is referenced by the repo-server.

---

## PHASE 2 — Platform app-of-apps + Vault

▶ Fix bootstrap values first in `platform-gitops/charts/app-of-apps/values.yaml`:
- `vault.host` → real Vault route (was `CHANGE_ME`).
- `generator.repo_url` → your **actual** config repo (`…/mas-config-repo.git`). Mismatch here = account-root globs an empty repo.

```bash
oc apply -f platform-gitops/bootstrap/02-platform-app-of-apps.yaml
# sync platform-app-of-apps, then the hashicorp-vault-server app
```
✓ `oc get application -n openshift-gitops | grep -E 'platform|vault'` all `Synced/Healthy`.
▶ If Vault was just created: `oc exec -n vault vault-0 -- vault operator init` (save keys+root **securely**), unseal all pods, join HA.

---

## PHASE 3 — Vault k8s auth for AVP (DURABLE)

Use the durable script — never the 24h-token version (that 403s every sync a day later).
```bash
cp <kit>/vault-auth/setup-vault-auth.sh platform-gitops/vault-auth/setup-vault-auth.sh
export VAULT_TOKEN='<root-or-admin>'
./platform-gitops/vault-auth/setup-vault-auth.sh
```
✓ Script prints the detected repo-server SA, writes policy `mas-gitops`, role `mas-gitops`, and `auth/kubernetes/config` **without** a `token_reviewer_jwt`.
✓ `oc get clusterrolebinding -o wide | grep auth-delegator` shows the repo-server SA.

---

## PHASE 4 — AVP sidecar + CMP + credentials

```bash
oc apply -f platform-gitops/argocd/argocd-vault-plugin-credentials.example.yaml   # filled in
oc apply -f platform-gitops/argocd/cmp-plugin-configmap.yaml
oc patch argocd openshift-gitops -n openshift-gitops --type merge \
  --patch-file platform-gitops/argocd/argocd-cr-avp-sidecar-patch.yaml
oc rollout restart deploy/openshift-gitops-repo-server -n openshift-gitops
```
✓ `oc get pods -n openshift-gitops` → repo-server pod has the extra AVP container `READY 2/2` (or 3/3).
✓ `./platform-gitops/vault-auth/test-avp.sh` resolves a test placeholder.
✗ AVP "Must provide supported Vault Type" → the sidecar env (AVP_TYPE/AUTH_TYPE/K8S_ROLE/VAULT_ADDR) isn't set; re-check the sidecar patch.
✗ AVP 403 "permission denied" → re-run Phase 3 (durable config). With the durable config it won't recur.

---

## PHASE 5 — Account root

```bash
# account-root comes from the platform app-of-apps (30-ibm-mas-account-root)
oc get application ibm-mas-account-root -n openshift-gitops
```
✓ `ibm-mas-account-root` exists and is `Synced` (it's an ApplicationSet generator; child apps appear as you add cluster/instance config).

**Hub is done. Phases 6–16 repeat per instance.**

---

## PHASE 6 — Per-instance config: env → render → secrets

▶ Fill `envs/<cluster>.env` completely. Required before the Suite renders:

| Field | Note |
|---|---|
| `ACCOUNT_ID / CLUSTER_ID / INSTANCE_ID / WORKSPACE_ID` | identity |
| `API_HOST` | cluster API host |
| `MAS_DOMAIN` | the MAS domain for routes — **must be real before Suite** |
| `MAS_CHANNEL / MAS_APP_CHANNEL / SLS_CHANNEL / MAS_EDITION` | versions |
| `MAS_CATALOG_VERSION` | pin (e.g. `v9-240625-amd64`) — must match what's on the cluster |
| `STORAGE_CLASS / RWX_STORAGE_CLASS` | e.g. `isilon` |
| `SLS_MONGO_HOST` | if SLS shares `mas-mongo-ce`: `mas-mongo-ce-svc.mongoce.svc.cluster.local` |
| `DRO_*` | only matters if you sync the GitOps DRO app (skip on coexistence) |

▶ Render, then load secrets (auto-generates/derives the rest):
```bash
cd mas-config-repo
python3 render.py <cluster>
export VAULT_TOKEN='<vault admin>'
export IBM_ENTITLEMENT_KEY=... MAS_LICENSE_FILE=./license.dat \
       JDBC_USERNAME=... JDBC_PASSWORD=... JDBC_URL=... JDBC_CA_CRT=./oracle-ca.pem
AUTO_MONGO=1 ./vault/<cluster>-load-secrets.sh
```
✓ Loader prints writes for entitlement, license, superuser, manage-crypto, jdbc, mongo, sls-mongo.
✗ `mas-mongo-ce-admin-password` not found → set `MONGO_CE_NS` or export `MONGO_*` manually.

▶ Commit & push (ArgoCD only reads committed git state):
```bash
git add -A && git commit -m "config: <cluster>/<instance>" && git push
```

---

## PHASE 7 — Preflight Vault

```bash
./scripts/preflight-vault.sh envs/<cluster>.env
```
✓ All `PASS` except `sls` which **WARN**s (expected — harvested in Phase 11).
✗ Any `FAIL` (missing key / bad base64 / escaped CA) → fix with the loader or `scripts/update-vault-ca.sh`, re-run. Do not sync with FAILs — you'll just get ComparisonErrors.

---

## PHASE 8 — Register cluster + open the instance apps

▶ Ensure the target cluster is registered in ArgoCD (cluster Secret in `openshift-gitops`). Then refresh account-root so the ApplicationSet generates this instance's child apps:
```bash
oc annotate application ibm-mas-account-root -n openshift-gitops argocd.argoproj.io/refresh=hard --overwrite
oc get applications -n openshift-gitops -o json | jq -r \
  --arg i "<instance>" '.items[]|select(.metadata.name|test($i))|.metadata.name' | sort
```
✓ You see the child apps: `<instance>-sls`, `<instance>-mongo-system`, `<instance>-sls-system`, `<instance>-jdbc-system`, `<instance>-suite`, `<instance>-workspace`, `<instance>-manage`, etc.

---

## PHASE 9 — Coexistence guard (cluster already runs an Ansible MAS)

The shared cluster singletons are Ansible-owned — **do not let GitOps re-own or prune them**:
- `000-ibm-operator-catalog` — leave to Ansible; if GitOps manages it, pin **exactly** your catalog version.
- `030-ibm-dro` (+ `032-cleanup`) — disable the GitOps DRO app.
- `010-redhat-cert-manager` — leave to Ansible.

✓ Keep `prune: false` / autoSync off on anything touching these. Confirm GitOps is scoped to the **instance** apps only.

---

## PHASE 10 — SLS (deploy → Ready)

```bash
# sync <instance>-sls
oc get application <instance>-sls.<cluster> -n openshift-gitops \
  -o jsonpath='{.status.sync.status}  {.status.health.status}{"\n"}'
oc get po -n mas-<instance>-sls
```
✓ `sls-api-licensing` pod `Running`, `LicenseService` reports `Ready=True`.
✗ ComparisonError "missing entitlement" → Phase 7 didn't pass for entitlement.
✗ "No Features" later → license not bound to this SLS's Server ID (see RUNBOOK §6 SLS decision; consider centralized SLS).

---

## PHASE 11 — Harvest SLS registration → render sls-system

```bash
export VAULT_TOKEN='<vault admin>'
./scripts/harvest-sls-registration.sh envs/<cluster>.env
oc get pods -n openshift-gitops | grep repo-server          # WAIT for 1/1 Running
oc annotate application <instance>-sls-system.<cluster> -n openshift-gitops argocd.argoproj.io/refresh=hard --overwrite
```
✓ `vault kv get secret/mas/<cluster>/<instance>/sls` shows `registration_key`, `url`, PEM `ca.crt`.
✓ `<instance>-sls-system` leaves `ComparisonError`; `oc get slscfg -n mas-<instance>-core` shows the SlsCfg.
✗ App still stale after harvest → you refreshed before repo-server finished restarting; re-annotate once it's `1/1 Running` (Vault changes don't invalidate ArgoCD's git-keyed cache, so the restart is mandatory).

---

## PHASE 12 — Mongo config verifies

```bash
oc get mongocfg <instance>-mongo-system -n mas-<instance>-core
oc get mongocfg <instance>-mongo-system -n mas-<instance>-core -o jsonpath='{.metadata.labels}{"\n"}'
oc describe mongocfg <instance>-mongo-system -n mas-<instance>-core | sed -n '/Events/,$p'
```
✓ `STATUS`/`VERSION` columns populate (operator verified the Mongo connection).
✗ **Empty status for many minutes/hours** → the operator isn't watching it. Check the labels show `mas.ibm.com/instanceId: <instance>` (the watch predicate filters on it). Missing/wrong label = never reconciled; fix the label in the rendered MongoCfg (and the template) and re-sync.
✗ Events show a connection error → CA/creds/host problem; re-check `mongo#ca.crt` is real PEM and creds match `mas-mongo-ce`.

---

## PHASE 13 — JDBC config

```bash
oc get jdbccfg -n mas-<instance>-core
```
✓ JdbcCfg present and verified (operator connected to the external DB).
✗ Verify the `jdbc-system` Vault secret: `username/password/jdbc_url` plain, `ca.crt` real PEM.

---

## PHASE 14 — Suite (MAS Core)

Configs (`MongoCfg`, `SlsCfg`, `JdbcCfg`) must be present/verified first — they verify in the Suite's reconcile context, so both Mongo and SLS configs green is the gate.
```bash
# sync <instance>-suite
oc get suite -n mas-<instance>-core
oc get po -n mas-<instance>-core
```
✓ `Suite` reconciles; core pods appear (`coreidp`, `coreapi`, etc.) and go `Running`.
✗ Suite stuck `Reconciling` → almost always a config not verified (re-check Phase 11/12/13) or the catalog/entitlement.

---

## PHASE 15 — Workspace

```bash
# sync <instance>-workspace
oc get workspace -n mas-<instance>-core
```
✓ Workspace `<workspace>` Ready.

---

## PHASE 16 — Manage (install → DB build → Ready)

```bash
# sync <instance>-manage (app install), then <instance>-manage-config
oc get manageworkspace -n mas-<instance>-manage
oc get po -n mas-<instance>-manage
```
✓ Manage build/init jobs complete; `manageworkspace` Ready; Manage pods `Running`.
✗ DB init fails → JDBC config / schema / tablespace mismatch (`DB_SCHEMA`, `DB_TABLESPACE`, `DB_INDEXSPACE`).

▶ Final check:
```bash
oc get route -n mas-<instance>-core; oc get route -n mas-<instance>-manage
```
✓ MAS admin and Manage URLs resolve; log in with the generated superuser (read it from Vault: `vault kv get -field=password secret/mas/<cluster>/<instance>/superuser`).

---

## Per-cluster repeat (the short version)

Once the hub (Phases 0–5) exists, a new cluster is just:
```bash
# 1. edit envs/<cluster>.env   (identity, API_HOST, MAS_DOMAIN, storage, channels)
# 2. provide the 3 external inputs + VAULT_TOKEN, then:
AUTO_MONGO=1 ./deploy-cluster.sh <cluster> --load
git add -A && git commit -m "config <cluster>" && git push
# 3. sync SLS → harvest (Phase 11) → confirm configs (12/13) → sync Suite/Workspace/Manage
```
The single manual gate is the SLS harvest after LicenseService is Ready. **Centralized SLS removes even that** — load the shared SLS's `registration_key/url/ca` once and skip Phases 10–11.

---

## Quick failure map

| Symptom | Phase | Fix |
|---|---|---|
| AVP 403 after ~1 day | 3 | durable `setup-vault-auth.sh` |
| ComparisonError "missing Vault value" | 7 | preflight; `kv patch` the missing key |
| `illegal base64 … byte 36` | 6 | entitlement must be base64 dockerconfigjson |
| CA `InvalidByte(..,92)` | 6 | real PEM via `update-vault-ca.sh`, not escaped `\n` |
| App stale after Vault change | 11 | `rollout restart` repo-server, then hard-refresh |
| MongoCfg empty status forever | 12 | missing `mas.ibm.com/instanceId` label → operator not watching |
| SLS "No Features" | 10 | license not bound to this SLS Server ID → centralized SLS |
| Suite stuck Reconciling | 14 | a config (mongo/sls/jdbc) not verified yet |

Triage all instance apps at once:
```bash
oc get applications -n openshift-gitops -o json | jq -r \
  --arg i "<instance>" '.items[]|select(.metadata.name|test($i))
  |"\(.metadata.name)\t\(.status.sync.status)\t\(.status.health.status)"' | column -t
```
