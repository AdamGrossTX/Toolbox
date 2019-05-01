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

    .Guide
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

    Once you've added the files to the correct folders, you are ready to begin servicing. Close any open explorer windows or anything else that could be using the files if your servicing folder, otherwise, DISM will likely break during the dismount process.

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

        1.5 - Added fix for 2018-09 SetupUpdates not being classified correctly.
        
        1.6 - Added $Optimize switch (set to false by default) to remove -Optimize switch to address issues with Windows 10 1809 (11/21/2018)

        1.7 - Updated the Params to accept defaults without using command line args. Added Remove-InBox apps functionality using configfile.

        1.8 - Added .NET Cumulative Update function. Cleaned up folder logic to allow it to pre-create folders before exiting. Misc changes. (4/10/2019).
        
        1.9 - Added quick start guide.
    
#>

Param
(
    [Parameter(Position=0, HelpMessage="Operating System Name to be serviced.")]
    [ValidateSet("Windows 10 Education","Windows 10 Education N","Windows 10 Enterprise","Windows 10 Enterprise N","Windows 10 Pro","Windows 10 Pro N")]
    [string]
    $OSName = "Windows 10 Enterprise",

    [Parameter(Position=1, HelpMessage="Operating System version to service. Default is 1709.")]
    [ValidateSet('1709','1803','1809')]
    [string]
    $OSVersion = "1809",

    [Parameter(Position=2, HelpMessage="Architecture version to service. Default is x64.")]
    [ValidateSet ('x64', 'x86','ARM64')]
    [string]
    $OSArch = "x64",   

    [Parameter(Position=3, HelpMessage="Year-Month of updates to apply (Format YYYY-MM). Default is 2018-08.")]
    [ValidatePattern("\d{4}-\d{2}")]
    [string]
    $Month = "2019-03",

    [Parameter(Position=4, HelpMessage="Path to working directory for servicing data. Default is C:\ImageServicing.")]
    [ValidateNotNullOrEmpty()]
    [string]
    $RootFolder = "C:\ImageServicing",

    [Parameter(Position=5, HelpMessage="SCCM Primary Server Name.")]
    [ValidateNotNullOrEmpty()]
    [string]
    $SCCMServer = '',

    [Parameter(Position=6, HelpMessage="SCCM Site Code.")]
    [ValidateNotNullOrEmpty()]
    [string]
    $SiteCode = '',

    [Parameter(Position=7, HelpMessage="Change path here to ADK dism.exe if your OS version doesn't match ADK version. Default dism.exe.")]
    [string]
    $DISMPath = "Dism.exe",
    
    [Parameter(HelpMessage="Outputs fully serviced media.")]
    [switch]
    $CreateProdMedia = [switch]::Present,

    [Parameter(HelpMessage="Optionally apply Dynamic Updates to Install.wim and Sources for InPlace Upgrade compatibility.")]
    [switch]
    $ApplyDynamicUpdates = [switch]::Present,

    [Parameter(HelpMessage="Delete temp folders and patches.")]
    [switch]
    $Cleanup = $false,

    [Parameter(HelpMessage="This is set to false by default to prevent issues with Windows 10 1809. Set to true for other OS builds.")]
    [switch]
    $Optimize = $false,

    [Parameter(HelpMessage="Remove InBox Apps - Update the included RemoveApps.XML to meet your needs.")]
    [switch]
    $RemoveInBoxApps = [switch]::Present

)


#Main
##################################################

