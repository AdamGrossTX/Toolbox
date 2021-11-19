#https://msendpointmgr.com/2014/01/09/create-an-application-in-configmgr-2012-with-powershell/
[cmdletbinding()]
param (
    $SiteServer = "CM01.asd.net",
    $ContentSourcePath = "\\cm01\Media\Applications\Recast",
    $ApplicationTitle = "TestApp10",
    $ApplicationVersion = 1.0,
    $ApplicationSoftwareVersion = "1.0",
    $ApplicationLanguage = (Get-Culture).Name,
    $ApplicationDescription = "Test description",
    $ApplicationPublisher = "TestCorp",
    $DeploymentInstallCommandLine = "msiexec /i Recast_RCT_Latest.msi /qb",
    $DeploymentUninstallCommandLine = "msiexec /x Recast_RCT_Latest.msi /qb"
)

function New-ScopeID {
    param (
        $SiteServer
    )
    try {
        #<ActionImport Name="SMS_Identification.GetSiteID" Action="AdminService.SMS_Identification.GetSiteID"/>
        $GetSiteID = Invoke-RestMethod -Method Get -Uri "https://$($SiteServer)/AdminService/wmi/SMS_Identification.GetSiteID" -UseDefaultCredentials
        $SiteID   = $GetSiteID.SiteID
        $SiteID   = $SiteID.Replace("{","").Replace("}","")
        $ScopeID  = "ScopeId_$($SiteID)".ToUpper()

        return $ScopeID
    }
    catch {
        throw $_
    }
}

function New-ResourceID {
    $guid = New-Guid
    $resnum = $guid.GetHashCode()
    $ResourceID = "Res_$($resnum)"
    return $ResourceID
}

function New-SDMPackageXML {
    param (
        $SiteServer,
        $ContentSourcePath,
        $ApplicationTitle,
        $ApplicationVersion,
        $ApplicationSoftwareVersion,
        $ApplicationLanguage,
        $ApplicationDescription,
        $ApplicationPublisher,
        $DeploymentInstallCommandLine,
        $DeploymentUninstallCommandLine
    )
    
    try {
        [System.Reflection.Assembly]::LoadFrom((Join-Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName "Microsoft.ConfigurationManagement.ApplicationManagement.dll")) | Out-Null 
        [System.Reflection.Assembly]::LoadFrom((Join-Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName "Microsoft.ConfigurationManagement.ApplicationManagement.MsiInstaller.dll")) | Out-Null 
        # Variables 

        # Get ScopeID 
        $ScopeID = New-ScopeID -SiteServer $SiteServer
        
        # Create unique ID for application and deployment type 
        $ApplicationID = "APP_$(New-Guid)"
        $DeploymentTypeID = "APP_$(New-Guid)"

        # Create application object
        $ObjectApplicationID = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.ObjectId($ScopeID,$ApplicationID) 
        $ObjectApplication = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.Application($ObjectApplicationID) 
        $ObjectApplication.DisplayInfo.DefaultLanguage = $ApplicationLanguage 
        $ObjectApplication.Title = $ApplicationTitle 
        $ObjectApplication.Version = $ApplicationVersion 
        $ObjectApplication.SoftwareVersion = $ApplicationSoftwareVersion 
        $ObjectApplication.Description = $ApplicationDescription 
        $ObjectApplication.Publisher = $ApplicationPublisher 
        
        # Add content to the Application
        $ApplicationContent = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentImporter]::CreateContentFromFolder($ContentSourcePath) 
        $ApplicationContent.OnSlowNetwork = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentHandlingMode]::DoNothing 
        $ApplicationContent.OnFastNetwork = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentHandlingMode]::Download 

        # Application information
        $ObjectDisplayInfo = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.AppDisplayInfo 
        $ObjectDisplayInfo.Language = $ApplicationLanguage 
        $ObjectDisplayInfo.Title = $ApplicationTitle 
        $ObjectDisplayInfo.Description = $ApplicationDescription 
        $ObjectApplication.DisplayInfo.Add($ObjectDisplayInfo) 
        #endregion

        # DeploymentType configuration
        # Create deployment type objects
        $ObjectDeploymentTypeID = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.ObjectId($ScopeID,$DeploymentTypeID) 
        $ObjectDeploymentType = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.DeploymentType($ObjectDeploymentTypeID,"MSI") 
        $ObjectDeploymentType.Title = $ApplicationTitle 
        $ObjectDeploymentType.Version = $ApplicationVersion 
        $ObjectDeploymentType.Enabled = $true 
        $ObjectDeploymentType.Description = $ApplicationDescription 
        $ObjectDeploymentType.Installer.Contents.Add($ApplicationContent) 
        $ObjectDeploymentType.Installer.InstallCommandLine = $DeploymentInstallCommandLine 
        $ObjectDeploymentType.Installer.UninstallCommandLine = $DeploymentUninstallCommandLine 
        $ObjectDeploymentType.Installer.ProductCode = "{" + [GUID]::NewGuid().ToString() + "}" 
        $ObjectDeploymentType.Installer.DetectionMethod = [Microsoft.ConfigurationManagement.ApplicationManagement.DetectionMethod]::ProductCode 

        # Add DeploymentType to Application 
        $ObjectApplication.DeploymentTypes.Add($ObjectDeploymentType) 

        # Serialize the Application 
        $SDMPackageXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToString($ObjectApplication)
    }

    catch {
        throw $_
    }

    return $SDMPackageXML
}


#Do Work!
$NewSDMPackageXMLSplat = @{
    SiteServer = $SiteServer
    ContentSourcePath = $ContentSourcePath
    ApplicationTitle = $ApplicationTitle
    ApplicationVersion = $ApplicationVersion
    ApplicationSoftwareVersion = $ApplicationSoftwareVersion
    ApplicationLanguage = $ApplicationLanguage
    ApplicationDescription = $ApplicationDescription
    ApplicationPublisher = $ApplicationPublisher
    DeploymentInstallCommandLine = $DeploymentInstallCommandLine
    DeploymentUninstallCommandLine = $DeploymentUninstallCommandLine
}

$SDMPackageXML = New-SDMPackageXML @NewSDMPackageXMLSplat
$SDMPackageXMLJson = @{
    SDMPackageXML = $SDMPackageXML
} | ConvertTo-Json

try {
    $NewApp = Invoke-RestMethod -Method Post -Uri "https://$($SiteServer)/AdminService/wmi/SMS_Application" -body $SDMPackageXMLJson -UseDefaultCredentials -ContentType "application/json"
    $NewApp
}
catch {
    throw $_
}