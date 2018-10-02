Download all of the files included here then follow the blog post for steps. See Examples in PowerShell for command line options.

http://www.asquaredozen.com/2018/07/29/configuring-802-1x-authentication-for-windows-deployment/


Add your own Root Certificate to the media and name it root.cer

NOTE: I found that my password contained special characters that caused winpeshl.exe to fail to pass the creds properly. I moved the creds into the PowerShell script instead of passing them in the command line inside the winpeshl.ini file.
