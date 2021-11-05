# CertInfo.ps1
#
# Written by: Rob VandenBrink
#
# Params: Site name or IP ($ip), Port ($port)


function ChkCert
{
Param ($ip,[int] $Port)
$TCPClient = New-Object -TypeName System.Net.Sockets.TCPClient
try
{
$TcpSocket = New-Object Net.Sockets.TcpClient($ip,$port)
$tcpstream = $TcpSocket.GetStream()
$Callback = {param($sender,$cert,$chain,$errors) return $true}
$SSLStream = New-Object -TypeName System.Net.Security.SSLStream -ArgumentList @($tcpstream, $True, $Callback)
try
{
$SSLStream.AuthenticateAsClient($IP)
$Certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($SSLStream.RemoteCertificate)
}
finally
{
$SSLStream.Dispose()
}
}
finally
{
$TCPClient.Dispose()
}
return $Certificate

}

$Cert = chkcert "cm01.asd.net" 443

