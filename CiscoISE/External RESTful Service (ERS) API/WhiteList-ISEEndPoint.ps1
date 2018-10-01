<#
.SYNOPSIS

Interfaces with Cisco ISE 2.2 External RESTful Service (ERS)

.DESCRIPTION

Provides several function to manage Cisco ISE resources

Author
    Adam Gross
    @AdamGrossTX
    http://www.asquaredozen.com
    https://github.com/AdamGrossTX
    https://twitter.com/AdamGrossTX


Version Information
    1.0 - Started with a sample script
    1.1 - First Release
    1.2 - Fixed issues with mandatory parameters Remove parameter

.PARAMETER UserName

Username to ERS Admin account. Must be an Admin account.

.PARAMETER Password

Password to the ERS Admin account.

.PARAMETER WhiteListGroupName

Name of the EndPoint Group on the ISE server that will be used to WhiteList devices.

.PARAMETER Remove

Removes the MAC address EndPoint record from ISE.

.PARAMETER MACAddress

Optional. When specified, this value is used instead of the MAC address for the device where the script is being run.

.PARAMETER ServerName

Optional. Name of ISEServerName. When specified, lookup into ISEServerName.txt file is skipped and this value is used instead.

.EXAMPLE

.\WhiteList-ISEEndPoint.ps1 -UserName "ERSAdmin" -Password "ERSAdminPassword" -WhiteListGroupName "WhiteListGroup" 
#Add current device to WhilteList group
 
.EXAMPLE

.\WhiteList-ISEEndPoint.ps1 -UserName "ERSAdmin" -Password "ERSAdminPassword" -WhiteListGroupName "WhiteListGroup" -MACAddress "11:22:33:44:55:66"
#Add specific device to WhilteList group

.EXAMPLE

.\WhiteList-ISEEndPoint.ps1 -WhiteListGroupName "WhiteListGroup" -UserName "ERSAdmin" -Password "ERSAdminPassword" -ServerName "servername.domain.com"
#Add current device to a whitelist group using a specific servername


.EXAMPLE

.\WhiteList-ISEEndPoint.ps1 -UserName "ERSAdmin" -Password "ERSAdminPassword" -Remove
#Delete current device MAC record from Cisco ISE
    
.EXAMPLE

.\WhiteList-ISEEndPoint.ps1 -UserName "ERSAdmin" -Password "ERSAdminPassword" -Remove -MACAddress "11:22:33:44:55:66"
#Delete specific device MAC record from Cisco ISE

.EXAMPLE

.\WhiteList-ISEEndPoint.ps1 -UserName "ERSAdmin" -Password "ERSAdminPassword" -Remove -ServerName "servername.domain.com"
#Delete current device record from Cisco ISE using a specific servername

.LINK

#Main Blog Post
http://www.asquaredozen.com/2018/07/29/configuring-802-1x-authentication-for-windows-deployment/
#These were resources that I found helpful in writing this script
https://community.cisco.com/t5/security-documents/ise-ers-api-examples/ta-p/3622623
https://www.cisco.com/c/en/us/td/docs/security/ise/1-3/api_ref_guide/api_ref_book/ise_api_ref_ers1.html
https://blogs.technet.microsoft.com/heyscriptingguy/2015/10/08/playing-with-json-and-powershell/

.NOTES
Has Logic to handle Powershell 3.0 and 5.0 web requests.
#>

