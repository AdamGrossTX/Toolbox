$ServerName = "CM01"
$SiteCode = "PS1"

  $Applications = Get-CMApplication | Where-Object {$_.NumberOfDependentTS -gt 0 -and $_.NumberOfDeploymentTypes -eq 0}
  $TaskSequences = Get-CMTaskSequence | Where-Object { $_.References -ne $null }
  
  # Run application report
  foreach ($Application in $Applications) {
      foreach ($TaskSequence in $TaskSequences) {
          $Ref = New-Object PSObject
          $Ref | Add-Member -type NoteProperty -Name 'Application Name' -Value $Application.LocalizedDisplayName
          $Ref | Add-Member -type NoteProperty -Name 'Package ID' -Value $Application.PackageID
          $Ref | Add-Member -type NoteProperty -Name 'Task Sequence Name' -Value $TaskSequence.Name

        }
      }

      $Ref