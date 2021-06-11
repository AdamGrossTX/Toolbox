<#
.SYNOPSIS
    Backup and copy group policies to other domains and control with AGPM
.DESCRIPTION
    Backup and copy group policies to other domains and control with AGPM
.EXAMPLE
    PS C:\> .\Copy-GPO.ps1 -BackupPath "C:\GPO\Backup" -GPOList ("My GPO 1","My GPO 1") -SourceDomain "MyDomain.com" -TargetDomain "YourDomain.com" -DomainList @{"MyDomain.com" = "MyDomainDC.MyDomain.com";"YourDomain.com" = "YourDomainDC.YourDomain.com"}

    Backup GPO from MyDomain.com and Import into YourDomain.com
.EXAMPLE
    PS C:\> .\Copy-GPO.ps1 -BackupPath "C:\GPO\Backup" -GPOList ("My GPO 1","My GPO 1") -SourceDomain "MyDomain.com" -TargetDomain "YourDomain.com" -DomainList @{"MyDomain.com" = "MyDomainDC.MyDomain.com";"YourDomain.com" = "YourDomainDC.YourDomain.com"} -ImportIntoAGPM -AGPMGroup "AGPM-ADGroupName" -AGPMUser "AGPM-ADServiceAccountName"

    Backup GPO from MyDomain.com and Import into YourDomain.com and Import into Advanced Group Policy Management (AGPM)
    Explanation of what the example does
.PARAMETER BackupPath
    local path to back up GPOs to. If it doesn't exist, the script will create it.

.PARAMETER GPOList
    one or more GPO names to backup and copy

.PARAMETER SourceDomain
    fqdn of the domain you are copying FROM

.PARAMETER TargetDomain
    fqdn of the domain you are copying TO

.PARAMETER DomainList
    hashtable to map domain fqdn to preferred AD Domain Controller that will be used for copying policies

.PARAMETER ImportIntoAGPM
    optional - if you have AGPM enable this option to import into AGPM

.PARAMETER AGPMGroup
    optional - the AD Group that AGPM uses

.PARAMETER AGPMUser
    optional - the AD Service Account that AGPM uses

.NOTES
    Version:          1.0
    Author:           Adam Gross - @AdamGrossTX
    GitHub:           https://www.github.com/AdamGrossTX
    WebSite:          https://www.asquaredozen.com
    Creation Date:    06/11/2021

#>

[cmdletbinding()]
param (
    [parameter(ParameterSetName="All")]
    [parameter(ParameterSetName="AGPM")]
    [System.IO.DirectoryInfo]$BackupPath,

    [parameter(ParameterSetName="All")]
    [parameter(ParameterSetName="AGPM")]
    [string[]]$GPOList,

    [parameter(ParameterSetName="All")]
    [parameter(ParameterSetName="AGPM")]
    [string]$SourceDomain,

    [parameter(ParameterSetName="All")]
    [parameter(ParameterSetName="AGPM")]
    [string[]]$TargetDomain,

    [parameter(ParameterSetName="All")]
    [parameter(ParameterSetName="AGPM")]
    [hashtable]$DomainList,

    [parameter(ParameterSetName="AGPM")]
    [switch]$ImportIntoAGPM,

    [parameter(ParameterSetName="AGPM")]
    [string[]]$AGPMGroup,

    [parameter(ParameterSetName="AGPM")]
    [string[]]$AGPMUser

)

$script:tick = " " + [char]0x221a
$script:X = " " + [char]0x0058

try {
    if(-not (Test-Path $BackupPath)) { $BackupPath = New-Item -Path $BackupPath -ItemType Directory -Force}

    $GPOs = foreach($GPO in $GPOList) {
        Get-GPO -Name $GPO -Domain $SourceDomain -ErrorAction SilentlyContinue
    }

    foreach($GPO in $GPOs) {
        Write-Host " + Backing up $($GPO.DisplayName)" -ForegroundColor Cyan -NoNewline
        $GPO | Backup-GPO -Path $BackupPath | Out-Null
        Write-Host $Script:tick -ForegroundColor green
    }

    foreach($Domain in $TargetDomain) {
        Write-Host "Domain $($Domain)" -ForegroundColor "Green"
        ForEach($GPO in $GPOs) {
            Write-Host " + Importing $($GPO.DisplayName)" -ForegroundColor Cyan -NoNewline
            $ImportedGPO = Import-GPO -BackupGpoName $GPO.DisplayName -Path $BackupPath -CreateIfNeeded -Domain $Domain -TargetName $GPO.DisplayName -Server $DomainList[$Domain]
            Write-Host $Script:tick -ForegroundColor green

            if($ImportIntoAGPM.IsPresent) {
                if($AGPMGroup) {
                    foreach($Group in $AGPMGroup) {
                        Write-Host " ++ Setting Permissions for $($Group)" -ForegroundColor Cyan -NoNewline
                        $ImportedGPO | Set-GPPermission -TargetType Group -TargetName $Group -PermissionLevel GpoEditDeleteModifySecurity -Server $DomainList[$Domain] -DomainName $Domain | Out-Null
                        Write-Host $Script:tick -ForegroundColor green
                    }
                }
                if($AGPMUser) {
                    foreach($User in $AGPMUser) {
                        Write-Host " ++ Setting Permissions for $($User)" -ForegroundColor Cyan -NoNewline
                        $ImportedGPO | Set-GPPermission -TargetType Group -TargetName $User -PermissionLevel GpoEditDeleteModifySecurity -Server $DomainList[$Domain] -DomainName $Domain | Out-Null
                        Write-Host $Script:tick -ForegroundColor green
                    }
                }

                Write-Host " ++ Getting Controlled GPO" -ForegroundColor Cyan -NoNewline
                $ControlledGPO = Get-ControlledGpo -Domain $Domain | Where-Object {$_.Name -eq $ImportedGPO.DisplayName}
                if($ControlledGPO) {
                    Write-Host $Script:X -ForegroundColor Red
                    Write-Host " ++ $($ImportedGPO.DisplayName) is already managed by AGPM. Manually import from prod in AGPM for Domain $($Domain)." -ForegroundColor "Yellow"
                }
                else {
                    Write-Host $Script:tick -ForegroundColor green
                    Write-Host " ++ Controlled GPO Not Found. Controlling" -ForegroundColor Cyan -NoNewline
                    $ControlledGPO = $ImportedGPO | Add-ControlledGpo -PassThru
                    Write-Host $Script:tick -ForegroundColor green
                    #Don't need to publish it if we just imported it.
                    #$NewControlledGPO | Publish-ControlledGpo -Domain $Domain -PassThru
                }
            }
        }
    }
}
catch {
    Write-Host $Script:X -ForegroundColor Red
    Throw $_
}