## Quick Start Guide

Download the contents of this folder to a local driver such as c:\ImageServicing.

Launch the script and enter parameters as needed. At a minimum you will need to enter your servername and site code. On first launch, the script will look for all of the files and folders needed for servicing. It will create the required folder structure. You will need to add your ISO to the appropriate folder under the ISO folder.

You will also need to have Dynamic Updates enabled in your SCCM Console and be able to see Dynamic Updates in your ConfigMgr console.

Then, go to https://www.catalog.update.microsoft.com/Home.aspx and search for updates that match the os version and build you are servicing. You will need to add each update to their respective folder.

Mount_Image = The DISM mount folder for the OS Image
Mount_BootImage = The DISM mount folder for the Boot Image
Mount_WinREImage = The DISM mount folder for the WinRE Image
WIM_OutPut = a temp directory for WIM files
OriginalBaseMedia = the ISO is extracted here

ISO = Windows ISO Source Media
LCU = Latest Cumilative Update
SSU = Servicing Stack Update (check the LCU KB for the KB number of the required SSU)
Flash = Adobe Flash Player
DotNet = .NET Framework Cumulative Update (New for 1809)
SetupUpdate = Dynamic Update Setup Update
ComponentUpdate = Dynamic Update Component Update

Once you've added the files to the correct folders, you are ready to begin servicing. Close any open explorer windows or anything else that could be using the files if your servicing folder, otherwise, DISM will likely break during the dismount process.

Launch the script again with the desired command lines. If all files and folders are present, it will begin working. In the end, you will end up with a CompletedMedia folder which will have the completed media with updated wims.

Originally created for this blog post. https://www.asquaredozen.com/2018/08/20/adding-dynamic-updates-to-windows-10-in-place-upgrade-media-during-offline-servicing/