$main = {

    #Setup
    ##################################################


    If([string]::IsNullOrEmpty($SCCMServer)) {
        $SCCMServer = Read-Host -Prompt 'Input your server name'
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

    $ISO = Get-ChildItem -Path $ISOPath -Filter "*.ISO" | Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue
    $LCU = Get-ChildItem -Path "$($LCUPath)" -Filter "*.MSU" | Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue
    $SSU = Get-ChildItem -Path "$($SSUPath)" -Filter "*.MSU" | Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue
    $Flash = Get-ChildItem -Path "$($FlashPath)" -Filter "*.MSU" | Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue
    $DotNet = Get-ChildItem -Path "$($DotNetPath)" -Filter "*.MSU" | Select-Object -ExpandProperty FullName -ErrorAction SilentlyContinue

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


    try
    {
        Check-OSVersion
    
        Check-Paths
    
        If($ApplyDynamicUpdates) {Get-DynamicUpdates}

        If($CreateProdMedia) {
            Get-BaseMedia
            Patch-BootWIM
            Mount-InstallWIM
            If($RemoveInBoxApps){
                Remove-InBoxApps
            }
            Patch-WinREWIM
            Patch-InstallWIM
            Copy-CompletedWIMs
        }

        If($Cleanup) {Cleanup}
        
    }

    catch 
    {   
        Write-Warning $Error[0].Exception
        Write-Host Write-Error $Error[0].Exception -ForegroundColor Red
    }

}
####################################################


#Functions
##################################################
Function Check-Paths
{
    $Error.Clear()
    Try {
        $ErrorMessages = @()
        Write-Host "Checking for folders and creating them if they don't exist" -ForegroundColor Green
        if (!(Test-Path -path $ISO)) {$ErrorMessages += "Could not find Windows 10 ISO file."}
        if (!(Test-Path -path $SSUPath)) {New-Item -path $SSUPath -ItemType Directory}
        if (!(Test-Path -path $FlashPath)) {New-Item -path $FlashPath -ItemType Directory}
        if (!(Test-Path -path $DotNetPath)) {New-Item -path $DotNetPath -ItemType Directory}
        if (!(Test-Path -path $LCUPath)) {New-Item -path $LCUPath -ItemType Directory}
        if (!(Test-Path -path $DUSUPath)) {New-Item -path $DUSUPath -ItemType Directory}
        if (!(Test-Path -path $DUCUPath)) {New-Item -path $DUCUPath -ItemType Directory}
        if (!(Test-Path -path $ImageMountFolder)) {New-Item -path $ImageMountFolder -ItemType Directory}
        if (!(Test-Path -path $BootImageMountFolder)) {New-Item -path $BootImageMountFolder -ItemType Directory}
        if (!(Test-Path -path $WinREImageMountFolder)) {New-Item -path $WinREImageMountFolder -ItemType Directory}
        if (!(Test-Path -path $WIMImageFolder)) {New-Item -path $WIMImageFolder -ItemType Directory}
        if (!(Test-Path -path $OriginalBaseMediaFolder)) {New-Item -path $OriginalBaseMediaFolder -ItemType Directory}
        if (!(Test-Path -path $CompletedMediaFolder)) {New-Item -path $CompletedMediaFolder -ItemType Directory}
  
        if(!($SSU)) {$ErrorMessages +=  "Could not find Servicing Update for Windows 10."}
        if(!($LCU)) {$ErrorMessages +=  "Could not find Monthly Update for Windows 10."}
        if(!($Flash)) {$ErrorMessages +=  "Could not find Adobe Flash Update for Windows 10."}

        #Only check for .NET Updates for 1809 and above.
        If($OSVersion -ge '1809') { 
            If(!($DotNet)) {$ErrorMessages +=  "Could not find .NET Update for Windows 10."}
        }
         If($ErrorMessages) {
             $ErrorMessages | ForEach-Object {Write-Warning $_} ; break;}
        Else {
            Write-Host "All Updates found" -ForegroundColor Green
        }
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
                
                if ($current)
                {
                    Remove-AppxProvisionedPackage -Path $ImageMountFolder -PackageName $current.PackageName
                }
                else
                {
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
    [switch]$InstallDotNET=$False,
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
    Write-Host "InstallDotNET: $($InstallDotNET)" -ForegroundColor Green
    Write-Host "ApplySSU: $($ApplySSU)" -ForegroundColor Green
    Write-Host "ApplyFlash: $($ApplyFlash)" -ForegroundColor Green
    Write-Host "ApplyLCU: $($ApplyLCU)" -ForegroundColor Green
    Write-Host "ApplyDUCU: $($ApplyDUCU)" -ForegroundColor Green
    Write-Host "CleanWIM: $($CleanWIM)" -ForegroundColor Green
    
    Try
    {
        if($InstallDotNET) #Enabled .Net 3.5
        {
            Write-Host "Enabling .NET 3.5" -ForegroundColor Green
            & $DISMPath /Image:$MountFolder /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:"$($OriginalBaseMediaFolder)\sources\sxs"
        }

        if($ApplyDotNET)
        {
            If($OSVersion -ge '1809') { 
                Write-Host "Applying .NET Updates" -ForegroundColor Green
                Add-WindowsPackage -PackagePath $DotNet -Path $MountFolder
            }
        }

        if($ApplySSU)
        {
            Write-Host "Applying SSU" -ForegroundColor Green
            Add-WindowsPackage -PackagePath $SSU -Path $MountFolder        
        }

        if($ApplyFlash)
        {
            Write-Host "Applying Flash Updates" -ForegroundColor Green
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
                $DUCU = Get-ChildItem -Path "$($DUCUPath)" -Filter "*.CAB" | Select-Object -ExpandProperty FullName

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

Function Mount-InstallWIM
{
    $Error.Clear()
    try{
        Write-Host "Mounting Install WIM" -ForegroundColor Green

        If ($Optimize) {
            Mount-WindowsImage -ImagePath $TmpInstallWIM -Index 1 -Path $ImageMountFolder -Optimize
        }
        Else
        {
            Mount-WindowsImage -ImagePath $TmpInstallWIM -Index 1 -Path $ImageMountFolder
        }
       
    }
    catch
    {
        Write-Warning "Mounting Install WIM failed"
        Throw $Error
    }    
}

Function Patch-InstallWIM {
    $Error.Clear()
    try{

        Apply-Patches -MountFolder $ImageMountFolder -ApplySSU -ApplyLCU -ApplyFlash -CleanWIM
        Apply-Patches -MountFolder $ImageMountFolder -InstallDotNET -ApplyDotNET -ApplyLCU -ApplyDUCU
        
        DisMount-WindowsImage -Path $ImageMountFolder -Save
        Export-WindowsImage -SourceImagePath $TmpInstallWIM -SourceName $OSName -DestinationImagePath $InstallWIM
       
    }
    catch
    {
        Write-Warning "Install WIM patching failed"
        Throw $Error
    }    
}

Function Copy-CompletedWIMs {
    $Error.Clear()
    try {
        Write-Host "Copying Production Media" -ForegroundColor Green

        Copy-Item -Path $InstallWIM -Destination "$($CompletedMediaFolder)\Sources" -Container -Force
        Copy-Item -Path $BootWIM -Destination "$($CompletedMediaFolder)\Sources" -Container -Force
        
    }
    catch
    {
        $Error
        Write-Warning "Copying Production Media failed"
        Write-Host $Error
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

# Calling the main function
&$main
# ------------------------------------------------------------------------------------------------
# END
