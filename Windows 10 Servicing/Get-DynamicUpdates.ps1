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

        1.2 - Added logic to export .JSON files as well. You're welcome @SeguraOSD!!

        1.3 - Changed Property sort order for readability and added KBInfoURL. Removed Month param and collapsed folder structure to \version-arch instead of \version\month\arch\

        1.4 - Fixed Typo and Parameter Validation

        1.5 - Added fix for 2018-09 Windows10.0-KB4457190-x64.cab Setup Update not being classified correctly.

        1.6 - Corrected logic for ALL Updates

#>

#####################

Param
(
    
    [Parameter(HelpMessage="Operating System version to service.")]
    [ValidateSet('1511','1607','1703','1709','1803','1809','Next','All')]
    [string]$OSVersion,
    
    [Parameter(HelpMessage="Architecture version to service.")]
    [ValidateSet ('x64', 'x86','ARM64','All')]
    [string]$OSArch,

    [Parameter(HelpMessage="Path to working directory for servicing data. Default is C:\ImageServicing.")]
    [ValidateNotNullOrEmpty()]
    [string]$RootFolder = "C:\ImageServicing",
    
    [Parameter(Mandatory=$true, HelpMessage="SCCM Primary Server Name.")]
    [string]$SCCMServer,
    
    [Parameter(Mandatory=$true, HelpMessage="SCCM Site Code.")]
    [string]$SiteCode,

    #Use this to download updates. Set to false to just generate the files list(s)
    [Switch]$DownloadUpdates = $True,

    #Use this to download updates. Set to false to just generate the files list(s)
    [Switch]$ExcludeSuperseded

)

$Script:MasterList = @()
$OSVersionList = @('1511','1607','1703','1709','1803','1809','Next')
$OSArchList = @('x86','x64','ARM64')
$AllDynamicUpdatesFilter = 'LocalizedCategoryInstanceNames = "Windows 10 Dynamic Update"'
$AllDynamicUpdates = Get-WmiObject -ComputerName $SCCMServer -Class SMS_SoftwareUpdate -Namespace "root\SMS\Site_$($SiteCode)" -Filter $AllDynamicUpdatesFilter

Function Process-Updates ($OSVersion,$OSArch) {
    Write-Host "Processing $($OSVersion)-$($OSArch)"  -ForegroundColor Green
    If($DownloadUpdates) {
        $UpdatesPath = "$($RootFolder)\Updates\$($OSVersion)-$($OSArch)"
        $DUSUPath = "$($UpdatesPath)\SetupUpdate"
        $DUCUPath = "$($UpdatesPath)\ComponentUpdate"

        if (!(Test-Path -path $DUSUPath)) {New-Item -path $DUSUPath -ItemType Directory}
        if (!(Test-Path -path $DUCUPath)) {New-Item -path $DUCUPath -ItemType Directory}
    }

    $DownloadList = @()
    $DisplayNameFilter = "*$($OSVersion)*$($OSArch)*"

    If($ExcludeSuperseded) {
        $FilteredUpdateList = $AllDynamicUpdates | Where {$_.LocalizedDisplayName -like $DisplayNameFilter -and $_.IsSuperseded -eq $False -and $_.IsLatest -eq $True}
    } Else {
        $FilteredUpdateList = $AllDynamicUpdates | Where {$_.LocalizedDisplayName -like $DisplayNameFilter}
    }

    ForEach ($Update in $FilteredUpdateList) {
        $ContentIDs = Get-WmiObject -ComputerName $SCCMServer -Class SMS_CIToContent -Namespace "root\SMS\Site_$($SiteCode)" -Filter "CI_ID = $($Update.CI_ID)"
        ForEach ($ContentID in $ContentIDs) {
            $Content = Get-WmiObject -ComputerName $SCCMServer -Class SMS_CIContentFiles -Namespace "root\SMS\Site_$($SiteCode)" -Filter "ContentID = $($ContentID.ContentID)"
            $DownloadList  += New-Object PSObject -Property:@{
            'KB' = $Update.ArticleID;
            #'CI_ID' = $Update.CI_ID;
            'DisplayName' = $Update.LocalizedDisplayName;
            #'ContentID' = $ContentIDs.ContentID;
            'FileName' = $Content.FileName;
            'URL' = $Content.SourceURL;
            'KBInfoURL'= $Update.LocalizedInformativeURL;
            'Type' = $Update.LocalizedDescription.Replace(":","")
            'SuperSeded' = $Update.IsSuperseded
            }
        }
    }

    ForEach ($File in $DownloadList) {
        $Path = $null
        #Fix for September SetupUpdate not containing the correct text to classify propery.
        If($File.FileName -eq "Windows10.0-KB4457190-x64.cab") { 
            $Path = "$($DUSUPath)\$($File.FileName)"
        }
        Else {
            switch ($File.Type) {
                SetupUpdate {$Path = "$($DUSUPath)\$($File.FileName)"; break;}
                ComponentUpdate {$Path = "$($DUCUPath)\$($File.FileName)"; break;}
                Default {$Path = "$($UpdatesPath)\$($File.FileName)"; break;}
            }
        }

        If($DownloadUpdates) {
            Write-Host $Path -ForegroundColor Green
            Invoke-WebRequest -Uri $File.URL -OutFile $Path
        }
    }

    If($DownloadList)
    {
        $DownloadList | Sort-Object -Property Type, KB | Select KB, DisplayName, KBInfoURL, Type, FileName, URL | Export-Clixml -Path "$($RootFolder)\$($OSVersion)-$($OSArch)-Windows10DynamicUpdateList.XML"
        $DownloadList | Sort-Object -Property Type, KB | Select KB, DisplayName, KBInfoURL, Type, FileName, URL | ConvertTo-Json | Out-File "$($RootFolder)\$($OSVersion)-$($OSArch)-Windows10DynamicUpdateList.json"
        $Script:MasterList += $DownloadList
    }
}


## MAIN ##
#################################### 

If($OSVersion -eq 'ALL' -and $OSArch -eq 'ALL') {
    ForEach($Version in $OSVersionList) { 
        ForEach($Arch in $OSArchList) { 
            Process-Updates $Version $Arch
        }
    }
}
ElseIf ($OSVersion -eq 'ALL') {
    ForEach($Version in $OSVersionList) { 
        Process-Updates $Version $OSArch
    }
}
ElseIf ($OSArch -eq 'ALL') {
    ForEach($Arch in $OSArchList) { 
        Process-Updates $OSVersion $Arch
    }
} 
Else {
    Process-Updates $OSVersion $OSArch
}

$Script:MasterList | Sort-Object -Property Type, KB | Select KB, DisplayName, KBInfoURL, Type, FileName, URL | Export-Clixml -Path "$($RootFolder)\All-Windows10DynamicUpdateList.XML"
$Script:MasterList | Sort-Object -Property Type, KB | Select KB, DisplayName, KBInfoURL, Type, FileName, URL | ConvertTo-Json | Out-File "$($RootFolder)\All-Windows10DynamicUpdateList.json"

####################################    