[cmdletbinding()]
Param(
    [Parameter(Mandatory,
        ParameterSetName='Add',
        Position=0)]
    [Parameter(Mandatory,
        ParameterSetName='Remove',
        Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]$UserName,
    
    [Parameter(Mandatory,
        ParameterSetName='Add',
        Position=1)]
    [Parameter(Mandatory,
        ParameterSetName='Remove',
        Position=1)]
    [ValidateNotNullOrEmpty()]
    [String]$Password,

    [Parameter(Mandatory,
        ParameterSetName='Add',
        Position=2)]
    [ValidateNotNullOrEmpty()]
    [string]$WhiteListGroupName,
    
    [parameter(Mandatory,
        ParameterSetName="Remove",
        Position=2)]
    [ValidateNotNullOrEmpty()]
    [switch]$Remove,

    [Parameter(ParameterSetName='Add',
        Position=3)]
    [Parameter(ParameterSetName='Remove',
        Position=3)]
    [string]$MACAddress,

    [Parameter(ParameterSetName='Add',
        Position=4)]
    [Parameter(ParameterSetName='Remove',
        Position=4)]
    [string]$ServerName
    
)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Script:PSVersion = $PSVersionTable.PSVersion.Major
$Script:ISEGroupName =$WhiteListGroupName
$Script:ISEScriptName = $myInvocation.MyCommand.Name
$Script:ISELogFilePath = "$($PSScriptRoot)\$($ISEScriptName).log"
$Script:ERSEndPointJsonTemplate = @"
    {
        "ERSEndPoint" : {
        "id" : "",
        "name" : "",
        "description" : "",
        "mac" : "",
        "profileId" : "",
        "staticProfileAssignment" : "",
        "groupId" : "",
        "staticGroupAssignment" : "",
        "portalUser" : "",
        "identityStore" : "",
        "identityStoreId" : ""
        }
    }
"@    
Function LogIt {
[cmdletbinding()]
param
(
    [string] $Message,
    [ValidateSet('Info','Warning','Error','Verbose')]
    [string] $Type = 'Info'
)
    If([string]::IsNullOrEmpty($ISELogFilePath)){$Script:ISELogFilePath = "C:\Temp\Log.log"}
    If(!($Message)){$Message=""}
    $Var = (Get-PSCallStack).Command
    $CallingFunction = $Var[1]
    #Write-Host "$($CallingFunction) - $($Type)" | Out-Null
    $LogLevel = Switch($type) {
        "Info" {1; break;}
        "Warning" {2; break;}
        "Error" {3; break;}
        "Verbose" {4; break;}
    }

    $Time = Get-Date -Format "HH:mm:ss.ffffff"
    $Date = Get-Date -Format MM-dd-yyyy
    $Component = "{0}:{1}" -f $ISEScriptName,$CallingFunction

    $LogTemplate = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="{5}" file="{6}">'
    $LogEntries = $Message,$Time,$Date,$Component,$LogLevel,$Pid,$ScriptName
    $LogEntry = $LogTemplate -f $LogEntries
    $LogEntry | Out-File -Append -Encoding UTF8 -FilePath ("filesystem::{0}" -f $ISELogFilePath)
    
    Write-Host "Logging:$($Message)" | Out-Null
}
Function Get-ISECredential {
[cmdletbinding()]
Param(
    [string]$UserName,
    [string]$Password
)
    LogIt "Getting ISE Credentials."
    Try {
        If([string]::IsNullOrEmpty($UserName)) {
            $Credential = Get-Credential
        }
        Else
        {
            $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force;
            $Credential = New-Object Management.Automation.PSCredential($UserName, $SecurePassword);
        }
    }
    Catch {
        LogIt "An error occurred getting credential." -Type Error
        Throw
    }

    If($Credential) {
        LogIt "Finished ISE Credentials."
    }
    Else {
        LogIt "No Credentials Created"
    }
    Return $Credential;
}
Function Set-ISERequestHeaders {
[cmdletbinding()]
Param(
    [ValidateSet("endpoint","endpointgroup")]
    [String]$ResourceType = "endpoint"
)
    $ERSMediaType = Switch($ResourceType)
    {
        "endpoint" {"identity.endpoint.1.2"; break;}
        "endpointgroup" {"identity.endpointgroup.1.0"; break;}
    }

    Try {

        $Auth = "AUTHORIZATION=$($BasicAuthValue)"
        $Accept = "ACCEPT=application/json"
        $Content = "CONTENT-TYPE=application/json"
        $ERS = "ERS-Media-Type=$($ERSMediaType)"

        $Headers = @{}
        $Headers += ConvertFrom-StringData $Auth
        $Headers += ConvertFrom-StringData $Accept
        $Headers += ConvertFrom-StringData $Content
        $Headers += ConvertFrom-StringData $ERS
    }
    Catch {
        LogIt "An error occurred setting Headers." -Type Error
        Throw
    }

    If($Headers) {
        LogIt "Finished getting Headers."
    }
    Else {
        LogIt "No Headers Created"
    }
    Return $Headers;
}
Function Invoke-ISEWebRequest {
    Param
    (
        [ValidateSet("endpoint","endpointgroup","identitygroup")]
        [string]$ResourceType,
        [string]$URI,
        [string]$Method,
        [string]$Body
    )
    $ERSMediaType = Switch($ResourceType)
    {
        "endpoint" {"identity.endpoint.1.2"; break;}
        "endpointgroup" {"identity.endpointgroup.1.0"; break;}
    }

    $WebClient = New-Object System.Net.WebClient;
    $WebClient.headers["AUTHORIZATION"] = "$($BasicAuthValue)"
    $WebClient.headers["ACCEPT"] = "application/json"
    $WebClient.headers["CONTENT-TYPE"] = "application/json"
    $WebClient.headers["ERS-Media-Type"] = "$($ERSMediaType)"
    $Result = Switch($Method) {
        'GET' {ConvertFrom-Json $WebClient.DownloadString($URI); Break;}
        'PUT' {
                ConvertFrom-Json $WebClient.UploadString($URI,"PUT",$Body);
                Break;
                }
        'POST' {
                $WebClient.UploadString($URI,$Body);
                $WebClient.ResponseHeaders[4];
                Break;
                }
        'DELETE'{
                $WebClient.UploadString($URI,"DELETE", "");
                $WebClient.ResponseHeaders;
                Break;
                }
    }
    Return $Result
}
Function Search-ISEResource {
[cmdletbinding()]
Param
(
    [ValidateSet("endpoint","endpointgroup","identitygroup")]
    [string]$ResourceType,
    [ValidateSet("name","id","mac","groupid")]
    [string]$ResourceProperty,
    [ValidateSet("EQ","NEQ","GT","LT","STARTSW","NSTARTSW","ENDSW","NENDSW","CONTAINS","NCONTAINS")]
    [string]$FilterOperator,
    [Parameter(mandatory=$true)]
    [string]$SearchValue,
    [System.Collections.IDictionary]$Headers

)
    Try {
        LogIt "Started Searching for Resource" | Out-Null;
        $SearchURI = "{0}/{1}?filter={2}.{3}.{4}" -f ($ISEBaseURI,$ResourceType,$ResourceProperty,$FilterOperator,$SearchValue)
        If($PSVersion -ge 5) {
            $SearchResult = Invoke-RestMethod -Method Get -Uri $SearchURI -Headers $Headers
        }
        Else {
            $SearchResult = Invoke-ISEWebRequest -Method Get -Uri $SearchURI -ResourceType $ResourceType
        }
        If($SearchResult.SearchResult.total -eq 0) {
            LogIt "Resource Not Found" -Type Error
            $Resource = $null
        }
        Else {
            $Headers = Switch($ResourceType)
            {
                "endpoint" {$ERSEndPointHeaders; break;}
                "endpointgroup" {$EndPointGroupHeaders; break;}
            }
            $Resource = Get-ISEResource -ResourceURI $SearchResult.SearchResult.resources[0].link.href -ResourceType $ResourceType -Headers $Headers
        }
    }
    Catch {
        LogIt "An error occurred Searching for Resource." -Type Error
        Throw
    }

    If($Headers) {
        LogIt "Finished searching for Resource."
    }
    Else {
        LogIt "No Resoure Found."
    }

    Return $Resource
    
}
Function Get-ISEResource {
[cmdletbinding()]
Param
(
    [Parameter(mandatory=$true)]
    [string]$ResourceURI,
    [ValidateSet("endpoint","endpointgroup","identitygroup")]
    [string]$ResourceType,
    [System.Collections.IDictionary]$Headers
)
    Logit "Getting ISE Resource"
    Try {
        If($PSVersion -ge 5) {
            $Resource = Invoke-RestMethod -Method Get -Uri $ResourceURI -Headers $Headers
        }
        Else {
            $Resource = Invoke-ISEWebRequest -Method Get -Uri $ResourceURI -ResourceType $ResourceType
        }
    }
    Catch {
        LogIt "An error occurred getting ISE Resource."
        Throw
    }
    If ($Resource)
    {
        Logit "Finished Getting ISE Resource"
    }
    Else {
        LogIt "No ISE Resource Found."
    }
    Return $Resource
}
Function Update-ISEResource {
[cmdletbinding()]
Param
(
    [Parameter(mandatory=$true)]
    [string]$ResourceURI,
    [ValidateSet("endpoint","endpointgroup","identitygroup")]
    [string]$ResourceType,
    [Parameter(mandatory=$true)]
    [string]$ResourceBody,
    [System.Collections.IDictionary]$Headers
)
    Logit "Updating ISE Resource"
    Try {
        If($PSVersion -ge 5) {
            $UpdateResult = Invoke-RestMethod -Method Put -Uri $ResourceURI -Headers $Headers -Body $ResourceBody
        }
        Else {
            $UpdateResult = Invoke-ISEWebRequest -Method Put -Uri $ResourceURI -Body $ResourceBody -ResourceType $ResourceType
        }
    }
    Catch {
        LogIt "An error occurred updating ISE Resource."
        Throw
    }
    If ($UpdateResult)
    {
        Logit "Result $($UpdateResult.UpdatedFieldsList.UpdatedField)"
        Logit "Finished Updating ISE Resource"    
    }
    Else {
        LogIt "No Updates made to Resource."
    }
    Return $UpdateResult
}
Function Remove-ISEResource {
[cmdletbinding()]
Param
(
    [Parameter(mandatory=$true)]
    [string]$ResourceURI,
    [ValidateSet("endpoint","endpointgroup","identitygroup")]
    [string]$ResourceType,
    [System.Collections.IDictionary]$Headers

)
    Logit "Removing ISE Resource"
    Try {
        If($PSVersion -ge 5) {
            $DeleteResult = Invoke-WebRequest -Method Delete -Uri $ResourceURI -Headers $Headers
        }
        Else {
            $DeleteResult = Invoke-ISEWebRequest -Method Delete -Uri $ResourceURI -ResourceType $ResourceType
        }
    }
    Catch {
        LogIt "An error occurred updating ISE Resource."
        Throw
    }
    If ($DeleteResult)
    {
        Logit "Finished Removing ISE Resource"
    }
    Else {
        LogIt "Resource removal did not return a result."
    }
    
    Return $DeleteResult
}
Function New-ISEResource {
[cmdletbinding()]
Param
(
    [ValidateSet("endpoint","endpointgroup","identitygroup")]
    [string]$ResourceType,
    [Parameter(mandatory=$true)]
    [string]$NewResourceObject,
    [System.Collections.IDictionary]$Headers

)
    LogIt "Creating ISE Resource"
    Try {
        #$Headers = Get-ISERequestHeaders -RequestType Post -ResourceType $ResourceType
        $CreateURI = "{0}/{1}" -f ($ISEBaseURI,$ResourceType)
        If($PSVersion -ge 5) {
            $NewResource = Invoke-WebRequest -Method Post -Uri $CreateURI -Headers $Headers -Body $NewResourceObject -UseBasicParsing
            $ResultSet =@{}
            $ResultSet = ConvertFrom-StringData $NewResource.RawContent.Replace('=','XXX').Replace(': ','=').Replace("HTTP/1.1","Result=HTTP/1.1").Replace('XXX','=')
            $Resource = Get-ISEResource -ResourceURI $ResultSet.Location -ResourceType $ResourceType -Headers $ERSEndPointHeaders
        }
        Else {
            $NewResource = Invoke-ISEWebRequest -Method Post -Uri $CreateURI -Headers $Headers -Body $NewResourceObject -ResourceType $ResourceType
            $Resource = Get-ISEResource -ResourceURI $NewResource[1] -ResourceType $ResourceType -Headers $ERSEndPointHeaders
        }
        
    }
    Catch {
        LogIt "An error occurred creating resource."
        Throw
    }
    If ($Resource)
    {
        LogIt "Finished Creating ISE Resource"
    }
    Else {
        LogIt "No Resource Created"
    }
    Return $Resource
}
Function Get-ISEServerName {
[cmdletbinding()]
Param
(
)
    LogIt "Getting ISE Server Name"
    Try {        
        $ServerList = Import-Csv -Path ".\ISEServerList.txt"
        $Gateway = [string](Get-WmiObject Win32_networkAdapterConfiguration -Filter 'IPEnabled = True' -ErrorAction Stop | Where-Object { $null -ne $_.DefaultIPGateway } | Select-Object -ExpandProperty DefaultIPGateway | Select-Object -First 1)
        if ($Gateway -ne $null) {
            $Match = $ServerList -match $Gateway
            If($Match)
            {
                $ServerName = $Match.ISEServerName
                Logit -Message "ISE Server Found - $($ServerName)" -Type Error
            }
            Else {
                Logit -Message "No Gateway Found. Using Default" -Type Error
                $ServerName = [string]($ServerList | Where-Object Gateway -eq '0.0.0.0' | Select-Object -First 1 -ExpandProperty ISEServerName)
            }
        }       
    }
    Catch {
        LogIt "An error occurred getting servername."
        Throw
    }
    If ($ServerName) {
        LogIt "Finished Getting ISE Server Name"  
    }
    Else {
        LogIt "No ISEServer found" -Type Warning
    }
              
    Return $ServerName
}

Try {
        
    $Script:ISECredential = Get-ISECredential -UserName $UserName -Password $Password -ErrorAction Stop
    $Script:BasicAuthValue = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $ISECredential.GetNetworkCredential().UserName,$ISECredential.GetNetworkCredential().Password)))
    $BasicAuthValue = "Basic $($BasicAuthValue)"

    If($ServerName) {
        $Script:ISEServerName = $ServerName
    }
    Else {
        $Script:ISEServerName = Get-ISEServerName -ErrorAction Stop
    }

    If($MACAddress) {
        $Script:ISEMACAddress = $MACAddress
    }
    Else {
        $Script:ISEMACAddress = [string]((Get-WmiObject Win32_networkAdapterConfiguration -Filter 'IPEnabled = True' -ErrorAction Stop | Where-Object { $_.DefaultIPGateway -ne $null -and $_.DefaultIPGateway -ne "0.0.0.0" -and $_.DHCPEnabled -eq $True} | Select-Object -First 1 -ExpandProperty MacAddress).Replace("-",":"))
    }
    $Script:ISEBaseURI = "https://$($ISEServerName):9060/ers/config"
    
    $Script:ERSEndPointHeaders = Set-ISERequestHeaders -ResourceType endpoint
    $Script:EndPointGroupHeaders = Set-ISERequestHeaders -ResourceType endpointgroup

    $ERSEndPoint = Search-ISEResource -ResourceType endpoint -ResourceProperty mac -FilterOperator EQ -SearchValue $ISEMACAddress -Headers $ERSEndPointHeaders -ErrorAction Stop
    If(!$Remove) {
        $EndPointGroup = Search-ISEResource -ResourceType endpointgroup -ResourceProperty name -FilterOperator EQ -SearchValue $ISEGroupName -Headers $EndPointGroupHeaders  -ErrorAction Stop
    }
    If(!($Remove) -and ($null -eq $ERSEndPoint) -and $EndPointGroup) {
        $NewERSEndPoint = $ERSEndPointJsonTemplate | ConvertFrom-Json
        $NewERSEndPoint.ERSEndPoint.name = $ISEMACAddress
        $NewERSEndPoint.ERSEndPoint.mac = $ISEMACAddress
        $NewERSEndPoint.ERSEndPoint.staticGroupAssignment = "false"
        $NewERSEndPoint.ERSEndPoint.staticProfileAssignment = "false"
        $NewERSEndPoint.ERSEndPoint.groupId = $EndPointGroup.EndPointGroup.id
        $NewERSEndPoint = $NewERSEndPoint | ConvertTo-Json
        $ERSEndPoint = New-ISEResource -ResourceType endpoint -NewResourceObject $NewERSEndPoint -Headers $ERSEndPointHeaders
    }
    
    If($ERSEndPoint) {
        LogIt "ERSEndPoint: $($ERSEndPoint.ERSEndPoint.name) : $($ERSEndPoint.ERSEndPoint.groupid) : $($ERSEndPoint.ERSEndPoint.link.href)"
        $ERSEndPointURI = $ERSEndPoint.ERSEndPoint.link.href

        If($Remove) {
            $RemoveResult = Remove-ISEResource -ResourceURI $ERSEndPointURI -ResourceType endpoint -Headers $ERSEndPointHeaders
            Logit "Remove Status: $($RemoveResult.StatusCode)"
        }
        ElseIf ($EndPointGroup) {
            LogIt "EndPointGroup: $($EndPointGroup.EndPointGroup.name) : $($EndPointGroup.EndPointGroup.id) : $($EndPointGroup.EndPointGroup.link.href)"
            $EndPointGroupName = $EndPointGroup.EndPointGroup.name        
            $EndPointGroupId = $EndPointGroup.EndPointGroup.id
            $CurrentGroupId = $ERSEndPoint.ERSEndPoint.groupId
            If($EndPointGroupId -ne $CurrentGroupId) {
                LogIt "Currently in group $CurrentGroupId"
                LogIt "Target group $($EndPointGroupName) - $($EndPointGroupId)"
                $UpdatedERSEndPoint = $ERSEndPoint
                $UpdatedERSEndPoint.ERSEndPoint.groupId = $EndPointGroupId
                $UpdatedERSEndPoint.ERSEndPoint.staticGroupAssignment = "true"
                $UpdatedERSEndPoint.ERSEndPoint.staticProfileAssignment = "false"
                $UpdatedERSEndPoint.ERSEndPoint.link.href
                $UpdatedERSEndPoint = $UpdatedERSEndPoint | ConvertTo-Json
                $AddToGroupResult = Update-ISEResource -ResourceURI $ERSEndPointURI -ResourceType endpoint -ResourceBody $UpdatedERSEndPoint -Headers $ERSEndPointHeaders
                LogIt "$($AddToGroupResult)"
            }
            Else {
                Logit "Resource is already in the group" -Type Warning
            }
        }
        Else {
            LogIt "No Group Found."
        }
    }
    Else {
        LogIt "No Resource Found."
    }
    
}
Catch {
    Logit $Error[0] -Type Error
}