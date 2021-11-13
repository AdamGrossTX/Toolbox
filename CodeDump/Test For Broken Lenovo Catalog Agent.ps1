<#
.NOTES
    Author:           Adam Gross - @AdamGrossTX
    GitHub:           https://www.github.com/AdamGrossTX
    WebSite:          https://www.asquaredozen.com

#>
Try {
    $Value = Get-CIMInstance -Namespace ROOT\Lenovo\Drivers -ClassName Win32_PnPSignedDriverEx -ErrorAction Stop
}
Catch [Microsoft.Management.Infrastructure.CimException]{
    #Write-Host "Error"
    if($_.Exception.Message -like "*Invalid namespace*") {
        return $true
    }
    else {
        return $false
    }
}

$Event = Get-WinEvent -LogName Application -MaxEvents 3
if($Event.ProviderName -eq "Windows Error Reporting") {
    #$Event | Select *
    Return $false
}
{
    Return $true
}