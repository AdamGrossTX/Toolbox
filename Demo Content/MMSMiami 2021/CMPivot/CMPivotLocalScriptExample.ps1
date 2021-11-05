param(
    [string] $kustoquery = 'E:RSgwKSB8IHdoZXJlIChQcm9wZXJ0eSA9PSAnR2F0ZWRCbG9ja0lkJykgfCBqb2luIChFKDEpIHwgd2hlcmUgKFByb3BlcnR5ID09ICdHYXRlZEJsb2NrUmVhc29uJykpIHwgd2hlcmUgKEtleSA9PSBLZXkxKSB8IGpvaW4gKEUoMikgfCB3aGVyZSAoUHJvcGVydHkgPT0gJ1JlZFJlYXNvbicpKSB8IHdoZXJlIChLZXkgPT0gS2V5MikgfCBqb2luIChFKDMpIHwgd2hlcmUgKFByb3BlcnR5ID09ICdVcGdFeCcpKSB8IHdoZXJlIChLZXkgPT0gS2V5MykgfCBqb2luIGtpbmQ9bGVmdG91dGVyIChFKDQpIHwgd2hlcmUgKFByb3BlcnR5ID09ICdTZGJFbnRyaWVzJykpIHwgcHJvamVjdCBEZXZpY2UsIFRhcmdldE9TQnVpbGQgPSBzdWJzdHJpbmcoIEtleSwgKGluZGV4b2YoIEtleSwgJ1RhcmdldFZlcnNpb25VcGdyYWRlRXhwZXJpZW5jZUluZGljYXRvcnNcXCcgKSArIHN0cmxlbiggJ1RhcmdldFZlcnNpb25VcGdyYWRlRXhwZXJpZW5jZUluZGljYXRvcnNcXCcgKSkgKSwgR2F0ZWRCbG9ja0lEID0gVmFsdWUsIEdhdGVkQmxvY2tSZWFzb24gPSBWYWx1ZTEsIFJlZFJlYXNvbiA9IFZhbHVlMiwgVXBnRXggPSBWYWx1ZTMsIFNkYkVudHJpZXMgPSBWYWx1ZTQ=',
    [string] $wmiquery = 'E:UmVnaXN0cnkoJ0hLTE06XFxTT0ZUV0FSRVxcTWljcm9zb2Z0XFxXaW5kb3dzIE5UXFxDdXJyZW50VmVyc2lvblxcQXBwQ29tcGF0RmxhZ3NcXFRhcmdldFZlcnNpb25VcGdyYWRlRXhwZXJpZW5jZUluZGljYXRvcnNcXCpcXCcpDQpSZWdpc3RyeSgnSEtMTTpcXFNPRlRXQVJFXFxNaWNyb3NvZnRcXFdpbmRvd3MgTlRcXEN1cnJlbnRWZXJzaW9uXFxBcHBDb21wYXRGbGFnc1xcVGFyZ2V0VmVyc2lvblVwZ3JhZGVFeHBlcmllbmNlSW5kaWNhdG9yc1xcKlxcJykNClJlZ2lzdHJ5KCdIS0xNOlxcU09GVFdBUkVcXE1pY3Jvc29mdFxcV2luZG93cyBOVFxcQ3VycmVudFZlcnNpb25cXEFwcENvbXBhdEZsYWdzXFxUYXJnZXRWZXJzaW9uVXBncmFkZUV4cGVyaWVuY2VJbmRpY2F0b3JzXFwqXFwnKQ0KUmVnaXN0cnkoJ0hLTE06XFxTT0ZUV0FSRVxcTWljcm9zb2Z0XFxXaW5kb3dzIE5UXFxDdXJyZW50VmVyc2lvblxcQXBwQ29tcGF0RmxhZ3NcXFRhcmdldFZlcnNpb25VcGdyYWRlRXhwZXJpZW5jZUluZGljYXRvcnNcXCpcXCcpDQpSZWdpc3RyeSgnSEtMTTpcXFNPRlRXQVJFXFxNaWNyb3NvZnRcXFdpbmRvd3MgTlRcXEN1cnJlbnRWZXJzaW9uXFxBcHBDb21wYXRGbGFnc1xcQXBwcmFpc2VyXFxHV1gnKQ==',
    [string] $select = 'E:RGV2aWNlOkRldmljZSxQcm9wZXJ0eTpTdHJpbmcsVmFsdWU6U3RyaW5nLEtleTpTdHJpbmcNCkRldmljZTpEZXZpY2UsUHJvcGVydHk6U3RyaW5nLFZhbHVlOlN0cmluZyxLZXk6U3RyaW5nDQpEZXZpY2U6RGV2aWNlLFByb3BlcnR5OlN0cmluZyxWYWx1ZTpTdHJpbmcsS2V5OlN0cmluZw0KRGV2aWNlOkRldmljZSxQcm9wZXJ0eTpTdHJpbmcsVmFsdWU6U3RyaW5nLEtleTpTdHJpbmcNCkRldmljZTpEZXZpY2UsUHJvcGVydHk6U3RyaW5nLFZhbHVlOlN0cmluZyxLZXk6U3RyaW5n'
)

