<#
.SYNOPSIS

Converts Windows Compatibility Appraiser BIN files to Human Readable XML files

.DESCRIPTION

Converts Windows Compatibility Appraiser BIN files to Human Readable XML files

Author
    Adam Gross
    @AdamGrossTX
    http://www.asquaredozen.com
    https://github.com/AdamGrossTX
    https://twitter.com/AdamGrossTX


.PARAMETER DeviceName

DeviceName of a remote computer. Defaults to local computer if not specified

.PARAMETER OutputFilePath

Path where all results are stored. Default to c:\Temp.

.PARAMETER BinFilePath

Path to specific BIN files that need to be processed. Defaults to c:\Windows\appcompat\appraiser\ if not specified

.PARAMETER ProcessPantherLogs

Switch parameter to look in any Panther locations for existing XML files to process


.EXAMPLE

Process BIN files from c:\Windows\appcompat\appraiser\ on the current computer and output to the default location of c:\Temp

.\Get-FeatureUpdateBlocks.ps1

.EXAMPLE

Process BIN files from c:\Windows\appcompat\appraiser\ on a remote computer and output to custom location of C:\MyDir

.\Get-FeatureUpdateBlocks.ps1 -DeviceName "MyDevice" -OutputFilePath "C:\MyDir"

.EXAMPLE

Process BIN files from c:\Windows\appcompat\appraiser\ on a remote computer and output to custom location of C:\MyDir and process any Panther logs that may exist on the device

.\Get-FeatureUpdateBlocks.ps1 -DeviceName "MyDevice" -OutputFilePath "C:\MyDir" -ProcessPantherLogs
 
.EXAMPLE

Process BIN files for a remote computer and output to custom location of C:\MyDir and process any Panther logs that may exist on the device and uses bin files from c:\MyBinFiles instead of the default locations

.\Get-FeatureUpdateBlocks.ps1 -DeviceName "MyDevice" -OutputFilePath "C:\MyDir" -ProcessPantherLogs -BinFilePath "C:\MyBinFiles"


.LINK

#Original Source
#https://gallery.technet.microsoft.com/scriptcenter/APPRAISE-APPRAISERbin-to-8399c0ee#content

#Main Blog Post
http://www.asquaredozen.com/2018/07/29/configuring-802-1x-authentication-for-windows-deployment/

#>

[cmdletbinding()]
Param(

    [string]
    $DeviceName,

    [string]
    $OutputFilePath = "c:\Temp",

    [string]
    $BinFilePath,

    [switch]
    $ProcessPantherLogs
)

$Main = {

    If($DeviceName) {
        $OutputFilePath = Join-Path -Path $OutputFilePath -ChildPath "$($DeviceName)"
        New-Item -Path $OutputFilePath -ItemType Directory -ErrorAction SilentlyContinue
    }

    Remove-Item -Path $OutputFilePath\* -Recurse -ErrorAction SilentlyContinue

    $BlocksFile = "$($OutputFilePath)\Blocks.TXT"
    $SDBValuesFile = "$($OutputFilePath)\Sdbvalues_all.TXT"

    If(!($BinFilePath)) {
        If($DeviceName) {
            $RootPath = "\\$($DeviceName)\c`$"
        }
        Else {
            $RootPath = "C:\"
        }
        $BinFilePath = Join-Path -Path $RootPath -ChildPath "Windows\appcompat\appraiser\*.bin"
        $WindowsBTPath = Join-Path -Path $RootPath -ChildPath "`$WINDOWS.~BT"
    }
    
    $BinFiles = Get-BinFiles -DeviceName $DeviceName -BinPath $BinFilePath
    If($BinFiles) {
        ForEach ($BinFile in $BinFiles) {
            ConvertFrom-BinToXML -InputBinFile $BinFile -OutputXMLPath $OutputFilePath
        }
        }
        Else {
            "No XML FIles Found" | Out-File -FilePath $BlocksFile -Append
        }

    If($ProcessPantherLogs.IsPresent) {
        Copy-Item (Join-Path -Path $WindowsBTPath -ChildPath "Sources\Panther\*APPRAISER_HumanReadable.xml") $OutputFilePath -ErrorAction SilentlyContinue 
    }
    
    [System.Collections.ArrayList]$BlockList = @()
    ForEach($File in (Get-Item -Path "*Humanreadable.xml" -ErrorAction SilentlyContinue)) 
        { 
            [xml]$AppraiserXML = Get-Content -Path $File.FullName
            Search-XMLForBlocks -AppraiserXML $AppraiserXML -InputFilePath $File.FullName -BlocksFilePath $BlocksFile -SdbValuesFilePath $SDBValuesFile -OutVariable $blocks
            $BlockList.Add($blocks)
        } 
    
    "AppCompatFlags" | Out-File -FilePath $BlocksFile -Append
    "==============" | Out-File -FilePath $BlocksFile -Append

    Get-Item 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser' | Out-File -FilePath $BlocksFile -Append
    Get-Item 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser\SEC' | Out-File -FilePath $BlocksFile -Append
    Get-Item 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser\GWX' | Out-File -FilePath $BlocksFile -Append
    
    If($ProcessPantherLogs.IsPresent) {
        Copy-Item -Path (Join-Path -Path $WindowsBTPath -ChildPath "Sources\Panther\appraiser.sdb") -Destination (Join-Path -Path $OutputFilePath -ChildPath "BT-Panther-sdb.sdb") -ErrorAction SilentlyContinue 
        Copy-Item -Path (Join-Path -Path $WindowsBTPath -ChildPath "Sources\appraiser.sdb") -Destination (Join-Path -Path $OutputFilePath -ChildPath "BT-sdb.sdb") -ErrorAction SilentlyContinue
        Copy-Item -Path (Join-Path -Path $RootPath -ChildPath "Windows\Panther\appraiser.sdb")  -Destination (Join-Path -Path $OutputFilePath -ChildPath "WIN-Panther-sdb.sdb") -ErrorAction SilentlyContinue
    }

}

