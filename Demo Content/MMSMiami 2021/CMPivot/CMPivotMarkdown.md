# CMPivot Reference

## AadStatus

* **Query Type**: Powershell
* **Local Query Name**: AadStatus
* **Syntax**:

    ```Kusto
    AadStatus
    ```

* **Example**:

    ```Kusto
    AadStatus
    ```

* **PowerShell Equivalent**:

    ```ps
    $dsregcmd = "$Env:Windir\system32\dsregcmd.exe"
    $rawoutput = & $dsregcmd /status

    $hash = @{}

    foreach( $line in $rawoutput )
    {
        $sep = $line.IndexOf(":")

        if( $sep -ne -1 )
        {
            $propName = $line.SubString(0, $sep).Trim()
            $propValue = $line.SubString($sep+1).Trim()

            if( $propValue -eq 'YES' )
            {
                $propValue = $true
            }
            elseif( $propValue -eq 'NO' )
            {
                $propValue = $false
            }

            $hash.Add($propName,$propValue)
        }
    }

    if( $hash.Count -eq 0 ) 
    {
        throw 'dsregcmd returned invalid response'
    }

    $hash
    ```

## Administrators

* **Query Type**: Powershell
* **Local Query Name**: Administrators
* **Syntax**:

    ```Kusto
    Administrators
    ```

* **Example**:

    ```Kusto
    Administrators
    ```

* **PowerShell Equivalent**:

    ```ps
    Get-LocalGroupMember -SID S-1-5-32-544
    ```

## AppCrash

* **Query Type**: Powershell
* **Local Query Name**: AppCrash
* **Syntax**:

    ```Kusto
    AppCrash
    ```

* **Example**:

    ```Kusto
    AppCrash | summarize dcount( Device ) by FileName,Version
    ```

* **PowerShell Equivalent**:

    ```ps
    try {
        $crashes = Get-EventLog -LogName Application -After (Get-Date).AddDays(-7) -InstanceId 1000 -Source 'Application Error'

        $results = foreach ($crash in $crashes)  
        {
            $hash = @{
                    FileName = $crash.ReplacementStrings[0]
                    Version = $crash.ReplacementStrings[1]
                    ReportId = $crash.ReplacementStrings[12]
                    DateTime = $crash.TimeGenerated
            } 
        }
        $results       
    }
    catch{}
    ```

## AutoStartSoftware

* **Query Type**: Wmi
* **WMI (Namespace, Class)**: (ROOT/cimv2/sms, SMS_AutoStartSoftware)
* **Syntax**:

    ```Kusto
    AutoStartSoftware
    ```

* **Example**:

    ```Kusto
    AutoStartSoftware | summarize dcount( Device ) by Product
    ```

* **PowerShell Equivalent**:

    ```ps
    Get-WMIObject -Namespace ROOT/cimv2/sms -Class SMS_AutoStartSoftware
    ```

## Bios

* **Query Type**: Wmi
* **WMI (Namespace, Class)**: Win32_Bios
* **Syntax**:

    ```Kusto
    Bios
    ```

* **Example**:

    ```Kusto
    Bios | summarize dcount( Device ) by Manufacturer
    ```

* **PowerShell Equivalent**:

    ```ps
    Get-WMIObject -Namespace ROOT/cimv2 -Class Win32_Bios
    ```

## CcmLog

* **Query Type**: Powershell
* **Local Query Name**: CCMlog
* **Syntax**:

    ```Kusto
    CcmLog(<logFileName>,[<timespan>])
    ```

* **Example**:

    ```Kusto
    CcmLog('Scripts', 1d)
    ```