# Read the queries and selects
$kustoquery  = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($kustoquery.Substring(2))).Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries)
$wmiqueries  = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($wmiquery.Substring(2))).Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries)
$selects = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($select.Substring(2))).Split([Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries)


#create the result xml writer
$sb = New-Object System.Text.StringBuilder
$sw = New-Object System.IO.StringWriter($sb)
$writer = New-Object System.Xml.XmlTextWriter($sw)
$writer.WriteStartDocument()
$writer.WriteStartElement("result")
$writer.WriteAttributeString("ResultCode", 0x00000000 )

# A helper function to create a datatable of properties
function CreateTableFromPropertyList
{
    param ([string[]]$properties, [String[]]$propertyTypes)

    $dt = New-Object system.Data.DataTable

    # Add Device column first
    $col_device = New-Object system.Data.DataColumn 'Device',([Microsoft.ConfigurationManagement.AdminConsole.CMPivotParser.Device])
    $dt.Columns.Add($col_device)

    # Add the rest properties to columns
    for( $index = 0; $index -lt $properties.Length; $index++ )
    {
        # Get the column datatype
        switch($propertyTypes[$index])
        {
            "Boolean"
            {
                $colType = [System.Boolean]
                break
            }
            "Number"
            {
                $colType = [System.Int64]
                break
            }
            "String"
            {
                $colType = [System.String]
                break
            }
            "TimeSpan"
            {
                $colType = [System.TimeSpan]
                break
            }
            "DateTime"
            {
                $colType = [System.DateTime]
                break                
            }
            default
            {
                throw
            }
        }
        $column = New-Object system.Data.DataColumn $properties[$index], ($colType)
        $dt.Columns.Add($column)
    }

    return ,$dt
}

Try
{
    # Lookup the CCM directory
    $key = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
    $subKey =  $key.OpenSubKey("SOFTWARE\Microsoft\SMS\Client\Configuration\Client Properties")
    $ccmdir = $subKey.GetValue("Local SMS Path")
    $key.Close()
    $binName = 'AdminUI.CMPivotParser.dll'
    $binPath = (join-path $ccmdir $binName)
        
    # Try to load AdminUI.CMPivotParser.dll from ccm binary folder
    try
    {
        [System.Reflection.Assembly]::LoadFile($binPath) | Out-Null
    }
    catch
    {   
        throw 'Failed to load CMPivotParser'
    }

    # Create the resultant data table list
    $datatables = New-Object System.Collections.Generic.List[Data.DataTable]

    # For each query
    for( $queryIndex = 0; $queryIndex -lt $wmiqueries.Length; $queryIndex++ )
    {
        # For this index
        $wmiquery = $wmiqueries[$queryIndex]
        $select = $selects[$queryIndex]

        # Parse the select parameter
        $propertyFilter = @()
        $propertyTypes = @()
        $propertySerializer = @()

        foreach($p in $select.Split(','))
        {
            # Parse property definition
            $p = $p.Split(':')

            # Generate a property serializer
            if( $p[2] -eq "KiloBytes" )
            {   
                $propertyFilter+= $p[0]                
                $propertyTypes+= $p[1]
                $propertySerializer += { Param( [Object] $val ) return [Int64]::Parse($val.ToString()) -shr 10 }
            }
            elseif( $p[2] -eq "MegaBytes" )
            {   
                $propertyFilter+= $p[0]                
                $propertyTypes+= $p[1]
                $propertySerializer += { Param( [Object] $val ) return [Int64]::Parse($val.ToString()) -shr 20 }
            }
            elseif( $p[2] -eq "GigaBytes" )
            {   
                $propertyFilter+= $p[0]                
                $propertyTypes+= $p[1]
                $propertySerializer += { Param( [Object] $val ) return [Int64]::Parse($val.ToString()) -shr 30 }
            }
            elseif( $p[2] -eq "Seconds" )
            {   
                $propertyFilter+= $p[0]                
                $propertyTypes+= $p[1]
                $propertySerializer += { Param( [Object] $val ) return [Int64]::Parse($val.ToString())/1000 }
            }
            elseif( $p[2] -eq "HexSring" )
            {   
                $propertyFilter+= $p[0]                
                $propertyTypes+= $p[1]
                $propertySerializer += { Param( [Object] $val ) return "0x"+[Int64]::Parse($val.ToString()).ToString("X") }
            }
            elseif( $p[2] -eq "DateString" )
            {   
                # The DateString field format is "ddddddddHHMMSS.mmmmmm:000" --> %d Days 02:01:01 Hours
                $propertyFilter+= $p[0]                
                $propertyTypes+= $p[1]
                $propertySerializer += { 
                    Param( [Object] $val ) 
                    $days = [Int64]::Parse( $val.SubString(0, 8))
                    $hours = $val.SubString(8, 2)
                    $min = $val.SubString(10, 2)
                    $seconds = $val.SubString(12, 2)
                    return "${days} Days ${hours}:${min}:${seconds} Hours"
                }
            }
            elseif ( $p[1] -eq 'Number' )
            {
                $propertyFilter+= $p[0]                
                $propertyTypes+= $p[1]
                $propertySerializer += { Param( [Object] $val ) return [Int64]::Parse($val.ToString()) }
            }
            elseif ( $p[1] -eq 'Boolean' )
            {
                $propertyFilter+= $p[0]                
                $propertyTypes+= $p[1]
                $propertySerializer += { Param( [Object] $val ) return [Boolean]::Parse($val.ToString()) }
            }
            elseif( $p[1] -eq 'DateTime' )
            {
                $propertyFilter+= $p[0]                
                $propertyTypes+= $p[1]  
                $propertySerializer += { 
                    Param( [Object] $val )           
            
                    try
                    {
                       $val = [System.Management.ManagementDateTimeconverter]::ToDateTime($val)
                         
                       #Sql.MinDateTime -> Null
                       if( $val -lt (get-date -Year 1753 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0))
                       {     
                          return $null
                       }
                       else
                       {
                          return $val
                       }
                     
                    }
                    catch
                    {
                        return $null
                    }
                }
            }
            elseif( $p[1] -ne 'Device' )
            {
                $propertyFilter+= $p[0]                
                $propertyTypes+= $p[1]
                $propertySerializer += { Param( [Object] $val ) return $val.ToString() }                
            }
        }

        # Create a data table to store the results of this query
        $dt = CreateTableFromPropertyList -properties $propertyFilter -propertyTypes $propertyTypes

        #Create the result set
        $results = New-Object System.Collections.Generic.List[Object]

        #deal with one-offs that don't work well over WMI
        if( $wmiquery -eq 'SMBConfig' )
        {
            # Get Smb Config
            $smbConfig = Get-SmbServerConfiguration -ErrorAction Stop| Select-object -Property $propertyFilter

            #Add to results list
            $results.Add($smbConfig)
        }
        elseif( $wmiquery -eq 'Users' )
        {
            $users = New-Object System.Collections.Generic.List[String]

            foreach( $user in (get-WmiObject -class Win32_LoggedOnuser -ErrorAction Stop | Select Antecedent))
            {
                $parts = $user.Antecedent.Split("""")
        
                # If this is not a built-in account
                if(( $parts[1] -ne "Window Manager" ) -and (($parts[1] -ne $env:COMPUTERNAME) -or (($parts[3] -notlike "UMFD-*")) -and ($parts[3] -notlike "DWM-*")))
                {
                    # add to list
                    $users.Add($parts[1] + "\" + $parts[3])            
                }
            }
   
            # Create unique set of users
            $users | sort-object -Unique | foreach-object { $results.Add(@{ UserName = $_ }) }         
        }
        elseif( $wmiquery -eq 'IPConfig' )
        {
            $ipconfigs = (Get-NetIPConfiguration -ErrorAction Stop)

            foreach( $ipconfig in $ipconfigs )
            {
                $hash = @{
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
    
                $results.add($hash)
            }
        }
        elseif( $wmiquery -eq 'Connections' )
        {
            $netstat = "$Env:Windir\system32\netstat.exe"
            $rawoutput = & $netstat -f
            $netstatdata = $rawoutput[3..$rawoutput.count] | ConvertFrom-String | select p2,p3,p4,p5 | where p5 -eq 'established' | select P4  

            foreach( $data in $netstatdata)
            {        
                #Add to results list
                $hash = @{ Server = $data.P4.Substring(0,$data.P4.LastIndexOf(":")) }
                $results.Add($hash )
            }        
        }
        elseif( $wmiquery -eq 'EPStatus' )
        {
            $epStatus = (Get-MpComputerStatus -ErrorAction Stop)

            $hash = @{                 
                AMServiceEnabled = $epStatus.AMServiceEnabled
                AntispywareEnabled = $epStatus.AntispywareEnabled
                AntispywareSignatureLastUpdated = $epStatus.AntispywareSignatureLastUpdated
                AntispywareSignatureVersion = $epStatus.AntispywareSignatureVersion
                AntivirusEnabled = $epStatus.AntivirusEnabled
                AntivirusSignatureLastUpdated = $epStatus.AntivirusSignatureLastUpdated
                AntivirusSignatureVersion = $epStatus.AntivirusSignatureVersion
                BehaviorMonitorEnabled = $epStatus.BehaviorMonitorEnabled
                IoavProtectionEnabled = $epStatus.IoavProtectionEnabled
                IsTamperProtected = $epStatus.IsTamperProtected
                NISEnabled = $epStatus.NISEnabled
                NISSignatureLastUpdated = $epStatus.NISSignatureLastUpdated
                NISSignatureVersion = $epStatus.NISSignatureVersion
                OnAccessProtectionEnabled = $epStatus.OnAccessProtectionEnabled
                QuickScanEndTime = $epStatus.QuickScanEndTime
                RealTimeProtectionEnabled = $epStatus.RealTimeProtectionEnabled            
            }
                
            $results.Add($hash)
        }
        elseif( $wmiquery.StartsWith('Updates') )
        {
            # Default server selection
            $serverSelection = 0 

            # if server selection has been specified then use it
            $first = $wmiquery.IndexOf("(")

            if( $first -ne -1 ) 
            {
                $last = $wmiquery.LastIndexOf(")")            
                $serverSelection = [Int32]::Parse( $wmiquery.Substring($first+1, $last-$first-1))
            }

            # Create an update session object
            $Session =  [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session",$null))
            $Searcher = $Session.CreateUpdateSearcher()
            $Searcher.ServerSelection = $serverSelection

            # Search for any uninstalled updates
            $MissingUpdates = $Searcher.Search("DeploymentAction=* and IsInstalled=0 and Type='Software'")  
    
            if ($MissingUpdates.Updates.Count -gt 0) 
            {
                foreach( $Update in $MissingUpdates.Updates )
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

                    #Add to results list
                    $hash = @{                 
                        Title = $Update.Title
                        RebootRequired = $Update.RebootRequired
                        LastDeploymentChangeTime = $Update.LastDeploymentChangeTime
                        UpdateID = $Update.Identity.UpdateID
                        KBArticleIDs = $KBArticleIDs
                        SecurityBulletinIDs = $SecurityBulletinIDs                                
                        Categories = $Categories                
                    }
                
                    $results.Add($hash)            
                }
            } 
        }
        elseif( $wmiquery -eq 'AppCrash' )
        {
            Try
            {
                $crashes = get-eventlog -ErrorAction Stop -LogName Application  -After (Get-Date).AddDays(-7) -InstanceId 1000 -Source 'Application Error'

                foreach ($crash in $crashes)  
                {
                    $hash = @{
                            FileName = $crash.ReplacementStrings[0]
                            Version = $crash.ReplacementStrings[1]
                            ReportId = $crash.ReplacementStrings[12]
                            DateTime = $crash.TimeGenerated
                    } 
    
                    $results.Add($hash)        
                }
            }
            Catch
            {
            }
        }
        elseif( $wmiquery -eq 'AadStatus' )
        {
            $dsregcmd = "$Env:Windir\system32\dsregcmd.exe"
            $hash = @{}

            if( Test-Path -Path $dsregcmd -PathType Leaf )            
            {
                $rawoutput = & $dsregcmd /status

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
            }
            else
            {   
                # On an OS that does not support AAD Join         
                $hash.Add("EnterpriseJoined",$false)
                $hash.Add("AzureAdJoined",$false)
                $hash.Add("WorkplaceJoined",$false)

                $OSInfo=(Get-CIMInstance Win32_ComputerSystem)

                if( $OSInfo.PartOfDomain )
                {
                    $hash.Add("DomainJoined",$true)
                    $hash.Add("DomainName",$OSInfo.Domain)
                }
                else
                {
                    $hash.Add("DomainJoined",$false)
                }
            }

            $results.Add($hash)
        }
        elseif( $wmiquery -eq 'Administrators' )
        {
            $admins = (get-localgroupmember -SID S-1-5-32-544 -ErrorAction Stop)
            foreach( $admin in $admins )
            {
                $hash = @{
                    ObjectClass = $admin.ObjectClass
                    Name = $admin.Name
                    PrincipalSource = $admin.PrincipalSource
                }

                $results.Add($hash)        
            }
        }
        elseif ($wmiquery.StartsWith("File(") )
        {
            $first = $wmiquery.IndexOf("'")+1
            $last = $wmiquery.LastIndexOf("'")
    
            $fileSpec = [System.Environment]::ExpandEnvironmentVariables( $wmiquery.Substring($first, $last-$first))
   
            foreach( $file in (Get-Item -Force -ErrorAction SilentlyContinue -Path $filespec))
            {
                $fileSHA256 = ""
                $fileMD5 = ""

                Try
                {
                    $fileSHA256 = (get-filehash -ErrorAction SilentlyContinue -Path $file).Hash 
                    $fileMD5 = (get-filehash -ErrorAction SilentlyContinue -Path $file -Algorithm MD5).Hash
                }
                Catch
                {
                }

                 $hash = @{
                    FileName = $file.FullName
                    Mode = $file.Mode
                    LastWriteTime = $file.LastWriteTime
                    Size = $file.Length
                    Version = $file.VersionInfo.ProductVersion
                    SHA256Hash = $fileSHA256
                    MD5Hash = $fileMD5
                 }

                 $results.Add($hash)

            }
        }
        elseif ($wmiquery.StartsWith("FileContent(") )
        {
            $first = $wmiquery.IndexOf("'")+1
            $last = $wmiquery.LastIndexOf("'") 

            $filepath = [System.Environment]::ExpandEnvironmentVariables( $wmiquery.Substring($first, $last-$first) )   

            #verify if the file exists
            if( [System.IO.File]::Exists($filepath) )
            {        
                $lines = (get-content -path $filepath -ErrorAction Stop)

                for ($index = 0; $index -lt $lines.Length; $index++)
                {
                    $line = $lines[$index]

                    $hash = @{
                            Line = $index+1
                            Content = $line
                    }
                    $results.Add($hash)
                }
            }
        }
        elseif ($wmiquery.StartsWith("EventLog(") )
        {
            $first = $wmiquery.IndexOf("'")+1
            $last = $wmiquery.LastIndexOf("'")    
            $logName = $wmiquery.Substring($first, $last-$first)

            $first_time = $wmiquery.LastIndexOf(",")+1
            $last_time = $wmiquery.LastIndexOf(")")
            $secondsAgo = [System.Int64]::Parse($wmiquery.Substring($first_time, $last_time-$first_time))
    
            $events = get-eventlog -LogName $logName -ErrorAction Stop -After (Get-Date).AddSeconds(-1*$secondsAgo)
    
            foreach ($event in $events)  
            {
                $hash = @{
                        DateTime = $event.TimeGenerated
                        EntryType = $event.EntryType
                        Source = $event.Source
                        EventID = $Event.EventID
                        Message = $Event.Message
                } 
    
                $results.Add($hash)        
            }
        }
        elseif ($wmiquery.StartsWith("CcmLog(") )
        {
            $first = $wmiquery.IndexOf("'")+1
            $last = $wmiquery.LastIndexOf("'")    
            $logFileName = $wmiquery.Substring($first, $last-$first)

            $first_time = $wmiquery.LastIndexOf(",")+1
            $last_time = $wmiquery.LastIndexOf(")")
            $secondsAgo = [System.Int64]::Parse($wmiquery.Substring($first_time, $last_time-$first_time))

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

                for( $index = $lines.Length-1; $index -ge 0; $index-- )
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
                            $results.Add($hash)
                        }
                    }   
                }

                # Reverse the results list to ascending datetime
                $results.Reverse()
            }
        }
        elseif ($wmiquery.StartsWith("WinEvent("))
        {
            $first = $wmiquery.IndexOf("'")+1
            $last = $wmiquery.LastIndexOf("'")
            $logFileName =  $wmiquery.Substring($first, $last-$first)

            $first_time = $wmiquery.LastIndexOf(",")+1
            $last_time = $wmiquery.LastIndexOf(")")
            $secondsAgo = [System.Int64]::Parse($wmiquery.Substring($first_time, $last_time-$first_time))

            $ComputerName = [System.Environment]::MachineName 
            $EventStartDate = (Get-Date).AddSeconds(-1*$secondsAgo)
            $EventEndTime = (Get-Date)
            $filterTable = @{logname = $logFileName; StartTime=$EventStartDate; EndTime=$EventEndTime}

            # Filter out the winEvent logs that we need
            try
            {
                $winEvents = Get-WinEvent -ComputerName $ComputerName -FilterHashTable $filterTable  -ErrorAction Stop
            }
            catch
            {
            }

            foreach ($winEvent in $winEvents)  
            {
                $hash = @{
                        DateTime = $winEvent.TimeCreated
                        LevelDisplayName = $winEvent.LevelDisplayName
                        ProviderName = $winEvent.ProviderName
                        ID = $winEvent.ID
                        Message = $winEvent.Message
                } 
    
                $results.Add($hash)        
            }
        }
        elseif ($wmiquery.StartsWith("Registry(") )
        {
            $first = $wmiquery.IndexOf("'")+1
            $last = $wmiquery.LastIndexOf("'")
            $regSpec =  $wmiquery.Substring($first, $last-$first)
   
            $result = New-Object System.Collections.Generic.List[Object]

            foreach( $regKey in (Get-Item -ErrorAction SilentlyContinue -Path $regSpec) )
            {
                foreach( $regValue in $regKey.Property )
                {
                    $val = $regKey.GetValue($regValue)

                    if ( $val -eq $null)
                    { 
                        $valDefaultProp = Get-ItemProperty -Path $regSpec
                        $valDefault = $valDefaultProp."(Default)"

                        $hashDefault = @{
                            Key = $regKey.Name
                            Property = '(Default)' 
                            Value = $valDefault.ToString()
                        }

                        $results.Add($hashDefault)
                    }
                    else
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
                            Key = $regKey.Name
                            Property = $regValue
                            Value = $val.ToString()
                        }

                        $results.Add($hash)
                    }
                }
            }
        }
        elseif ($wmiquery.StartsWith("Registry(") )
        {
            $first = $wmiquery.IndexOf("'")+1
            $last = $wmiquery.LastIndexOf("'")
            $regSpec =  $wmiquery.Substring($first, $last-$first)
   
            $result = New-Object System.Collections.Generic.List[Object]

            foreach( $regKey in (Get-Item -ErrorAction SilentlyContinue -Path $regSpec) )
            {
                foreach( $regValue in $regKey.Property )
                {
                    $val = $regKey.GetValue($regValue)

                    if ( $val -eq $null)
                    { 
                        $valDefaultProp = Get-ItemProperty -Path $regSpec
                        $valDefault = $valDefaultProp."(Default)"

                        $hashDefault = @{
                            Key = $regKey.Name
                            Property = '(Default)' 
                            Value = $valDefault.ToString()
                        }

                        $results.Add($hashDefault)
                    }
                    else
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
                            Key = $regKey.Name
                            Property = $regValue
                            Value = $val.ToString()
                        }

                        $results.Add($hash)
                    }
                }
            }
        }
        elseif ($wmiquery.StartsWith("RegistryKey(") )
        {
            $first = $wmiquery.IndexOf("'")+1
            $last = $wmiquery.LastIndexOf("'")
            $regSpec =  $wmiquery.Substring($first, $last-$first)
   
            $result = New-Object System.Collections.Generic.List[Object]

            foreach( $regKey in (Get-Item -ErrorAction SilentlyContinue -Path $regSpec) )
            {
                $hash = @{
                    Key = $regKey.Name
                }

                $results.Add($hash)
            }

        }
        elseif ($wmiquery.StartsWith("ProcessModule(") )
        {
            $first = $wmiquery.IndexOf("'")+1
            $last = $wmiquery.LastIndexOf("'")
            $processName =  $wmiquery.Substring($first, $last-$first)

            $modules = get-process -name $processName -module -ErrorAction SilentlyContinue

            foreach ($module in $modules)  
            {
                $hash = @{
                        ModuleName = $module.ModuleName
                        FileName = $module.FileName
                        FileVersion = $module.FileVersion
                        Size = $module.Size
                        MD5Hash = (get-filehash -ErrorAction SilentlyContinue -Path $module.FileName -Algorithm MD5).Hash
                } 
    
                $results.Add($hash)     
            }

        }
        else
        {
            $namespace = "root/cimv2"

            # if there is a namespace
            if( ($wmiquery.StartsWith("root/")) -and ($wmiquery.Contains(":")))
            {
                $seperator = $wmiquery.IndexOf(":")
                $namespace =  $wmiquery.Substring(0, $seperator)
                $wmiquery = $wmiquery.Substring($seperator+1)
            }

            # Execute the query
            $wmiresult = (get-wmiobject -query $wmiquery -Namespace $namespace -ErrorAction Stop) 

            # create result set
            $result = New-Object System.Collections.Generic.List[Object]

            foreach( $obj in $wmiresult )
            {
                $hash = @{}

                for( $i=0; $i -lt $propertyFilter.Length; $i++ )
                {            
                   $propName = $propertyFilter[$i]
                   $propValue = $obj[$propName]
 
                   if( $propValue -ne $null)
                   {
                       $hash[$propName] = $($propertySerializer[$i].Invoke($propValue))
                   }
                   else
                   {
                       $hash[$propName] = $null
                   }
                }

                $results.Add($hash)
            }
        }

        # Write the results to the data table
        foreach( $obj in $results )
        {   
            # Add a row in data table
            $insertRow = $dt.NewRow()

            $device = New-Object Microsoft.ConfigurationManagement.AdminConsole.CMPivotParser.Device ([System.Environment]::MachineName), 1

            $insertRow.Device = [Microsoft.ConfigurationManagement.AdminConsole.CMPivotParser.Device]$device
        
            for( $i=0; $i -lt $propertyFilter.Length; $i++ )
            {
                $propName = $propertyFilter[$i]
                $propValue = $obj[$propName]

                if( $propValue -ne $null)
                {
                    switch($propertyTypes[$i])
                    {
                        "Boolean"
                        {
                            $insertRow[$propName] = [System.Boolean]$propValue
                            break
                        }
                        "Number"
                        {
                            $insertRow[$propName] = [System.Int64]$propValue
                            break
                        }
                        "TimeSpan"
                        {
                            $insertRow[$propName] = [System.TimeSpan]$propValue
                            break
                        }
                        "DateTime"
                        {
                            $insertRow[$propName] = ([System.DateTime]$propValue).ToUniversalTime()
                            break                
                        }
                        default
                        {
                            $insertRow[$propName] = $propValue
                        }
                    }
                }
                else
                {
                    $insertRow[$propName] = [System.DBNull]::Value
                }
            }
            $dt.Rows.Add($insertRow)
        }

        # Add the data table to list
        $datatables.Add($dt)
    }

    # Call the static method to evaluate the pivot query
    $maxResultSize = 128000
    $moreResults = $false
    $eval_result = [Microsoft.ConfigurationManagement.AdminConsole.CMPivotParser.KustoParser]::Evaluate($kustoquery, $datatables, $maxResultSize, [ref]$moreResults)

    # Add an attribute to result node to indicate if there should be more results
    $writer.WriteAttributeString("moreResults", $moreResults.ToString())

    # Write the results to Xml
    foreach ( $dr in $eval_result.Rows )
    {
        $writer.WriteStartElement("e")
        
        $writer.WriteAttributeString("_i", 0 )

        foreach ( $dc in $eval_result.Columns )
        {
            $prop = $dc.ColumnName

            # Skip Device column in writing to xml
            if ($prop -eq 'Device')
            {
                continue
            }
            $Value = $dr[$prop]
            
            if( !([DBNull]::Value).Equals($Value) )
            {
                if( $Value.GetType() -eq [DateTime] )
                {
                    $writer.WriteAttributeString("$prop", $Value.ToString("yyyy-MM-dd HH:mm:ss", [CultureInfo]::InvariantCulture))
                }
                else
                {
                    $writer.WriteAttributeString("$prop", $Value.ToString() )
                }
            }
        }

        $writer.WriteEndElement()
    }
}
Catch
{
    #format the exception as an xml 
    $sb = New-Object System.Text.StringBuilder
    $sw = New-Object System.IO.StringWriter($sb)
    $writer = New-Object System.Xml.XmlTextWriter($sw)

    $writer.WriteStartDocument()
    $writer.WriteStartElement("result")
    $writer.WriteAttributeString("ResultCode", 0x80004005 )
    $writer.WriteStartElement("error")
    $writer.WriteAttributeString("ErrorMessage", $_.Exception.Message )
    $writer.WriteEndElement()

    # Dispose the datatable if catch an exception
    if( $dt -ne $null )
    {
        $dt.Dispose()
		$datatables = $null
    }
}

# Finish off Xml
$writer.WriteEndElement()
$writer.WriteEndDocument()
$writer.Flush()
$writer.Close()

$writer.Close()
$sw.Dispose()

$Bytes = [System.Text.Encoding]::Unicode.GetBytes($sb.ToString())

if( $Bytes.Length -lt 4096 ) 
{
    return [Convert]::ToBase64String($Bytes)
}
else
{
    # Otherwise compress
    [System.IO.MemoryStream] $output = New-Object System.IO.MemoryStream
    $gzipStream = New-Object System.IO.Compression.GzipStream $output, ([IO.Compression.CompressionMode]::Compress)
    $gzipStream.Write( $Bytes, 0, $Bytes.Length )
    $gzipStream.Close()
    $output.Close()

    return [Convert]::ToBase64String($output.ToArray())
}

# SIG # Begin signature block
# MIIjkgYJKoZIhvcNAQcCoIIjgzCCI38CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB4kLnZapml6Nv6
# 6CHjBPRH0mXO/mGvJxVl4ZvPQX63saCCDYEwggX/MIID56ADAgECAhMzAAAB32vw
# LpKnSrTQAAAAAAHfMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjAxMjE1MjEzMTQ1WhcNMjExMjAyMjEzMTQ1WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQC2uxlZEACjqfHkuFyoCwfL25ofI9DZWKt4wEj3JBQ48GPt1UsDv834CcoUUPMn
# s/6CtPoaQ4Thy/kbOOg/zJAnrJeiMQqRe2Lsdb/NSI2gXXX9lad1/yPUDOXo4GNw
# PjXq1JZi+HZV91bUr6ZjzePj1g+bepsqd/HC1XScj0fT3aAxLRykJSzExEBmU9eS
# yuOwUuq+CriudQtWGMdJU650v/KmzfM46Y6lo/MCnnpvz3zEL7PMdUdwqj/nYhGG
# 3UVILxX7tAdMbz7LN+6WOIpT1A41rwaoOVnv+8Ua94HwhjZmu1S73yeV7RZZNxoh
# EegJi9YYssXa7UZUUkCCA+KnAgMBAAGjggF+MIIBejAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUOPbML8IdkNGtCfMmVPtvI6VZ8+Mw
# UAYDVR0RBEkwR6RFMEMxKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1
# ZXJ0byBSaWNvMRYwFAYDVQQFEw0yMzAwMTIrNDYzMDA5MB8GA1UdIwQYMBaAFEhu
# ZOVQBdOCqhc3NyK1bajKdQKVMFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0w
# Ny0wOC5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAx
# MS0wNy0wOC5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAnnqH
# tDyYUFaVAkvAK0eqq6nhoL95SZQu3RnpZ7tdQ89QR3++7A+4hrr7V4xxmkB5BObS
# 0YK+MALE02atjwWgPdpYQ68WdLGroJZHkbZdgERG+7tETFl3aKF4KpoSaGOskZXp
# TPnCaMo2PXoAMVMGpsQEQswimZq3IQ3nRQfBlJ0PoMMcN/+Pks8ZTL1BoPYsJpok
# t6cql59q6CypZYIwgyJ892HpttybHKg1ZtQLUlSXccRMlugPgEcNZJagPEgPYni4
# b11snjRAgf0dyQ0zI9aLXqTxWUU5pCIFiPT0b2wsxzRqCtyGqpkGM8P9GazO8eao
# mVItCYBcJSByBx/pS0cSYwBBHAZxJODUqxSXoSGDvmTfqUJXntnWkL4okok1FiCD
# Z4jpyXOQunb6egIXvkgQ7jb2uO26Ow0m8RwleDvhOMrnHsupiOPbozKroSa6paFt
# VSh89abUSooR8QdZciemmoFhcWkEwFg4spzvYNP4nIs193261WyTaRMZoceGun7G
# CT2Rl653uUj+F+g94c63AhzSq4khdL4HlFIP2ePv29smfUnHtGq6yYFDLnT0q/Y+
# Di3jwloF8EWkkHRtSuXlFUbTmwr/lDDgbpZiKhLS7CBTDj32I0L5i532+uHczw82
# oZDmYmYmIUSMbZOgS65h797rj5JJ6OkeEUJoAVwwggd6MIIFYqADAgECAgphDpDS
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
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAAAd9r8C6Sp0q00AAAAAAB3zAN
# BglghkgBZQMEAgEFAKCBrjAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg+wiwJtRQ
# fLBmhDY7y/Ul4KwqbgiYqehJ4NKDVuI6b8cwQgYKKwYBBAGCNwIBDDE0MDKgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRqAGGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbTAN
# BgkqhkiG9w0BAQEFAASCAQCtd9OgwOsi+m4KXqc4FoCBx3uMwVD+McfOWnoxIvjJ
# o8PYHXzcYNyxxxVP+yuzGKDhHQYCEdcizzX1uNFv2zAd28xIueqfXWQiCV+I47Cq
# CJVCbiX3sNd7yjtchY3OklQbH4DtWIYO/+VgX4Y05QPP9q00zkny4X6SW7EHaO1T
# g3YZfzohTg4uWNQnAOuVctRzHLBAMbJgZ3FWatr9P1IRYkLfObk/Xm0iCpy+ulgj
# YhaFYWqsgX5OokPMBQuwZQHu4LfWLq243FQ0/0zcwgheqppFunRAILFGLAF5JX+S
# 6hZWBRbyE1e3fSp/3zQehAUf8i82kENNyFr289sg+MZsoYIS8TCCEu0GCisGAQQB
# gjcDAwExghLdMIIS2QYJKoZIhvcNAQcCoIISyjCCEsYCAQMxDzANBglghkgBZQME
# AgEFADCCAVUGCyqGSIb3DQEJEAEEoIIBRASCAUAwggE8AgEBBgorBgEEAYRZCgMB
# MDEwDQYJYIZIAWUDBAIBBQAEIOgTtwHRIpRImNADxfun4b0vaxSo0mWJD8SBAa+v
# gtRyAgZg06F2424YEzIwMjEwNzAxMDg1MTM3LjEwMlowBIACAfSggdSkgdEwgc4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1p
# Y3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMg
# VFNTIEVTTjpGN0E2LUUyNTEtMTUwQTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgU2VydmljZaCCDkQwggT1MIID3aADAgECAhMzAAABWZ/8fl8s6vJDAAAA
# AAFZMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# MB4XDTIxMDExNDE5MDIxNVoXDTIyMDQxMTE5MDIxNVowgc4xCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVy
# YXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpGN0E2
# LUUyNTEtMTUwQTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vydmlj
# ZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAK54xGHJZ8SHREtNIoBo
# 9AG6Mro8gEZCt8WgV/mNdIt2tMOP3zVYU4+sRsImxTwfzJEDBWaTc7LxlEy/1302
# fRmd/R2pwnY7pyT90yvZAmQQLZ6D+faGBwwhi5rre/tmBJdbAXFZ8qL2JDc4txBn
# 30Mr1C8DFBdrIjwbP+i2RdAOaSwIs/xQsMeZAz3v5j9VEdwq8+iM6YcLcqKrYAwP
# +OE58371ST5kj2f7quToeTXhSvDczKYrVokL3Zn0+KNAnbpp4rH1tXymmgXQcgVC
# z1E/Ey8NEsvZ1FjV5QP6ovDMT8YAo7KzaYvT4Ix+xMVvW+1/1MnYaaoR8bLnQxmT
# ZOMCAwEAAaOCARswggEXMB0GA1UdDgQWBBT20KmFRryt+uTrJ9eIwjyy6Tdj5zAf
# BgNVHSMEGDAWgBTVYzpcijGQ80N7fEYbxTNoWoVtVTBWBgNVHR8ETzBNMEugSaBH
# hkVodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNU
# aW1TdGFQQ0FfMjAxMC0wNy0wMS5jcmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUF
# BzAChj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1RpbVN0
# YVBDQV8yMDEwLTA3LTAxLmNydDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsG
# AQUFBwMIMA0GCSqGSIb3DQEBCwUAA4IBAQCNkVQS6A+BhrfGOCAWo3KcuUa4estp
# zyn+ZLlkh0pJmAJp4EUDrLWsieYCf2oyoc8KjVMC+NHFFVvHLrSMhWnR5FtY6l3Z
# 6Ur9ITBSz64j5wTRRE8vIpQiHVYjRVNPGR2tiqG5nKP5+sD0rZI464OFNz4n7erD
# JOpV7Im1L/sAwfX+GHoc4j5rfuAuQTFY82sdYvtHM4LTxwV997uhlFs52oHapdFW
# 1KXt6vMxEXnSX8soQfUd+M+Yq3J7udc6R941Guxfd6A0vecV56JjvmpCng4jRkqu
# Aeyf/dKmQUaR1fKvALBRAmZkAUtWijS/3MkeQv/lUvHVo7GPFzJ/O3wJMIIGcTCC
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
# cGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpG
# N0E2LUUyNTEtMTUwQTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
# dmljZaIjCgEBMAcGBSsOAwIaAxUAKnbLAI8fhO58SCWrpZnXvXEZshGggYMwgYCk
# fjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQD
# Ex1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIF
# AOSHWk0wIhgPMjAyMTA3MDEwMTAyMDVaGA8yMDIxMDcwMjAxMDIwNVowdzA9Bgor
# BgEEAYRZCgQBMS8wLTAKAgUA5IdaTQIBADAKAgEAAgInaAIB/zAHAgEAAgIR3zAK
# AgUA5IirzQIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIB
# AAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBACbH1qlG/4eAjr6b
# OpGqHuR3hxGW6bau01IBkt/FhOg+pjk0cO/0RxfYP28O8IB+miYRrzGFE0THYOFx
# jo2ubiaEEnAIjmOACMCpsJaVd9dBD8timZKqUCB5amhEmnTPbJ+uc490ZkAAkXGD
# BpFospyeDIUxhX5cdYsXS/ojoMx7MYIDDTCCAwkCAQEwgZMwfDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
# bWUtU3RhbXAgUENBIDIwMTACEzMAAAFZn/x+Xyzq8kMAAAAAAVkwDQYJYIZIAWUD
# BAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0B
# CQQxIgQg6/oXMvgc/64xRnZMCEFn9iWmXiRUMTQaXsEJh/cDIgowgfoGCyqGSIb3
# DQEJEAIvMYHqMIHnMIHkMIG9BCABWBvPvzDmfNeSzmJT4+dGA+uj/qq7/fKkUn36
# rxND6DCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
# MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB
# WZ/8fl8s6vJDAAAAAAFZMCIEILXVYF1nlBZ7jlo7DG/g/upd5UrYm+FnIrOczA2E
# 4rfDMA0GCSqGSIb3DQEBCwUABIIBAI/jAnp7JgmY1rGxg8TYIg4fsTPv1D3Vx4p5
# PlIRNE6I1fcoYNLVx5ok0m6fu1HL2wDtSJLNOo1IPAEah6UUV5RR+ygXKlbeJ10+
# /nK/l7BYrFHQm6koOcQuLaIq7rkMgvqbtRFJH6TkR/imNh97E/mNUJ5P1bPbFF3b
# yAHsKtae/k6wFNAsjKtbTnZKdB/VgQ7gANbhCVroW11elMTEopqBOlItSNRiXLy1
# YRrxhI+pEmoaB27CNqdl/SVsFjz4Z8UseNcy+B2Nvda0J/SbjLXwAKU7aynyuQmg
# Y27c7rDTT6xF6THcNBwJ2tkUZybCIhwBRFj8tX6ybGShdQronNo=
# SIG # End signature block
