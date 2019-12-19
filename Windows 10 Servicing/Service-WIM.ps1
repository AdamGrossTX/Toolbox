<#
    .SYNOPSIS
        Service your Windows WIM with monthly updates.

    .DESCRIPTION
        To use the Dynamic Updates feature, you must have Dynamic Updates enabled in SCCM, otherwise the script won't find the updates. If you have
        an alternate method to get the updates, just modIfy the script to handle that. Hopefully I can get a Windows Update URL to use instead of
        querying SCCM.

        You will have to pre-download you SSU, LCU and Flash Updates from the Windows Update Catalog.

        The base script components were stolen from Johan Arwidmark @jarwidmark and bits and pieces from others along the way. 
        Also, thanks to Johan for mentioning this script at Microsoft Ignite 2018 in the BRK2288 and BRK4028 sessions.

        If you want an ultimate, hands-off seriving tool, please take a look at David Segura's (@SeguraOSD) OSBuilder tool.
        It does EVERYTHING and is way better than this!
        http://www.OSDeploy.com

        Special Thanks to Gary Blok and Mike Terrill for their tireless efforts to solve the Dynamic Updates issue!

    .PARAMETER ServerName
        SCCM Primary Server Name.

    .PARAMETER SiteCode
        SCCM Site Code.

    .PARAMETER OSName
        Operating System Name to be serviced.Default is 'Windows 10 Enterprise'

    .PARAMETER OSVersion
        Operating System version to service. Default is 1909.

    .PARAMETER OSArch
        Architecture version to service. Default is x64.

    .PARAMETER Month
        Year-Month of updates to apply (Format YYYY-MM). Default is Current Month.

    .PARAMETER RootFolder
        Path to working directory for servicing data. Default is C:\ImageServicing.

    .PARAMETER DISMPath
        Change path here to ADK dism.exe If your OS version doesn't match ADK version. Default dism.exe.

    .PARAMETER CreateProdMedia
        Outputs fully serviced media.

    .PARAMETER ApplyDynamicUpdates
        Optionally apply Dynamic Updates to Install.wim and Sources for InPlace Upgrade compatibility.

    .PARAMETER Cleanup
        Delete temp folders and patches.

    .PARAMETER Optimize
        This is set to false by default to prevent issues with Windows 10 1809. Set to true for other OS builds.

    .PARAMETER RemoveInBoxApps
        Remove InBox Apps - Update the included RemoveApps.XML to meet your needs.

    .PARAMETER IgnoreTheseUpdates
        If there is no update for a specIfic catgory add it to this array and the script will skip validation for it. Options include 'LCU' 'SSU' 'Flash' 'DotNet'

    .PARAMETER KillAV
        Kill the AV Process on your box before servicing. You will need to update the script with the correct command for yourr specIfic AV.

    .PARAMETER AutoDLUpdates
        Option to enable updates to be auto downloaded using the LatestUpdate module.

    .NOTES
        Author:  Adam Gross
        Twitter: @AdamGrossTX
        Website: https://www.asquaredozen.com

    .LINK
        https://github.com/AdamGrossTX/PowershellScripts/tree/master/Windows%2010%20Servicing
        https://www.asquaredozen.com/2018/08/20/adding-dynamic-updates-to-windows-10-in-place-upgrade-media-during-offline-servicing/

    .GUIDE
        ## Quick Start Guide

        Download the contents of this folder to a local driver such as c:\ImageServicing.

        Launch the script and enter parameters as needed. At a minimum you will need to enter your servername and site code. On first launch, the script will look for all of the files and folders needed for servicing. It will create the required folder structure. You will need to add your ISO to the appropriate folder under the ISO folder.

        You will also need to have Dynamic Updates enabled in your SCCM Console and be able to see Dynamic Updates in your ConfigMgr console.

        Then, go to https://www.catalog.update.microsoft.com/Home.aspx and search for updates that match the os version and build you are servicing. You will need to add each update to their respective folder.

        Mount_Image = The DISM mount folder for the OS Image
        Mount_BootImage = The DISM mount folder for the Boot Image
        Mount_WinREImage = The DISM mount folder for the WinRE Image
        WIM_OutPut = a temp directory for WIM files
        OriginalBaseMedia = the ISO is extracted here

        ISO = Windows ISO Source Media
        LCU = Latest Cumilative Update
        SSU = Servicing Stack Update (check the LCU KB for the KB number of the required SSU)
        Flash = Adobe Flash Player
        DotNet = .NET Framework Cumulative Update (New for 1809)
        SetupUpdate = Dynamic Update Setup Update
        ComponentUpdate = Dynamic Update Component Update

        Once you've added the files to the correct folders, you are ready to begin servicing. Close any open explorer windows or anything else that could be using the files If your servicing folder, otherwise, DISM will likely break during the dismount process.

        Launch the script again with the desired command lines. If all files and folders are present, it will begin working. In the end, you will end up with a CompletedMedia folder which will have the completed media with updated wims.

        ### Note
        Beginning in Windows 10 1809, the servicing model has improved. At the moment, dynamic updates are no longer delivered from WSUS and can't be downloaded by the script. I have reached out to the product group to ask for assistance on offline servicing options. They said that this is being worked on, but there's no solution yet. The best option I've found is to run the Feature Update on a device and it will download the CAB files into the c:\$Windows.~BT folder where you can grab them and add to the script.

        Originally created for this blog post. https://www.asquaredozen.com/2018/08/20/adding-dynamic-updates-to-windows-10-in-place-upgrade-media-during-offline-servicing/

    .History

        1.0 - Original

        1.1 - Fixed bugs
        
        1.2 - Added better folder creation logic and messaging. - (This version is being tested right now 08/21/2018 3:20 PM CST)
        
        1.3 - Updated params for defaults
        
        1.4 - Added Mandatory flags to some params

        1.5 - Added fix for 2018-09 SetupUpdates not being classIfied correctly.
        
        1.6 - Added $Optimize switch (set to false by default) to remove -Optimize switch to address issues with Windows 10 1809 (11/21/2018)

        1.7 - Updated the Params to accept defaults without using command line args. Added Remove-InBox apps functionality using configfile.

        1.8 - Added .NET Cumulative Update function. Cleaned up folder logic to allow it to pre-create folders before exiting. Misc changes. (4/10/2019).
        
        1.9 - Added quick start guide.

        1.10 - Minor Updates

        1.11 - Added some params for AV and Ignoring Updates when there aren't any that month. 
               Restructured things a bit and added some more help. 
               Added https://github.com/aaronparker/LatestUpdate
    

        #https://www.catalog.update.microsoft.com/Search.aspx?q=2019-07%201803%20Windows%2010%20x64
