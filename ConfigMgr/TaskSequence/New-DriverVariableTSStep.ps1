[cmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    $SiteCode,
    
    [Parameter(Mandatory=$true)]
    [string]
    $ProviderMachineName
)

$initParams = @{}
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}
Set-Location "$($SiteCode):\" @initParams

$TaskSequenceID = "<YourTSID>"
$StepNameBegin = "Set "
$StepNameEnd = " Driver Variables"
$Description = "Sets dynamic variables for drivers"
$PackageSearchDescription = "Windows 10 Driver Package"

$Packages = Get-CMPackage | Where-Object -Property Description -eq $PackageSearchDescription
$Manufacturers = $Packages | Select-Object -Unique Manufacturer
$TaskSequence = Get-CMTaskSequence -TaskSequencePackageId $TaskSequenceID

ForEach ($Manufacturer in $Manufacturers.Manufacturer)
{
    $RuleList = @()
    $StepName = "{0}{1}{2}" -f $StepNameBegin, $Manufacturer, $StepNameEnd

    $FilteredPackages = $Packages | Where-Object Manufacturer -eq $Manufacturer | Select-Object *
    Foreach ($Package in $FilteredPackages) {
        #Change this to match your driver package naming convention
        $Model = $Package.Name.Split("-")[0].trim()
        $Model = "*{0}*" -f $Model
        $Model
        $RuleList += New-CMTSRule -Make $Package.Manufacturer.ToString() -Model $Model -Variable @{"OSDUpgradeDriverPackageID" = $Package.PackageID}
    }

    $Step = New-CMTSStepSetDynamicVariable -AddRule $RuleList -Name $StepName -Description $Description
    $TaskSequence | Add-CMTaskSequenceStep -Step $Step
}



