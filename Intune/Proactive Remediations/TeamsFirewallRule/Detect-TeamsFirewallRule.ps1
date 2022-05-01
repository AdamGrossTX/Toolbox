param (
    [switch]$remediate = $false
)

try {

    $Compilant = $true
    
    $users = Get-ChildItem (Join-Path -Path $env:SystemDrive -ChildPath 'Users') -Exclude 'Public', 'ADMINI~*'
    if ($null -ne $users) {
        foreach ($user in $users) {
            $progPath = Join-Path -Path $user.FullName -ChildPath "AppData\Local\Microsoft\Teams\Current\Teams.exe"
            if (Test-Path $progPath) {
                if (-not (Get-NetFirewallApplicationFilter -Program $progPath -ErrorAction SilentlyContinue)) {
                    $InboundRuleName = "Teams.exe Inbound for user $($user.Name)"
                    $OutboundRuleName = "Teams.exe Outbound for user $($user.Name)"
                    
                    $InboundPolicyExists = Get-NetFirewallRule -DisplayName $InboundRuleName -ErrorAction SilentlyContinue
                    $OutboundPolicyExists = Get-NetFirewallRule -DisplayName $OutboundRuleName -ErrorAction SilentlyContinue

                    if(-not $InboundPolicyExists -or -not $InboundPolicyExists) {
                        if($Remediate.IsPresent) {
                            Clear-Variable InboundPolicyExists
                            Clear-Variable OutboundPolicyExists

                            New-NetFirewallRule -DisplayName $InboundRuleName -Direction Inbound -Profile Domain,Public,Private -Program $progPath -Action Allow -Protocol Any -ErrorAction SilentlyContinue
                            New-NetFirewallRule -DisplayName $OutboundRuleName -Direction Outbound -Profile Domain,Public,Private -Program $progPath -Action Allow -Protocol Any -ErrorAction SilentlyContinue
                            
                            $InboundPolicyExists = Get-NetFirewallRule -DisplayName $InboundRuleName -ErrorAction SilentlyContinue
                            $OutboundPolicyExists = Get-NetFirewallRule -DisplayName $OutboundRuleName -ErrorAction SilentlyContinue
                            
                            if($InboundPolicyExists -and $InboundPolicyExists) {
                                Write-Host "Success"
                                exit 0
                            }
                            else {
                                Write-Host "Failure, No Rule Detected after remdiation for user:$($User.Name)"
                                exit 1
                            }
                        }
                        else {
                            Write-Host "Failure, No Rule Detected. Remdiation Needed for user:$($User.Name)"
                            exit 1
                        }
                    }
                    Clear-Variable InboundRuleName
                    Clear-Variable OutboundRuleName
                }
            }
            Clear-Variable progPath
        }
    }
    Write-Host "No Errors Reported. No Remediation Needed."
    exit 0
}
catch {
    Write-Host $_
    exit 1
}

