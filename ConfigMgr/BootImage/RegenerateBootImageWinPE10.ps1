# //****************************************************************************
# // ***** Script Header *****
# // 
# // File:      RegenerateBootImageWinPE.ps1
# // 
# // Purpose:   Regenerate the Configuration Manager default boot images to use
# //            the latest Windows PE winpe.wim from the Windows ADK
# //            The script must be used on your Primary Site Server
# // 
# // Usage:     powershell -ExecutionPolicy Bypass -file .\RegenerateBootImageWinPE.ps1 -BootimageName "CMBoot.wim" -BootImageConsoleName "Boot Image 1607" -OSArchitecture "x64" 
# // 
# // File Version:   1.0.7
# // 
# // Note:  
# // $PxeEnabled and $EnableDebugShell are only honored if you create new Boot Images
# // $UpdateDistributionPoints is only honored if you OverwriteExistingImage is set to $True
# // 
# // 
# // ***** End Header *****
# //****************************************************************************

# ***** Disclaimer *****
# This file is provided "AS IS" with no warranties, confers no rights, 
# and is not supported by the authors or Microsoft Corporation. 

 
### Static Parameters
[CmdLetBinding()]
Param
(
    [Parameter(Mandatory = $true,
    HelpMessage='Change the name matching your personal preference - Example: CMBootImage.wim')]
    [ValidateScript({$_.EndsWith(".wim")})]
    [String]$BootImageName,

    [Parameter(Mandatory = $true,
    HelpMessage='Change the name matching your personal preference - Example: "Boot Image 1607"')]
    [String]$BootImageConsoleName,

    [Parameter(Mandatory = $true,
    HelpMessage='Change the name matching your personal preference - Example: "Boot Image based on Windows 10 1607"')]
    [AllowEmptyString()]
    [String]$BootImageConsoleDescription,

    [Parameter(Mandatory = $true,
    HelpMessage='Just cosmetics to display the OS version of your boot image. If this is "" we copy OS version as new version name')]
    [AllowEmptyString()]
    [String]$BootImageConsoleVersion,

    [Parameter(Mandatory = $true,
    HelpMessage="Provide the Boote Image Architecture - Valid Values x86, x64 or Both")]
    [ValidateSet("x86","x64","Both")]
    [String]$OSArchitecture,

    [Parameter(Mandatory = $true,
    HelpMessage='Valid Values True/False - Set to True if you want to enable Command Command support on your new created boot images (applies only to new  created boot images)')]
    [ValidateSet('True','False')]
    [String]$EnableDebugShell,

    [Parameter(Mandatory = $true,
    HelpMessage='Valid Values True/False -Set to True if the new created boot image should be enabled to be deployed from PXE enabled DP  (applies only to new  created boot images)')]
    [ValidateSet('True','False')]
    [String]$PxeEnabled,

    [Parameter(Mandatory = $true,
    HelpMessage='Valid Values True/False - Set to $True if you want to replace an existing boot image')] 
    [ValidateSet('True','False')]
    [String]$OverwriteExistingImage,

    [Parameter(Mandatory = $true,
    HelpMessage='Valid Values True/False - Set to $True if you want update Distribution Point (applies only if $OverwriteExistingImage = $True and the script detects an existing boot image matching $BootImageName)')] 
    [ValidateSet('True','False')]
    [String]$UpdateDistributionPoints
)

### Convert necessary Parameter to Boolean - the Param-Strings were used to simplify the Input in the Beginning

Switch ($EnableDebugShell)
{
    "True" {[Boolean]$EnableDebugShell = $true; Break}
    "False" {[Boolean]$EnableDebugShell = $false; Break}
}

Switch ($PxeEnabled)
{
    "True" {[Boolean]$PxeEnabled = $true; Break}
    "False" {[Boolean]$PxeEnabled = $false; Break}
}

Switch ($OverwriteExistingImage)
{
    "True" {[Boolean]$OverwriteExistingImage = $true; Break}
    "False" {[Boolean]$OverwriteExistingImage = $false; Break}
}

Switch ($UpdateDistributionPoints)
{
    "True" {[Boolean]$UpdateDistributionPoints = $true; Break}
    "False" {[Boolean]$UpdateDistributionPoints = $false; Break}
}
 
### Logging - Static Paramter can be changed
 
[String]$LogfileName = "RegenerateBootImageWinPE"
[String]$Logfile = "$env:SystemRoot\logs\$LogfileName.log"
 
