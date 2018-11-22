<#

    .SYNOPSIS

        Service your Windows WIM with monthly updates.

    .DESCRIPTION
        
        To use the Dynamic Updates feature, you must have Dynamic Updates enabled in SCCM, otherwise the script won't find the updates. If you have
        an alternate method to get the updates, just modify the script to handle that. Hopefully I can get a Windows Update URL to use instead of
        querying SCCM.

        You will have to pre-download you SSU, LCU and Flash Updates from the Windows Update Catalog.

        The base script components were stolen from Johan Arwidmark @jarwidmark and bits and pieces from others along the way. 
        Also, thanks to Johan for mentioning this script at Microsoft Ignite 2018 in the BRK2288 and BRK4028 sessions.

        If you want an ultimate, hands-off seriving tool, please take a look at David Segura's (@SeguraOSD) OSBuilder tool.
        It does EVERYTHING and is way better than this!
        http://www.OSDeploy.com

        Special Thanks to Gary Blok and Mike Terrill for their tireless efforts to solve the Dynamic Updates issue!
        
    .NOTES

        Author: Adam Gross

        Twitter: @AdamGrossTX


    .LINK
        https://keithga.wordpress.com/2017/05/21/new-tool-get-the-latest-windows-10-cumulative-updates/
        https://stealthpuppy.com/powershell-download-import-updates-mdt/#.W3hFn_ZFyOc
        
    .History

        1.0 - Original

        1.1 - Fixed bugs
        
        1.2 - Added better folder creation logic and messaging. - (This version is being tested right now 08/21/2018 3:20 PM CST)
        
        1.3 - Updated params for defaults
        
        1.4 - Added Mandatory flags to some params

        1.5 - Added fix for 2018-09 SetupUpdates not being classified correctly.
        
        1.6 - Added $Optimize switch (set to false by default) to remove -Optimize switch to address issues with Windows 10 1809 (11/21/2018)
    
#>

Param
(
    [Parameter(Position=0, HelpMessage="Operating System Name to be serviced.")]
    [ValidateSet("Windows 10 Education","Windows 10 Education N","Windows 10 Enterprise","Windows 10 Enterprise N","Windows 10 Pro","Windows 10 Pro N")]
    [string]$OSName = "Windows 10 Enterprise",

    [Parameter(Position=1, HelpMessage="Operating System version to service. Default is 1709.")]
    [ValidateSet('1709','1803','1809')]
    [string]$OSVersion = "1803",

    [Parameter(Position=2, HelpMessage="Architecture version to service. Default is x64.")]
    [ValidateSet ('x64', 'x86','ARM64')]
    [string]$OSArch = "x64",   

    [Parameter(Position=3, HelpMessage="Year-Month of updates to apply (Format YYYY-MM). Default is 2018-08.")]
    [ValidatePattern("\d{4}-\d{2}")]
    [string]$Month = "2018-09",

    [Parameter(Mandatory=$true, Position=4, HelpMessage="Path to working directory for servicing data. Default is C:\ImageServicing.")]
    [string]$RootFolder = "C:\ImageServicing",

    [Parameter(Mandatory=$true, Position=5, HelpMessage="SCCM Primary Server Name.")]
    [string]$SCCMServer,

    [Parameter(Mandatory=$true, Position=6, HelpMessage="SCCM Site Code.")]
    [string]$SiteCode,

    [Parameter(Mandatory=$true, Position=7, HelpMessage="Change path here to ADK dism.exe if your OS version doesn't match ADK version. Default dism.exe.")]
    [string]$DISMPath = "Dism.exe",
    
    [Parameter(HelpMessage="Outputs fully serviced media.")]
    [switch]$CreateProdMedia = $True,

    [Parameter(HelpMessage="Optionally apply Dynamic Updates to Install.wim and Sources for InPlace Upgrade compatibility.")]
    [switch]$ApplyDynamicUpdates = $True,

    [Parameter(HelpMessage="Delete temp folders and patches.")]
    [switch]$Cleanup = $false,

    [Parameter(HelpMessage="This is set to false by default to prevent issues with Windows 10 1809. Set to true for other OS builds.")]
    [switch]$Optimize = $false

)

