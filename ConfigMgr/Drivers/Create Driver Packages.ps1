#
# Press 'F5' to run this script. Running this script will load the ConfigurationManager
# module for Windows PowerShell and will connect to the site.
#
# This script was auto-generated at '7/26/2018 10:02:16 AM'.

# Uncomment the line below if running in an environment where script signing is 
# required.
#Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Site configuration
$SiteCode = "" # Site code 
$ProviderMachineName = "" # SMS Provider machine name

# Customizations
$initParams = @{}
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

# Do not change anything below this line

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

 get-cmpackage | foreach {
  if ($_.pkgflags -eq ($_.pkgflags -bor 0x80)) {
  Write-host $_.Packageid
  $_ | Set-CMPackage -CopyToPackageShareOnDistributionPoint:$False
  }
}



#Set-Location "c:\"
<#

$PackageSource = "\\DriverPackages\Standard Packages"
$DateFilter = "08/14/2018 00:00:00 AM"

$Sources = Get-ChildItem -Path $PackageSource | where CreationTime -ge $DateFilter

Function Create-Package
{
    New-CMPackage -Name 
}

Function Get-Manufacturer($PathName)
{
    $ManufacturerName = $null
    switch($PathName)
    {
        {$_ -Match "[-]A[0-9][0-9][-]"} {$ManufacturerName = "Dell"; Break;}
        {$_ -Match "^[T][P][_]"} {$ManufacturerName = "Lenovo"; Break;}
        {$_ -like "Surface*"} {$ManufacturerName = "Microsoft"; Break;}
        {$_ -Match "^[H][P][_]"} {$ManufacturerName = "HP"; Break;}
        Default {$ManufacturerName = "Unknown"; Break;}
    }
    Return $ManufacturerName
}

Foreach ($Source in $Sources)
{
    Set-Location "$($SiteCode):\" @initParams
    $ManufacturerName = Get-Manufacturer $Source.Name`

    $ManufacturerName = $null
    $NameParts = $null
    $DriverName = $null
    $DriverVersion = $null
    $NewPackage = $null

    switch($Source.Name)
    {
        {$_ -Match "[-]A[0-9][0-9][-]"} 
            {
                $ManufacturerName = "Dell"
                $NameParts = ($Source.Name).Split("-")
                If($NameParts[1] -eq "AIO") {
                    $DriverName = "$($NameParts[0]) $($NameParts[1])"
                }
                else
                {
                    $DriverName = $NameParts[0]
                }                
                $DriverVersion = "$($NameParts[$NameParts.Count-2])-$($NameParts[$NameParts.Count-1])"
                Break;
            }
        {$_ -Match "^[T][P][_]"}
            {
                $ManufacturerName = "Lenovo"
                $NameParts = ($Source.Name).Split("_")
                $DriverName = $NameParts[1]
                $DriverVersion = "$($NameParts[$NameParts.Count-2])-$($NameParts[$NameParts.Count-1])"
                Break;
            }

        {$_ -like "Surface*"}
            {
                $ManufacturerName = "Microsoft"
                $NameParts = ($Source.Name).Split("_")
                $DriverName = $NameParts[0]
                $DriverVersion = "$($NameParts[$NameParts.Count-3])-$($NameParts[$NameParts.Count-2])-$($NameParts[$NameParts.Count-1])"
                Break;
            }

        {$_ -Match "^[H][P][_]"}
            {
                $ManufacturerName = "HP"
                $NameParts = ($Source.Name).Split("_")
                $DriverName = $NameParts[1]
                $DriverVersion = "$($NameParts[$NameParts.Count-1])"
         
                Break;
            }

        #Default {$ManufacturerName = "Unknown"; Break;}
    }

    Write-Host "########################" -ForegroundColor Green
    Write-Host $DriverName
    Write-Host $Source.Name
    Write-Host $ManufacturerName
    Write-Host $Source.FullName
    Write-Host $DriverName
    Write-Host $DriverVersion

    $Description = "Driver Package"
    $Language = "OSD TS"
    $DistributionPointGroup = "All Distribution Points"

    $DriverName = "$($DriverName) - Windows 10 - $($DriverVersion)"


    $NewPackage = Get-CMPackage -Name $DriverName 
    $NewPackageFiltered = $NewPackage | Where {($_.Description -eq $Description) -and ($_.Name -eq $DriverName) -and ($_.Manufacturer -eq $ManufacturerName) -and ($_.Version -eq $DriverVersion)} 
    
    #$NewPackageFiltered | Set-CMPackage -EnableBinaryDeltaReplication $true

    #$NewPackageFiltered | Start-CMContentDistribution -DistributionPointGroupName $DistributionPointGroup

    #$NewPackageFiltered | Set-CMPackage -NewName "$($DriverName) - Windows 10 - $($DriverVersion)"
    
    #$NewPackage = New-CMPackage -Name $DriverName -Description "CPDesk 4 Driver Package" -Manufacturer $ManufacturerName -Language $Language -Version $DriverVersion -Path $Source.FullName
}


#>
