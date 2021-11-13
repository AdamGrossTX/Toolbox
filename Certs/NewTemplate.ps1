<#
.NOTES
    Author:           Adam Gross - @AdamGrossTX
    GitHub:           https://www.github.com/AdamGrossTX
    WebSite:          https://www.asquaredozen.com

#>
$env = "ASD"
$ConfigContext = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext
$ADSI = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"

$SourceTemplateName = "WebServer"
$SourceTemplate = [ADSI]"LDAP://CN=$($SourceTemplateName),CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"
$SourceTemplateDN = $SourceTemplate.distinguishedName.Replace($SourceTemplateName,$NewTemplateName.Replace(' ',''))

$NewTemplateName = "ConfigMgr $($SourceTemplate.displayName) Certificate Test"
Remove-CATemplate -name $NewTemplateName -ErrorAction SilentlyContinue -Force
$NewTemplate = $ADSI.Create($SourceTemplate.SchemaClassName, "CN=$($NewTemplateName)")
$NewTemplate.DeleteTree()
$NewTemplate = $ADSI.Create($SourceTemplate.SchemaClassName, "CN=$($NewTemplateName)")

$NewTemplate.put("DistinguishedName",$SourceTemplateDN)
$NewTemplate.put("flags","131649")
$NewTemplate.put("DisplayName",$NewTemplateName)
$NewTemplate.put("revision","100")
$NewTemplate.put("pKIDefaultKeySpec",$SourceTemplate.pKIDefaultKeySpec.ToString())
$NewTemplate.setinfo()


$NewTemplate.put("msPKI-Cert-Template-OID",$SourceTemplate.'msPKI-Cert-Template-OID'.ToString())
#$NewTemplate.put("msPKI-Certificate-Name-Flag",$SourceTemplate.'msPKI-Certificate-Name-Flag'.ToString())
#$NewTemplate.put("msPKI-Enrollment-Flag",$SourceTemplate.'msPKI-Enrollment-Flag'.ToString())
#$NewTemplate.put("msPKI-Minimal-Key-Size",$SourceTemplate.'msPKI-Minimal-Key-Size'.ToString())
$NewTemplate.put("msPKI-Private-Key-Flag",$SourceTemplate.'msPKI-Private-Key-Flag'.ToString())
#$NewTemplate.put("msPKI-RA-Signature",$SourceTemplate.'msPKI-RA-Signature'.ToString())
#$NewTemplate.put("msPKI-Template-Minor-Revision",$SourceTemplate.'msPKI-Template-Minor-Revision'.ToString())
#$NewTemplate.put("msPKI-Template-Schema-Version",$SourceTemplate.'msPKI-Template-Schema-Version'.ToString())
$NewTemplate.put("pKICriticalExtensions",$SourceTemplate.pKICriticalExtensions.ToString())
$NewTemplate.put("pKIDefaultCSPs",($SourceTemplate.pKIDefaultCSPs -join ", ").ToString())
$NewTemplate.put("pKIExtendedKeyUsage",$SourceTemplate.pKIExtendedKeyUsage.ToString())
$NewTemplate.put("pKIMaxIssuingDepth",$SourceTemplate.pKIMaxIssuingDepth.ToString())

$NewTemplate.put("msPKI-RA-Signature","0")
$NewTemplate.put("msPKI-Enrollment-Flag","8")
$NewTemplate.put("msPKI-Private-Key-Flag","16842752")
$NewTemplate.put("msPKI-Certificate-Name-Flag","1")
$NewTemplate.put("msPKI-Minimal-Key-Size","2048")
$NewTemplate.put("msPKI-Template-Schema-Version","2")
$NewTemplate.put("msPKI-Template-Minor-Revision","0")
$NewTemplate.put("pKIExpirationPeriod","0 64 30 164 232 101 250 255")
$NewTemplate.put("pKIOverlapPeriod","0 128 166 10 255 222 255 255")
#$NewTemplate.put("msPKI-Cert-Template-OID","1.3.6.1.4.1.311.21.8.9297300.10481922.2378919.4036973.687234.60.11634013.16673656")
$NewTemplate.put("msPKI-Certificate-Application-Policy","1.3.6.1.5.5.7.3.1")

$NewTemplate.setinfo()

$NewTemplate.pKIKeyUsage = $SourceTemplate.pKIKeyUsage
$NewTemplate.pKIExpirationPeriod = $SourceTemplate.pKIExpirationPeriod
$NewTemplate.pKIOverlapPeriod = $SourceTemplate.pKIOverlapPeriod
$NewTemplate.setinfo()

$NewTemplate | select *

$AdObj = New-Object System.Security.Principal.NTAccount("$env\Domain Controllers")
$identity = $AdObj.Translate([System.Security.Principal.SecurityIdentifier])
$adRights = "ReadProperty, WriteProperty, ExtendedRight"
$type = "Allow"
$ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($identity, $adRights, $type)
$NewTemplate.psbase.ObjectSecurity.SetAccessRule($ACE)
$NewTemplate.psbase.commitchanges()
$p = Start-Process "C:\Windows\System32\certtmpl.msc"-PassThru
Start-Sleep 2
$p | Stop-Process            
Add-CATemplate -name $NewTemplateName -ErrorAction SilentlyContinue -Force


