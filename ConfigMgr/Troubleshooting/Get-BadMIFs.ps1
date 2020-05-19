Param (
    [parameter(Mandatory)]
    [string]    
    $ServerName,

    [string]    
    $ServerShare = "e$",
        
    [string]    
    $ExportPath = ".\",
    
    [switch]
    $ShowGrid=$True
      
)

$ServerMIFPath = "\\$($ServerName)\$($ServerShare)\Program Files\Microsoft Configuration Manager\inboxes\auth\dataldr.box\BADMIFS"

$DeviceList = @()
$FileList = Get-ChildItem -Path $ServerMIFPath -Include *.MIF -Recurse -Force -ErrorAction SilentlyContinue

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

$DeviceList | Export-Csv -Path "$($ExportPath)BadMIFDeviceList_$(Get-Date -Format yyyymmdd_hhmmss).csv" -NoTypeInformation -Force
