#Be sure to test your regular expressions.  There are several online test tools available.
#I used this one and it worked very well http://regexstorm.net/tester
#Regex Reference
#https://www.zerrouki.com/powershell-cheatsheet-regular-expressions/

##############################################################################################################################################
#Modify these entries to match your site's needs. So far, these 4 are all I need, but there may be others.
#Format is (RegexValue, ReplacementValue)
$regex = @{}
$regex.Add("ASD\w*-\w+","XXX-ServerName") #Replace server names following format <CompanyPrefix>*-*
$regex.Add("(PS1)\w*","XXX") #Replace all exact matches for your CCM Site Code
$regex.Add("(\.\w?\w?\.|\.)asquaredozen.com",".XXXXXXX.com") #Replace all domain urls matching .*.<mydomain.com> or .<mydomain.com>
$regex.Add("(SecretProductName)","XXXXXXXXX") #Replace any other exact match words - like internal product names and such.
##############################################################################################################################################

#Location of this script.
set-location $PSScriptRoot 

#Path to the log files.  Default location is the same folder as this script.
$logfiles = Get-ChildItem "$PSScriptRoot\*.log" 

Write-Host
forEach ($log in $logfiles){
    Write-Host -f green "Parsing $($log)"
    $Content = (Get-Content $log)
    foreach ($rex in $regex.keys)
    {
        $Content = $Content -ireplace "$($rex)","$($regex[$rex])" #Use ireplace for case insensetive replace
    }
     #Files are saved with "_parsed appended to the end to preserve your originals.
     $parsedLogName = $log.Name.Split('.')[0] + "_parsed." + $log.Name.Split('.')[-1]
     $content | Set-Content $parsedLogName
     
     Write-Host -f green "Parsing Completed for $($log)."
}     