#Setup
##################################################

$VerbosePreference="Continue"
$ErrorActionPreference="Stop"

$DownloadList = @()

$DisplayNameFilter = "*$($OSVersion)*$($OSArch)*"

$ISOPath = "$($RootFolder)\ISO\$($OSVersion)"
$UpdatesPath = "$($RootFolder)\Updates\$($OSVersion)\$($Month)\$($OSArch)"
$LCUPath = "$($UpdatesPath)\LCU"
$SSUPath = "$($UpdatesPath)\SSU"
$FlashPath = "$($UpdatesPath)\Flash"

If(!(Test-Path -path $ISOPath)) {New-Item -path $ISOPath -ItemType Directory; Write-Warning "Please place an ISO for your selected OS into this folder: $($ISOPath) then retry. Existing script.";Break}
if (!(Test-Path -path $SSUPath)) {New-Item -path $SSUPath -ItemType Directory}
if (!(Test-Path -path $FlashPath)) {New-Item -path $FlashPath -ItemType Directory}
If (!(Test-Path -path $LCUPath)) {New-Item -path $LCUPath -ItemType Directory}
If(!(Test-Path -path $UpdatesPath)) {New-Item -path $UpdatesPath -ItemType Directory; Write-Warning "Please Download your SSU, LCU, and Flash Updates to : $($UpdatesPath) then retry. Existing script.";Break}
If(!(Get-ChildItem -Path $ISOPath -Filter "*.ISO")) {Write-Warning "No ISO Found in: $($ISOPath)";Break}
If(!(Get-ChildItem -Path $UpdatesPath -Filter "*.MSU" -Recurse)) {Write-Warning "No Updates Found in: $($UpdatesPath)";Break}

$DUSUPath = "$($UpdatesPath)\SetupUpdate"
$DUCUPath = "$($UpdatesPath)\ComponentUpdate"

$ISO = Get-ChildItem -Path $ISOPath -Filter "*.ISO" | Select -ExpandProperty FullName

$LCU = Get-ChildItem -Path "$($LCUPath)" -Filter "*.MSU" | Select -ExpandProperty FullName
$SSU = Get-ChildItem -Path "$($SSUPath)" -Filter "*.MSU" | Select -ExpandProperty FullName
$Flash = Get-ChildItem -Path "$($FlashPath)" -Filter "*.MSU" | Select -ExpandProperty FullName

$ImageMountFolder = "$($RootFolder)\Mount_Image"
$BootImageMountFolder = "$($RootFolder)\Mount_BootImage"
$WinREImageMountFolder = "$($RootFolder)\Mount_WinREImage"
$WIMImageFolder = "$($RootFolder)\WIM_Output\$($OSVersion)\$($Month)\$($OSArch)"
$OriginalBaseMediaFolder = "$($RootFolder)\OriginalBaseMedia\$($OSVersion)\$($OSArch)"
$CompletedMediaFolder = "$($RootFolder)\CompletedMedia\$($OSVersion)\$($Month)\$($OSArch)"

$TmpInstallWIM = "$WIMImageFolder\tmp_install.wim"
$TmpWinREWIM = "$WIMImageFolder\tmp_winre.wim"
$TmpBootWIM = "$WIMImageFolder\tmp_boot.wim"

$InstallWIM = "$WIMImageFolder\install.wim"
$BootWIM = "$WIMImageFolder\boot.wim"
$WinREWIM = "$WIMImageFolder\winre.wim"

$exclude = @('install.wim','boot.wim')

