# Run on Windows PowerShell after logging into the current MAS cluster.
# This exports current JDBC configs without decoding any Secret values.

cd $env:USERPROFILE\Documents

oc get jdbccfg -A
oc get jdbccfg drmasapp-jdbc-system -n mas-drmasapp-core -o yaml > drmasapp-jdbc-system.yaml
oc get jdbccfg drmasapp-jdbc-wsapp-drmaswks-manage -n mas-drmasapp-core -o yaml > drmasapp-jdbc-wsapp-drmaswks-manage.yaml

Select-String -Path .\drmasapp-jdbc-system.yaml -Pattern "name:|scope|db|jdbc|url|host|port|database|schema|username|secret|ssl|certificate" -CaseSensitive:$false
Select-String -Path .\drmasapp-jdbc-wsapp-drmaswks-manage.yaml -Pattern "name:|scope|db|jdbc|url|host|port|database|schema|username|secret|ssl|certificate" -CaseSensitive:$false
