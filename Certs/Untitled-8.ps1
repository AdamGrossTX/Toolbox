$Good = "ConfigMgr Cloud-Based Distribution"
$GoodTemplate = [ADSI]"LDAP://CN=$($Good),CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"

$GoodTemplate | select *


