
$ConfigMgrBootWim = "E:\Program Files\Microsoft Configuration Manager\OSD\boot\x64\boot.wim"
$BootImagesPath = "E:\Media\BootImages\"
$NewFolderName = "WinPE1809_20190414"
$MountDir = "F:\Mount"
$CustomFiles = "$($PSScriptRoot)\Custom"
$CustomFolders = Get-ChildItem -Path $CustomFiles
$BootWIMUNC = "\\CM01\Media\BootImages\WinPE1809_20190414\boot.wim"
$SiteCode = "PS1"
$ProviderMachineName = "CM01.asd.net"
$initParams = @{}

Try {
    If(!(Test-Path -Path "$($BootImagesPath)$($NewFolderName)" -ErrorAction SilentlyContinue)) {
        $BootWimPath = New-Item -Path $BootImagesPath  -Name $NewFolderName
    }
    Else {
        $BootWimPath = "$($BootImagesPath)$($NewFolderName)\"
    }

    Copy-Item -Path $ConfigMgrBootWim -Destination $BootWimPath -Force

    Mount-WindowsImage -Path $MountDir -ImagePath "$($BootWimPath)boot.wim" -Index 1
    ForEach ($Folder in $CustomFolders) {
        $Folder | Get-ChildItem | Copy-Item -Destination $MountDir -Container -Recurse -Force
    }
    Dismount-WindowsImage -Path $MountDir -Save

    if((Get-Module ConfigurationManager) -eq $null) {
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
    }

    if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
        New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
    }

    Set-Location "$($SiteCode):\" @initParams

    New-CMBootImage -Path $BootWIMUNC -Index 1 -Name $NewFolderName -Version "1809"
}
Catch {
    
}