#https://lazywinadmin.com/2015/09/powershellsccm-find-applications.html

#https://setupconfigmgr.com/how-to-configure-microsoft-sccm-to-use-https-pki

#https://docs.microsoft.com/en-us/graph/query-parameters

#https://www.petervanderwoude.nl/post/install-user-targeted-applications-during-os-deployment-via-powershell-and-configmgr-2012/

#E:\Program Files\Microsoft Configuration Manager\bin\X64\CMRestProvider\AdminService.Host\adminservice.host.dll


<#
#URL Format Options

<ClassName>('KeyValue') - only works for key properties
<ClassName>?$filter=<PropertyName> <Operator> <PropertyValue>

<ClassName>?$filter=<PropertyName>%20<Operator>%20<PropertyValue>
<ClassName>?$filter=<PropertyName> <Operator> <PropertyValue>

EXAMPLE - https://<FQDN>/AdminService/wmi/Collection?$filter=CollectionType%20eq%201 - searches for all collections with CollectionType being 1.
EXAMPLE - https://<FQDN>/AdminService/wmi/Collection?$filter=CollectionType eq 1

OPERATORS

$path
$filter
$orderby
$select;
$expand;
$skip;
$top;
$inlineCount
$format
any all

#>


Function StringBuilder {
[CmdletBinding()]
param(
    [string]
    $PropertyName,

    [string]
    $PropertyValue,
    

    [ValidateSet(
        'filter',
        'any',
        'all',
        'cast',
        'ceiling',
        'concat',
        'contains',
        'day',
        'endswith',
        'floor',
        'hour',
        'indexof',
        'isof',
        'length',
        'minute',
        'month',
        'round',
        'second',
        'startswith',
        'substring',
        'tolower',
        'toupper',
        'trim',
        'year',
        'date',
        'time',
        'fractionalseconds'
    )]
    [string]
    $Function,

    [string]
    [ValidateSet("eq","ne")]
    $Operator,

    [switch]
    $quote
  
)

    $ReturnValue = $null

    If($quote) {
        $PropertyValue = "'{0}'" -f $PropertyValue
    }
    $ReturnValue = "`${0}={1}%20{2}%20{3}" -f $Function,$PropertyName,$Operator,$PropertyValue

    Write-Host $ReturnValue | Out-Null
    Return $ReturnValue

}


$ComputerName = 'CM01'

$Script:WMIBaseURI = "https://CM01.ASD.NET:443/AdminService/wmi/"

Function Get-WMIResults($URI)
{
    $FullURI = "$($Script:WMIBaseURI)$($URI)" 
    Write-Host $FullURI
    $Results = Invoke-RestMethod -Method get -Uri $FullURI -UseDefaultCredentials
    Return $Results
}




#####################################################################
#Get DeviceList
$URI = "Device"
$Results = Get-WMIResults -URI $URI
$DeviceList = $Results.Value
$SelectedDevice = $DeviceList | Out-GridView -Title "Select A Device" -OutputMode Single


#Get WMI Function List
$URI = "$metadata"
$Results = Get-WMIResults -URI $URI
$WMIFunctionList = $Results.Value

$ClickResult = $WMIFunctionList | Out-GridView -Title "AdminService WMI Function List" -OutputMode Single
$URI = "Device($($SelectedDevice.ResourceId))/$($ClickResult.Name)"
$Results = Get-WMIResults -URI $URI

#####################################################################


##############################################################
#Get Device Not Equal to CM01 and Select Name only
$URI = "Device?`$filter=Name ne 'CM01'&`$select=Name"
$Results = Get-WMIResults -URI $URI
$Results.Value

#Get Top 2 Devices
$URI = 'Device?$top=2'
$Results = Get-WMIResults -URI $URI
#$Results.Value
$Results.Value.Name

#Find Primary User
$URI = "UserMachineRelationship?`$filter=ResourceName eq 'CM01'"
$Results = Get-WMIResults -URI $URI
$Results.Value
##############################################################


##############################################################

#Get Device
$Filter = StringBuilder -PropertyName "Name" -PropertyValue $ComputerName -Function filter -Operator eq -quote
#$URI = "Device?{0}&select=ResourceId"-f $Filter
$URI = "Device?{0}"-f $Filter
$Results = Get-WMIResults -URI $URI
$Device = $Results.Value
Write-Host ("The Destination Computer Name is: {0} and ResourceID is: {1}" -f $Device.Name,$Device.ResourceID)

#Get Source Computer Name
$Filter = StringBuilder -PropertyName "RestoreClientResourceID" -PropertyValue $Device.ResourceId -Function filter -Operator eq
$URI = "StateMigration?{0}&`$select=SourceName,SourceClientResourceID" -f $filter
$Results = Get-WMIResults -URI $URI
$SourceDevice = $Results.Value
Write-Host ("The Source Computer Name is: {0} and ResourceID is:{1}" -f $SourceDevice.SourceName,$SourceDevice.SourceClientResourceID)

#Collection Membership for SourceComputer
$Filter = StringBuilder -PropertyName "ResourceID" -PropertyValue $SourceDevice.SourceClientResourceID -Function filter -Operator eq
$URI = "FullCollectionMembership?{0}"-f $Filter
$Results = Get-WMIResults -URI $URI
$SourceComputerCollectionList = $Results.Value

$Collections = $SourceComputerCollectionList
[string[]]$AddList = $null

#Application AdministativeCategories
$Filter = StringBuilder -PropertyName "CategoryTypeName" -PropertyValue 'AppCategories' -Function filter -Operator eq -quote
$URI = "CategoryInstance?{0}"-f $Filter
$Results = Get-WMIResults -URI $URI
$AppCategories = $Results.Value


ForEach($Collection in $Collections) {
    #Application Advertisements
    $Filter = StringBuilder -PropertyName "TargetCollectionID" -PropertyValue $Collection.CollectionID -Function filter -Operator eq -quote
    $URI = "ApplicationAssignment?{0}"-f $Filter
    $Results = Get-WMIResults -URI $URI
    $Deployment = $Results.Value

    If($Results.Value)
    {
        Write-Host ("CollectionID {0} has Application {1} Deployed to It. Adding collection to list." -f $Collection.CollectionID, $Deployment.Name)
        $AddList.Add($Collection)
    }
    
}



#Application Advertisements
$URI = "Application"
$Results = Get-WMIResults -URI $URI
$Results.Value
