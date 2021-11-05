function Get-CMPivotEventMessages {
    #ExcludeMe
    $logFileName = 'Microsoft-Windows-PowerShell/Operational'
    $ComputerName = [System.Environment]::MachineName 
    $EventStartDate = (Get-Date).AddMinutes(-10)
    $EventEndTime = (Get-Date)
    $filterTable = @{logname = $logFileName; StartTime=$EventStartDate; EndTime=$EventEndTime; Id=4104;}

    # Filter out the winEvent logs that we need
    try {
        $winEvents = Get-WinEvent -ComputerName $ComputerName -FilterHashTable $filterTable -ErrorAction Stop | Where-Object {$_.Message -like '*C:\Windows\CCM\ScriptStore\*' -and $_.Message -like '*-kustoquery*' -and $_.Message -notlike '*ExcludeMe*'}
        $Messages = $winEvents | Select-Object -ExpandProperty Message
        Return $Messages
    }
    catch {
        throw "No Match Found"
    }
}

function Get-CMPivotVars {
    param(
        $Message
    )
    [regex]$KustoQueryRegex = "(?:-kustoquery.*?')(.*?)(?:')"
    [regex]$WMIQueryRegex = "(?:-wmiquery.*?')(.*?)(?:')"
    [regex]$SelectRegex = "(?:-select.*?')(.*?)(?:')"

    $KustoQueryMatches = ($Message | Select-String -AllMatches -Pattern $KustoQueryRegex).Matches.Value
    $WMIQueryMatches = ($Message | Select-String -AllMatches -Pattern $WMIQueryRegex).Matches.Value
    $SelectMatches = ($Message | Select-String -AllMatches -Pattern $SelectRegex).Matches.Value

    $kustoquery = $KustoQueryMatches.Replace("-kustoquery ", "").Replace("'","")
    $wmiquery = $WMIQueryMatches.Replace("-wmiquery ", "").Replace("'","")
    $select = $SelectMatches.Replace("-select ", "").Replace("'","")

    @{
        kustoquery = $kustoquery
        wmiquery = $wmiquery
        select = $select
    }
}

function Decode-CMPivotVars {
    param([string] $kustoquery, [string] $wmiquery, [string] $select)
    # Read the queries and selects
    $kustoquery  = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($kustoquery.Substring(2))).Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries)
    $wmiqueries  = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($wmiquery.Substring(2))).Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries)
    $selects = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($select.Substring(2))).Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries)

    [PSCustomObject]@{
        kustoquery = $kustoquery
        wmiqueries = $wmiqueries
        selects = $selects
    }
}

$EventMessages = Get-CMPivotEventMessages
$Results = foreach($Message in $EventMessages) {
    $vars = Get-CMPivotVars -Message $Message
    if($vars) {
        Decode-CMPivotVars @vars
    }
}

$Results[0].kustoquery
$Results[0].wmiqueries
$Results[0].selects