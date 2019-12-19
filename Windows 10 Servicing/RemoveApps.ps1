
$ImageMountFolder = "$($RootFolder)\Mount_Image"

$configFile = "$PSScriptRoot\RemoveApps.xml"

Function Remove-InBoxApps {
    Write-Host "Reading list of apps from $configFile"
    $list = Get-Content $configFile
    Write-Host "Apps selected for removal: $list.Count"

    $provisioned = Get-AppxProvisionedPackage -Path $ImageMountFolder
  
    ForEach ($app in $provisioned) {
        Write-Information "Removing provisioned package $app"
        $current = $Provisioned | ? { $_.DisplayName -eq $app }
        
        if ($current)
        {
            Remove-AppxProvisionedPackage -Path $ImageMountFolder -PackageName $current.PackageName
        }
        else
        {
            Write-Warning "Unable to find provisioned package $app"
        }
    }
}