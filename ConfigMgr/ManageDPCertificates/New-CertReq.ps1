Param (

    [string]
    $DNSName,

    [string]
    $FQDN,

    [string]
    $TemplateName,

    [string]
    $CertStoreLocation = "cert:\LocalMachine\MY",

    [string]
    $CAUrl,

    [string]
    $FriendlyName = "ConfigMgr Web Server/Client Auth",

    [string]
    $OutputFile = "c:\Temp\CertRequest.txt",

    [switch]
    $RequestNewCert = $True,

    [switch]
    $UpdateIISCert = $True,

    [switch]
    $Export = $True,

    [string]
    $ExportPath = "\\CM01.ASD.Net\DPCerts",

    $Creds

)

$Main = {

    If(!($DNSName)) {
        $DNSName = ($ENV:ComputerName).ToString().ToLower()
    }

    If(!($FQDN)) {
        $FQDN = ([System.Net.DNS]::GetHostByName(($DNSName)).HostName).ToString().ToLower()
    }

    $Templates = Get-TemplateList
    $TemplateToIssue = $Templates[$Templates.TemplatePropFriendlyName.IndexOf($TemplateName)]

    If($TemplateToIssue) {

        Write-Host $SANDNSName

        $SANDNSName = @($FQDN,$DNSName)

        If($RequestNewCert) {
            Get-Certificate -Url "LDAP:////$($CAUrl)" -Template $TemplateToIssue.TemplatePropCommonName -DnsName $SANDNSName -CertStoreLocation $CertStoreLocation -Verbose
        } 
        Else {
            Write-Host "Skipping Cert Request. Checking for pending certs."
        }

        $Requests = Get-ChildItem -Path "cert:\LocalMachine\Request" | Where-Object {$_.EnrollmentServerEndPoint.URL.OriginalString -ne $Null}

        ForEach ($Request in $Requests){
            Do {
                $Result = Get-Certificate -Request $Request
                If($Result.Status -eq 'Pending') {
                    Write-Host "Cert still Pending Approval"
                }
                ElseIf($Result.Status -eq 'Issued') {
                    $CertsToUpdate = Get-ChildItem -Path $CertStoreLocation | Where-Object {$_.Thumbprint -eq $Result.Certificate.Thumbprint}
                }
                Write-Host "Waiting for Pending Cert to Be Issued" -ForegroundColor Green
                Write-Host "Sleeping 30 seconds" -ForegroundColor Green
                Start-Sleep -Seconds 30
            } Until ($Result.Status -eq 'Issued')
        }

        If(!($CertsToUpdate)) {
            $CertsToUpdate = Get-ChildItem -Path $CertStoreLocation | Where-Object {$_.FriendlyName -eq '' -and  $_.Extensions.Oid.FriendlyName -match "Certificate Template Information" -and $_.Extensions.Format(1) -Match $TemplateToIssue.TemplatePropFriendlyName}
        }

        If($CertsToUpdate) {
            ForEach($Cert in $CertsToUpdate) {
                If(!$Cert.FriendlyName) {
                    $Cert.FriendlyName = $FriendlyName  
                }
            }
        }
    }

    IF($UpdateIISCert) {
        Update-IISCert -FriendlyName $FriendlyName -CertStoreLocation $CertStoreLocation
    }

    If($Export) {
        Export-DPCert -FriendlyName $FriendlyName -CertStoreLocation $CertStoreLocation -ExportPath $ExportPath -Creds $Creds
    }

}

Function Get-TemplateList {
    $TemplateList = certutil -template | Select-String -Pattern "Template\[.+]\:" -AllMatches -Context 2

    $Templates = @()
    ForEach($Template in $TemplateList.Context)
    {
        $TempVals = $Template.PostContext.Split('=')
        $TemplateObject = [PSCustomObject]@{
            $TempVals[0].Trim() = $TempVals[1].Trim()
            $TempVals[2].Trim() = $TempVals[3].Trim()
        }

        $Templates += $TemplateObject
    }

    Return $Templates
}

Function Update-IISCert {
    Param (
        [string]
        $IISSite = "Default Web Site",

        [string]
        $FriendlyName,

        [string]
        $HostName,

        [string]
        $CertStoreLocation

    )

    Import-Module WebAdministration

    Set-Location -Path $CertStoreLocation
    $WebServerCert = Get-ChildItem -Path $CertStoreLocation | Where-Object {$_.FriendlyName -eq $FriendlyName}

    If($WebServerCert) {
        Set-Location IIS:\SSLBindings
        $CurrentCert = Get-ChildItem -Path IIS:\SSLBindings | Where-Object {$_.Port -eq 443}
        If($CurrentCert)
        {
            If($CurrentCert.Thumbprint -eq $WebServerCert.Thumbprint) {
                Write-Host "Correct Cert is Already Assigned."
                iisreset
            }
            Else {
                Write-Host "Updating Cert."
                $CurrentCert | Remove-Item
                $WebServerCert | New-Item 0.0.0.0!443
            }
        }
    }
    Else {
        Write-Host "No web server cert found in the store"
    }
    Set-Location $PSScriptRoot
}



Function Export-DPCert {
    Param (
        [string]
        $FriendlyName,

        [string]
        $CertStoreLocation,

        [string]
        $ExportPath,

        $Creds

    )

    Set-Location -Path $CertStoreLocation
    $DPCert = Get-ChildItem -Path $CertStoreLocation | Where-Object {$_.FriendlyName -eq $FriendlyName}

    $myPwd = ConvertTo-SecureString -string "P@ssw0rd" -Force -AsPlainText
    If($DPCert) {
        $DPCert | Export-PfxCertificate -FilePath (Join-Path -Path $ExportPath -ChildPath "$($ENV:ComputerName)_DPCert.pfx") -Password $myPwd
    }
    Else {
        Write-Host "No Distribution Point cert found in the store"
    }
    Set-Location $PSScriptRoot
}

& $Main