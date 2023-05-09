
Setup for UWF Machines

- Deploy Proactive Remediation to enable Unified Write Filter using Detect-UWFFeature.ps1 and Remediate-UWFFeature.ps1
- Deploy policy to revent PreferredAzureADTenant from being set. If this gets set, the UWFServicing user can't log in and the machine will get stuck in a loop.
- Log into the machine and install all Windows updates that may be pending. Reboot to ensure they are all installed.  This will speed up servicing later on.
- If any updates are attempting to install when you attempt to install the UWF Windows Feature, the feature install will hang until the Windows updates are finished.
- Install any required applications
- Add device to any groups needed to configure Kiosk lockdown
- Sync Intune policies and ensure all settings have applied properly
- Run UWF Enablement PowerShell script - deploy scripts in Win32 app if desired.
- Reboot
- Verify that UWF is working by running "uwfmgr get-config" in an admin cmd prompt Window.
- Ensure that the device has a defined maintenance window - this can be done in the kiosk policy. The device will automatically go into servicing mode during this window and apply any updates.
- Manually disable UWF from admin cmd prompt "uwfmgr filter disable" "uwfmgr volume unprotect c:" then reboot.
- Manually re-enable UWF from admin cmd prompt "uwfmgr filter enable" "uwfmgr volume protect c:" then reboot.
- Any changes made while UWF is disabled will be applied to the OS.
- UWF servicing won't work if any local account doesn't have a password set.