#Functions
##################################################
Function Check-Paths {
    $Error.Clear()
    Try {
        Write-Host "Checking for folders and creating them if they don't exist" -ForegroundColor Green
        if (!(Test-Path -path $ISO)) {Write-Warning "Could not find Windows 10 ISO file. Aborting...";Break}
        if (!(Test-Path -path $SSUPath)) {New-Item -path $SSUPath -ItemType Directory}
        if (!(Test-Path -path $FlashPath)) {New-Item -path $FlashPath -ItemType Directory}
        if (!(Test-Path -path $LCUPath)) {New-Item -path $LCUPath -ItemType Directory}
        if (!(Test-Path -path $DUSUPath)) {New-Item -path $DUSUPath -ItemType Directory}
        if (!(Test-Path -path $DUCUPath)) {New-Item -path $DUCUPath -ItemType Directory}
        if (!(Test-Path -path $ImageMountFolder)) {New-Item -path $ImageMountFolder -ItemType Directory}
        if (!(Test-Path -path $BootImageMountFolder)) {New-Item -path $BootImageMountFolder -ItemType Directory}
        if (!(Test-Path -path $WinREImageMountFolder)) {New-Item -path $WinREImageMountFolder -ItemType Directory}
        if (!(Test-Path -path $WIMImageFolder)) {New-Item -path $WIMImageFolder -ItemType Directory}
        if (!(Test-Path -path $OriginalBaseMediaFolder)) {New-Item -path $OriginalBaseMediaFolder -ItemType Directory}
        if (!(Test-Path -path $CompletedMediaFolder)) {New-Item -path $CompletedMediaFolder -ItemType Directory}
  
        if(!($SSU)) {Write-Warning "Could not find Servicing Update for Windows 10. Aborting...";Break;}
        if(!($LCU)) {Write-Warning "Could not find Monthly Update for Windows 10. Aborting...";Break;}
        if(!($Flash)) {Write-Warning "Could not find Adobe Flash Update for Windows 10. Aborting...";Break;}
    }
    Catch
    {
        Write-Host "Check Paths failed."
        Throw $Error
    }
}

Function Check-OSVersion {
    $Error.Clear()
    Try {
        Write-Host "Checking OS Version" -ForegroundColor Green
        $OSCaption = (Get-WmiObject win32_operatingsystem).caption

        If (!($OSCaption -like "Microsoft Windows 10*") -and !($OSCaption -like "Microsoft Windows Server 2016*"))
        {
            Write-Warning "$Env:Computername Oops, you really should use Windows 10 or Windows Server 2016 when servicing Windows 10 offline"
            Write-Warning "$Env:Computername Aborting script..."
            Break;
        } 
    }
    Catch
    {
        Write-Warning "Check OS Version failed."
        Throw $Error
    }
}

Function Get-DynamicUpdates {
    $Error.Clear()
    Try {
        Write-Host "Getting Dynamic Updates." -ForegroundColor Green

        #Delete Any existing updates

        Get-ChildItem $DUCUPath | Remove-Item -Recurse -Force
        Get-ChildItem $DUSUPath | Remove-Item -Recurse -Force

        $DownloadList = @()

        $AllDynamicUpdatesFilter = 'LocalizedCategoryInstanceNames = "Windows 10 Dynamic Update"'

        $DisplayNameFilter = "*$($OSVersion)*$($OSArch)*"

        $AllDynamicUpdates = Get-WmiObject -ComputerName $SCCMServer -Class SMS_SoftwareUpdate -Namespace "root\SMS\Site_$($SiteCode)" -Filter $AllDynamicUpdatesFilter

        $FilteredUpdateList = $AllDynamicUpdates | Where {$_.LocalizedDisplayName -like $DisplayNameFilter -and $_.IsSuperseded -eq $False -and $_.IsLatest -eq $True}

        ForEach ($Update in $FilteredUpdateList)
        {

            $ContentIDs = Get-WmiObject -ComputerName $SCCMServer -Class SMS_CIToContent -Namespace "root\SMS\Site_$($SiteCode)" -Filter "CI_ID = $($Update.CI_ID)"

            ForEach ($ContentID in $ContentIDs) {

                $Content = Get-WmiObject -ComputerName $SCCMServer -Class SMS_CIContentFiles -Namespace "root\SMS\Site_$($SiteCode)" -Filter "ContentID = $($ContentID.ContentID)"
            
                $DownloadList  += New-Object PSObject -Property:@{
                'ArticleID' = $Update.ArticleID;
                'CI_ID' = $Update.CI_ID;
                'DisplayName' = $Update.LocalizedDisplayName;
                'ContentID' = $ContentIDs.ContentID;
                'FileName' = $Content.FileName;
                'URL' = $Content.SourceURL;
                'Type' = If(($Update.ArticleID -eq "4457190") -or ($Update.ArticleID -eq "4457189")) {"SetupUpdate"} Else {$Update.LocalizedDescription.Replace(":","")}
                }
            }
        }

        ForEach ($File in $DownloadList)
        {
            $Path = $Null
            #Fix for September SetupUpdate not containing the correct text to classify propery.
            If($File.FileName -like "*KB4457190*" -or $File.FileName -like "*KB4457189*") {
                $Path = "$($DUSUPath)\$($File.FileName)"
            }
            Else {
                switch ($File.Type)
                {
                    SetupUpdate {$Path = "$($DUSUPath)\$($File.FileName)"; break;}
                    ComponentUpdate {$Path = "$($DUCUPath)\$($File.FileName)"; break;}
                    Default {$Path = "$($UpdatesPath)\$($File.FileName)"; break;}
                }
            }
            Invoke-WebRequest -Uri $File.URL -OutFile $Path -ErrorAction Continue
        }

        $SUFiles = Get-ChildItem -Path $DUSUPath

        ForEach ($File in $SUFiles)
        {
            $ExtractFolder = "$($DUSUPath)\$($File.Name.Replace('.cab',''))\"
            New-Item -path $ExtractFolder -ItemType Directory
            & Expand "$($File.FullName)" -F:* $ExtractFolder
        }
    }
    Catch
    {
        Write-Warning "Get Dynamic Updates failed."
        Throw $Error
    }

}