Function Get-BinFiles {
Param (
    [string]
    $DeviceName,

    [string]
    $BinFilePath
)
    Try {
        If(!($BinFilePath)) {
            If($DeviceName) {
                $BinFilePath = "\\$($DeviceName)\c`$\Windows\appcompat\appraiser\*.bin"
            }
            Else {
                $BinFilePath = "C:\Windows\appcompat\appraiser\*.bin"
            }
        }
        $BinFiles = Get-Item -Path $BinFilePath -ErrorAction SilentlyContinue

        Return $BinFiles
    }
    Catch {
        $Error[0]
    }
}
Function ConvertFrom-BinToXML {
Param(
    [System.IO.FileSystemInfo]
    $InputBinFile,

    [string]
    $OutputXMLPath
)
    Try {
        $XMLOutputFilePath = "$($OutputXMLPath)\$($InputBinFile.Name)_HUMANREADABLE.XML"
            $XML = @( 
            '<?xml version="1.0" encoding="UTF-8"?>', 
            '<WicaRun>', 
            '  <RunInfos>', 
            '    <RunInfo> ', 
            '      <Component TypeIdentifier="InventoryBinaryDeserializer" SpecificIdentifier="InventoryBinaryDeserializer" Type="Inventory">', 
            '        <Property Name="BinaryDeserializerTier" Value="Inventory" />', 
            '        <Property Name="BinaryDeserializerTier" Value="DataSource" />', 
            '        <Property Name="BinaryDeserializerTier" Value="DecisionMaker" />', 
            '        <Property Name="BinaryDeserializerTier" Value="DecisionAggregator" />', 
            "        <Property Name=`"BinaryDeserializerFilePath`" Value=`"$InputBinFile`" />", 
            '      </Component>', 
            '      <Component TypeIdentifier="OutputEverything" SpecificIdentifier="OutputEverything" Type="Outputter">', 
            "        <Property Name=`"OutputFilePath`" Value=`"$XMLOutputFilePath`" />", 
            '      </Component>', 
            '    </RunInfo>', 
            '  </RunInfos>', 
            '</WicaRun>' ) 
    
        $XML | Out-File -FilePath "$($OutputXMLPath)\$($InputBinFile.Name)_ConvertBinTaskList.xml" -Encoding utf8
        Set-Location -Path $OutputXMLPath
        & cmd /C "rundll32.exe appraiser.dll,RunTest $($InputBinFile.Name)_ConvertBinTaskList.xml" 
    }
    Catch {
        $Error[0]
    }
} 
 