* **PowerShell Equivalent**:

    ```ps
    $logFileName = 'Scripts'
    $secondsAgo = 86400

    $key = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
    $subKey =  $key.OpenSubKey("SOFTWARE\Microsoft\CCM\Logging\@Global")
    $ccmlogdir = $subKey.GetValue("LogDirectory")
    $key.Close()
    $logPath = (join-path $ccmlogdir ($logFileName+".log"))

    #verify format of file name
    if(( $logFileName -match '[\w\d-_@]+' ) -and ([System.IO.File]::Exists($logPath)))
    {        
        $lines = (get-content -path $logpath -ErrorAction Stop)

        [regex]$ccmLog = '<!\[LOG\[(?<logtext>.*)\]LOG\]!><\s*time\s*\=\s*"(?<time>\d\d:\d\d:\d\d)[^"]+"\s+date\s*\=\s*"(?<date>[^"]+)"\s+component\s*\=\s*"(?<component>[^"]*)"\s+context\s*\=\s*"(?<context>[^"]*)"\s+type\s*\=\s*"(?<type>[^"]+)"\s+thread\s*\=\s*"(?<thread>[^"]+)"\s+file\s*\=\s*"(?<file>[^"]+)"\s*>'

        $results = for( $index = $lines.Length-1; $index -ge 0; $index-- )
        {
            $line = $lines[$index]

            $m = $ccmLog.Match($line)

            if( $m.Success -eq $true )
            {
                $hash = @{
                    LogText = $m.Groups["logtext"].Value
                    DateTime = ([DateTime]($m.Groups["date"].Value +' '+ $m.Groups["time"].Value)).ToUniversalTime()
                    Component = $m.Groups["component"].Value
                    Context = $m.Groups["context"].Value
                    Type = $m.Groups["type"].Value
                    Thread = $m.Groups["thread"].Value
                    File = $m.Groups["file"].Value
                }
                
                # Filter out logs based on timespan
                if ( [System.DateTime]::Compare($hash.DateTime, (Get-Date).AddSeconds(-1*$secondsAgo).ToUniversalTime()) -lt 0 )
                {
                    break
                }
                else
                {
                    $hash
                }
            }   
        }

        # Reverse the results list to ascending datetime
        $results.Reverse()
    }
    ```

## Connection

* **Query Type**: Powershell
* **Local Query Name**: Connections
* **Syntax**:

    ```Kusto
    Connection
    ```

* **Example**:

    ```Kusto
    Connection
    ```

* **PowerShell Equivalent**:

    ```ps
    $netstat = "$Env:Windir\system32\netstat.exe"
    $rawoutput = & $netstat -f
    $netstatdata = $rawoutput[3..$rawoutput.count] | ConvertFrom-String | select p2,p3,p4,p5 | where p5 -eq 'established' | select P4  

    foreach( $data in $netstatdata) {
        $data.P4.Substring(0,$data.P4.LastIndexOf(":"))
    }
    
    ```

## Device

* **Query Type**: Wmi
* **WMI (Namespace, Class)**: (ROOT/cimv2, Win32_ComputerSystem)
* **Syntax**:

    ```Kusto
    Device
    ```

* **Example**:

    ```Kusto
    Device
    ```

## Disk

* **Query Type**: Wmi
* **WMI (Namespace, Class)**: (ROOT/cimv2, Win32_LogicalDisk)
* **Syntax**:

    ```Kusto
    Disk
    ```

* **Example**:

    ```Kusto
    Disk | summarize dcount( Device ) by Description
    ```

* **PowerShell Equivalent**:

    ```ps
    Get-WMIObject -Namespace ROOT/cimv2 -Class Win32_LogicalDisk
    ```

## EPStatus

* **WMI (Namespace, Class)**: EPStatus
* **Query Type**: Powershell
* **Local Query Name**: EPStatus
* **Syntax**:

    ```Kusto
    EPStatus
    ```

* **Example**:

    ```Kusto
    EPStatus
    ```

* **PowerShell Equivalent**:

    ```ps
    Get-MpComputerStatus
    ```

## EventLog

* **Query Type**: Powershell
* **Local Query Name**: EventLog
* **Syntax**:

    ```Kusto
    EventLog(<logFileName>, [timespan])
    ```

* **Example**:

    ```Kusto
    EventLog('Security',1d)
    ```

* **PowerShell Equivalent**:

    ```ps
    $logName = 'Security'
    $secondsAgo = 86400

    $events = Get-EventLog -LogName $logName -After (Get-Date).AddSeconds(-1*$secondsAgo)

    $results = foreach ($event in $events)  
    {
        @{
            DateTime = $event.TimeGenerated
            EntryType = $event.EntryType
            Source = $event.Source
            EventID = $Event.EventID
            Message = $Event.Message
        } 
    }
    $results
    ```

## File

* **Query Type**: Powershell
* **Local Query Name**: File
* **Syntax**:

    ```Kusto
    File(<filename>)
    ```

