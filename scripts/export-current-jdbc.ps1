# Export JDBCCfg resources for review.
# Run in PowerShell after logging into the target OpenShift cluster.
# This file is a helper only. It does not export secret values by default, but review output before sharing.

cd $env:USERPROFILE\Documents

oc get jdbccfg -A

# For the new GitOps instance/workspace, expected names after deployment are:
#   namespace: mas-drgitopsapp-core
#   system JDBC: drgitopsapp-jdbc-system
#   wsapp JDBC, if created: drgitopsapp-jdbc-wsapp-drgitopswks-manage

# Uncomment after resources exist:
# oc get jdbccfg drgitopsapp-jdbc-system -n mas-drgitopsapp-core -o yaml > drgitopsapp-jdbc-system.yaml
# oc get jdbccfg drgitopsapp-jdbc-wsapp-drgitopswks-manage -n mas-drgitopsapp-core -o yaml > drgitopsapp-jdbc-wsapp-drgitopswks-manage.yaml
# Select-String -Path .\drgitopsapp-jdbc-system.yaml -Pattern "name:|scope|db|jdbc|url|host|port|database|schema|username|secret|ssl|certificate" -CaseSensitive:$false
