<#
This sample script is not supported under any Microsoft standard support program or service. The sample script is
provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without
limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising
out of the use or performance of the sample script and documentation remains with you. In no event shall Microsoft,
its authors, or anyone else involved in the creation, production, or delivery of the script be liable for any damages
whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of
business information, or other pecuniary loss) arising out of the use of or inability to use the sample script or
documentation, even if Microsoft has been advised of the possibility of such damages.
#>

Param(
  # Re-enroll device if cert is missing
  [Parameter(Position = 0)][ValidateRange(0, 1)][int]$Remediate = 0
)

$unregScript = [scriptblock] {
}

if (-not ([System.Management.Automation.PSTypeName]'MdmInterop').Type) {
  $isRegisteredPinvoke = @"
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;

public static class MdmInterop
{
    //DeviceRegistrationBasicInfo - Information about the device registration.
    //MaxDeviceInfoClass      - Max Information about the device registration.
    private enum _REGISTRATION_INFORMATION_CLASS
    {
        DeviceRegistrationBasicInfo = 1,
        MaxDeviceInfoClass
    }

    private  enum DEVICEREGISTRATIONTYPE
    {
        DEVICEREGISTRATIONTYPE_MDM_ONLY = 0,
        DEVICEREGISTRATIONTYPE_MAM = 5,
        DEVICEREGISTRATIONTYPE_MDM_DEVICEWIDE_WITH_AAD = 6,
        DEVICEREGISTRATIONTYPE_MDM_USERSPECIFIC_WITH_AAD = 13
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct _MANAGEMENT_REGISTRATION_INFO
    {
        public bool fDeviceRegisteredWithManagement;
        public int dwDeviceRegistionKind;
        [MarshalAs(UnmanagedType.LPWStr)]
        public string pszUPN;
        [MarshalAs(UnmanagedType.LPWStr)]
        public string pszMDMServiceUri;
    }

    [DllImport("mdmregistration.dll")]
    private static extern int IsDeviceRegisteredWithManagement(ref bool isDeviceRegisteredWithManagement, int upnMaxLength, [MarshalAs(UnmanagedType.LPWStr)] StringBuilder upn);

    [DllImport("mdmregistration.dll")]
    private static extern int GetDeviceRegistrationInfo(_REGISTRATION_INFORMATION_CLASS classType, out IntPtr regInfo);

    public static bool IsDeviceRegisteredWithManagement()
    {
        bool isRegistered = false;
        StringBuilder upn = new StringBuilder(256);
        int hr = IsDeviceRegisteredWithManagement(ref isRegistered, upn.MaxCapacity, upn);
        if (hr != 0)
        {
            throw new Win32Exception(hr);
        }

        //Console.WriteLine("IsDeviceRegisteredWithManagement: Result: 0x{0:x} Upn: {1} IsRegistered: {2}", hr, upn, isRegistered);
        return isRegistered;
    }

    public static bool IsAadBasedEnrollment()
    {
        bool result = false;
        IntPtr pPtr = IntPtr.Zero;

        _REGISTRATION_INFORMATION_CLASS classType = _REGISTRATION_INFORMATION_CLASS.DeviceRegistrationBasicInfo;

        int hr = 0;
        try
        {
            hr = GetDeviceRegistrationInfo(classType, out pPtr);
        }
        catch
        {
            //OS Not support
            return result;
        }

        if (hr != 0)
        {
            throw new Win32Exception(hr);
        }

        _MANAGEMENT_REGISTRATION_INFO regInfo = (_MANAGEMENT_REGISTRATION_INFO)(Marshal.PtrToStructure(pPtr, typeof(_MANAGEMENT_REGISTRATION_INFO)));

        if (regInfo.dwDeviceRegistionKind == (int)DEVICEREGISTRATIONTYPE.DEVICEREGISTRATIONTYPE_MDM_DEVICEWIDE_WITH_AAD)
        {
            result = true;
        }

        return result;
    }
}
"@

  Add-Type -TypeDefinition $isRegisteredPinvoke -Language CSharp -ErrorAction SilentlyContinue
}

if (-not ([System.Management.Automation.PSTypeName]'NetInterop').Type) {
  $isAADJoinPinvoke = @"
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;

    public static class NetInterop
    {
        [DllImport("netapi32.dll")]
        public static extern int NetGetAadJoinInformation(string pcszTenantId, out IntPtr ppJoinInfo);

        [DllImport("netapi32.dll")]
        public static extern void NetFreeAadJoinInformation(IntPtr pJoinInfo);

        [DllImport("netapi32.dll")]
        public static extern int NetGetJoinInformation(string server, out IntPtr name, out NetJoinStatus status);

        //NetSetupUnknownStatus - The status is unknown.
        //NetSetupUnjoined      - The computer is not joined.
        //NetSetupWorkgroupName - The computer is joined to a workgroup.
        //NetSetupDomainName    - The computer is joined to a domain.
        public enum NetJoinStatus
        {
            NetSetupUnknownStatus = 0,
            NetSetupUnjoined,
            NetSetupWorkgroupName,
            NetSetupDomainName
        }

        public static bool IsADJoined()
        {
            IntPtr pPtr = IntPtr.Zero;
            NetJoinStatus joinStatus = new NetJoinStatus();

            int hr = NetGetJoinInformation(null, out pPtr, out joinStatus);

            if (hr != 0)
            {
                throw new Win32Exception(hr);
            }

            if (joinStatus == NetJoinStatus.NetSetupDomainName)
            {
                return true;
            }
            else
            {
                return false;
            }
        }

        public static bool IsAADJoined()
        {
            bool result = false;
            IntPtr pPtr = IntPtr.Zero;

            int hr = 0;
            try
            {
                hr = NetGetAadJoinInformation(null, out pPtr);
                if (hr == 1)
                {
                    //In correct function on 17763.1577 server
                    return false;
                }
                else if(hr != 0)
                {
                    throw new Win32Exception(hr);
                }

                if (pPtr != IntPtr.Zero)
                {
                    result = true;
                }
                else
                {
                    result = false;
                }
            }
            catch
            {
                //OS Not support
                return false;
            }
            finally
            {
                if(pPtr != IntPtr.Zero)
                {
                    NetFreeAadJoinInformation(pPtr);
                }
            }

            return result;
        }
    }
"@
  Add-Type -TypeDefinition $isAADJoinPinvoke -Language CSharp -ErrorAction SilentlyContinue
}

$unregScript = [scriptblock] {
  $pinvokeType = @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class MdmUnregister
{
    [DllImport("mdmregistration.dll")]
    public static extern int UnregisterDeviceWithManagement([MarshalAs(UnmanagedType.LPWStr)] string enrollmentId);
}
"@

  Add-Type -Language CSharp -TypeDefinition $pinvokeType -ErrorAction SilentlyContinue
  $result = [MdmUnregister]::UnregisterDeviceWithManagement($enrollmentId);
  Write-Verbose ("UnregisterDeviceWithManagement returned 0x{0:x8}" -f $result)

  if ($result -eq 0) {
    return
  }

  # See: https://docs.microsoft.com/en-us/windows/win32/mdmreg/mdm-registration-constants for reference
  Write-Error "UnregisterDeviceWithManagement API returned unexpected result: 0x{0:x8}" -f $result
  throw "Could not unregister"
}

$regScript = [scriptblock] {
  $pinvokeType = @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class MdmRegister
{
    [DllImport("mdmregistration.dll")]
    public static extern int RegisterDeviceWithManagementUsingAADDeviceCredentials();

    [DllImport("mdmregistration.dll")]
    public static extern int RegisterDeviceWithManagementUsingAADCredentials(IntPtr token);
}
"@

  Add-Type -Language CSharp -TypeDefinition $pinvokeType -ErrorAction SilentlyContinue
  $result = [MdmRegister]::RegisterDeviceWithManagementUsingAADDeviceCredentials()
  Write-Verbose ("RegisterDeviceWithManagementUsingAADDeviceCredentials returned 0x{0:x8}" -f $result)
  if ($result -eq 0) {
    Write-Output $true
    return
  }

  # See: https://docs.microsoft.com/en-us/windows/win32/mdmreg/mdm-registration-constants for reference
  Write-Warning ("RegisterDeviceWithManagementUsingAADDeviceCredentials API returned unexpected result: 0x{0:x8}. Will attempt fallback API." -f $result)

  $result = [MdmRegister]::RegisterDeviceWithManagementUsingAADCredentials([System.IntPtr]::Zero)
  if ($result -eq 0) {
    Write-Output $true
    return
  }
  else {
    Write-Warning ("Fallback: RegisterDeviceWithManagementUsingAADCredentials API returned unexpected result: 0x{0:x8}" -f $result)
  }

  throw "Could not re-register"
}

function PerformDJ() {
  Write-Verbose "Perform DJ++: dsregcmd.exe"
  dsregcmd.exe /join

  $result = $LASTEXITCODE
  Write-Verbose ("dsregcmd.exe returned 0x{0:x8}" -f $result)

  if ($result -ne 0) {
    Write-Error ("dsregcmd.exe returned unexpected result: 0x{0:x8}" -f $result)
    return $false
  }

  return $true
}

function IsReadyToRemediate() {
  $ReadyToRemediate = $true

  $isAAdJoined = [NetInterop]::IsAADJoined()
  $isAdJoined = [NetInterop]::IsADJoined()

  #Workgroup only
  if (($isAAdJoined -eq $false) -and ($isAdJoined -eq $false)) {
    #Report remediation attempt failed.
    Write-Error "Remediation attempt failed, device is neither AAD joined nor AD joined."
    $ReadyToRemediate = $false
  }

  #AAD joined only
  if (($isAAdJoined -eq $true) -and ($isAdJoined -eq $false)) {
    #Report remediation attempt failed.
    Write-Verbose "Device is AAD joined only. Ready to remediate."
    $ReadyToRemediate = $true
  }

  #Domain joined only
  if (($isAAdJoined -eq $false) -and ($isAdJoined -eq $true)) {
    #Try to perform DJ++
    $exeResult = PerformDJ

    # Check result
    if ($exeResult -eq $true) {
      $isAAdJoined = [NetInterop]::IsAADJoined()
      $isAdJoined = [NetInterop]::IsADJoined()

      if ($isAAdJoined -eq $false) {
        Write-Error "Remediation attempt failed, perform DJ++ success but device is still not AAD joined."
        $ReadyToRemediate = $false
      }

      if ($isAdJoined -eq $false) {
        Write-Error "Remediation attempt failed, perform DJ++ success but device is still not AD joined."
        $ReadyToRemediate = $false
      }
    }
    else {
      Write-Error "Remediation attempt failed, perform DJ++ failed."
      $ReadyToRemediate = $false
    }
  }

  #DJ++
  if (($isAAdJoined -eq $true) -and ($isAdJoined -eq $true)) {
    Write-Verbose "Device is DJ++, ready to remediate."
    $ReadyToRemediate = $true
  }

  return $ReadyToRemediate
}

function IsCoManagementDevice {
  try {
    $ccmSystem = Get-CimInstance -ClassName "CCM_System" -Namespace "root\ccm\invagt"
    return $ccmSystem.CoManaged -eq 1
  }
  catch [System.Exception] {
    Write-Error "Not MDM enrolled device or retrieve wmi 'root\ccm\invagt' failed. Error message: $($_.Exception.Message)"
    return $false
  }
}

function GetGuidAndThumbprintPairFromRegistry {
  $guidAndThumbPrintPair = @{}

  try {
    # Is there mutiple account?
    $account = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts

    foreach ($_ in $account) {
      $p = get-item -path ($_.PSPath + '\Protected')
      if ($p.GetValue("ServerId") -ne "MS DM Server") {
        continue
      }

      try {
        $guidAndThumbPrintPair.Add($_.PSChildName, $_.GetValue("SslClientCertReference"))
      }
      catch {
        $guidAndThumbPrintPair.Add($_.PSChildName, $null)
      }
    }

    return $guidAndThumbPrintPair
  }
  catch {
    Write-Error "Retrieve registry 'HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts' failed."
    return $null
  }
}

function GetGuidAndSubjectPairFromRegistry {
  $guidAndSubjectPair = @{}

  try {
    # Is there mutiple account?
    $account = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts

    foreach ($_ in $account) {
      $p = get-item -path ($_.PSPath + '\Protected')
      if ($p.GetValue("ServerId") -ne "MS DM Server") {
        continue
      }

      try {
        $guidAndSubjectPair.Add($_.PSChildName, $p.GetValue("SslClientCertSearchCriteria"))
      }
      catch {
        $guidAndSubjectPair.Add($_.PSChildName, $null)
      }
    }

    return $guidAndSubjectPair
  }
  catch {
    Write-Error "Retrieve registry 'HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts' failed."
    return $null
  }
}

function IsCertInstalled($pThumbprint) {
  try {
    Write-Verbose "Searching for certificate with thumbprint $pThumbprint"
    $installedCert = Get-ChildItem -Path "Cert:LocalMachine\MY" | Where-Object { $_.Thumbprint -eq $pThumbprint }

    if ($installedCert -ne $null) {
      Write-Verbose "Certificate $pThumbprint was found"
      return $true
    }
    else {
      Write-Verbose "Certificate $pThumbprint was NOT found"
      return $false
    }
  }
  catch {
    Write-Error "Retrieve cert store 'Cert:LocalMachine\MY' failed."
    return $false
  }
}

function IsCertInstalledSubject($pSubject) {
  try {
    Write-Verbose "Searching for certificate with Subject $pSubject"
    $installedCert = Get-ChildItem -Path "Cert:LocalMachine\MY" | Where-Object { $_.Subject -eq $pSubject }

    if ($installedCert -ne $null) {
      Write-Verbose "Certificate $pSubject was found"
      return $true
    }
    else {
      Write-Verbose "Certificate $pSubject was NOT found"
      return $false
    }
  }
  catch {
    Write-Error "Retrieve cert store 'Cert:LocalMachine\MY' failed."
    return $false
  }
}

function GetGuidAndCertConfigurationResultForCoManagementDevice {
  # Get guid and thumbprint pairs from registry
  $guidAndThumbPrintPairs = GetGuidAndThumbprintPairFromRegistry
  $guidAndSubjectPairs = GetGuidAndSubjectPairFromRegistry

  if ($guidAndThumbPrintPairs -ne $null -and $guidAndThumbPrintPairs.Count -gt 0) {
    $thumbprintPrefix = "MY;System;"
    $guidAndThumbPrintAndCertInstalled = @{}

    foreach ($_ in $guidAndThumbPrintPairs.GetEnumerator()) {
      # If the thumbprint is null for the enrollment Id, try fallback to subject, otherwise say missing.
      if ($_.Value -eq $null) {

        $subjectCriteriaPrefix = "Subject=CN%3d"
        $subjectCriteriaSuffix = "&Stores=MY%5CSystem"
        $isFallback = $false
        foreach ($_sb in $guidAndSubjectPairs.GetEnumerator()) {
          if ($_sb.Name -eq $_.Name) {
            if (($_sb.Value -ne $null) -and ($_sb.Value.StartsWith($subjectCriteriaPrefix) -eq $true)) {

              if ($_sb.Value.EndsWith($subjectCriteriaSuffix) -eq $true) {

                $subject = $_sb.Value.Replace($subjectCriteriaSuffix, "")
                $subject = $subject.Replace($subjectCriteriaPrefix, "CN=")

                $isFallback = IsCertInstalledSubject $subject

                if ($isFallback -eq $true) {
                  $guidAndThumbPrintAndCertInstalled.Add($_.Name, ($_sb.Value, $true))
                }
              }
              else {
                #If is not MY;SYSTEM;, then we dont care, say not missing.
                $isFallback = $true
                $guidAndThumbPrintAndCertInstalled.Add($_.Name, ($_sb.Value, $true))
              }
            }

            break
          }
        }

        if ($isFallback -eq $false) {
          $guidAndThumbPrintAndCertInstalled.Add($_.Name, ("", $false))
        }

        continue
      }

      # If the thumbprint is MY;SYSTEM;, check if cert is installed.
      if ($_.Value.StartsWith($thumbprintPrefix) -eq $true) {
        $thumbprint = $_.Value.Replace($thumbprintPrefix, "")
        $certInstalled = IsCertInstalled $thumbprint
        $guidAndThumbPrintAndCertInstalled.Add($_.Key, ($_.Value, $certInstalled))
      }
      else {
        #If is not MY;SYSTEM;, then we dont care, say not missing.
        $guidAndThumbPrintAndCertInstalled.Add($_.Key, ($_.Value, $true))
      }
    }

    return $guidAndThumbPrintAndCertInstalled
  }
  else {
    Write-Verbose "Failed to get enrollment id and thrumbpoint from registry."
  }

  return $null
}


function IsOldWindowsExisted {
  return Test-Path "$env:SystemDrive\Windows.old"
}

function SetUninstallWindow {
  Write-Verbose 'Run DISM /Online /Set-OSUninstallWindow /Value:60'
  try {
    DISM /Online /Set-OSUninstallWindow /Value:60
  }
  catch [System.Exception] {
    Write-Error "Error message: $($_.Exception.Message)"
  }
}

function IsEnrollmentIdInRegistry($enrollmentId) {
  $result = Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\$enrollmentId"
  return $result
}

function IsCertInstalledForEnrollmentId($enrollmentId) {
  $result = $false
  Write-Verbose "Check if the cert is installed for enrollment Id: $enrollmentId"
  $testResult = Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\$enrollmentId"

  if ($testResult -eq $true) {
    try {
      $account = Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\$enrollmentId"
      $thumbprint = $account.GetValue("SslClientCertReference")
      $thumbprintPrefix = "MY;System;"

      if ($thumbprint -ne $null) {
        # If the thumbprint is MY;SYSTEM;, check if cert is installed.
        if ($thumbprint.StartsWith($thumbprintPrefix) -eq $true) {
          $thumbprint = $thumbprint.Replace($thumbprintPrefix, "")
          $result = IsCertInstalled $thumbprint

          if ($result -eq $false) {
            Write-Verbose "$thumbprint cert is not installed for $enrollmentId"
          }
          else {
            Write-Verbose "$thumbprint cert is installed for $enrollmentId."
          }
        }
        else {
          Write-Verbose "$thumbprint is not MY;SYSTEM cert for $enrollmentId in registry, just return true"
          $result = $true
        }
      }
      else {
        Write-Verbose "Thumbprint is null for $enrollmentId in registry."

        #Try to fallback to SslClientCertSearchCriteria
        Write-Verbose "Try to fallback to SslClientCertSearchCriteria."
        $testResult = Test-Path -Path ("HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\$enrollmentId" + "\Protected")
        if ($testResult -eq $true) {
          $protected = Get-Item -Path ("HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\$enrollmentId" + "\Protected")
          $subjectCriteria = $protected.GetValue("SslClientCertSearchCriteria")

          if ($subjectCriteria -ne $null) {
            $subjectCriteriaPrefix = "Subject=CN%3d"
            $subjectCriteriaSuffix = "&Stores=MY%5CSystem"

            # If the subject criteria ends with &Stores=MY%5CSystem
            if ($subjectCriteria.EndsWith($subjectCriteriaSuffix) -eq $true) {
              # If the subject criteria starts with Subject=CN%3d, check if cert is installed.
              if ($subjectCriteria.StartsWith($subjectCriteriaPrefix) -eq $true) {
                $subject = $subjectCriteria.Replace($subjectCriteriaSuffix, "")
                $subject = $subject.Replace($subjectCriteriaPrefix, "CN=")

                $result = IsCertInstalledSubject $subject

                if ($result -eq $false) {
                  Write-Verbose "$subjectCriteria cert is not installed for $enrollmentId"
                }
                else {
                  Write-Verbose "$subjectCriteria cert is installed for $enrollmentId."
                }
              }
              else {
                Write-Verbose "$subjectCriteria is not search by subject."
                $result = $false
              }
            }
            else {
              Write-Verbose "$subjectCriteria is not MY;SYSTEM cert for $enrollmentId in registry, just return true"
              $result = $true
            }
          }
          else {
            Write-Verbose "SslClientCertSearchCriteria was not found for $enrollmentId in registry."
            $result = $false
          }
        }
        else {
          Write-Verbose "The fallback entry 'Protected' key was not found in registry."
          $result = $false
        }
      }
    }
    catch [System.Exception] {
      Write-Error "Failed to get thumbprint for $enrollmentId from registry. Error message: $($_.Exception.Message)"
      $result = $false
    }
  }
  else {
    Write-Verbose "Enrollment Id was not found in registry."
  }

  return $result
}

function CheckEnrollResult {
  Write-Verbose "Check enroll result..."

  # Get cert status for all enrollment Ids by validate registry and cert store
  $guidAndCertConfigurationResult = GetGuidAndCertConfigurationResultForCoManagementDevice

  if ($guidAndCertConfigurationResult -ne $null) {
    $thumbprintPrefix = "MY;System;"
    $subjectCriteriaSuffix = "&Stores=MY%5CSystem"
    $hasMYSystem = $false

    # Check cert status for each enrollment Id
    foreach ($_ in $guidAndCertConfigurationResult.GetEnumerator()) {
      $enrollmentId = $_.Name
      $certThumbprint = $_.Value[0]
      $certConfigurationResult = $_.Value[1]

      # Check if the cert is configured/installed correctly for the current enrollment Id
      if ($certConfigurationResult -eq $false) {
        Write-Verbose "Cert '$certThumbprint' for enrollment Id $enrollmentId is not installed."
        return $false
      }
      else {
        # Check if the cert thumbprint starts with MY;System;
        if ($certThumbprint.StartsWith($thumbprintPrefix) -eq $true -or $certThumbprint.EndsWith($subjectCriteriaSuffix)) {
          $hasMYSystem = $true
        }

        Write-Verbose "Cert $certThumbprint for enrollment Id $enrollmentId is installed/configured correctly."
      }
    }

    if ($hasMYSystem -eq $true) {
      Write-Verbose "All certs are configured correctly."
      return $true
    }
    else {
      Write-Verbose "All existing certs are configured correctly, but still not found MY;System; cert after re-enrollment."
      return $false
    }
  }
  else {
    Write-Warning "Enrollment Id/Certificates are Not Found."
    return $false
  }
}

# Check if it's MDM enrolled device
$isCoMgmt = [MdmInterop]::IsDeviceRegisteredWithManagement() -or (IsCoManagementDevice)
if ($isCoMgmt -eq $true) {
  Write-Verbose "This device is MDM enrolled."

  #Check if AAD based enrollment
  $isAADBasedEnrollment = [MdmInterop]::IsAadBasedEnrollment()
  if ($isAADBasedEnrollment -eq $true) {
    Write-Verbose "This device is AAD based enrollment, perform detect/remediation."

    # Get cert status for all enrollment Ids by validate registry and cert store
    $guidAndCertConfigurationResult = GetGuidAndCertConfigurationResultForCoManagementDevice

    if ($guidAndCertConfigurationResult -ne $null) {
      $overallCertMissing = $false
      $remediationExecuted = $false

      # Check cert status for each enrollment Id
      foreach ($_ in $guidAndCertConfigurationResult.GetEnumerator()) {
        $enrollmentId = $_.Name
        $certThumbprint = $_.Value[0]
        $certConfigurationResult = $_.Value[1]

        # Check if the cert is configured/installed correctly for the current enrollment Id
        if ($certConfigurationResult -eq $false) {
          $overallCertMissing = $true

          Write-Verbose "Cert $certThumbprint for enrollment Id $enrollmentId is not installed."

          # Check if previous Windows exists
          $oldWindows = IsOldWindowsExisted
          if ($oldWindows -eq $true) {
            Write-Verbose "Found previous installed Windows, set uninstall window..."
            SetUninstallWindow
          }
          else {
            Write-Verbose "Cert missed and there is no old windows."
          }

          # Check if we need to remediate the device for the enrollment Id
          if ($Remediate -eq $true) {
            #Check if device is ready to remediate
            $readyToRemediate = IsReadyToRemediate

            if ($readyToRemediate -eq $true) {
              Write-Host "Call unregister device for enrollment Id: $enrollmentId"

              # This must run in MTA and PowerShell is STA by default. We will force it to run in MTA by creating a separate runspace.
              $runspace = [runspacefactory]::CreateRunspace()
              try {
                $runspace.ApartmentState = [System.Threading.ApartmentState]::MTA
                $runspace.Open()
                $pipeline = $runspace.CreatePipeline()
                $pipeline.Commands.AddScript("`$enrollmentId = '$enrollmentId'")
                $pipeline.Commands.AddScript($unregScript)

                $pipeline.Invoke()

                if ($pipeline.HadErrors -eq $true) {
                  Write-Error "One or more errors occurred"
                  $pipeline.Error.ReadToEnd()
                  $callUnregister = $false
                }
                else {
                  $pipeline.Output.ReadToEnd()
                  $callUnregister = $true
                }
              }
              catch {
                $callRegister = $false
              }
              finally {
                $runspace.Close()
              }

              if ($callUnregister -eq $true) {
                $remediationExecuted = $true
                Write-Host "Unregister completed, start to register MDM Using AAD device credentials."

                # This must run in MTA and PowerShell is STA by default. We will force it to run in MTA by creating a separate runspace.
                $runspace = [runspacefactory]::CreateRunspace()
                try {
                  $runspace.ApartmentState = [System.Threading.ApartmentState]::MTA
                  $runspace.Open()
                  $pipeline = $runspace.CreatePipeline()
                  $pipeline.Commands.AddScript($regScript)
                  $pipeline.Invoke()
                  if ($pipeline.HadErrors -eq $true) {
                    Write-Error "One or more errors occurred"
                    $pipeline.Error.ReadToEnd()
                    $callRegister = $false
                  }
                  else {
                    $pipeline.Output.ReadToEnd()
                    $callRegister = $true
                  }
                }
                catch {
                  $callRegister = $false
                }
                finally {
                  $runspace.Close()
                }

                if ($callRegister -eq $true) {
                  Write-Host "Register MDM completed."
                }
                else {
                  Write-Error "Call register MDM failed, leave the work to ccmexec to do on its own schedule."
                }
              }
              else {
                Write-Error "Call unregister failed for enrollment Id: $enrollmentId"
              }
            }
            else {
              Write-Error "Device is not ready for remediate."
            }
          }
          else {
            Write-Verbose "Remediation not enabled."
          }
        }
        else {
          Write-Verbose "Cert $certThumbprint for enrollment Id $enrollmentId is installed/configured correctly."
        }
      }

      # If all certs are installed/configured correctly
      if ($overallCertMissing -eq $false) {
        Write-Output "[Success] Device is MDM enrolled and certificates are present."
      }
      elseif ($remediationExecuted -eq $true) {
        if ($callRegister -eq $true) {
          Write-Output "[Success] Device is now MDM enrolled."
        }
        else {
          Write-Output "[Success] Device is queued for MDM enrollment on next registration cycle"
        }
      }
      else {
        Write-Output "[Error] Device is MDM enrolled but enrollment certificate is missing."
      }
    }
    else {
      Write-Output "[Error] Device is MDM enrolled but enrollment configuration is missing."
    }
  }
  else {
    Write-Output "[Success] Device is not AAD based enrollment."
  }
}
else {
  Write-Output "[Success] This device is not MDM enrolled."
}
# SIG # Begin signature block
# MIIjkgYJKoZIhvcNAQcCoIIjgzCCI38CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCmk7QfRjNvxsh4
# TDhISXCsPDYxzFq+eSSPTN8HlNtkGKCCDYEwggX/MIID56ADAgECAhMzAAABh3IX
# chVZQMcJAAAAAAGHMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjAwMzA0MTgzOTQ3WhcNMjEwMzAzMTgzOTQ3WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDOt8kLc7P3T7MKIhouYHewMFmnq8Ayu7FOhZCQabVwBp2VS4WyB2Qe4TQBT8aB
# znANDEPjHKNdPT8Xz5cNali6XHefS8i/WXtF0vSsP8NEv6mBHuA2p1fw2wB/F0dH
# sJ3GfZ5c0sPJjklsiYqPw59xJ54kM91IOgiO2OUzjNAljPibjCWfH7UzQ1TPHc4d
# weils8GEIrbBRb7IWwiObL12jWT4Yh71NQgvJ9Fn6+UhD9x2uk3dLj84vwt1NuFQ
# itKJxIV0fVsRNR3abQVOLqpDugbr0SzNL6o8xzOHL5OXiGGwg6ekiXA1/2XXY7yV
# Fc39tledDtZjSjNbex1zzwSXAgMBAAGjggF+MIIBejAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUhov4ZyO96axkJdMjpzu2zVXOJcsw
# UAYDVR0RBEkwR6RFMEMxKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1
# ZXJ0byBSaWNvMRYwFAYDVQQFEw0yMzAwMTIrNDU4Mzg1MB8GA1UdIwQYMBaAFEhu
# ZOVQBdOCqhc3NyK1bajKdQKVMFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0w
# Ny0wOC5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAx
# MS0wNy0wOC5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAixmy
# S6E6vprWD9KFNIB9G5zyMuIjZAOuUJ1EK/Vlg6Fb3ZHXjjUwATKIcXbFuFC6Wr4K
# NrU4DY/sBVqmab5AC/je3bpUpjtxpEyqUqtPc30wEg/rO9vmKmqKoLPT37svc2NV
# BmGNl+85qO4fV/w7Cx7J0Bbqk19KcRNdjt6eKoTnTPHBHlVHQIHZpMxacbFOAkJr
# qAVkYZdz7ikNXTxV+GRb36tC4ByMNxE2DF7vFdvaiZP0CVZ5ByJ2gAhXMdK9+usx
# zVk913qKde1OAuWdv+rndqkAIm8fUlRnr4saSCg7cIbUwCCf116wUJ7EuJDg0vHe
# yhnCeHnBbyH3RZkHEi2ofmfgnFISJZDdMAeVZGVOh20Jp50XBzqokpPzeZ6zc1/g
# yILNyiVgE+RPkjnUQshd1f1PMgn3tns2Cz7bJiVUaqEO3n9qRFgy5JuLae6UweGf
# AeOo3dgLZxikKzYs3hDMaEtJq8IP71cX7QXe6lnMmXU/Hdfz2p897Zd+kU+vZvKI
# 3cwLfuVQgK2RZ2z+Kc3K3dRPz2rXycK5XCuRZmvGab/WbrZiC7wJQapgBodltMI5
# GMdFrBg9IeF7/rP4EqVQXeKtevTlZXjpuNhhjuR+2DMt/dWufjXpiW91bo3aH6Ea
# jOALXmoxgltCp1K7hrS6gmsvj94cLRf50QQ4U8Qwggd6MIIFYqADAgECAgphDpDS
# AAAAAAADMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0
# ZSBBdXRob3JpdHkgMjAxMTAeFw0xMTA3MDgyMDU5MDlaFw0yNjA3MDgyMTA5MDla
# MH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMT
# H01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTEwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCr8PpyEBwurdhuqoIQTTS68rZYIZ9CGypr6VpQqrgG
# OBoESbp/wwwe3TdrxhLYC/A4wpkGsMg51QEUMULTiQ15ZId+lGAkbK+eSZzpaF7S
# 35tTsgosw6/ZqSuuegmv15ZZymAaBelmdugyUiYSL+erCFDPs0S3XdjELgN1q2jz
# y23zOlyhFvRGuuA4ZKxuZDV4pqBjDy3TQJP4494HDdVceaVJKecNvqATd76UPe/7
# 4ytaEB9NViiienLgEjq3SV7Y7e1DkYPZe7J7hhvZPrGMXeiJT4Qa8qEvWeSQOy2u
# M1jFtz7+MtOzAz2xsq+SOH7SnYAs9U5WkSE1JcM5bmR/U7qcD60ZI4TL9LoDho33
# X/DQUr+MlIe8wCF0JV8YKLbMJyg4JZg5SjbPfLGSrhwjp6lm7GEfauEoSZ1fiOIl
# XdMhSz5SxLVXPyQD8NF6Wy/VI+NwXQ9RRnez+ADhvKwCgl/bwBWzvRvUVUvnOaEP
# 6SNJvBi4RHxF5MHDcnrgcuck379GmcXvwhxX24ON7E1JMKerjt/sW5+v/N2wZuLB
# l4F77dbtS+dJKacTKKanfWeA5opieF+yL4TXV5xcv3coKPHtbcMojyyPQDdPweGF
# RInECUzF1KVDL3SV9274eCBYLBNdYJWaPk8zhNqwiBfenk70lrC8RqBsmNLg1oiM
# CwIDAQABo4IB7TCCAekwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFEhuZOVQ
# BdOCqhc3NyK1bajKdQKVMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1Ud
# DwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFHItOgIxkEO5FAVO
# 4eqnxzHRI4k0MFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwubWljcm9zb2Z0
# LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcmwwXgYIKwYBBQUHAQEEUjBQME4GCCsGAQUFBzAChkJodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcnQwgZ8GA1UdIASBlzCBlDCBkQYJKwYBBAGCNy4DMIGDMD8GCCsGAQUFBwIB
# FjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2RvY3MvcHJpbWFyeWNw
# cy5odG0wQAYIKwYBBQUHAgIwNB4yIB0ATABlAGcAYQBsAF8AcABvAGwAaQBjAHkA
# XwBzAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJKoZIhvcNAQELBQADggIBAGfyhqWY
# 4FR5Gi7T2HRnIpsLlhHhY5KZQpZ90nkMkMFlXy4sPvjDctFtg/6+P+gKyju/R6mj
# 82nbY78iNaWXXWWEkH2LRlBV2AySfNIaSxzzPEKLUtCw/WvjPgcuKZvmPRul1LUd
# d5Q54ulkyUQ9eHoj8xN9ppB0g430yyYCRirCihC7pKkFDJvtaPpoLpWgKj8qa1hJ
# Yx8JaW5amJbkg/TAj/NGK978O9C9Ne9uJa7lryft0N3zDq+ZKJeYTQ49C/IIidYf
# wzIY4vDFLc5bnrRJOQrGCsLGra7lstnbFYhRRVg4MnEnGn+x9Cf43iw6IGmYslmJ
# aG5vp7d0w0AFBqYBKig+gj8TTWYLwLNN9eGPfxxvFX1Fp3blQCplo8NdUmKGwx1j
# NpeG39rz+PIWoZon4c2ll9DuXWNB41sHnIc+BncG0QaxdR8UvmFhtfDcxhsEvt9B
# xw4o7t5lL+yX9qFcltgA1qFGvVnzl6UJS0gQmYAf0AApxbGbpT9Fdx41xtKiop96
# eiL6SJUfq/tHI4D1nvi/a7dLl+LrdXga7Oo3mXkYS//WsyNodeav+vyL6wuA6mk7
# r/ww7QRMjt/fdW1jkT3RnVZOT7+AVyKheBEyIXrvQQqxP/uozKRdwaGIm1dxVk5I
# RcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIVZzCCFWMCAQEwgZUwfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAAAYdyF3IVWUDHCQAAAAABhzAN
# BglghkgBZQMEAgEFAKCBrjAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgrpdU/gdi
# Bw3EKj3rWerb5xZc4vI1TCXYVoex/3naiAwwQgYKKwYBBAGCNwIBDDE0MDKgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRqAGGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbTAN
# BgkqhkiG9w0BAQEFAASCAQC1gL9bgQqObEX22ejxxRNjJzQ3HpoyPnpu0paJG53o
# f2GH70uFq/4P34FhqmWoapgjbz/oJwusYqc/12BVvdbJdMj6GjHeynMzd8wtCkEk
# ZMaZAJ5utdicK/qKIjikvN147uI3euezFBFjFDxlh69I2O/0Su0YH04trF9HKOl+
# tMgqDIOAdAYsH9E7Ccs5Gzs2mMeMW6EiHc5dLjBx74jKCz+s5AKXCeGw3Z5kb3ur
# MKiqvzzErb9NUxjINbYaA23UMwOkaxYlLy3QgudI3ea0yneq2qyZ7Z0/tuC30m9K
# Jhp2zlWDMk8hDXxDjats8zHKW1PfGfP2J1zAYqSyUoYVoYIS8TCCEu0GCisGAQQB
# gjcDAwExghLdMIIS2QYJKoZIhvcNAQcCoIISyjCCEsYCAQMxDzANBglghkgBZQME
# AgEFADCCAVUGCyqGSIb3DQEJEAEEoIIBRASCAUAwggE8AgEBBgorBgEEAYRZCgMB
# MDEwDQYJYIZIAWUDBAIBBQAEIIvxvcjQiDB78CUdBHGd5h01sCPn78zX33HS2MuI
# 6uE9AgZfu+hid+EYEzIwMjAxMjA4MjE1NjExLjMzNVowBIACAfSggdSkgdEwgc4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1p
# Y3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMg
# VFNTIEVTTjo4OTdBLUUzNTYtMTcwMTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgU2VydmljZaCCDkQwggT1MIID3aADAgECAhMzAAABLCKvRZd1+RvuAAAA
# AAEsMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# MB4XDTE5MTIxOTAxMTUwM1oXDTIxMDMxNzAxMTUwM1owgc4xCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVy
# YXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjo4OTdB
# LUUzNTYtMTcwMTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vydmlj
# ZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAPK1zgSSq+MxAYo3qpCt
# QDxSMPPJy6mm/wfEJNjNUnYtLFBwl1BUS5trEk/t41ldxITKehs+ABxYqo4Qxsg3
# Gy1ugKiwHAnYiiekfC+ZhptNFgtnDZIn45zC0AlVr/6UfLtsLcHCh1XElLUHfEC0
# nBuQcM/SpYo9e3l1qY5NdMgDGxCsmCKdiZfYXIu+U0UYIBhdzmSHnB3fxZOBVcr5
# htFHEBBNt/rFJlm/A4yb8oBsp+Uf0p5QwmO/bCcdqB15JpylOhZmWs0sUfJKlK9E
# rAhBwGki2eIRFKsQBdkXS9PWpF1w2gIJRvSkDEaCf+lbGTPdSzHSbfREWOF9wY3i
# Yj8CAwEAAaOCARswggEXMB0GA1UdDgQWBBRRahZSGfrCQhCyIyGH9DkiaW7L0zAf
# BgNVHSMEGDAWgBTVYzpcijGQ80N7fEYbxTNoWoVtVTBWBgNVHR8ETzBNMEugSaBH
# hkVodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNU
# aW1TdGFQQ0FfMjAxMC0wNy0wMS5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUF
# BzAChj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1RpbVN0
# YVBDQV8yMDEwLTA3LTAxLmNydDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsG
# AQUFBwMIMA0GCSqGSIb3DQEBCwUAA4IBAQBPFxHIwi4vAH49w9Svmz6K3tM55RlW
# 5pPeULXdut2Rqy6Ys0+VpZsbuaEoxs6Z1C3hMbkiqZFxxyltxJpuHTyGTg61zfNI
# F5n6RsYF3s7IElDXNfZznF1/2iWc6uRPZK8rxxUJ/7emYXZCYwuUY0XjsCpP9pbR
# RKeJi6r5arSyI+NfKxvgoM21JNt1BcdlXuAecdd/k8UjxCscffanoK2n6LFw1PcZ
# lEO7NId7o+soM2C0QY5BYdghpn7uqopB6ixyFIIkDXFub+1E7GmAEwfU6VwEHL7y
# 9rNE8bd+JrQs+yAtkkHy9FmXg/PsGq1daVzX1So7CJ6nyphpuHSN3VfTMIIGcTCC
# BFmgAwIBAgIKYQmBKgAAAAAAAjANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJv
# b3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcNMTAwNzAxMjEzNjU1WhcN
# MjUwNzAxMjE0NjU1WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKkdDbx3EYo6IOz8E5f1+n9plGt0
# VBDVpQoAgoX77XxoSyxfxcPlYcJ2tz5mK1vwFVMnBDEfQRsalR3OCROOfGEwWbEw
# RA/xYIiEVEMM1024OAizQt2TrNZzMFcmgqNFDdDq9UeBzb8kYDJYYEbyWEeGMoQe
# dGFnkV+BVLHPk0ySwcSmXdFhE24oxhr5hoC732H8RsEnHSRnEnIaIYqvS2SJUGKx
# Xf13Hz3wV3WsvYpCTUBR0Q+cBj5nf/VmwAOWRH7v0Ev9buWayrGo8noqCjHw2k4G
# kbaICDXoeByw6ZnNPOcvRLqn9NxkvaQBwSAJk3jN/LzAyURdXhacAQVPIk0CAwEA
# AaOCAeYwggHiMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBTVYzpcijGQ80N7
# fEYbxTNoWoVtVTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMC
# AYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV9lbLj+iiXGJo0T2UkFvX
# zpoYxDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20v
# cGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcmwwWgYI
# KwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNydDCBoAYDVR0g
# AQH/BIGVMIGSMIGPBgkrBgEEAYI3LgMwgYEwPQYIKwYBBQUHAgEWMWh0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9QS0kvZG9jcy9DUFMvZGVmYXVsdC5odG0wQAYIKwYB
# BQUHAgIwNB4yIB0ATABlAGcAYQBsAF8AUABvAGwAaQBjAHkAXwBTAHQAYQB0AGUA
# bQBlAG4AdAAuIB0wDQYJKoZIhvcNAQELBQADggIBAAfmiFEN4sbgmD+BcQM9naOh
# IW+z66bM9TG+zwXiqf76V20ZMLPCxWbJat/15/B4vceoniXj+bzta1RXCCtRgkQS
# +7lTjMz0YBKKdsxAQEGb3FwX/1z5Xhc1mCRWS3TvQhDIr79/xn/yN31aPxzymXlK
# kVIArzgPF/UveYFl2am1a+THzvbKegBvSzBEJCI8z+0DpZaPWSm8tv0E4XCfMkon
# /VWvL/625Y4zu2JfmttXQOnxzplmkIz/amJ/3cVKC5Em4jnsGUpxY517IW3DnKOi
# PPp/fZZqkHimbdLhnPkd/DjYlPTGpQqWhqS9nhquBEKDuLWAmyI4ILUl5WTs9/S/
# fmNZJQ96LjlXdqJxqgaKD4kWumGnEcua2A5HmoDF0M2n0O99g/DhO3EJ3110mCII
# YdqwUB5vvfHhAN/nMQekkzr3ZUd46PioSKv33nJ+YWtvd6mBy6cJrDm77MbL2IK0
# cs0d9LiFAR6A+xuJKlQ5slvayA1VmXqHczsI5pgt6o3gMy4SKfXAL1QnIffIrE7a
# KLixqduWsqdCosnPGUFN4Ib5KpqjEWYw07t0MkvfY3v1mYovG8chr1m1rtxEPJdQ
# cdeh0sVV42neV8HR3jDA/czmTfsNv11P6Z0eGTgvvM9YBS7vDaBQNdrvCScc1bN+
# NR4Iuto229Nfj950iEkSoYIC0jCCAjsCAQEwgfyhgdSkgdEwgc4xCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBP
# cGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjo4
# OTdBLUUzNTYtMTcwMTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
# dmljZaIjCgEBMAcGBSsOAwIaAxUADE5OKSMoNx/mYxYWap1RTOohbJ2ggYMwgYCk
# fjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQD
# Ex1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIF
# AON6LOswIhgPMjAyMDEyMDgyMDQ4NDNaGA8yMDIwMTIwOTIwNDg0M1owdzA9Bgor
# BgEEAYRZCgQBMS8wLTAKAgUA43os6wIBADAKAgEAAgInfwIB/zAHAgEAAgIR4zAK
# AgUA43t+awIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIB
# AAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBAC2KreBUMzOjseVR
# jiG78MsYSFK1Zwi+r0YqVjfdQJEuwPIZ6UHuyjGU/3siBUQahXUfqO4kgFdDgyf7
# dbaMMLZWL+Dd0RQ9xagpbmfN4cw75jpIJwdx1VigvPapyS7HrN5gpyUVLapbrhZX
# Ivo0ZyTDoUvJT+n88ED7eJ70zJkYMYIDDTCCAwkCAQEwgZMwfDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
# bWUtU3RhbXAgUENBIDIwMTACEzMAAAEsIq9Fl3X5G+4AAAAAASwwDQYJYIZIAWUD
# BAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0B
# CQQxIgQgkz5fifbc7R1kkl9USLd5o6EBkRqzcsb/BeNVMj/LYikwgfoGCyqGSIb3
# DQEJEAIvMYHqMIHnMIHkMIG9BCBbn/0uFFh42hTM5XOoKdXevBaiSxmYK9Ilcn9n
# u5ZH4TCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
# MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB
# LCKvRZd1+RvuAAAAAAEsMCIEIFwNk2RQwgR31rwcEbn1T5A2cgHjfxw6uhtI2989
# XxIEMA0GCSqGSIb3DQEBCwUABIIBAJyqjK/+mFZN/NE+KFDXIHwTquDqj4Jgjo1B
# y6R0TI7zWLnqWNBCztejoSQjHrMXt+YNq5gL8qVSU1Y5FGIbp0wPedOgnNLb9xuj
# awGW9x5ZkJMIkjH5Ej9RoSFGHRNbG8aA1uOt9+D/tkmE7Ol+bzkXNcyvi+RI6c8f
# XD6Tz14uNwwWot/0MWTzHmlX8dhCuhzM4Strni8E86IeTyR6jIxwE5cA2WpHh4sr
# sQe5UIEjwD35IFL3FfxZWSFb29foohMB6abOw77XNKwpCIjAkyvw94zZcKvKQI2I
# fZVyguQBAXKtk2lFoA6b+IIa6PnQyvnBy9RmYCZyXtbZhd6tDDA=
# SIG # End signature block
