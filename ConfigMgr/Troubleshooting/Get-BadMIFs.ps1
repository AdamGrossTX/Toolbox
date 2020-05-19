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
