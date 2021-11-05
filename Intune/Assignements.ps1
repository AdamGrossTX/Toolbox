
#Connect-MSGraph -AdminConsent
$GraphURI = "https://graph.microsoft.com/beta/"
$configurationPoliciesURI = "{0}{1}" -f $GraphURI, "/deviceManagement/configurationPolicies"
$configurationPoliciesAssignURI = "{0}{1}" -f $GraphURI, "/deviceManagement/configurationPolicies"
$AuthToken = ""

$Headers = @{
    "Authorization"="Bearer $($AuthToken)"
}

$configurationPolicies = (Invoke-RestMethod -Uri $configurationPoliciesURI -Method Get -Headers $Headers -ContentType "application/json").value

$configurationPolicyObjects =
    foreach($policy in $configurationPolicies) {
        $assignmentURI = "{0}('{1}')/{2}" -f $configurationPoliciesURI,$policy.id,"assignments"
        $assignments = (Invoke-RestMethod -Uri $assignmentURI -Method Get -Headers $Headers -ContentType "application/json").value
        [string[]]$groupIDs = $assignments.target.groupId
        $body = @{
            ids = $groupIDs
        } | ConvertTo-Json

        $groupURI = "{0}{1}" -f $GraphURI, "directoryObjects/getByIds"
        $GroupNames = (Invoke-RestMethod -Uri $groupURI -Method Post -Body $body -Headers $Headers -ContentType "application/json").value.displayName

        [PSCustomObject]@{
            Type = "ConfigurationPolicy"
            PolicyName = $policy.name
            GroupName = $GroupNames
        }
    }

#$configurationPolicyObjects | Out-GridView


#Connect-MSGraph -AdminConsent
$GraphURI = "https://graph.microsoft.com/beta/"
$configurationPoliciesURI = "{0}{1}" -f $GraphURI, "/deviceManagement/configurationPolicies"
$configurationPoliciesAssignURI = "{0}{1}" -f $GraphURI, "/deviceManagement/configurationPolicies"

$Headers = @{
    "Authorization"="Bearer $($AuthToken)"
}

$configurationPolicies = (Invoke-RestMethod -Uri $configurationPoliciesURI -Method Get -Headers $Headers -ContentType "application/json").value

$configurationPolicyObjects =
    foreach($policy in $configurationPolicies) {
        $assignmentURI = "{0}('{1}')/{2}" -f $configurationPoliciesURI,$policy.id,"assignments"
        $assignments = (Invoke-RestMethod -Uri $assignmentURI -Method Get -Headers $Headers -ContentType "application/json").value
        [string[]]$groupIDs = $assignments.target.groupId
        $body = @{
            ids = $groupIDs
        } | ConvertTo-Json

        $groupURI = "{0}{1}" -f $GraphURI, "directoryObjects/getByIds"
        $GroupNames = (Invoke-RestMethod -Uri $groupURI -Method Post -Body $body -Headers $Headers -ContentType "application/json").value.displayName

        [PSCustomObject]@{
            Type = "ConfigurationPolicy"
            PolicyName = $policy.name
            GroupName = $GroupNames
        }
    }

$configurationPolicyObjects | Out-GridView

