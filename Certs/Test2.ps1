#https://github.com/PowerShell/CertificateDsc/issues/54
$configContext = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext 
$ADSI = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$configContext" 

#ConfigMgrWebServerCert
$templateName = "ConfigMgrWebServerTest"
$template = [ADSI]"LDAP://CN=$templateName,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"
if([string]::IsNullOrEmpty($template.Name)){
    # create if not exists
	$template = $ADSI.Create("pKICertificateTemplate", "CN=$($templateName)")
}

$template.Put("displayName", $templateName)
$template.SetInfo()

$pkiConfig = @{
    "DisplayName" = $templateName
    "Flags" = "131649"
    "revision" = "100"
	"pKIDefaultKeySpec" = "1"
    "pKIKeyUsage" = [Byte[]]("160","0")
    "pKIMaxIssuingDepth" = "0"
    "pKICriticalExtensions" = @("2.5.29.15")
    "pKIExpirationPeriod" = ([Byte[]](0,64,30,164,232,101,250,255))
    "pKIOverlapPeriod" = ([Byte[]](0,128,166,10,255,222,255,255))
    "pKIExtendedKeyUsage" = @("1.3.6.1.5.5.7.3.1")
    "pKIDefaultCSPs" = @("2,Microsoft DH SChannel Cryptographic Provider","1,Microsoft RSA SChannel Cryptographic Provider")
    "msPKI-RA-Signature" = "0"
    "msPKI-Enrollment-Flag" = "8"
    "msPKI-Private-Key-Flag" = "16842752"
    "msPKI-Certificate-Name-Flag" = "1"
    "msPKI-Minimal-Key-Size" = "2048"
    "msPKI-Template-Schema-Version" = "2"
    "msPKI-Template-Minor-Revision" = "0"
    "msPKI-Cert-Template-OID" = "1.3.6.1.4.1.311.21.8.9297300.10481922.2378919.4036973.687234.60.11634013.16673656"
    "msPKI-Certificate-Application-Policy" = @("1.3.6.1.5.5.7.3.1")
}
foreach($key in $pkiConfig.Keys){
	$template.Put($key, $pkiConfig[$key])
}

$template.SetInfo()

# Allow Computers to Enroll
#$template.ObjectSecurity.GetAccessRules($true, $true, [System.Security.Principal.NTAccount])
#$acc = [System.Security.Principal.NTAccount]::new($Using:domainNetbiosName, "Domain Computers")
#$enrollObjectType = [Guid]::Parse("0e10c968-78fb-11d2-90d4-00c04f79dc55")
#$adRights = [System.DirectoryServices.ActiveDirectoryRights]::ReadProperty -bor [System.DirectoryServices.ActiveDirectoryRights]::WriteProperty -bor [System.DirectoryServices.ActiveDirectoryRights]::ExtendedRight
#$rule = [System.DirectoryServices.ActiveDirectoryAccessRule]::new($acc, $adRights, [System.Security.AccessControl.AccessControlType]::Allow, $enrollObjectType)
#$template.ObjectSecurity.AddAccessRule($rule)
#$template.commitchanges()


#ConfigMgrDistributionPointCertificateTest
$templateName = "ConfigMgrDistributionPointCertificateTest"
$template = [ADSI]"LDAP://CN=$templateName,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"
if([string]::IsNullOrEmpty($template.Name)){
    # create if not exists
	$template = $ADSI.Create("pKICertificateTemplate", "CN=$($templateName)")
}

$template.Put("displayName", $templateName)
$template.SetInfo()

$pkiConfig = @{
    "DisplayName" = $templateName
    "revision" = "100"
    "flags" = "131680"
    "pKIDefaultKeySpec" = "1"
    "pKIKeyUsage" = [Byte[]]("160","0")
    "pKIMaxIssuingDepth" = "0"
    "pKICriticalExtensions" = @("2.5.29.15")
    "pKIExpirationPeriod" = ([Byte[]](0,192,171,149,139,163,252,255))
    "pKIOverlapPeriod" = ([Byte[]](0,128,166,10,255,222,255,255))
    "pKIExtendedKeyUsage" = @("1.3.6.1.5.5.7.3.2")
    "pKIDefaultCSPs" = @("1,Microsoft RSA SChannel Cryptographic Provider")
    "msPKI-RA-Signature" = "0"
    "msPKI-Enrollment-Flag" = "40"
    "msPKI-Private-Key-Flag" = "16842768"
    "msPKI-Certificate-Name-Flag" = "134217728"
    "msPKI-Minimal-Key-Size" = "2048"
    "msPKI-Template-Schema-Version" = "2"
    "msPKI-Template-Minor-Revision" = "2"
    "msPKI-Cert-Template-OID" = "1.3.6.1.4.1.311.21.8.9297300.10481922.2378919.4036973.687234.60.7762591.7797208"
    "msPKI-Certificate-Application-Policy" = @("1.3.6.1.5.5.7.3.2")
}
foreach($key in $pkiConfig.Keys){
	$template.Put($key, $pkiConfig[$key])
}

$template.SetInfo()


#ConfigMgrCloud-BasedDistributionTest
$templateName = "ConfigMgrCloud-BasedDistributionTest"
$template = [ADSI]"LDAP://CN=$templateName,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"
if([string]::IsNullOrEmpty($template.Name)){
    # create if not exists
	$template = $ADSI.Create("pKICertificateTemplate", "CN=$($templateName)")
}

$template.Put("displayName", $templateName)
$template.SetInfo()

