param (
    [string]$ApplicationName
)
function Connect-CMSite {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory=$False)]
        [string]$Script:SiteServer = (Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\CCM\FSP" -Name "HostName" -ErrorAction Stop),

        [Parameter(Mandatory=$False)]
        [string]$Script:SiteCode = (Get-CimInstance -Namespace "root\SMS" -ClassName "SMS_ProviderLocation" -ComputerName $SiteServer -ErrorAction Stop | Select-Object -ExpandProperty SiteCode)
    )

    try {
        Write-Host " + Connecting to ConfigMgr Site $($Script:SiteServer) - $($Script:SiteCode)" -ForegroundColor Cyan -NoNewline
        if((Get-Module ConfigurationManager) -eq $null) {
            Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
        }
    
        if((Get-PSDrive -Name $Script:SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
            New-PSDrive -Name $Script:SiteCode -PSProvider CMSite -Root $Script:SiteServer
        }
        Set-Location "$($Script:SiteCode):\"
        Write-Host $Script:tick -ForegroundColor green
    }
    catch {
        throw $_
    }
}

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
Add-Type -AssemblyName PresentationCore,PresentationFramework
Remove-Variable * -ErrorAction SilentlyContinue

$ApplicationName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter application name (full or partial): ", "Search String", "java") 
$ApplicationName = "*$($ApplicationName)*"

Connect-CMSite

$Applications = Get-CMApplication -Name $ApplicationName -Fast -ForceWildcardHandling

$AppList = ForEach ($Application in $Applications) {
    $Deployments = $Application | Foreach-Object {Get-CMApplicationDeployment -InputObject $_}
    if ($Deployments) {
        ForEach ($Deployment in $Deployments) {
            $Collections = $Deployment | ForEach-Object {Get-CMCollection -Id $_.TargetCollectionID}
                if ($Collections) {
                    ForEach ($Collection in $Collections) {
                    [PSCustomObject]@{
                        AppID = $Collections.Comment.SubString($Collections.Comment.LastIndexOf('|')+1).trim()
                        Manufacturer = $Application.Manufacturer
                        ApplicationName = $Application.LocalizedDisplayName
                        ApplicationVerison = $Application.SoftwareVersion
                        CollectionName = $Collections.Name
                        CollectionID = $Collections.CollectionID
                        CollectionComment = $Collections.Comment
                    }
                }
            }
        }
    }
}

$AppList | Format-List