#>

Param
(
    [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName = $true, Position=1)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ServerName,

    [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName = $true, Position=2)]
    [ValidateNotNullOrEmpty()]
    [string]
    $SiteCode,

    [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName = $true, Position=3)]
    [ValidateSet("Windows 10 Education","Windows 10 Education N","Windows 10 Enterprise","Windows 10 Enterprise N","Windows 10 Pro","Windows 10 Pro N")]
    [string]
    $OSName = 'Windows 10 Enterprise',

    [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName = $true, Position=4)]
    [ValidateSet('1709','1803','1809','1903','1909')]
    [string]
    $OSVersion = "1909",

    [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName = $true, Position=5)]
    [ValidateSet ('x64', 'x86','ARM64')]
    [string]
    $OSArch = "x64",   

    [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName = $true, Position=6)]
    [ValidatePattern("\d{4}-\d{2}")]
    [string]
    $Month = ("{0}-{1}" -f (Get-Date).Year, (Get-Date).Month),

    [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName = $true, Position=7)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RootFolder='C:\ImageServicing.',

    [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName = $true, Position=8)]
    [string]
    $DISMPath='dism.exe',
    
    [Parameter(Mandatory=$False)]
    [switch]
    $CreateProdMedia = [switch]::Present,

    [Parameter(Mandatory=$False)]
    [switch]
    $ApplyDynamicUpdates = [switch]::Present,

    [Parameter(Mandatory=$False)]
    [switch]
    $Cleanup=$False,

    [Parameter(Mandatory=$False)]
    [switch]
    $Optimize=[switch]::Present,

    [Parameter(Mandatory=$False)]
    [switch]
    $RemoveInBoxApps=[switch]::Present,

    [Parameter(Mandatory=$False)]
    [string[]]
    $IgnoreTheseUpdates = (""),

    [Parameter(Mandatory=$False)]
    [switch]
    $KillAV,
    
    [Parameter(Mandatory=$False)]
    [switch]
    $AutoDLUpdates = [switch]::Present

)


