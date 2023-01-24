param (
    $id,
    [bool]$Remediate = $True
)
try{
    # registry keys to look for
    $RegKeys = @("registry::HKEY_LOCAL_MACHINE\SOFTWARE\TeamViewer\DeviceManagementV2", "registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\TeamViewer\DeviceManagementV2")
    $Name = "Unmanaged"
    $FoundKeys = Get-ItemProperty -Path $RegKeys -Name $Name -ErrorAction SilentlyContinue
    if ($FoundKeys.Unmanaged) {     # is either reg entry there?
        if($remediate -eq $True) {    # please remediate it
            if ($FoundKeys.PSPath -like '*WOW6432Node*') {
                #run 32 bit
                $FilePath = "C:\Program Files (x86)\TeamViewer\TeamViewer.exe"
            }
            else {
                #run 64 bit
                $FilePath = "C:\Program Files\TeamViewer\TeamViewer.exe"
            }
            # assignment ID for account
            $ArgumentList = @("assignment --id $($id)")
            
            # run it
            start-process -wait -FilePath $FilePath -ArgumentList $ArgumentList
            write-output "TeamViewer assignment executed"
            Exit 0
        } else {    # no remediation requested
            write-output "Not Compliant"
            exit 1
        }
    }
    else {
        #not found
        write-output "Compliant"
        exit 0
    }
}

Catch {
    Write-Warning $_
    Exit 1
}
