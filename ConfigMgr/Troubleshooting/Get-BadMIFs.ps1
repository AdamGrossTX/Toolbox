<#
.SYNOPSIS
    Parses files in the BADMIFs folder and sub folders on the ConfigMgr site server to extract computer names and the type of bad MIF
.DESCRIPTION
    See SYNOPSIS
.PARAMETER ServerName
    Mandatory
    The path to the server where your MIFs are stored
    
.PARAMETER ServerShare
    The share name on the server where the MIFs are stored. 
    Default is e$ because you didn't actually install ConfigMgr on your C drive did you??
    
.PARAMETER ExportPath
    Defaults to the script path '.\'
    
.PARAMETER ShowGrid
    Displays the gridview of results. Disabled by default

.NOTES
  Version:          1.0
  Author:           Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:    05/19/2020
  Purpose/Change:   Initial script development

  More info on MIFS from Umair Kahn
  https://techcommunity.microsoft.com/t5/configuration-manager-archive/configmgr-2012-hardware-inventory-resync-and-badmif-internals/ba-p/339939

    Outdated – The Client send a delta version which was less than what was expected by Dataldr. This causes a resync and it’s then fixed automatically.
    
    DeltaMisMatch – The Client send a delta version which was more than what was expected by Dataldr. This causes a resync and it’s then fixed automatically.

    MajorMisMatch – When there is a Major version mismatch.

    InvalidMachine – Reads the MIF and if cannot find the machine in the DB this will be marked as Invalid. ValidateMachine, FindMachine() are called to check that.

    NonExistentRow – Generally for the resync which came tries to insert the record which is not in the DB. The logs gives the error with the Stored Procedure and the data which it was trying to update.

    GroupFailure – When we are trying to process a MIF and if it fails to add the group for a class then we can get this error. We generally add the group in the GroupMap table which contains the groupname, the respective table name and their history table name along with Architecture. More info on the error in the logs.

    MissingSystemClass – Failed because there was a Class in the MIF which had to reference in the GroupMap i.e. Error is Top Level group not found; expected group with the same name as the architecture .

    InvalidFileName – If the MIF file name is more than 14 characters and the first three letters are (XXX or xxx) then the file is considered as Invalid.

    ExceedSizeLimit – If the MIF file exceeds the size limit (HKLM\Software\Microsoft\SMS\Components\SMS_Inventory_Dataloader\Max MIF Size) then it will be placed here.

    ErrorCode_<Number> – If the MIF file failure is because of any other reasons other than above then it will be placed here. Here <Number> is the ErrorCode for the failure. Log file can help in identifying the cause.
    
#>


Param (
    [parameter(Mandatory)]
    [string]    
    $ServerName,

    [string]    
    $ServerShare = "e$",
        
    [string]    
    $ExportPath = ".\",
    
    [switch]
    $ShowGrid
      
)

$ServerMIFPath = "\\$($ServerName)\$($ServerShare)\Program Files\Microsoft Configuration Manager\inboxes\auth\dataldr.box\BADMIFS"

$DeviceList = @()
$FileList = Get-ChildItem -Path $ServerMIFPath -Include *.MIF -Recurse -Force

If($FileList) {

    ForEach($File in $FileList) {
        Try {
            $Folder = Split-Path -Path $File.Directory -Leaf
            $DeviceName = ($File | Get-Content -ReadCount 1 -TotalCount 6 -ErrorAction Stop  | Select-String -Pattern "//KeyAttribute<NetBIOS\sName><(?<ComputerName>.*)>" -ErrorAction Stop).Matches.Groups[-1].Value
            
            $DeviceList += [PSCustomObject]@{
                Name = $DeviceName
                Type = $Folder
                Path = $File.FullName
            }

        } Catch {
            Write-Warning -Message "Failed for $File"
        }
    }

    If($ShowGrid.IsPresent) {
        $DeviceList | Out-GridView -Title "Devices with Bad MIFs"
    }

    $DeviceList | Export-Csv -Path (Join-Path -Path $ExportPath -ChildPath "BadMIFDeviceList_$(Get-Date -Format yyyymmdd_hhmmss).csv)") -NoTypeInformation -Force
}

Else {
    Write-Host "No Files Found."
}