Function Apply-Patches {
param
(
    [string]$MountFolder,
    [switch]$ApplyDotNET=$False,
    [switch]$ApplySSU=$False,
    [switch]$ApplyFlash=$False,
    [switch]$ApplyLCU=$False,
    [switch]$ApplyDUCU=$False,
    [switch]$CleanWIM=$False

)
    $Error.Clear()

    Write-Host "Applying patches to WIM $($MountFolder)." -ForegroundColor Green
    Write-Host "Selected Options:" -ForegroundColor Green
    Write-Host "ApplyDotNET: $($ApplyDotNET)" -ForegroundColor Green
    Write-Host "ApplySSU: $($ApplySSU)" -ForegroundColor Green
    Write-Host "ApplyFlash: $($ApplyFlash)" -ForegroundColor Green
    Write-Host "ApplyLCU: $($ApplyLCU)" -ForegroundColor Green
    Write-Host "ApplyDUCU: $($ApplyDUCU)" -ForegroundColor Green
    Write-Host "CleanWIM: $($CleanWIM)" -ForegroundColor Green
    
    Try
    {
        if($ApplyDotNET)
        {
            Write-Host "Enabling .NET 3.5" -ForegroundColor Green
            & $DISMPath /Image:$MountFolder /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:"$($OriginalBaseMediaFolder)\sources\sxs"
        }
    
        if($ApplySSU)
        {
            Write-Host "Applying SSU" -ForegroundColor Green
            Add-WindowsPackage -PackagePath $SSU -Path $MountFolder        
        }

        if($ApplyFlash)
        {
            Write-Host "Applying Flash" -ForegroundColor Green
            Add-WindowsPackage -PackagePath $Flash -Path $MountFolder
        }

        if($ApplyLCU)
        {
            Write-Host "Applying LCU" -ForegroundColor Green
            Add-WindowsPackage -PackagePath $LCU -Path $MountFolder
        }

        if($ApplyDUCU)
        {
            If($ApplyDynamicUpdates) #Only apply DU is specified in the script params. Default is True.
            {
                Write-Host "Applying Dynamic Component Updates" -ForegroundColor Green
                #Get All Dynamic Cumulative Updates
                $DUCU = Get-ChildItem -Path "$($DUCUPath)" -Filter "*.CAB" | Select -ExpandProperty FullName

                $Count = 0
                $DUCU.Count
                #Recurse All Updates in DUCUPath
                ForEach($CAB in $DUCU) {
                    Write-Host "Applying Dynamic Component Update $($Count + 1) of $($DUCU.Count)" -ForegroundColor Green
                    Add-WindowsPackage -PackagePath $CAB -Path $ImageMountFolder
                }
            }
        } 

        if($CleanWIM)
        {
            Write-Host "Running Cleanup and ResetBase" -ForegroundColor Green
            & $DISMPath /Image:$MountFolder /cleanup-image /startcomponentcleanup /resetbase
        }
    }
    Catch
    {
        Write-Warning "Apply Patches failed."
        Throw $Error
    }

}

