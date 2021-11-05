Remove-Variable * -ErrorAction SilentlyContinue

#Import AD Module
if (-not (Get-Module -Name ActiveDirectory)) {
    Import-Module -Name ActiveDirectory -ErrorAction Stop
}
#########################################

$ComputerList = Import-Csv -Delimiter "," -Path $FilePath -Header "ComputerName,DomainName,DomainController"

$SiteCode = "" # Site code 
$ProviderMachineName = "" # SMS Provider machine name

##############################################################

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\"



Function Delete-ADComputers($ComputerList)
{
    Foreach ($Computer in $ComputerList)
    {

        Write-Host "Processing $($ComputerName); Server:$($ServerName)" -ForegroundColor Blue
        Try{
            $Computer = Get-ADComputer -Identity $ComputerName -Server $ServerName -ErrorAction SilentlyContinue
            If($Computer)
            {
                Write-Host "Deleting $($ComputerName) from AD." -ForegroundColor Blue
################THIS IS THE LINE TO DELETE FROM AD############################################
                $Computer | Remove-ADObject -recursive -Confirm:$false -Server $ServerName -ErrorAction Stop
                
                If(Get-ADComputer -Identity $ComputerName -Server $ServerName -ErrorAction SilentlyContinue)
                {
                    Write-Warning "Failed to delete $($ComputerName) from AD."
                }
                Else
                {
                    Write-Host "Deleted $($ComputerName) from AD." -ForegroundColor Blue
                }
                    
            }
            Else
            {
                Write-Warning "Computer $($ComputerName) not found in AD."
            
                    
            }
        }
        catch
        {
           Write-Error "An Error occurred deleting $($Computer) from AD."
        }
}


Function Delete-SCCMObjects ($ComputerList)
{
    Set-Location "$($CMSiteCode):" # Set the current location to be the site code.    

    foreach ($Computer in $ComputerList)
    {
        Write-Host "Processing $($Computer) from SCCM."

        try 
        {
           
            $Device = Get-CMDevice -Name $Computer
            
            If($Device)
            {
                Write-Host "Deleting $($Computer) from SCCM." -ForegroundColor Blue
################THIS IS THE LINE TO DELETE FROM SCCM############################################
                $Device | Remove-CMDevice -Force -ErrorAction Stop
                If(Get-CMDevice -Name $Computer)
                {
                    Write-Warning "Failed to Delete $($Computer) from SCCM." -ForegroundColor Blue
                }
                Else
                {
                    Write-Host "Deleted $($Computer) from SCCM." -ForegroundColor Blue
                }
            }
            Else
            {
                Write-Warning "Could not find $($Computer) in SCCM."
            }
            
        }
        catch
        {
           Write-Error "An Error occurred deleting $($Computer) from SCCM."
           Write-Error $Error[0]
        }
    }
    Set-Location $PSScriptRoot
}



Delete-SCCMObjects $ComputerList
Delete-ADComputers $ComputerList
