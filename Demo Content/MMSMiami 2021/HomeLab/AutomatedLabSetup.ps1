Install-PackageProvider Nuget -Force
Install-Module AutomatedLab -AllowClobber

Set-PSFConfig -Module AutomatedLab -Name LabAppDataRoot -Value /home/youruser/.alConfig -PassThru | Register-PSFConfig
New-LabSourcesFolder -Drive D

#
Get-LabAvailableOperatingSystem -Path D:\LabSources


#
New-LabDefinition -Name GettingStarted2 -DefaultVirtualizationEngine HyperV

Add-LabMachineDefinition -Name SecondServer -OperatingSystem 'Windows Server 2019 Standard (Desktop Experience)'

Install-Lab

Show-LabDeploymentSummary