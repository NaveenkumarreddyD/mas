# Naming decision for this package

This package intentionally uses a new MAS instance ID so it does not collide with the already-running MAS/Manage installation in the cluster.

## Selected names

- Account ID: `mas`
- Region ID: `lac1`
- Cluster ID: `drroc4`
- MAS instance ID: `drgitopsapp`
- Config repo path: `mas/drroc4/drgitopsapp/`

## Expected namespaces created by MAS

- MAS core: `mas-drgitopsapp-core`
- Manage: `mas-drgitopsapp-manage`

## Why not `drmasapp`?

Your current cluster already has MAS/Manage resources using the `drmasapp` naming pattern, for example `mas-drmasapp-core` and `mas-drmasapp-manage`. Reusing that name for a GitOps-based install could collide with the existing running application.

## If you want a different instance ID

Before first deployment, you can safely search/replace `drgitopsapp` with your preferred new instance ID. Do not change the instance ID after deployment unless you intend to create a new MAS instance.