Function Get-BaseMedia {
    $Error.Clear()
    try
    {
        #Mount Windows ISO and extract media into the OriginalBaseMediaFolder
        If(!(Get-ChildItem $OriginalBaseMediaFolder)) {
            Write-Host "Extracting ISO Media" -ForegroundColor Green
            Mount-DiskImage -ImagePath $ISO
            $ISOImage = Get-DiskImage -ImagePath $ISO | Get-Volume
            $ISODrive = [string]$ISOImage.DriveLetter+":"
            Get-ChildItem -Path "$($ISODrive)\" | Copy-Item -Destination $OriginalBaseMediaFolder -Recurse -Force
            Dismount-DiskImage -ImagePath $ISO 
        }


        #Remove Any tmp files before starting
        If($Cleanup) 
        {
            Get-Item $InstallWIM | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Get-Item $BootWIM | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Get-Item $TmpInstallWIM | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Get-Item $TmpWinREWIM | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Get-Item $TmpBootWIM | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
       }

        #Copy base media to completed media folder - note, that install.wim and boot.wim are not updateded at this stage 
        Get-ChildItem $OriginalBaseMediaFolder | Copy-Item -Destination $CompletedMediaFolder -exclude $exclude -Recurse -Force
        
        #Export the Windows index we want to Service
        Export-WindowsImage -SourceImagePath "$($OriginalBaseMediaFolder)\Sources\install.wim" -SourceName $OSName -DestinationImagePath $TmpInstallWIM
    
        #Copy boot.wim and to temp location
        Copy-Item "$OriginalBaseMediaFolder\Sources\boot.wim" $TmpBootWIM -Force
        & Attrib -r $TmpBootWIM

        If($ApplyDynamicUpdates)
        {
            #Get all SetupUpdate Dynamic Update contents and apply them to the Completed Sources folder
            $DUSUContents = Get-ChildItem -Path $DUSUPath -Directory
            ForEach ($Folder in $DUSUContents)
            {
                Copy-Item -Path "$($Folder.FullName)\*" -Destination "$($CompletedMediaFolder)\Sources" -Container -Force -Recurse
           
            }
        }
                
    }
    Catch
    {
        Write-Warning "Extract ISO Media failed."
        Throw $Error
    }
}

Function Patch-BootWIM {
    $Error.Clear()
    try{
        Write-Host "Patching Boot WIM" -ForegroundColor Green
        #Mount current WIM and fully patch
        
        #Uncomment to patch WinPE.wim
        #Mount-WindowsImage -ImagePath $TmpBootWIM -Index 1 -Path $BootImageMountFolder
        #Apply-Patches -MountFolder $BootImageMountFolder -ApplySSU -ApplyLCU -CleanWIM
        #Save-WindowsImage -Path $BootImageMountFolder
        #DisMount-WindowsImage -Path $BootImageMountFolder -Save
     
        
        #Boot WIM
        Mount-WindowsImage -ImagePath $TmpBootWIM -Index 2 -Path $BootImageMountFolder
        Apply-Patches -MountFolder $BootImageMountFolder -ApplySSU -ApplyLCU -CleanWIM
        DisMount-WindowsImage -Path $BootImageMountFolder -Save
        Copy-Item -Path $TmpBootWIM -Destination $BootWIM -Force
        ####
    }
    catch
    {
        Write-Warning "Boot WIM patching failed"
        Throw $Error
    }
}

