######################

<#
    .SYNOPSIS
        Service your Windows WIM with monthly updates.

    .DESCRIPTION
        Download Dynamic Updates from Microsoft using SCCM Catalog

    .NOTES

        Author: Adam Gross
        Twitter: @AdamGrossTX

    .LINK
        https://github.com/AdamGrossTX/PowershellScripts/blob/master/Windows%2010%20Servicing/Get-DynamicUpdates.ps1

    .History

        1.0 - Original

        1.1 - Added logic to export XML file list. Added logic to loop through OS Version if No OSVersion or OSArch is selected

#>

#####################


Param
(
    
    [Parameter(Position=1, HelpMessage="Operating System version to service.")]
    [ValidateSet('1511','1607','1703','1709','1803','1809','Next',$null)]
    [string]$OSVersion,
    
    [Parameter(Position=2, HelpMessage="Architecture version to service.")]
    [ValidateSet ('x64', 'x86','ARM64', $null)]
    [string]$OSArch,

    [Parameter(Position=3, HelpMessage="Year-Month of updates to apply (Format YYYY-MM). Default is 2018-08.")]
    [string]$Month,
    
    [Parameter(Position=4, HelpMessage="Path to working directory for servicing data. Default is C:\ImageServicing.")]
    [ValidateNotNullOrEmpty()]
    [string]$RootFolder = "C:\ImageServicing",
    
    [Parameter(Mandatory=$true, Position=5, HelpMessage="SCCM Primary Server Name.")]
    [string]$SCCMServer,
    
    [Parameter(Mandatory=$true, Position=6, HelpMessage="SCCM Site Code.")]
    [string]$SiteCode,

    #Use this to download updates. Set to false to just generate the files list(s)
    [Switch]$DownloadUpdates = $True

)

$Script:MasterList = @()

$OSVersionList = @('1511','1607','1703','1709','1803','1809','Next')

$OSArchList = @('x86','x64','ARM64')

$AllDynamicUpdatesFilter = 'LocalizedCategoryInstanceNames = "Windows 10 Dynamic Update"'

$AllDynamicUpdates = Get-WmiObject -ComputerName $SCCMServer -Class SMS_SoftwareUpdate -Namespace "root\SMS\Site_$($SiteCode)" -Filter $AllDynamicUpdatesFilter


Function Process-Updates ($OSVersion,$OSArch)
{
        Write-Host "Processing $($OSVersion)-$($OSArch)"  -ForegroundColor Green
        
        If($DownloadUpdates)
        {
            $UpdatesPath = "$($RootFolder)\Updates\$($OSVersion)\$($Month)\$($OSArch)"

            $DUSUPath = "$($UpdatesPath)\SetupUpdate"

            $DUCUPath = "$($UpdatesPath)\ComponentUpdate"


            if (!(Test-Path -path $DUSUPath)) {New-Item -path $DUSUPath -ItemType Directory}

            if (!(Test-Path -path $DUCUPath)) {New-Item -path $DUCUPath -ItemType Directory}
        }

        $DownloadList = @()

        $DisplayNameFilter = "*$($OSVersion)*$($OSArch)*"

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

                'Type' = $Update.LocalizedDescription.Replace(":","")

                }

            }

        }

        ForEach ($File in $DownloadList)

        {

            $Path = $null

            switch ($File.Type)

            {
                SetupUpdate {$Path = "$($DUSUPath)\$($File.FileName)"; break;}

                ComponentUpdate {$Path = "$($DUCUPath)\$($File.FileName)"; break;}

                Default {$Path = "$($UpdatesPath)\$($File.FileName)"; break;}

            }

            If($DownloadUpdates) {
                Write-Host $Path -ForegroundColor Green
                Invoke-WebRequest -Uri $File.URL -OutFile $Path
            }

        }

        If($DownloadList)
        {
            $DownloadList | Export-Clixml -Path "$($RootFolder)\$($OSVersion)-$($OSArch)-Windows10DynamicUpdateList.XML"
            $Script:MasterList += $DownloadList
        }

    }


## MAIN ##

If(!($OSVersion)) {

    ForEach($Version in $OSVersionList) { 

        If(!($OSArch))
        {
            ForEach($Arch in $OSArchList) { 
                Process-Updates $Version $Arch
            }
        }
        Else
        {
            Process-Updates Process-Updates $Version $OSArch
        }
    }
}
Else {

    If(!($OSArch))
    {
        ForEach($Arch in $OSArchList) { 
            Process-Updates $OSVersion $Arch
        }
    }
    Else
    {
        Process-Updates Process-Updates $OSVersion $OSArch
    }
}

$Script:MasterList | Export-Clixml -Path "$($RootFolder)\All-Windows10DynamicUpdateList.XML"

####################################    
