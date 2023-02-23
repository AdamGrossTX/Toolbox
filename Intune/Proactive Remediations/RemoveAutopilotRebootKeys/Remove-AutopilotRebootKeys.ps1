#AdamGrossTX
#Inspired by Rudy's blog. Written so that it doesn't need setacls.exe copied to the device to work
#https://call4cloud.nl/2022/04/dont-be-a-menace-to-autopilot-while-configuring-your-wufb-in-the-hood/
#Notes: 
#       This appears to work when you run as an Intune Script during pre-provisioning. 
#       It also works fine if you run it manually in OOBE before starting Autopilot.
#       It fails when run during user-driven AutoPilot - don't know why at this point. The better option is to NOT deploy any policies that are known to trigger reboots.

Function Enable-Privilege {
    param(
        $Privilege,
        $ProcessId = $pid,
        [Switch]$Disable)

    $Definition = @'
 using System;
 using System.Runtime.InteropServices;

 public class AdjPriv {
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
   ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);

  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);
  [DllImport("advapi32.dll", SetLastError = true)]
  internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);
  [StructLayout(LayoutKind.Sequential, Pack = 1)]
  internal struct TokPriv1Luid {
   public int Count;
   public long Luid;
   public int Attr;
  }

  internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
  internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
  internal const int TOKEN_QUERY = 0x00000008;
  internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
  public static bool EnablePrivilege(long processHandle, string privilege, bool disable) {
   bool retVal;
   TokPriv1Luid tp;
   IntPtr hproc = new IntPtr(processHandle);
   IntPtr htok = IntPtr.Zero;
   retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
   tp.Count = 1;
   tp.Luid = 0;
   if(disable) {
    tp.Attr = SE_PRIVILEGE_DISABLED;
   }
   else
   {
    tp.Attr = SE_PRIVILEGE_ENABLED;
   }
   retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
   retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
   return retVal;
  }
 }
'@


    $ProcessHandle = (Get-Process -id $ProcessId).Handle
    $type = Add-Type $definition -PassThru
    $type[0]::EnablePrivilege($processHandle, $Privilege, $Disable)

}


try {

    Start-Transcript -Path C:\Windows\Temp\Remove-AutoPilotRebootKeys.log -Force -ErrorAction SilentlyContinue
  
    $Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Provisioning\SyncML\RebootRequiredURIs"
    $Properties = @("./Device/Vendor/MSFT/Policy/Config/Update/ManagePreviewBuilds", "./Device/Vendor/MSFT/Policy/Config/DmaGuard/DeviceEnumerationPolicy")

    
    Write-Host "Checking for regkey entries in $regKey"
    do{} until (Enable-Privilege SeTakeOwnershipPrivilege)
    do{} until (Enable-Privilege SeRestorePrivilege)
    whoami /priv

    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Microsoft\Provisioning\SyncML\RebootRequiredURIs", 'ReadWriteSubTree', 'TakeOwnership')
    $person = [System.Security.Principal.NTAccount]"BuiltIn\Administrators"          
    $access = [System.Security.AccessControl.RegistryRights]"FullControl"
    $inheritance = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
    $propagation = [System.Security.AccessControl.PropagationFlags]"None"
    $type = [System.Security.AccessControl.AccessControlType]"Allow"
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule($person, $access, $inheritance, $propagation, $type)
    $acl = $key.GetAccessControl()
    
    Write-Host "Backing up ACL"
    $aclBackup = $key.GetAccessControl().GetSecurityDescriptorBinaryForm()
    $restoreAcl = New-Object System.Security.AccessControl.RegistrySecurity
    $aclIncludeAll = [System.Security.AccessControl.AccessControlSections]::All
    $restoreAcl.SetSecurityDescriptorBinaryForm($aclBackup, $aclIncludeAll)

    Write-Host "Taking Ownership"
    $acl.SetOwner($person)
    $key.SetAccessControl($acl)

    Write-Host "Granting Full Control"
    $acl.AddAccessRule($rule)
    $key.SetAccessControl($acl) 

    foreach ($property in $Properties) {
        Write-Host "Removing Property $($Property) from $($Key)"
        Remove-ItemProperty -Path registry::$Key -Name $property -ErrorAction Continue
    }

    Write-Host "Restoring ACL"
    $key.SetAccessControl($restoreAcl)

    Stop-Transcript -ErrorAction SilentlyContinue

}
catch {
    throw $_
}
