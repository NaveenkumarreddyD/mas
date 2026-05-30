# Why Db2U files are omitted

IBM example config includes:

```text
ibm-db2u.yaml
ibm-db2u-databases.yaml
```

Those files install/manage Db2U inside OpenShift.

Your current cluster discovery showed:

```text
ManageWorkspace version 8.7.24
jdbc: system
JDBCCfg resources in mas-drgitopsapp-core
No current requirement to use Db2U
```

Therefore this template intentionally omits active Db2U files. The correct path is to model the existing external/system JDBC configuration in `ibm-mas-suite-configs.yaml`.

Before production, export:

```powershell
oc get jdbccfg drgitopsapp-jdbc-system -n mas-drgitopsapp-core -o yaml
oc get jdbccfg drgitopsapp-jdbc-wsapp-drgitopswks-manage -n mas-drgitopsapp-core -o yaml
```

Then map the confirmed fields into GitOps.
