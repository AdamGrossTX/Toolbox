<#
.NOTES
    Author:           Adam Gross - @AdamGrossTX
    GitHub:           https://www.github.com/AdamGrossTX
    WebSite:          https://www.asquaredozen.com

#>
$templateName = "ConfigMgrCloudServicesCertificate"

$ConfigContext = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext 
$ADSI = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"
$template = [ADSI]"LDAP://CN=$templateName,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"
$template.Properties.PropertyNames | ? {$_.StartsWith("pKI") -or $_.StartsWith("msPKI-")} | % {
	Write-Host """$_"" = ""$($template.psbase.Properties.Item($_).ToString())"""
}