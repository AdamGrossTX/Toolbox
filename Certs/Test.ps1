$ConfigContext = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext 
$ADSI = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext" 

# and put other atributes that you need 
$WATempl = $ADSI.psbase.children | where {$_.cn -eq "WebServer"}

#Remove-CATemplate -name $NewTemplateName -Force -ErrorAction SilentlyContinue
$NewTemplate = $ADSI.Create("pKICertificateTemplate", "CN=Test") 
$NewTemplate.DeleteTree()
$NewTemplate = $ADSI.Create("pKICertificateTemplate", "CN=Test") 
$NewTemplate.put("distinguishedName","CN=Test,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext") 

#$WATempl..ToString()

$NewTemplate.put("flags","131649")
$NewTemplate.put("displayName","Test")
$NewTemplate.put("revision",$WATempl.revision.ToString())
$NewTemplate.put("pKIDefaultKeySpec",$WATempl.pKIDefaultKeySpec.ToString())
$NewTemplate.SetInfo()

$NewTemplate.put("msPKI-Cert-Template-OID",$WATempl.'msPKI-Cert-Template-OID'.ToString())
$NewTemplate.put("pKIMaxIssuingDepth",$WATempl.pKIMaxIssuingDepth.ToString())
$NewTemplate.put("pKICriticalExtensions",$WATempl.pKICriticalExtensions.ToString())
$NewTemplate.put("pKIExtendedKeyUsage",$WATempl.pKIExtendedKeyUsage.ToString())
$NewTemplate.put("pKIDefaultCSPs",$WATempl.pKIDefaultCSPs.ToString())
$NewTemplate.put("msPKI-RA-Signature",$WATempl.'msPKI-RA-Signature'.ToString())
$NewTemplate.put("msPKI-Enrollment-Flag",$WATempl.'msPKI-Enrollment-Flag'.ToString())
$NewTemplate.put("msPKI-Private-Key-Flag",$WATempl.'msPKI-Private-Key-Flag'.ToString())
$NewTemplate.put("msPKI-Certificate-Name-Flag",$WATempl.'msPKI-Certificate-Name-Flag'.ToString())
$NewTemplate.put("msPKI-Minimal-Key-Size",$WATempl.'msPKI-Minimal-Key-Size'.ToString())
$NewTemplate.put("msPKI-Template-Schema-Version","2")
$NewTemplate.put("msPKI-Template-Minor-Revision","2")
$NewTemplate.put("msPKI-Certificate-Application-Policy",$WATempl.pKIExtendedKeyUsage.ToString())

$NewTemplate.SetInfo()



#before
$NewTemplate.pKIKeyUsage = $WATempl.pKIKeyUsage
$NewTemplate.pKIExpirationPeriod = $WATempl.pKIExpirationPeriod
$NewTemplate.pKIOverlapPeriod = $WATempl.pKIOverlapPeriod
$NewTemplate.SetInfo()

$NewTemplate | select *