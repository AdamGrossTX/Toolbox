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
    Version:          1.0
    Author:           Adam Gross - @AdamGrossTX
    GitHub:           https://www.github.com/AdamGrossTX
    WebSite:          https://www.asquaredozen.com
    Creation Date:    11/13/2021

#>
function Get-DSREGCMDStatus {
    [cmdletbinding()]
    param(
        [parameter(HelpMessage="Use to add /DEBUG to DSREGCMD")]
        [switch]$bDebug #Can't use Debug since it's a reserved word
    )
    
    try {
        $DSREGCMDStatus = & DSREGCMD /Status
        $DSREGCMDEntries =
        for($i = 0; $i -le $DSREGCMDStatus.Count ; $i++) {
            if($DSREGCMDStatus[$i] -like "*|*") {
                $GroupName = $DSREGCMDStatus[$i].Replace("|","").Trim()
            }
            elseif($DSREGCMDStatus[$i] -like "*:*") {
                $EntryParts = $DSREGCMDStatus[$i].split(":")
                [PSCustomObject] @{
                    GroupName = $GroupName
                    PropertyName = $EntryParts[0].Trim()
                    PropertyValue = $EntryParts[1].Trim()
                }
            }
        }

        return $DSREGCMDEntries
    }
    catch {
        throw $_
    }
}