#Main
##################################################

$Main = {

    #Setup
    ##################################################

    Install-Module -Name LatestUpdate -Force

    If([string]::IsNullOrEmpty($ServerName)) {
        $ServerName = Read-Host -Prompt 'Input your server name'
    }
    If([string]::IsNullOrEmpty($SiteCode)) {
        $SiteCode = Read-Host -Prompt 'Input your site code'
    }

    $VerbosePreference="Continue"
    $ErrorActionPreference="Stop"

    $DownloadList = @()

    $DisplayNameFilter = "*$($OSVersion)*$($OSArch)*"

    $ISOPath = "$($RootFolder)\ISO\$($OSVersion)"
    $UpdatesPath = "$($RootFolder)\Updates\$($OSVersion)\$($Month)\$($OSArch)"
    $LCUPath = "$($UpdatesPath)\LCU"
    $SSUPath = "$($UpdatesPath)\SSU"
    $FlashPath = "$($UpdatesPath)\Flash"
    $DotNetPath = "$($UpdatesPath)\DotNet"

    $ConfigFile = "$($PSScriptRoot)\RemoveApps.xml"

    $DUSUPath = "$($UpdatesPath)\SetupUpdate"
    $DUCUPath = "$($UpdatesPath)\ComponentUpdate"

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


    ##################################################


    Try {

        #Stop the AV Service on your machine
        If($KillAV.IsPresent) {
            & 'C:\Program Files (x86)\Symantec\Symantec Endpoint Protection\Smc.exe' -Stop
        }

        Check-OSVersion
    
        Check-PathsAndDownloadMissingUpdates
    
        If($ApplyDynamicUpdates) {Get-DynamicUpdates}

        If($CreateProdMedia) {
            Get-BaseMedia
            Patch-BootWIM
            Mount-InstallWIM
            If($RemoveInBoxApps) {
                Remove-InBoxApps
            }
            Patch-WinREWIM
            Patch-InstallWIM
            Copy-CompletedWIMs
        }

        If($Cleanup) {Cleanup}
        
    }

    Catch {   
        Write-Warning $Error[0].Exception
        Write-Host Write-Error $Error[0].Exception -ForegroundColor Red
    }

}
####################################################


