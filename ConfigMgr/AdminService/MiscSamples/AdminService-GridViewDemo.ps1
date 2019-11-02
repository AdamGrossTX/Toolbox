
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
EXAMPLE - https://<FQDN>/AdminService/wmi/SMS_Collection?$filter=CollectionType%20eq%201 - searches for all collections with CollectionType being 1.
EXAMPLE - https://<FQDN>/AdminService/wmi/SMS_Collection?$filter=CollectionType eq 1

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

[cmdletbinding()]
Param(
    [parameter()]
    [string]
    $ServerName = "CM01" #SCCM Server Name where SMS Provider API is installed
)

$Main = {
    $BaseURI = "https://{0}/AdminService" -f $ServerName
    $WMIURI = "$($BaseURI)/wmi/"
    $ControllerURI = "$($BaseURI)/v1.0/"


    #####################################################################

    #Get WMI Class List
    #$WMIClassList = Get-Results -URI $WMIURI -Filter "`$metadata"
    
    #Get DeviceList
    $DeviceList = Get-Results -URI $WMIURI -Filter "SMS_R_System"
    $SelectedDevice = $DeviceList | Select-Object NetBiosName, ResourceId | Out-GridView -Title "Select A Device" -OutputMode Single

    #$ClickResult = $WMIClassList | Select-Object * | Out-GridView -Title "AdminService WMI Class List" -OutputMode Single
    #$Results = Get-Results -URI $WMIURI -Filter "SMS_R_System($($SelectedDevice.ResourceId))/$($ClickResult.Name)"

    #$Results.Value | Select-Object * | Out-GridView
    #break;

    #####################################################################


    ##############################################################
    #Get Device Not Equal to CM01 and Select Name only
    $DeviceName = $SelectedDevice.NetbiosName
#    $Filter = "SMS_R_System?`$filter=Name ne '$($DeviceName)'&`$select=Name" #Select=Name doesn't work in 1906 but does in 1910 TP
#    $Results = Get-Results -URI $WMIURI -Filter $Filter
#    $Results

    #Get Top 2 Devices
    $Filter = "SMS_R_System?`$top=2"
    $Results = Get-Results -URI $WMIURI -Filter $Filter
    #$Results.Value
    $Results

    #Find Primary User
    $Filter = "SMS_UserMachineRelationship?`$filter=ResourceName eq '$($DeviceName)'"
    $Results = Get-Results -URI $WMIURI -Filter $Filter
    $Results
    ##############################################################


    ##############################################################

    #Get Device
    $Filter = StringBuilder -PropertyName "Name" -PropertyValue $SelectedDevice -Function filter -Operator eq -quote
    $Filter = "SMS_R_System?{0}"-f $Filter
    $Results = Get-Results -URI $WMIURI -Filter $Filter
    $Device = $Results.Value
    Write-Host ("The Destination Computer Name is: {0} and ResourceID is: {1}" -f $Device.Name,$Device.ResourceID)

    #Get Source Computer Name
    $Filter = StringBuilder -PropertyName "RestoreClientResourceID" -PropertyValue $Device.ResourceId -Function filter -Operator eq
    $Filter = "StateMigration?{0}&`$select=SourceName,SourceClientResourceID" -f $filter
    $Results = Get-Results -URI $WMIURI -Filter $Filter
    $SourceDevice = $Results.Value
    Write-Host ("The Source Computer Name is: {0} and ResourceID is:{1}" -f $SourceDevice.SourceName,$SourceDevice.SourceClientResourceID)

    #Collection Membership for SourceComputer
    $Filter = StringBuilder -PropertyName "ResourceID" -PropertyValue $SourceDevice.SourceClientResourceID -Function filter -Operator eq
    $Filter = "FullCollectionMembership?{0}"-f $Filter
    $Results = Get-Results -URI $WMIURI -Filter $Filter
    $SourceComputerCollectionList = $Results.Value

    $Collections = $SourceComputerCollectionList
    [string[]]$AddList = $null

    #Application AdministativeCategories
    $Filter = StringBuilder -PropertyName "CategoryTypeName" -PropertyValue 'AppCategories' -Function filter -Operator eq -quote
    $Filter = "CategoryInstance?{0}"-f $Filter
    $Results = Get-Results -URI $WMIURI -Filter $Filter
    $AppCategories = $Results.Value


    ForEach($Collection in $Collections) {
        #Application Advertisements
        $Filter = StringBuilder -PropertyName "TargetCollectionID" -PropertyValue $Collection.CollectionID -Function filter -Operator eq -quote
        $Filter = "ApplicationAssignment?{0}"-f $Filter
        $Results = Get-Results -URI $WMIURI -Filter $Filter
        $Deployment = $Results.Value

        If($Results.Value)
        {
            Write-Host ("CollectionID {0} has Application {1} Deployed to It. Adding collection to list." -f $Collection.CollectionID, $Deployment.Name)
            $AddList.Add($Collection)
        }
        
    }



    #Application Advertisements
    $Filter = "Application"
    $Results = Get-Results -URI $WMIURI -Filter $Filter
    $Results.Value

    #EndRegion
}


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

Function Get-Results {
    Param (
        $URI,
        $Filter
    )
    $FullURI = "$($URI)$($Filter)"
    Write-Host $FullURI
    $Results = Invoke-RestMethod -Method get -Uri $FullURI -UseDefaultCredentials
    If($Results.GetType().Name -eq "XmlDocument") {
        Return $Results.Edmx.DataServices.Schema.EntityType
    }
    Else {
        Return $Results.Value
    }
}
Function ConvertFrom-Xml {
    param([parameter(Mandatory, ValueFromPipeline)] [System.Xml.XmlNode] $node)
    process {
      if ($node.DocumentElement) { $node = $node.DocumentElement }
      $oht = [ordered] @{}
      $name = $node.Name
      if ($node.FirstChild -is [system.xml.xmltext]) {
        $oht.$name = $node.FirstChild.InnerText
      } else {
        $oht.$name = New-Object System.Collections.ArrayList 
        foreach ($child in $node.ChildNodes) {
          $null = $oht.$name.Add((ConvertFrom-Xml $child))
        }
      }
      $oht
    }
  }
  
& $Main