* **Example**:

    ```Kusto
    File('%windir%\\notepad.exe')
    ```

* **PowerShell Equivalent**:

    ```ps
    $fileSpec = [System.Environment]::ExpandEnvironmentVariables( '%windir%\notepad.exe' )

    $results = foreach( $file in (Get-Item -Force -ErrorAction SilentlyContinue -Path $filespec))
    {
        $fileSHA256 = ""
        $fileMD5 = ""

        try {
            $fileSHA256 = (get-filehash -ErrorAction SilentlyContinue -Path $file).Hash 
            $fileMD5 = (get-filehash -ErrorAction SilentlyContinue -Path $file -Algorithm MD5).Hash
        }
        catch {}

        @{
            FileName = $file.FullName
            Mode = $file.Mode
            LastWriteTime = $file.LastWriteTime
            Size = $file.Length
            Version = $file.VersionInfo.ProductVersion
            SHA256Hash = $fileSHA256
            MD5Hash = $fileMD5
        }
    }
    $results
    ```

## FileContent

* **Query Type**: Powershell
* **Local Query Name**: FileContent
* **Syntax**:

    ```Kusto
    FileContent(<filename>)
    ```

* **Example**:

    ```Kusto
    FileContent('%windir%\\smscfg.ini')
    ```

* **PowerShell Equivalent**:

    ```ps
    $filepath = [System.Environment]::ExpandEnvironmentVariables( '%windir%\smscfg.ini' )

    if( [System.IO.File]::Exists($filepath) )
    {        
        $lines = (get-content -path $filepath -ErrorAction Stop)

        $results = for ($index = 0; $index -lt $lines.Length; $index++)
        {
            $line = $lines[$index]
            @{
                Line = $index+1
                Content = $line
            }
        }
        $results
    }
    ```

## FileShare

* **Query Type**: Wmi
* **WMI (Namespace, Class)**: (ROOT/cimv2, Win32_Share)
* **Syntax**:

    ```Kusto
    FileShare
    ```

* **Example**:

    ```Kusto
    FileShare | summarize dcount( Device ) by Name
    ```

* **PowerShell Equivalent**:

    ```ps
    Get-WMIObject -Namespace ROOT/cimv2 -Class Win32_Share
    ```

## InstalledSoftware

* **Query Type**: Wmi
* **WMI (Namespace, Class)**: (ROOT/cimv2/sms, SMS_InstalledSoftware)
* **Syntax**:

    ```Kusto
    InstalledSoftware
    ```

* **Example**:

    ```Kusto
    InstalledSoftware | summarize dcount( Device ) by ProductName
    ```

* **PowerShell Equivalent**:

    ```ps
    Get-WMIObject -Namespace ROOT/cimv2/sms -Class SMS_InstalledSoftware
    ```

## IPConfig

* **Query Type**: Powershell
* **Local Query Name**: IPConfig
* **Syntax**:

    ```Kusto
    IPConfig
    ```

* **Example**:

    ```Kusto
    IPConfig
    ```

* **PowerShell Equivalent**:

    ```ps
    $ipconfigs = (Get-NetIPConfiguration -ErrorAction Stop)

    $results = foreach( $ipconfig in $ipconfigs )
    {
        @{
            InterfaceAlias = $ipconfig.InterfaceAlias
            Name = $ipconfig.NetProfile.Name
            InterfaceDescription = $ipconfig.InterfaceDescription
            Status = $ipconfig.NetAdapter.Status
            IPV4Address = $ipconfig.IPv4Address.IPAddress
            IPV6Address = $ipconfig.IPv6Address.IPAddress
            IPV4DefaultGateway = $ipconfig.IPv4DefaultGateway.NextHop
            IPV6DefaultGateway = $ipconfig.IPv6DefaultGateway.NextHop
            DNSServerList = ($ipconfig.DNSServer.ServerAddresses -join "; ")
        }
    }
    $results
    ```

## OS

* **Query Type**: Wmi
* **WMI (Namespace, Class)**: Win32_OperatingSystem
* **Syntax**:

    ```Kusto
    OS
    ```

* **Example**:

    ```Kusto
    OS
    ```