#Functions
##################################################
Function Check-PathsAndDownloadMissingUpdates {
    $Error.Clear()
    Try {
        $ErrorMessages = @()
        Write-Host "Checking for folders and creating them If they don't exist" -ForegroundColor Green


        Write-Host "Checking for ISO." -ForegroundColor Green
        $Script:ISO = Get-ChildItem -Path $ISOPath -Filter "*.ISO" | Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue
        If (!$Script:ISO) {$ErrorMessages += "Could not find Windows 10 ISO file."}

        Write-Host "Checking for SSU" -ForegroundColor Green
        If(!$IgnoreTheseUpdates.Contains('SSU')) {
            New-Item -path $SSUPath -ItemType Directory -ErrorAction SilentlyContinue

            $Script:SSU = Get-ChildItem -Path "$($SSUPath)" -Filter "*.MSU" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue
            If(!$Script:SSU -and $AutoDLUpdates) {
                Get-LatestServicingStackUpdate -OperatingSystem Windows10 -Version $OSVersion | Where-Object { $_.Architecture -eq $OSArch } | Save-LatestUpdate -Path $SSUPath
            }

            $Script:SSU = Get-ChildItem -Path "$($SSUPath)" -Filter "*.MSU" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue
            If(!$Script:SSU) {
                $ErrorMessages +=  "Could not find Servicing Stack Update for Windows 10."
            }
        }

        Write-Host "Checking for Flash" -ForegroundColor Green
        If(!$IgnoreTheseUpdates.Contains('Flash')) {
            New-Item -path $FlashPath -ItemType Directory -Force -ErrorAction SilentlyContinue

            $Script:Flash = Get-ChildItem -Path "$($FlashPath)" -Filter "*.MSU" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue
            If(!$Script:Flash -and $AutoDLUpdates) {
                Get-LatestAdobeFlashUpdate -OperatingSystem Windows10 -Version $OSVersion | Where-Object { $_.Architecture -eq $OSArch } | Save-LatestUpdate -Path $FlashPath
            }

            $Script:Flash = Get-ChildItem -Path "$($FlashPath)" -Filter "*.MSU" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue
            If(!$Script:Flash) {
                $ErrorMessages +=  "Could not find Adobe Flash Update for Windows 10."
            }
        }

        Write-Host "Checking for DotNet" -ForegroundColor Green
        If(!$IgnoreTheseUpdates.Contains('DotNet')) {
            New-Item -path $DotNetPath -ItemType Directory -Force -ErrorAction SilentlyContinue
            
            $Script:DotNet = Get-ChildItem -Path "$($DotNetPath)" -Filter "*.MSU" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue
            If(!$Script:DotNet -and $AutoDLUpdates) {
                Get-LatestNetFrameworkUpdate -OperatingSystem Windows10 | Where-Object { $_.Architecture -eq $OSArch -and $_.Version -eq $OSVersion } | Save-LatestUpdate -Path $DotNetPath
            }

            $Script:DotNet = Get-ChildItem -Path "$($DotNetPath)" -Filter "*.MSU" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue
            If(!$Script:DotNet) {
                If($OSVersion -ge '1803') { 
                    If(!($DotNet)) {$ErrorMessages +=  "Could not find .NET Update for Windows 10."}
                }
            }
        }

        Write-Host "Checking for LCU" -ForegroundColor Green
        If(!$IgnoreTheseUpdates.Contains('LCU')) {
            New-Item -path $LCUPath -ItemType Directory -Force -ErrorAction SilentlyContinue

            $Script:LCU = Get-ChildItem -Path "$($LCUPath)" -Filter "*.MSU" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue
            If(!$Script:LCU -and $AutoDLUpdates) {
                Get-LatestCumulativeUpdate -OperatingSystem Windows10 -Version $OSVersion | Where-Object { $_.Architecture -eq $OSArch } | Save-LatestUpdate -Path $LCUPath
            }

            $Script:LCU = Get-ChildItem -Path "$($LCUPath)" -Filter "*.MSU" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue
            If(!$Script:LCU) {
                $ErrorMessages +=  $ErrorMessages +=  "Could not find Monthly Update for Windows 10."
            }
        }
        If (!(Test-Path -path $DUSUPath)) {New-Item -path $DUSUPath -ItemType Directory -Force}
        If (!(Test-Path -path $DUCUPath)) {New-Item -path $DUCUPath -ItemType Directory -Force}
        If (!(Test-Path -path $ImageMountFolder)) {New-Item -path $ImageMountFolder -ItemType Directory -Force}
        If (!(Test-Path -path $BootImageMountFolder)) {New-Item -path $BootImageMountFolder -ItemType Directory -Force}
        If (!(Test-Path -path $WinREImageMountFolder)) {New-Item -path $WinREImageMountFolder -ItemType Directory -Force}
        If (!(Test-Path -path $WIMImageFolder)) {New-Item -path $WIMImageFolder -ItemType Directory -Force}
        If (!(Test-Path -path $OriginalBaseMediaFolder)) {New-Item -path $OriginalBaseMediaFolder -ItemType Directory -Force}
        If (!(Test-Path -path $CompletedMediaFolder)) {New-Item -path $CompletedMediaFolder -ItemType Directory -Force}
  
        If($ErrorMessages) {
             $ErrorMessages | ForEach-Object {Write-Warning $_} ; break;}
        Else {
            Write-Host "All Updates found" -ForegroundColor Green
        }
    }
    Catch {
        Write-Host "Check Paths failed."
        Throw $Error
    }
}

