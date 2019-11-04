################
#Sample script for running CMPivot using ConfigMgr AdminService
# By: Adam Gross
# @AdamGrossTX
# https://www.asquaredozen.com
###############

Param (
    $SiteServer = "YourServerName"
)

$BaseUri = "https://$($SiteServer)/AdminService/v1.0/"

$Query = "OperatingSystem"

$Params = @{
    Method = "Post"
    Uri = "$($BaseUri)/Collections('SMS00001')/AdminService.RunCmpivot"
    Body = @{"InputQuery"="$($Query)"} | ConvertTo-Json
    ContentType = "application/json"
    UseDefaultCredentials = $true
}

    $Result = Invoke-RestMethod @Params
    $OperationID = $Result.OperationId


    Function Get-Status
    {
        If ($OperationID) {
            #start-sleep -seconds 30
            $uri = '{0}SMS_CMPivotStatus?$filter=ClientOperationId eq {1}' -f $BaseUri, $OperationID

            $Params = @{
                Method = "Get"
                Uri = [System.Web.HTTPUtility]::UrlEncode($uri)
                ContentType = "application/json"
                UseDefaultCredentials = $true
            }

            $agentsquery = New-Object System.Net.WebClient
            $agentsquery.UseDefaultCredentials =$true
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
            $Result = $agentsquery.DownloadString($uri)
        }

        $obj = @()
        $XML = ($Result | ConvertFrom-Json).value.ScriptOutput
        ForEach($ResultObj in $XML)
        {
            $Obj += @(([XML]$ResultObj).ChildNodes.e)
        }

        $ClickResult = $Obj | Out-GridView -OutputMode Single

        $GetResults = Read-Host -Prompt "Do you want to check for results? [y]es or [n]o"
        If ($GetResults = 'Y') {Get-Status}

    }

    Get-Status