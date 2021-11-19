[cmdletbinding()]
param (
    $ServerName,
    $ApplicationTitle,
    $ApplicationVersion = 1.0
)

function New-ScopeID {
    param (
        $ServerName
    )
    try {
        #<ActionImport Name="SMS_Identification.GetSiteID" Action="AdminService.SMS_Identification.GetSiteID"/>
        $GetSiteID = Invoke-RestMethod -Method Get -Uri "https://$($ServerName)/AdminService/wmi/SMS_Identification.GetSiteID" -UseDefaultCredentials
        $SiteID   = $GetSiteID.SiteID
        $SiteID   = $SiteID.Replace("{","").Replace("}","").ToUpper()
        $ScopeID  = "ScopeId_$($SiteID)"

        return $ScopeID
    }
    catch {
        throw $_
    }
}

function New-ResourceID {
    $guid = New-Guid
    [int]$resnum = [Math]::Abs($guid.GetHashCode())
    $ResourceID = "Res_$($resnum)"
    return $ResourceID
}

#App Variables
$ScopeID = New-ScopeID -ServerName $ServerName
$ApplicationID = "Application_$(New-Guid)"
$DigestVersion = 1
$Language = (Get-Culture).Name

#SDMPackageXML Template
$SDMPackageXML = '<AppMgmtDigest xmlns="http://schemas.microsoft.com/SystemCenterConfigurationManager/2009/AppMgmtDigest" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <Application AuthoringScopeId="{0}" LogicalName="{1}" Version="{2}">
    <DisplayInfo DefaultLanguage="{3}">
      <Info Language="{3}">
        <Title>{4}</Title>
      </Info>
    </DisplayInfo>
    <Title ResourceId="{5}">{4}</Title>
  </Application>
</AppMgmtDigest>' -f $ScopeID,$ApplicationID,$DigestVersion,$Language,$ApplicationTitle,(New-ResourceID)

$SDMPackageXMLJson = @{
    SDMPackageXML = $SDMPackageXML
} | ConvertTo-Json

try {
    $NewApp = Invoke-RestMethod -Method Post -Uri "https://$($ServerName)/AdminService/wmi/SMS_Application" -body $SDMPackageXMLJson -UseDefaultCredentials -ContentType "application/json"
    $NewApp
}
catch {
    throw $_
}