Function Patch-WinREWIM {
    $Error.Clear()
    try{
        Write-Host "Patching WinRE WIM" -ForegroundColor Green
        #WinRE
        If(!(Test-Path $ImageMountFolder)) 
        {
            Write-Warning "No Install.WIM mounted. Please mount Install.WIM and try again."
            Break;
        }
        Else
        {
            Move-Item -Path $ImageMountFolder\Windows\System32\Recovery\winre.wim -Destination $TmpWinREWIM -Force
            Mount-WindowsImage -ImagePath $TmpWinREWIM -Index 1 -Path $WinREImageMountFolder
            Apply-Patches -MountFolder $WinREImageMountFolder -ApplySSU -ApplyLCU -CleanWIM
            DisMount-WindowsImage -Path $WinREImageMountFolder -Save
            Export-WindowsImage -SourceImagePath $TmpWinREWIM -SourceName "Microsoft Windows Recovery Environment (x64)" -DestinationImagePath $WinREWIM
            Copy-Item -Path $WinREWIM -Destination $ImageMountFolder\Windows\System32\Recovery\winre.wim -Force
        }
    }
    catch
    {
        Write-Warning "WinRE WIM patching failed"
        Throw $Error
    }
}

Function Patch-InstallWIM {
    $Error.Clear()
    try{
        Write-Host "Patching Install WIM" -ForegroundColor Green

        If ($Optimize) {
            Mount-WindowsImage -ImagePath $TmpInstallWIM -Index 1 -Path $ImageMountFolder -Optimize
        }
        Else
        {
            Mount-WindowsImage -ImagePath $TmpInstallWIM -Index 1 -Path $ImageMountFolder -Optimize
        }
        
        Patch-WinREWIM

        Apply-Patches -MountFolder $ImageMountFolder -ApplySSU -ApplyLCU -ApplyFlash -CleanWIM
        Apply-Patches -MountFolder $ImageMountFolder -ApplyDotNET -ApplyLCU -ApplyDUCU
        
        DisMount-WindowsImage -Path $ImageMountFolder -Save
        Export-WindowsImage -SourceImagePath $TmpInstallWIM -SourceName $OSName -DestinationImagePath $InstallWIM
       
    }
    catch
    {
        Write-Warning "Install WIM patching failed"
        Throw $Error
    }    
}

Function Create-ProductionMedia {
    $Error.Clear()
    try {
        Write-Host "Creating Production Media" -ForegroundColor Green
        
        Get-BaseMedia
        
        Patch-InstallWIM
        Patch-BootWIM
 
        Copy-Item -Path $InstallWIM -Destination "$($CompletedMediaFolder)\Sources" -Container -Force
        Copy-Item -Path $BootWIM -Destination "$($CompletedMediaFolder)\Sources" -Container -Force
        
        
    }
    catch
    {
        Write-Warning "Creating Production Media failed"
        Throw $Error
    }
}

Function Cleanup {
    Try {
        Write-Host "Cleaning Up" -ForegroundColor Green
        if (Test-Path -path $TmpInstallWIM) {Remove-Item -Path $TmpInstallWIM -Force -ErrorAction Continue}
        if (Test-Path -path $TmpBootWIM) {Remove-Item -Path $TmpBootWIM -Force -ErrorAction Continue}
        if (Test-Path -path $TmpWinREWIM) {Remove-Item -Path $TmpWinREWIM -Force -ErrorAction Continue}
        if (Test-Path -path $DUSUPath) {Remove-Item -Path $DUSUPath -Force -Recurse -ErrorAction Continue}
        if (Test-Path -path $DUCUPath) {Remove-Item -Path $DUCUPath -Force -Recurse -ErrorAction Continue}
        & DISM /Cleanup-WIM
    }
    Catch 
    {
        Write-Warning "Cleanup failed"
        Throw $Error
    }
}

##################################################

#Main
##################################################
try
{
    Check-Paths

    Check-OSVersion
    
    If($ApplyDynamicUpdates) {Get-DynamicUpdates}

    If($CreateProdMedia) {Create-ProductionMedia}

    If($Cleanup) {Cleanup}
    
}

catch 
{
    Write-Warning $Error[0].Exception
    Write-Host Write-Error $Error[0].Exception -ForegroundColor Red
}

####################################################
