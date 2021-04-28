$SourceTemplateCN = "DomainControllerAuthentication(KDC)"

$ConfigContext = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext 
$ADSI = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"
$Template = [ADSI]"LDAP://CN=$SourceTemplateCN,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"
$PropertyList = $Template.Properties.PropertyNames | Where-Object {$_.StartsWith("pKI") -or $_.StartsWith("flags") -or $_.StartsWith("msPKI-")}

ForEach($Property in $PropertyList) {
	$Value = $Template.psbase.Properties.Item($Property).Value
	If($Property -eq "pKIExpirationPeriod" -or $Property -eq "pKIOverlapPeriod") {
		$b = $Value -join ','
		Write-Host """$Property"" = ([Byte[]]($b))"

	}
	ElseIf($Value -is [byte[]]) {
		$b = '"{0}"' -f ($Value -join '","')
		Write-Host """$Property"" = [Byte[]]("$($b.ToString())")"
	}
	ElseIf($Value -is [Object[]]) {
		$b = '"{0}"' -f ($Value -join '","')
		Write-Host """$Property"" = @("$($b.ToString())")"
	}
	ElseIf($Value -match '`') {
		$NewVal = $Value.Replace('`','``')
		Write-Host """$Property"" = ""$($NewVal.ToString())"""
	}
	Else {
		Write-Host """$Property"" = ""$($Value.ToString())"""
	}
}


#GetPermissions
#$Good = "ConfigMgrClientCertificate"
#$GoodTemplate = [ADSI]"LDAP://CN=$($Good),CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"
#$GoodTemplate.ObjectSecurity.Access | Select * | Format-List