Function Write-Log
{
   Param ([string]$logstring)
   If (Test-Path $Logfile)
   {
       If ((Get-Item $Logfile).Length -gt 2MB)
       {
       Rename-Item $Logfile $Logfile".bak" -Force
       }
   }
   $WriteLine = (Get-Date).ToString() + " " + $logstring
   Add-content $Logfile -value $WriteLine
   Write-Host $WriteLine
}
 
### Verify access to Configuration Manager Console for a PowerShell Commandlet import
 
Try
{
    $ConfigMgrModule = ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')
    Import-Module $ConfigMgrModule
    Write-Log "Found SCCM-Console-Environment"
    Write-Log $ConfigMgrModule
}
Catch
{
    Write-host "Exception Type: $($_.Exception.GetType().FullName)"
    Write-host "Exception Message: $($_.Exception.Message)"
    Write-Host "ERROR! Console not installed or found"
    Write-Host "Script will exit"
    Exit 1
}

### Get Site-Code and Site-Provider-Machine from WMI if possible

Try 
{
    $SMS = gwmi -Namespace 'root\sms' -query "SELECT SiteCode,Machine FROM SMS_ProviderLocation" 
    $SiteCode = $SMS.SiteCode
    $SccmServer = $SMS.Machine
    Write-Log "SiteCode: $SiteCode" 
    Write-Log "SiteServer: $SccmServer" 
}
Catch 
{
    Write-Log "Exception Type: $($_.Exception.GetType().FullName)" 
    Write-Log "Exception Message: $($_.Exception.Message)"
    Write-Log "Unable to find in WMI SMS_ProviderLocation. This Script has to run on a SiteServer!"
    Exit 1
}

### Change to CM-Powershell-Drive
 
Write-Log "Prepare Environment for Boot Image operations. Create PS-Drive if not found."
$CMDrive = Get-PSProvider -PSProvider CMSite
If ($CMDrive.Drives.Count -eq 0)
{
    Write-Log "CMSite-Provider does not have a Drive! Try to create it."
    Try
    {
        New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteProvider
        Write-Log "CMSite-Provider-Drive created!"
    }
    Catch
    {
        Write-Log "Exception Type: $($_.Exception.GetType().FullName)"
        Write-Log "Exception Message: $($_.Exception.Message)"
    }
}

### ReCreate BootImage Function

