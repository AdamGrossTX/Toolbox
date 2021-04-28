#http://www.checkyourlogs.net/?p=56283

Import-Module ActiveDirectory

$ConfigContext = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext 
$ADSI = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"
#$ADSI.Children | Sort-Object Name | Select-Object DisplayName, Name, msPKI-Cert-Template-OID
$Templates1 = @()
$templates = $ADSI.Children | Sort-Object Name | ForEach {
     $Templates1 += Get-ADObject $_.distinguishedName.ToString() -Properties * | Select *
}


($Templates1 | Where-Object Name -eq ConfigMgrWebServerCertificate).pKIExpirationPeriod.GetType()