$pkiConfig = @{
    "DisplayName" = $templateName
    "revision" = "100"
    "flags" = "131680"
    "pKIDefaultKeySpec" = "1"
    "pKIKeyUsage" = [Byte[]]("160","0")
    "pKIMaxIssuingDepth" = "0"
    "pKICriticalExtensions" = @("2.5.29.15")
    "pKIExpirationPeriod" = ([Byte[]](0,128,114,14,93,194,253,255))
    "pKIOverlapPeriod" = ([Byte[]](0,128,166,10,255,222,255,255))
    "pKIExtendedKeyUsage" = @("1.3.6.1.5.5.7.3.1")
    "pKIDefaultCSPs" = @("2,Microsoft DH SChannel Cryptographic Provider","1,Microsoft RSA SChannel Cryptographic Provider")
    "msPKI-RA-Signature" = "0"
    "msPKI-Enrollment-Flag" = "8"
    "msPKI-Private-Key-Flag" = "101056784"
    "msPKI-Certificate-Name-Flag" = "1"
    "msPKI-Minimal-Key-Size" = "2048"
    "msPKI-Template-Schema-Version" = "4"
    "msPKI-Template-Minor-Revision" = "0"
    "msPKI-Cert-Template-OID" = "1.3.6.1.4.1.311.21.8.9297300.10481922.2378919.4036973.687234.60.13599016.14072541"
    "msPKI-Certificate-Application-Policy" = @("1.3.6.1.5.5.7.3.1")
}
foreach($key in $pkiConfig.Keys){
	$template.Put($key, $pkiConfig[$key])
}

$template.SetInfo()


#ConfigMgrClientCertificateTest
$templateName = "ConfigMgrClientCertificateTest"
$template = [ADSI]"LDAP://CN=$templateName,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"
if([string]::IsNullOrEmpty($template.Name)){
    # create if not exists
	$template = $ADSI.Create("pKICertificateTemplate", "CN=$($templateName)")
}

$template.Put("displayName", $templateName)
$template.SetInfo()

$pkiConfig = @{
    "DisplayName" = $templateName
    "revision" = "100"
    "flags" = "131680"
    "pKIDefaultKeySpec" = "1"
    "pKIKeyUsage" = [Byte[]]("160","0")
    "pKIMaxIssuingDepth" = "0"
    "pKICriticalExtensions" = @("2.5.29.15")
    "pKIExpirationPeriod" = ([Byte[]](0,192,171,149,139,163,252,255))
    "pKIOverlapPeriod" = ([Byte[]](0,128,166,10,255,222,255,255))
    "pKIExtendedKeyUsage" = @("1.3.6.1.5.5.7.3.2")
    "pKIDefaultCSPs" = @("1,Microsoft RSA SChannel Cryptographic Provider")
    "msPKI-RA-Signature" = "0"
    "msPKI-Enrollment-Flag" = "40"
    "msPKI-Private-Key-Flag" = "16842752"
    "msPKI-Certificate-Name-Flag" = "134217728"
    "msPKI-Minimal-Key-Size" = "2048"
    "msPKI-Template-Schema-Version" = "2"
    "msPKI-Template-Minor-Revision" = "2"
    "msPKI-Cert-Template-OID" = "1.3.6.1.4.1.311.21.8.9297300.10481922.2378919.4036973.687234.60.16115542.5458281"
    "msPKI-Certificate-Application-Policy" = @("1.3.6.1.5.5.7.3.2")
}
foreach($key in $pkiConfig.Keys){
	$template.Put($key, $pkiConfig[$key])
}

$template.SetInfo()


#ConfigMgrCloudServicesCertificateTest
$templateName = "ConfigMgrCloudServicesCertificateTest"
$template = [ADSI]"LDAP://CN=$templateName,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"
if([string]::IsNullOrEmpty($template.Name)){
    # create if not exists
	$template = $ADSI.Create("pKICertificateTemplate", "CN=$($templateName)")
}

$template.Put("displayName", $templateName)
$template.SetInfo()

$pkiConfig = @{
    "DisplayName" = $templateName
    "revision" = "100"
    "flags" = "131680"
    "pKIDefaultKeySpec" = "1"
    "pKIKeyUsage" = [Byte[]]("160","0")
    "pKIMaxIssuingDepth" = "0"
    "pKICriticalExtensions" = @("2.5.29.15")
    "pKIExpirationPeriod" = ([Byte[]](0,64,30,164,232,101,250,255))
    "pKIOverlapPeriod" = ([Byte[]](0,128,166,10,255,222,255,255))
    "pKIExtendedKeyUsage" = @("1.3.6.1.5.5.7.3.1")
    "pKIDefaultCSPs" = @("2,Microsoft DH SChannel Cryptographic Provider","1,Microsoft RSA SChannel Cryptographic Provider")
    "msPKI-RA-Signature" = "0"
    "msPKI-Enrollment-Flag" = "8"
    "msPKI-Private-Key-Flag" = "16842768"
    "msPKI-Certificate-Name-Flag" = "1"
    "msPKI-Minimal-Key-Size" = "2048"
    "msPKI-Template-Schema-Version" = "2"
    "msPKI-Template-Minor-Revision" = "0"
    "msPKI-Cert-Template-OID" = "1.3.6.1.4.1.311.21.8.9297300.10481922.2378919.4036973.687234.60.12437731.4434972"
    "msPKI-Certificate-Application-Policy" = @("1.3.6.1.5.5.7.3.1")

}
foreach($key in $pkiConfig.Keys){
	$template.Put($key, $pkiConfig[$key])
}

$template.SetInfo()