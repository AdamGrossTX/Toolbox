## Quick Start Guide

Download the contents of this folder to a local driver such as c:\ImageServicing.

Launch the script and enter parameters as needed. At a minimum you will need to enter your servername and site code. On first launch, the script will look for all of the files and folders needed for servicing. It will create the required folder structure. You will need to add your ISO to the appropriate folder under the ISO folder.


* Mount_Image = The DISM mount folder for the OS Image
* Mount_BootImage = The DISM mount folder for the Boot Image
* Mount_WinREImage = The DISM mount folder for the WinRE Image
* WIM_OutPut = a temp directory for WIM files
* OriginalBaseMedia = the ISO is extracted here
* ISO = Windows ISO Source Media
* LCU = Latest Cumilative Update
* SSU = Servicing Stack Update (check the LCU KB for the KB number of the required SSU)
* Flash = Adobe Flash Player
* DotNet = .NET Framework Cumulative Update (New for 1809)
* SetupUpdate = Dynamic Update Setup Update
* ComponentUpdate = Dynamic Update Component Update

Launch the script again with the desired command lines. If all files and folders are present, it will begin working. In the end, you will end up with a CompletedMedia folder which will have the completed media with updated wims.

### Note
Beginning in Windows 10 1809, the servicing model has improved. At the moment, dynamic updates are no longer delivered from WSUS and can't be downloaded by the script. I have reached out to the product group to ask for assistance on offline servicing options. They said that this is being worked on, but there's no solution yet. The best option I've found is to run the Feature Update on a device and it will download the CAB files into the c:\$Windows.~BT folder where you can grab them and add to the script.

Originally created for this blog post. https://www.asquaredozen.com/2018/08/20/adding-dynamic-updates-to-windows-10-in-place-upgrade-media-during-offline-servicing/