Function funCreateBootImage
{
[CmdLetBinding()]
Param 
(
    [Parameter(Mandatory = $True)]
    [ValidateSet("x86","x64")]
    [string]$Architecture
)

Switch ($Architecture)
{
    "x86" {$ArchitecturePath = "i386"; Break}
    "x64" {$ArchitecturePath = "x64"; Break}
}

    Write-Log "Connecting to WMI Namespace: \\$SccmServer\root\sms\site_$SiteCode`:SMS_BootImagePackage"
    $BootImageWMIClass = [wmiclass]"\\$SccmServer\root\sms\site_$SiteCode`:SMS_BootImagePackage"
    [String]$BootImageSourcePath = "\\$SccmServer\SMS_$SiteCode`\OSD\boot\$ArchitecturePath\$BootImageName"

    If($(Get-Location) -match $SiteCode)
    {
        Write-Log "Switching Drive to File System"
        Set-Location "C:"
    }

    If (Test-Path -Path $BootImageSourcePath -PathType Leaf)
    {
        If(!$OverwriteExistingImage)
        {
            Write-Log "Error: $BootImageSourcePath found and OverwriteExistingImage is set to `$False"
            # Critical Error occured exit function
            break
        }   
        Write-Log "$BootImageSourcePath found need to backup first"
        Copy-Item $BootImageSourcePath $BootImageSourcePath".bak" -Force
        [boolean]$BootImageFound = $True        
    } 
    Else 
    {
        Write-Log "$BootImageSourcePath not found no need to backup"            
    }
      
    Try
    {
        Write-Log "Generating $Architecture Boot Image. This will take a few minutes... "
        $BootImageWMIClass.ExportDefaultBootImage($Architecture , 1, $BootImageSourcePath) | Out-Null
        Write-Log "New $Architecture Boot Image created continue with post tasks "
        $NewBootImageName = "$BootImageConsoleName ($Architecture)"

        If(-not($BootImageFound))
        {
        # Actions to perform if Boot Image file did not exist
            Write-Log "Performing actions section Boot Image not exist"
            If(-not($(Get-Location) -match $SiteCode))
            {
                Write-Log "Switching Drive for ConfigMgr-CmdLets"
                Set-Location $SiteCode":"
            }

            Try
            {
                Write-Log "Import Boot Image into SCCM"
                If($BootImageConsoleDescription.Length -eq 0)
                {
                    New-CMBootImage -Path $BootImageSourcePath -Index 1 -Name $NewBootImageName -Version $BootImageConsoleVersion | Out-Null
                    Write-Log "Successfully imported $BootImageSourcePath"
                }
                Else
                {
                    New-CMBootImage -Path $BootImageSourcePath -Index 1 -Name $NewBootImageName -Version $BootImageConsoleVersion -Description $BootImageConsoleDescription | Out-Null
                    Write-Log "Successfully imported $BootImageSourcePath"
                }
            }
            Catch
            {
                Write-Log "Error: Failed to import $BootImageSourcePath"
                # Critical Error occured exit function
                break
            }

            Try
            {
                If($BootImageConsoleVersion.Length -eq 0)
                {
                    Write-Log "Get Boot Image Property ImageOSVersion"
                    $BootImageConsoleVersion = (Get-CMBootImage -Name $NewBootImageName).ImageOSVersion
                }
                Write-Log "Apply Boot Image Properties EnableCommandSupport with Value $EnableDebugShell and DeployFromPxeDistributionPoint with Value $PxeEnabled"
                Set-CMBootImage -Name $NewBootImageName -EnableCommandSupport $EnableDebugShell -DeployFromPxeDistributionPoint $PxeEnabled -Version $BootImageConsoleVersion
                Write-Log "Successfully applied Boot image properties"
            }
            Catch
            {
                Write-Log "Failed to apply Boot image properties"
            }

        }
        Else
        {
        # Actions to perform if Boot Image file did exist
        Write-Log "Performing actions section Boot Image did exist"
        $BootImageQuery = Get-WmiObject -Class SMS_BootImagePackage  -Namespace root\sms\site_$($SiteCode) -ComputerName $SccmServer | where-object{$_.ImagePath -like "*$ArchitecturePath*" -and $_.ImagePath -like "*$BootImageName*"}
        
        ForEach($BootImagexIndex in $BootImageQuery)
        {
            $BootImageLogName = $BootImagexIndex.Name
            Write-Log "Working on Boot Image: $BootImageLogName" 
            # Verify if the current Site is owner of this Boot Image (Unneeded in single Primary Site environments)
            If($BootImagexIndex.SourceSite -ne $SiteCode)
            {
                Write-Log "Error: Site is not owner of this Boot Image $BootImageLogName will stop post actions"       
            } 
            Else 
            {
                If($BootImageConsoleVersion.Length -eq 0)
                {
                    $BootImageConsoleVersion = $BootImagexIndex.ImageOSVersion
                }
                
                $BootImagexIndexVersion = $BootImagexIndex.Version
                Write-Log "Will use version: $BootImageConsoleVersion as Version value"
            }
                
                $BootImage = Get-WmiObject -Class SMS_BootImagePackage  -Namespace root\sms\site_$SiteCode -ComputerName $SccmServer | where-object{$_.Name -like "*$BootImageLogName*"}
                Try
                {
                    Write-Log "Reload Image Properties to update console with new information"
                    $BootImage.ReloadImageProperties() | Out-Null
                }
                Catch
                {
                    Write-Log "Error: Failed to Reload Image Properties to update console with new information"
                }

                If($UpdateDistributionPoints)
                {
                    Try
                    {
                        Write-Log "Trigger update Distribution Points"            
                        $BootImage.UpdateImage | Out-Null
                    }
                    Catch
                    {
                        Write-Log "Error: Failed to Trigger update Distribution Points"
                    }
                }

                If(-not($(Get-Location) -match $SiteCode))
                {
                    Write-Log "Switching Drive for ConfigMgr-CmdLets"
                    Set-Location $SiteCode":"
                }

                Try
                {
                    Write-Log "Apply Boot Image Properties for Version with Value $BootImageConsoleVersion"
                    Set-CMBootImage -Name $BootImageLogName -Version $BootImageConsoleVersion
                    Write-Log "Successfully applied Boot image properties"
                }
                Catch
                {
                    Write-Log "Failed to apply Boot image properties"
                }
            }
        }
    }
    Catch
    {
        Write-Log "Error: Failed to create $Architecture Boot Image. Exit $Architecture Boot Image post taks "
        # Critical Error occured exit function
        break
    }
    $BootImageFound = $False  
}

Write-Log "Trying to generate Boot images"

Switch ($OSArchitecture)
{
    "x86" {funCreateBootImage -Architecture x86;Break}
    "x64" {funCreateBootImage -Architecture x64;Break}
    "Both" {
            funCreateBootImage -Architecture x86
            funCreateBootImage -Architecture x64
            ;Break
           }
}