Function Check-OSVersion {
    $Error.Clear()
    Try {
        Write-Host "Checking OS Version" -ForegroundColor Green
        $OSCaption = (Get-WmiObject win32_operatingsystem).caption

        If (!($OSCaption -like "Microsoft Windows 10*") -and !($OSCaption -like "Microsoft Windows Server 2016*")) {
            Write-Warning "$Env:Computername Oops, you really should use Windows 10 or Windows Server 2016 when servicing Windows 10 offline"
            Write-Warning "$Env:Computername Aborting script..."
            Break;
        } 
    }
    Catch {
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

        $AllDynamicUpdates = Get-WmiObject -ComputerName $ServerName -Class SMS_SoftwareUpdate -Namespace "root\SMS\Site_$($SiteCode)" -Filter $AllDynamicUpdatesFilter

        $FilteredUpdateList = $AllDynamicUpdates | Where {$_.LocalizedDisplayName -like $DisplayNameFilter -and $_.IsSuperseded -eq $False -and $_.IsLatest -eq $True}

        ForEach ($Update in $FilteredUpdateList) {

            $ContentIDs = Get-WmiObject -ComputerName $ServerName -Class SMS_CIToContent -Namespace "root\SMS\Site_$($SiteCode)" -Filter "CI_ID = $($Update.CI_ID)"

            ForEach ($ContentID in $ContentIDs) {

                $Content = Get-WmiObject -ComputerName $ServerName -Class SMS_CIContentFiles -Namespace "root\SMS\Site_$($SiteCode)" -Filter "ContentID = $($ContentID.ContentID)"
            
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

        ForEach ($File in $DownloadList) {
            $Path = $Null
            Switch ($File.Type) {
                SetupUpdate {$Path = "$($DUSUPath)\$($File.FileName)"; break;}
                ComponentUpdate {$Path = "$($DUCUPath)\$($File.FileName)"; break;}
                Default {$Path = "$($UpdatesPath)\$($File.FileName)"; break;}
            }
            Invoke-WebRequest -Uri $File.URL -OutFile $Path -ErrorAction Continue
        }

        $SUFiles = Get-ChildItem -Path $DUSUPath

        ForEach ($File in $SUFiles) {
            $ExtractFolder = "$($DUSUPath)\$($File.Name.Replace('.cab',''))\"
            New-Item -path $ExtractFolder -ItemType Directory
            & Expand "$($File.FullName)" -F:* $ExtractFolder
        }
    }
    Catch {
        Write-Warning "Get Dynamic Updates failed."
        Throw $Error[0]
    }

}

Function Remove-InBoxApps {
    Try {
        If(Test-Path -Path $configFile) {
            Write-Host "Reading list of apps from $configFile"
            $list = Get-Content $configFile
            Write-Host "Apps Select-Objected for removal: $list.Count"

            $provisioned = Get-AppxProvisionedPackage -Path $ImageMountFolder
        
            ForEach ($AppName in $List) {
                Write-Information "Removing provisioned package $AppName"
                $current = $Provisioned | Where-Object { $_.DisplayName -eq $AppName }
                
                If ($current) {
                    Remove-AppxProvisionedPackage -Path $ImageMountFolder -PackageName $current.PackageName
                }
                Else {
                    Write-Warning "Unable to find provisioned package $AppName"
                }
            }
        }
        Else {
            Write-Host "No RemoveApps.XML found"
        }
    }
    Catch {
        Error[0]
        Write-Warning "Remove-InBoxApps failed."
        Throw $Error[0]
    }
}


Function Apply-Patches {
param
(
    [string]$MountFolder,
    [switch]$ApplyDotNET=$False,
    [switch]$InstallDotNET35=$False,
    [switch]$ApplySSU=$False,
    [switch]$ApplyFlash=$False,
    [switch]$ApplyLCU=$False,
    [switch]$ApplyDUCU=$False,
    [switch]$CleanWIM=$False

)
    $Error.Clear()

    Write-Host "Applying patches to WIM $($MountFolder)." -ForegroundColor Green
    Write-Host "Select-Objected Options:" -ForegroundColor Green
    Write-Host "ApplyDotNET: $($ApplyDotNET)" -ForegroundColor Green
    Write-Host "InstallDotNET35: $($InstallDotNET35)" -ForegroundColor Green
    Write-Host "ApplySSU: $($ApplySSU)" -ForegroundColor Green
    Write-Host "ApplyFlash: $($ApplyFlash)" -ForegroundColor Green
    Write-Host "ApplyLCU: $($ApplyLCU)" -ForegroundColor Green
    Write-Host "ApplyDUCU: $($ApplyDUCU)" -ForegroundColor Green
    Write-Host "CleanWIM: $($CleanWIM)" -ForegroundColor Green
    
    Try {
        #Enabled .Net 3.5
        If($InstallDotNET35) {
            Write-Host "Enabling .NET 3.5" -ForegroundColor Green
            & $DISMPath /Image:$MountFolder /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:"$($OriginalBaseMediaFolder)\sources\sxs"
        }

        If($ApplyDotNET -and !$IgnoreTheseUpdates.Contains('DotNet')) {
            #Only needed for 1809 and higher.
            If($OSVersion -ge '1809') { 
                Write-Host "Applying .NET Updates" -ForegroundColor Green
                $Count = 0
                $DotNet.Count
                #Recurse All .NET Patches in DotNet Path
                ForEach($MSU in $DotNet) {
                    Write-Host "Applying .NET Patch $($Count + 1) of $($DUCU.Count)" -ForegroundColor Green
                    Add-WindowsPackage -PackagePath $MSU -Path $MountFolder
                }
            }
        }

        If($ApplySSU -and !$IgnoreTheseUpdates.Contains('SSU')) {
            Write-Host "Applying SSU" -ForegroundColor Green
            Add-WindowsPackage -PackagePath $SSU -Path $MountFolder        
        }

        If($ApplyFlash -and !$IgnoreTheseUpdates.Contains('Flash')) {
            Write-Host "Applying Flash Updates" -ForegroundColor Green
            If(!($Flash)) {
                Write-Host "Flash Not Found. Skipping Flash."    
            }
            {
                Add-WindowsPackage -PackagePath $Flash -Path $MountFolder
            }
        }

        If($ApplyLCU -and !$IgnoreTheseUpdates.Contains('LCU')) {
            Write-Host "Applying LCU" -ForegroundColor Green
            Add-WindowsPackage -PackagePath $LCU -Path $MountFolder
        }

        If($ApplyDUCU) {
            #Only apply DU is specIfied in the script params. Default is True.
            If($ApplyDynamicUpdates) {
                Write-Host "Applying Dynamic Component Updates" -ForegroundColor Green
                #Get All Dynamic Cumulative Updates
                $DUCU = Get-ChildItem -Path "$($DUCUPath)" -Filter "*.CAB" | Select-Object -ExpandProperty FullName

                $Count = 0
                $DUCU.Count
                #Recurse All Updates in DUCUPath
                ForEach($CAB in $DUCU) {
                    Write-Host "Applying Dynamic Component Update $($Count + 1) of $($DUCU.Count)" -ForegroundColor Green
                    Add-WindowsPackage -PackagePath $CAB -Path $MountFolder
                }
            }
        } 

        If($CleanWIM) {
            Write-Host "Running Cleanup and ResetBase" -ForegroundColor Green
            & $DISMPath /Image:$MountFolder /cleanup-image /startcomponentcleanup /resetbase
        }
    }
    Catch {
        Write-Warning "Apply Patches failed."
        Throw $Error
    }

}

Function Get-BaseMedia {
    $Error.Clear()
    Try {
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
        If($Cleanup) {
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

        If($ApplyDynamicUpdates) {
            #Get all SetupUpdate Dynamic Update contents and apply them to the Completed Sources folder
            $DUSUContents = Get-ChildItem -Path $DUSUPath -Directory
            ForEach ($Folder in $DUSUContents) {
                Copy-Item -Path "$($Folder.FullName)\*" -Destination "$($CompletedMediaFolder)\Sources" -Container -Force -Recurse
           
            }
        }
                
    }
    Catch {
        Write-Warning "Extract ISO Media failed."
        Throw $Error
    }
}

Function Patch-BootWIM {
    $Error.Clear()
    Try {
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
    Catch {
        Write-Warning "Boot WIM patching failed"
        Throw $Error
    }
}

Function Patch-WinREWIM {
    $Error.Clear()
    Try {
        Write-Host "Patching WinRE WIM" -ForegroundColor Green
        #WinRE
        If(!(Test-Path $ImageMountFolder)) {
            Write-Warning "No Install.WIM mounted. Please mount Install.WIM and try again."
            Break;
        }
        Else {
            Move-Item -Path $ImageMountFolder\Windows\System32\Recovery\winre.wim -Destination $TmpWinREWIM -Force
            Mount-WindowsImage -ImagePath $TmpWinREWIM -Index 1 -Path $WinREImageMountFolder
            Apply-Patches -MountFolder $WinREImageMountFolder -ApplySSU -ApplyLCU -CleanWIM
            DisMount-WindowsImage -Path $WinREImageMountFolder -Save
            Export-WindowsImage -SourceImagePath $TmpWinREWIM -SourceName "Microsoft Windows Recovery Environment (x64)" -DestinationImagePath $WinREWIM
            Copy-Item -Path $WinREWIM -Destination $ImageMountFolder\Windows\System32\Recovery\winre.wim -Force
        }
    }
    Catch {
        Write-Warning "WinRE WIM patching failed"
        Throw $Error
    }
}

Function Mount-InstallWIM {
    $Error.Clear()
    Try {
        Write-Host "Mounting Install WIM" -ForegroundColor Green

        If ($Optimize) {
            Mount-WindowsImage -ImagePath $TmpInstallWIM -Index 1 -Path $ImageMountFolder -Optimize
        }
        Else
        {
            Mount-WindowsImage -ImagePath $TmpInstallWIM -Index 1 -Path $ImageMountFolder
        }
       
    }
    Catch {
        Write-Warning "Mounting Install WIM failed"
        Throw $Error
    }    
}

Function Patch-InstallWIM {
    $Error.Clear()
    Try {

        Apply-Patches -MountFolder $ImageMountFolder -ApplySSU -ApplyLCU -ApplyFlash -CleanWIM
        Apply-Patches -MountFolder $ImageMountFolder -InstallDotNET35 -ApplyDotNET -ApplyLCU -ApplyDUCU
        
        DisMount-WindowsImage -Path $ImageMountFolder -Save
        Export-WindowsImage -SourceImagePath $TmpInstallWIM -SourceName $OSName -DestinationImagePath $InstallWIM
       
    }
    Catch {
        Write-Warning "Install WIM patching failed"
        Throw $Error
    }    
}

Function Copy-CompletedWIMs {
    $Error.Clear()
    Try {
        Write-Host "Copying Production Media" -ForegroundColor Green

        Copy-Item -Path $InstallWIM -Destination "$($CompletedMediaFolder)\Sources" -Container -Force
        Copy-Item -Path $BootWIM -Destination "$($CompletedMediaFolder)\Sources" -Container -Force
        
    }
    Catch {
        $Error
        Write-Warning "Copying Production Media failed"
        Write-Host $Error
        Throw $Error
    }
}

Function Cleanup {
    Try {
        Write-Host "Cleaning Up" -ForegroundColor Green
        If (Test-Path -path $TmpInstallWIM) {Remove-Item -Path $TmpInstallWIM -Force -ErrorAction Continue}
        If (Test-Path -path $TmpBootWIM) {Remove-Item -Path $TmpBootWIM -Force -ErrorAction Continue}
        If (Test-Path -path $TmpWinREWIM) {Remove-Item -Path $TmpWinREWIM -Force -ErrorAction Continue}
        If (Test-Path -path $DUSUPath) {Remove-Item -Path $DUSUPath -Force -Recurse -ErrorAction Continue}
        If (Test-Path -path $DUCUPath) {Remove-Item -Path $DUCUPath -Force -Recurse -ErrorAction Continue}
        & DISM /Cleanup-WIM
    }
    Catch 
    {
        Write-Warning "Cleanup failed"
        Throw $Error
    }
}

# Calling the main function
& $Main
# ------------------------------------------------------------------------------------------------
# END
