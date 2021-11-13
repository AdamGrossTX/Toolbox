<#
.NOTES
    Author:           Adam Gross - @AdamGrossTX
    GitHub:           https://www.github.com/AdamGrossTX
    WebSite:          https://www.asquaredozen.com

#>

$user = "azuread\xxx@domain.com"
$localadmingroup = get-localgroup -sid S-1-5-32-544
Add-LocalGroupMember -Group $localadmingroup -Member $user