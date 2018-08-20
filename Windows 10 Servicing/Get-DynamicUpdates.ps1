#########################################################################
$RootFolder = "C:\ImageServicing"

$OSVersion = "1709"

$OSArch = "x64"

$Month = "2018-07"

$SCCMServer = "CM01"

$SiteCode = "PS1"

#########################################################################

$UpdatesPath = "$($RootFolder)\Updates\$($OSVersion)\$($Month)\$($OSArch)"

$DUSUPath = "$($UpdatesPath)\SetupUpdate"
$DUCUPath = "$($UpdatesPath)\ComponentUpdate"

if (!(Test-Path -path $DUSUPath)) {New-Item -path $DUSUPath -ItemType Directory}
if (!(Test-Path -path $DUCUPath)) {New-Item -path $DUCUPath -ItemType Directory}

$DownloadList = @()

$DisplayNameFilter = "*$($OSVersion)*$($OSArch)*"

$AllDynamicUpdatesFilter = 'LocalizedCategoryInstanceNames = "Windows 10 Dynamic Update"'

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
    $Path

    Invoke-WebRequest -Uri $File.URL -OutFile $Path
}