* **PowerShell Equivalent**:

    ```ps
    Get-WMIObject -Namespace ROOT/cimv2 -Class Win32_OperatingSystem
    ```

## Process

* **Query Type**: Wmi
* **WMI (Namespace, Class)**: (ROOT/cimv2, Win32_Process)
* **Syntax**:

    ```Kusto
    Process
    ```

* **Example**:

    ```Kusto
    Process | summarize dcount( Device ) by Name
    ```

* **PowerShell Equivalent**:

    ```ps
    Get-WMIObject -Namespace ROOT/cimv2 -Class Win32_Process
    ```

## ProcessModule

* **Query Type**: Powershell
* **Local Query Name**: ProcessModule
* **Syntax**:

    ```Kusto
    ProcessModule(<processname>)
    ```

* **Example**:

    ```Kusto
    ProcessModule('explorer')"
    ```

* **PowerShell Equivalent**:

    ```ps
    $processName = 'explorer'

    $modules = Get-Process -name $processName -module -ErrorAction SilentlyContinue

    $results = foreach ($module in $modules)  
    {
        @{
            ModuleName = $module.ModuleName
            FileName = $module.FileName
            FileVersion = $module.FileVersion
            Size = $module.Size
            MD5Hash = (get-filehash -ErrorAction SilentlyContinue -Path $module.FileName -Algorithm MD5).Hash
        } 
    }
    $results
    ```

## Registry

* **Query Type**: Powershell
* **Local Query Name**: registry
* **Syntax**:

    ```Kusto
    Registry(<registrypath>)
    ```

* **Example**:

    ```Kusto
    Registry('hklm:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion')
    ```

* **PowerShell Equivalent**:

    ```ps
    $regSpec = 'hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion'

    $result = New-Object System.Collections.Generic.List[Object]

    foreach( $regKey in (Get-Item -ErrorAction SilentlyContinue -Path $regSpec) )
    {
        foreach( $regValue in $regKey.Property )
        {
            $val = $regKey.GetValue($regValue)

            if( $val -ne $null)
            {
                if( $val.GetType() -eq [Byte[]] )
                {
                    $val = [System.BitConverter]::ToString($val)
                }
                elseif( $val.GetType() -eq [String[]] )
                {
                    $val = [System.String]::Join(", ", $val)
                }

                $hash = @{
                    Property = $regValue
                    Value = $val.ToString()
                }
            }

            $result.Add($hash)
        }
    }
    $result
    ```

## RegistryKey

* **Query Type**: Powershell
* **Local Query Name**: registrykey
* **Syntax**:

    ```Kusto
    RegistryKey(<registrypath>)
    ```

* **Example**:

    ```Kusto
    RegistryKey('hklm:\\SOFTWARE\\Microsoft\\*')
    ```

* **PowerShell Equivalent**:

    ```ps
    $regSpec = 'hklm:\SOFTWARE\Microsoft\*'

    $result = New-Object System.Collections.Generic.List[Object]

    foreach( $regKey in (Get-Item -ErrorAction SilentlyContinue -Path $regSpec) )
    {
        foreach( $regValue in $regKey.Property )
        {
            $val = $regKey.GetValue($regValue)

            if( $val -ne $null)
            {
                if( $val.GetType() -eq [Byte[]] )
                {
                    $val = [System.BitConverter]::ToString($val)
                }
                elseif( $val.GetType() -eq [String[]] )
                {
                    $val = [System.String]::Join(", ", $val)
                }

                $hash = @{
                    Property = $regValue
                    Value = $val.ToString()
                }
            }

            $result.Add($hash)
        }
    }
    $result
    ```

## Service

* **Query Type**: Wmi
* **WMI (Namespace, Class)**: (ROOT/cimv2, Win32_Service)
* **Syntax**:

    ```Kusto
    Service
    ```

* **Example**:

    ```Kusto
    Service | summarize dcount( Device ) by Name
    ```

* **PowerShell Equivalent**:

    ```ps
    Get-WMIObject -Namespace ROOT/cimv2 -Class Win32_Service
    ```
  
## SMBConfig

* **Query Type**: Powershell
* **Local Query Name**: SMBConfig
* **Syntax**:

    ```Kusto
    SMBConfig
    ```

* **Example**:

    ```Kusto
    SMBConfig
    ```

