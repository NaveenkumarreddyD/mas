# Run on Windows PowerShell after logging into the current MAS cluster.
# This exports current JDBC configs without decoding any Secret values.

cd $env:USERPROFILE\Documents

oc get jdbccfg -A
oc get jdbccfg drgitopsapp-jdbc-system -n mas-drgitopsapp-core -o yaml > drgitopsapp-jdbc-system.yaml
oc get jdbccfg drgitopsapp-jdbc-wsapp-drmaswks-manage -n mas-drgitopsapp-core -o yaml > drgitopsapp-jdbc-wsapp-drmaswks-manage.yaml

Select-String -Path .\drgitopsapp-jdbc-system.yaml -Pattern "name:|scope|db|jdbc|url|host|port|database|schema|username|secret|ssl|certificate" -CaseSensitive:$false
Select-String -Path .\drgitopsapp-jdbc-wsapp-drmaswks-manage.yaml -Pattern "name:|scope|db|jdbc|url|host|port|database|schema|username|secret|ssl|certificate" -CaseSensitive:$false
