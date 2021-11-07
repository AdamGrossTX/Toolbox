$profiles = [system.collections.arraylist]::new()
(netsh wlan show profiles) | %{
    If ($_ -match "(profile)(\s+:)") {
        $profiles.Add(($_ -Split ":")[1] -Replace "\s") | Out-Null
    }
}

If (!$profiles) { Break }

ForEach ($profile in $profiles) {
    $config = (netsh wlan show profile name="$profile")
    $setting = (($config -match "(Cost\s+:+)") -Split ":")[1] -Replace "\s"

    If ($setting -ne 'Unrestricted') {
        (netsh wlan set profile parameter name="$profile" cost="Unrestricted")
    }

}