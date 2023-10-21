
<#PSScriptInfo

.VERSION 1.5

.GUID 89d1849e-0dcc-47f1-8adf-9147a2647a29

.AUTHOR Adam Gross

.COMPANYNAME A Square Dozen

.COPYRIGHT Adam Gross 2021

.TAGS Azure,Intune,AAD,HAADJ,DSREGCMD

.LICENSEURI

.PROJECTURI https://github.com/AdamGrossTX/Toolbox/blob/master/Intune/Get-DSREGCMGStatus.ps1

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#> 






<#
.SYNOPSIS
Simple script to format DSREGCMD /Status output

.DESCRIPTION 
Simple script to format DSREGCMD /Status output

.PARAMETER bDebug
Use to add /DEBUG to DSREGCMD

.EXAMPLE
Retun DSREGCMD /STATUS Output

PS C:\> Get-DSREGCMDStatus

.EXAMPLE
Retun DSREGCMD /STATUS /DEBUG Output. Only returns debug data if there are errors with the join process.

PS C:\> Get-DSREGCMDStatus -bDebug

.NOTES
    Version:          1.5
    Author:           Adam Gross - @AdamGrossTX
    GitHub:           https://www.github.com/AdamGrossTX
    WebSite:          https://www.asquaredozen.com
    Creation Date:    11/13/2021

#>
[cmdletbinding()]
param(
    [parameter(HelpMessage="Use to add /DEBUG to DSREGCMD")]
    [switch]$bDebug #Can't use Debug since it's a reserved word
)
try {
    $cmdArgs = if($bDebug) {"/STATUS","/DEBUG"} else {"/STATUS"}
    $DSREGCMDStatus = & DSREGCMD $cmdArgs

    $DSREGCMDEntries = [PSCustomObject]@{}

    if($DSREGCMDStatus) {
        for($i = 0; $i -le $DSREGCMDStatus.Count ; $i++) {
            if($DSREGCMDStatus[$i] -like "| *") {
                $GroupName = $DSREGCMDStatus[$i].Replace("|","").Trim().Replace(" ","")
                $Member = @{
                    MemberType = "NoteProperty"
                    Name = $GroupName
                    Value = $null
                }
                $DSREGCMDEntries | Add-Member @Member
                $i++ #Increment to skip next line with +----
                $GroupEntries = [PSCustomObject]@{}

                do {
                $i++
                    if($DSREGCMDStatus[$i] -like "*::*") {
                        $DiagnosticEntries = $DSREGCMDStatus[$i] -split "(^DsrCmd.+(?=DsrCmd)|DsrCmd.+(?=\n))" | Where-Object {$_ -ne ''}
                        foreach($Entry in $DiagnosticEntries) {
                            $EntryParts = $Entry -split "(^.+?::.+?: )" | Where-Object {$_ -ne ''}
                            $EntryParts[0] = $EntryParts[0].Replace("::","").Replace(": ","")
                            if($EntryParts) {
                                $Member = @{
                                    MemberType = "NoteProperty"
                                    Name = $EntryParts[0].Trim().Replace(" ","")
                                    Value = $EntryParts[1].Trim()
                                }
                                $GroupEntries | Add-Member @Member
                                $Member = $null
                            }
                        }
                    }
                    elseif($DSREGCMDStatus[$i] -like "* : *") {
                        $EntryParts = $DSREGCMDStatus[$i] -split ':'
                        if($EntryParts) {
                            $Member = @{
                                MemberType = "NoteProperty"
                                Name = $EntryParts[0].Trim().Replace(" ","")
                                Value      = if ($EntryParts.Count -gt 2) {
                                                ( $EntryParts[1..(($EntryParts.Count) - 1)] -join ":").Split("--").Replace("[ ", "").Replace(" ]", "").Trim()
                                            }
                                            else {
                                                $EntryParts[1].Trim()
                                            }
                            }
                            $GroupEntries | Add-Member @Member
                            $Member = $null
                        }
                    }
                    
                } until($DSREGCMDStatus[$i] -like "+-*" -or $i -eq $DSREGCMDStatus.Count)
    
                $DSREGCMDEntries.$GroupName = $GroupEntries
            }
        }
        return $DSREGCMDEntries
    }
    else {
        return "No Status Found"
    }
}
catch {
    throw $_
}
