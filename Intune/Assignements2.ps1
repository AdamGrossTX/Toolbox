param (
    $AuthToken
)

$GraphURI = "https://graph.microsoft.com/beta/"

$Headers = @{
    "Authorization"="Bearer $($AuthToken)"
}

$URIList = @(
    ("$($GraphURI)deviceManagement/groupPolicyConfigurations?`$expand=assignments"),
    ("$($GraphURI)deviceManagement/deviceConfigurations?`$expand=assignments"),
    ("$($GraphURI)deviceAppManagement/mobileAppConfigurations?`$expand=assignments"),
    ("$($GraphURI)/deviceManagement/configurationPolicies?`$expand=assignments"),
    ("$($GraphURI)/deviceManagement/intents?`$expand=assignments")
)

$Results =
    foreach($URI in $URIList) {
        (Invoke-RestMethod -Uri $URI -Method Get -Headers $Headers -ContentType "application/json").value
    }

    $groupURI = "$($GraphURI)directoryObjects/getByIds"
    $ProfileList =
    foreach($Result in $Results) {
        [string[]]$groupIDs = $null
        [string[]]$groupNames = $null
        $Assignments = $null

        if($Result."assignments@odata.context" -like '*intents*') {
            $AssigmentsURI = ($Result."assignments@odata.context").Replace("`$metadata#","")
            $Assignments = (Invoke-RestMethod -Uri $AssigmentsURI -Method Get -Headers $Headers -ContentType "application/json").value
        }
        else {
            $Assignments = $Result.assignments
        }

        if($Assignments.target.groupid) {
            [string[]]$groupIDs = $Assignments.target.groupid
            if($groupIDs) {
                $body = @{
                    ids = $groupIDs
                } | ConvertTo-Json
                [string[]]$GroupNames = (Invoke-RestMethod -Uri $groupURI -Method Post -Body $body -Headers $Headers -ContentType "application/json").value.displayName
            }
        }
        [PSCustomObject]@{
            Id = $Result.id
            Name = if($result.DisplayName) {$Result.DisplayName} else {$Result.Name}
            IsAssigned = if($Assignments) {$true} else {$Result.isassigned}
            Assignments = $Assignments
            GroupNames = if($GroupNames) {$GroupNames} else {"None"}
        }
    }

$ProfileList | Out-GridView