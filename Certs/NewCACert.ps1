#https://powershell.org/forums/topic/certificate-templates-add-catemplate-problems/

$ConfigContext = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext 
$ADSI = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext" 

$NewTempl = $ADSI.Create("pKICertificateTemplate", "CN=deploy-WebServer") 
$NewTempl.put("distinguishedName","CN=deploy-WebServer,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext") 
# and put other atributes that you need 





$NewTempl.put("flags","131649")
$NewTempl.put("displayName","deploy-WebServer")
$NewTempl.put("revision","100")
$NewTempl.put("pKIDefaultKeySpec","1")
$NewTempl.SetInfo()

$NewTempl.put("pKIMaxIssuingDepth","0")
$NewTempl.put("pKICriticalExtensions","2.5.29.15")
$NewTempl.put("pKIExtendedKeyUsage","1.3.6.1.5.5.7.3.1")
$NewTempl.put("pKIDefaultCSPs","1,Microsoft RSA SChannel Cryptographic Provider")
$NewTempl.put("msPKI-RA-Signature","0")
$NewTempl.put("msPKI-Enrollment-Flag","8")
$NewTempl.put("msPKI-Private-Key-Flag","16842768")
$NewTempl.put("msPKI-Certificate-Name-Flag","1")
$NewTempl.put("msPKI-Minimal-Key-Size","2048")
$NewTempl.put("msPKI-Template-Schema-Version","2")
$NewTempl.put("msPKI-Template-Minor-Revision","2")
$NewTempl.put("msPKI-Cert-Template-OID","1.3.6.1.4.1.311.21.8.7183632.6046387.16009101.13536898.4471759.164.5869043.12046343")
$NewTempl.put("msPKI-Certificate-Application-Policy","1.3.6.1.5.5.7.3.1")

$NewTempl.SetInfo()

$WATempl = $ADSI.psbase.children | where {$_.displayName -match "Subordinate Certification Authority"}

#before
$NewTempl.pKIExpirationPeriod = $WATempl.pKIExpirationPeriod
$NewTempl.pKIOverlapPeriod = $WATempl.pKIOverlapPeriod
$NewTempl.SetInfo()

$WATempl2 = $ADSI.psbase.children | where {$_.displayName -match "Web Server"}


$NewTempl.pKIKeyUsage = $WATempl2.pKIKeyUsage
$NewTempl.SetInfo()
$NewTempl | select *

$acl = $NewTempl.psbase.ObjectSecurity
$acl | select -ExpandProperty Access

#Set new
$AdObj = New-Object System.Security.Principal.NTAccount("Authenticated Users")
$identity = $AdObj.Translate([System.Security.Principal.SecurityIdentifier])
$adRights = "ReadProperty, ExtendedRight, GenericExecute"
$type = "Allow"

$ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($identity,$adRights,$type)
$NewTempl.psbase.ObjectSecurity.SetAccessRule($ACE)
$NewTempl.psbase.commitchanges()

$AdObj = New-Object System.Security.Principal.NTAccount("deploy\Administrator")
$identity = $AdObj.Translate([System.Security.Principal.SecurityIdentifier])
$adRights = "GenericAll"
$type = "Allow"

$ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($identity,$adRights,$type)
$NewTempl.psbase.ObjectSecurity.SetAccessRule($ACE)
$NewTempl.psbase.commitchanges()

sleep 5


Stop-Service CertSvc

sleep 5

Start-Service CertSvc

sleep 5

Get-CATemplate

Add-CATemplate -Name 'deploy-WebServer' -force 