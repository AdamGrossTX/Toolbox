<#
.NOTES
    Author:           Adam Gross - @AdamGrossTX
    GitHub:           https://www.github.com/AdamGrossTX
    WebSite:          https://www.asquaredozen.com

#>

param(
    [Parameter()]
    [string]
    $InputParam,

    [Parameter()]
    [switch]
    $Remediate = $True,

    [Parameter()]
    [string]
    $NameSpace = "root\cimv2",

    [Parameter()]
    [string]
    $ClassName = "Win32_UserProfile",

    [Parameter()]
    [string]
    $ValidProperty = "HealthStatus",

    [Parameter()]
    [string[]] 
    $FileList = @(
        "C:\Windows\System32\wbem\UserProfileWmiProvider.mof",
        "C:\Windows\System32\wbem\UserProfileConfigurationWmiProvider.mof"
        "C:\Windows\System32\wbem\en-us\UserProfileWmiProvider.mfl",
        "C:\Windows\System32\wbem\en-us\UserProfileConfigurationWmiProvider.mfl"
    )
)

Try {
    $Class = Get-CimInstance -Namespace $NameSpace -ClassName $ClassName
    If(!($Class[0].PSObject.Properties.Name -contains $ValidProperty)) {
        If($Remediate.IsPresent) {
            ForEach($File in $FileList) {
                If(Get-Item -Path $File -ErrorAction Stop) {
                    mofcomp.exe $File
                }
                Else {
                    Write-Host "File $($File) not found."
                }
            }
            Return 0
        }
        Return 1
    }
    Else {
        Return 0
    }
}
Catch {
    Return 0
}