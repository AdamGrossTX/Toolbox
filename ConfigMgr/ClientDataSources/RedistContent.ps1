$DPS = Get-CimInstance -ComputerName $SiteServer -Namespace "root\sms\site_$($SiteCode)" -query "SELECT * FROM SMS_SystemResourceList WHERE RoleName='SMS Distribution Point'" | Select-Object -ExpandProperty ServerName

foreach ($DP in $DPs){

    # Get Packages in INSTALL_RETRYING state (2)
    $Query = "select * from SMS_PackageStatusDistPointsSummarizer where State in ('1','2','3','7') and SourceNALPath like '%$DP%'"
    $Failures = Get-CimInstance -ComputerName $SiteServer -Namespace "root\sms\site_$($SiteCode)" -Query $Query
    #$Failures | Select PackageID
    Write-Information "INSTALL_RETRYING counts on $($DP) is:" $(($Failures | Measure-Object).Count) -InformationAction Continue

    foreach ($Failure in $Failures) {
        $PackageID = $Failure.PackageID
        Write-Information "Package in INSTALL_RETRYING state on $($DP): $PackageID" -InformationAction Continue
    }
}