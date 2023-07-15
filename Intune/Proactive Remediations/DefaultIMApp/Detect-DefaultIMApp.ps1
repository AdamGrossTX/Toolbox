#Thanks @matbg for the tip
#https://twitter.com/matbg/status/1679760512874053632?s=46&t=wqKIfQ91Lwnlhukm2orOpQ
#Run as logged on user.
#Detect the selected IM Provider
#Teams = Microsoft Teams
#MSTeams = New Teams preview appx app
#Skype = Shame on you. Time to upgrade!
try {
    $DefaultIMApp = Get-ItemProperty -Path registry::"HKEY_CURRENT_USER\Software\IM Providers" | Select-Object -ExpandProperty DefaultIMApp
    if($DefaultIMApp) {
        Write-Host $DefaultIMApp
    }
    else {
        Write-Host "NONE"
    }
    exit 0
}
catch {

}
