param(
    [string]$WorkspaceID = "", #Desktop Analytics WorkspaceID
    [switch]$CreateNewContext = $false,
    [int]$Hours = 24 
)

if (-not (Get-Module -Name Az)) {Install-Module Az -Force}

Try {

#region Get Desktop Analytics Data
    If($CreateNewContext.IsPresent) {
        Connect-AzAccount
        Login-AzAccount
        Save-AzContext -Path "$($PSScriptRoot)\azprofile.json" -Force
    }

    $Query ='MADevice'
    $TimeSpan = (New-TimeSpan -Hours $Hours)
    Import-AzContext -Path "$($PSScriptRoot)\azprofile.json" -ErrorAction Stop

    $AzResults = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceID -Query $Query -Timespan $TimeSpan
    $AzComputerList = $AzResults.Results | Sort-Object Computer

    If(!($AzResults) -or !($AzComputerList)) {
        Write-Output "No Azure Results, exiting."
        Break;
    }
    Else {
        Write-Output ("Retrieved {0} Azure Records" -f $AzComputerList.Count)
    }
}
Catch
{
    Write-Output "An error occurred connecting to Azure"
    $Error[0].Exception
    Return 1
}
