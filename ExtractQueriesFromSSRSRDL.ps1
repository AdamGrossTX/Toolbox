$ReportPath = "C:\SSRS"
$Reports = Get-ChildItem -Path $ReportPath -file "*.rdl"

Try {
ForEach($Report in $Reports) {
    Write-Host "Extracting $($Report.Name)" -ForegroundColor Green
    [xml]$ReportContent = $Report | Get-Content 
    $DataSets = $ReportContent.Report.DataSets.DataSet
    $Count = $DataSets.Count
    ForEach($DataSet in $DataSets) {
        $Number++
        Write-Host "Report $Number of $Count" -ForegroundColor Green
        $DataSet.Query.CommandText | Out-File -FilePath "$($ReportPath)\$($Report).BaseName_$($DataSet.Name).SQL" -Encoding utf8 -Force
    }
    $Count = 0
    $Number = 0
}
}
Catch {
    Write-Host "Error on $($Report.Name)"
}