* **PowerShell Equivalent**:

    ```ps
    Get-SmbServerConfiguration
    ```

## SoftwareUpdate

* **Query Type**: Powershell
* **Local Query Name**: Updates
* **Syntax**:

    ```Kusto
    SoftwareUpdate
    ```

* **Example**:

    ```Kusto
    SoftwareUpdate
    ```

* **PowerShell Equivalent**:

    ```ps
    $Session =  [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session",$null))
    $Searcher = $Session.CreateUpdateSearcher()
    $Searcher.ServerSelection = 0

    $MissingUpdates = $Searcher.Search("DeploymentAction=* and IsInstalled=0 and Type='Software'")  

    if ($MissingUpdates.Updates.Count -gt 0) 
    {
        $results = foreach( $Update in $MissingUpdates.Updates )
        {   
            $KBArticleIDs = ""
            foreach( $KB in $Update.KBArticleIDs)
            {
                if( $KBAticleIDs.Length -gt 0 )
                {
                    $KBArticleIDs = $KBArticleIDs + ","
                }

                $KBArticleIDs = $KBArticleIDs + "KB$KB"
            }
    
            $SecurityBulletinIDs = ""
            foreach( $BulletinID in $Update.SecurityBulletinIDs)
            {
                if( $SecurityBulletinIDs.Length -gt 0 )
                {
                    $SecurityBulletinIDs = $SecurityBulletinIDs + ","
                }

                $SecurityBulletinIDs = $SecurityBulletinIDs + $BulletinID
            }

            $Categories = ""
            foreach( $Category in $Update.Categories)
            {
                if( $Categories.Length -gt 0 )
                {
                    $Categories = $Categories + ","
                }

                $Categories = $Categories + $Category.Name
            }

            @{                 
                Title = $Update.Title
                RebootRequired = $Update.RebootRequired
                LastDeploymentChangeTime = $Update.LastDeploymentChangeTime
                UpdateID = $Update.Identity.UpdateID
                KBArticleIDs = $KBArticleIDs
                SecurityBulletinIDs = $SecurityBulletinIDs                                
                Categories = $Categories                
            }
        }
        $results
    } 
    ```

## User

* **Query Type**: Powershell
* **Local Query Name**: Users
* **Syntax**:

    ```Kusto
    User
    ```

* **Example**:

    ```Kusto
    User | summarize dcount( Device ) by UserName
    ```

* **PowerShell Equivalent**:

    ```ps
    $users = New-Object System.Collections.Generic.List[String]

    foreach( $user in (get-WmiObject -class Win32_LoggedOnUser -ErrorAction Stop | Select Antecedent))
    {
        $parts = $user.Antecedent.Split("""")

        if(( $parts[1] -ne "Window Manager" ) -and (($parts[1] -ne $env:COMPUTERNAME) -or (($parts[3] -notlike "UMFD-*")) -and ($parts[3] -notlike "DWM-*")))
        {
            $users.Add($parts[1] + "\" + $parts[3])            
        }
    }

    $users | sort-object -Unique
    ```

## WinEvent

* **Query Type**: Powershell
* **Local Query Name**: winevent
* **Syntax**:

    ```Kusto
    WinEvent(<logfilename>, [<timespan>])
    ```

* **Example**:

    ```Kusto
    WinEvent('Application', 1d)
    ```

* **PowerShell Equivalent**:

    ```ps
    $logFileName =  'Application'
    $secondsAgo = 86400

    $ComputerName = [System.Environment]::MachineName 
    $EventStartDate = (Get-Date).AddSeconds(-1*$secondsAgo)
    $EventEndTime = (Get-Date)
    $filterTable = @{logname = $logFileName; StartTime=$EventStartDate; EndTime=$EventEndTime}

    # Filter out the winEvent logs that we need
    try {
        $winEvents = Get-WinEvent -ComputerName $ComputerName -FilterHashTable $filterTable  -ErrorAction Stop
    }
    catch {}

    $results = foreach ($winEvent in $winEvents)  
    {
        @{
            DateTime = $winEvent.TimeCreated
            LevelDisplayName = $winEvent.LevelDisplayName
            ProviderName = $winEvent.ProviderName
            ID = $winEvent.ID
            Message = $winEvent.Message
        } 
    }
    $results
    ```