Function Search-XMLForBlocks {
Param ( 
    [xml]
    $AppraiserXML,  
    
    [string]
    $InputFilePath,
    
    [string]
    $BlocksFilePath,

    [string]
    $SdbValuesFilePath
) 

    [System.Xml.XmlElement] $root = $AppraiserXML.get_DocumentElement() 

    $i = 0 ; $s = 0 ; $sdbSearch = @() ; $sdb = @{}; $x = 0; $match = 0; $gBlock =@{}; $sBlock = @{} 
    Do { 
        $datasourceValues = @() 
        $datasourceValues = $root.Assets.Asset[$i].SelectNodes("PropertyList[@Type='DataSource']") 
        If($datasourceValues.Count -gt 0) 
            { 
                $sdbSearch = @() 
                $sdbSearch += $datasourceValues.SelectNodes("Property[@Name='SdbAppraiserData']") 
                $sdbSearch += $datasourceValues.SelectNodes("Property[@Name='SdbAppName']") 
                $sdbSearch += $datasourceValues.SelectNodes("Property[@Name='SdbEntryGuid']") 
                $sdbSearch += $datasourceValues.SelectNodes("Property[@Name='SdbBlockType']") 
                If($sdbSearch.Count -gt 0) 
                    { 
                        $sdb[$s] = $sdbSearch 
                        $s++ 
                    } 
            } 
        $count = $root.Assets.Asset.Count 
        Write-Progress -Activity "$count Items to Process" -PercentComplete (($i / $count) * 100) 
 
        $i++ 
 
    } Until($i -eq $count) 
    
    Write-Progress -Activity "$InputFilePath ..." -Completed 
    $InputFilePath | Out-File -FilePath $BlocksFilePath -Append
    "" | Out-File -FilePath $BlocksFilePath -Append
    
    Do { 
        $ordinal = ($sdb[$x] | Where-Object Value -EQ 'GatedBlock').Ordinal 
        If($ordinal.Count -gt 0) { 
            "Matching GatedBlock....FOUND!" | Out-File -FilePath $BlocksFilePath -Append
            "GatedBlock:" | Out-File -FilePath $BlocksFilePath -Append
            "==========" | Out-File -FilePath $BlocksFilePath -Append
            $match = 1
        } 
        If($ordinal.Count -gt 1) { 
            $gBlock = ForEach($num in $ordinal) {
                            $sdb[$x] | Where-Object Ordinal -EQ $num
                        } 
            $gBlock  | Out-File -FilePath $BlocksFilePath -Append
        }   
        If($ordinal.Count -eq 1) { 
            $gBlock = $sdb[$x] | Where-Object Ordinal -EQ $ordinal 
            $gBlock | Out-File -FilePath $BlocksFilePath -Append  
        } 

        $x++ 
    } Until ($x -gt $sdb.Count) 
 
    If($match -ne 1) {
        "Matching GatedBlock....NONE FOUND." | Out-File -FilePath $BlocksFilePath -Append
    } 
 
    $x=0 
 
    Do {      
        $ordinal = ($sdb[$x] | Where-Object Value -EQ 'BlockUpgrade').Ordinal 
        If($ordinal.Count -gt 0) { 
            "Matching BlockUpgrade....FOUND!" | Out-File -FilePath $BlocksFilePath -Append
            "BlockUpgrade:" | Out-File -FilePath $BlocksFilePath -Append
            "============" | Out-File -FilePath $BlocksFilePath -Append
            $match = 2
        }  
        If($ordinal.Count -gt 1) { 
            $sBlock = ForEach($num in $ordinal) {
                $sdb[$x] | Where-Object Ordinal -EQ $num
            } 
            $sBlock  | Out-File -FilePath $BlocksFilePath -Append
        }  
        Else {
            $sBlock = $sdb[$x] | Where-Object Ordinal -EQ $ordinal  
            $sBlock | Out-File -FilePath $BlocksFilePath -Append
        } 
    $x++ 
    } Until ($x -gt $sdb.Count) 

    If($match -ne 2){
        "Matching BlockUpgrade....NONE FOUND." | Out-File -FilePath $BlocksFilePath -Append
    }
    
    "For: $path" | Out-File -FilePath $SdbValuesFilePath -Append
    for($a=0; $a -lt $sdb.Count; $a++) 
        {   
            "Entry $a`:" | Out-File -FilePath $SdbValuesFilePath -Append 
            $sdb[$a] | Format-Table  | Out-File -FilePath $SdbValuesFilePath -Append
        } 
}

& $Main