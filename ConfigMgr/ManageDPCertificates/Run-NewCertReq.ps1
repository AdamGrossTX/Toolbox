$NewCertReqSplat = @{
    ConnectTo = "DEVICENAME"
    DNSName = ($ENV:ComputerName).ToString().ToLower()
    FQDN = ([System.Net.DNS]::GetHostByName(($DNSName)).HostName).ToString().ToLower()
    TemplateName = "ASD-Web Server/Client Auth"
    CertStoreLocation = "cert:\LocalMachine\MY"
    CAUrl = "CN=A Square Dozen Issuing CA2,CN=CA01,CN=CDP,CN=Public Key Services,CN=Services,CN=Configuration,DC=ASD,DC=net"
    FriendlyName = "ConfigMgr Web Server/Client Auth"
    OutputFile = "c:\Temp\CertRequest.txt"
    RequestNewCert = $False
    UpdateIISCert = $True
    Export = $False
    ExportPath = "\\cpamhq-wsm01\e$\CPDesk\DPCerts"
}

Set-Location $PSScriptRoot
.\New-CertReq.ps1 @NewCertReqSplat