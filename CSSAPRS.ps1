Param(

    [string]
    $DeviceName = "HQ-CA251610",

    [string]
    $BinFilePath,

    [switch]
    $ProcessFUXML,

    [string]
    $OutputFilePath = "C:\Temp\Temp"
)

$Main = {

    $BinFiles = Get-BinFiles -DeviceName $DeviceName -BinPath $BinPath
    ForEach ($BinFile in $BinFiles) {
        ConvertFrom-BinToXML -InputFile $BinFile -OutputFilePath $OutputFilePath
    }

    If($ProcessFUXML) {
        Copy-Item 'C:\$WINDOWS.~BT\Sources\Panther\*APPRAISER_HumanReadable.xml' $OutputFilePath -ErrorAction SilentlyContinue 
    }
    
    [System.Collections.ArrayList]$BlockList = @()
    ForEach($File in (Get-Item -Path "*Humanreadable.xml" -ErrorAction SilentlyContinue)) 
        { 
            Write-Host "`nReading XML...`n" 
            [xml]$AppraiserXML = Get-Content -Path $File.FullName
    
            Search-XMLForBlocks -AppraiserXML $AppraiserXML -Path $File.FullName -OutputFilePath "$($OutputFilePath)\Blocks.TXT"  -OutVariable $blocks
    
            $BlockList.Add($blocks)
        } 
    
    #    $BlockList 
    #"`nAppCompatFlags", "`n==============" | Out-File BLOCKS.TXT -Append

    Get-Item 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser' | Out-File "$($OutputFilePath)\Blocks.TXT" -Append
    Get-Item 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser\SEC' | Out-File "$($OutputFilePath)\Blocks.TXT" -Append
    Get-Item 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Appraiser\GWX' | Format-Table | Out-File "$($OutputFilePath)\Blocks.TXT" -Append
    
    #Copy 'C:\Temp\\appraiser.sdb' C:\Temp\BT-sdb.sdb -EA SilentlyContinue 
    #Copy 'C:\Temp\er.sdb' C:\Temp\BT-Panther-sdb.sdb -EA SilentlyContinue 
    #Copy 'C:\Temp\b' C:\Temp\WIN-Panther-sdb.sdb -EA SilentlyContinue 
    
    #Explorer.EXE C:\Temp
    
    #Stop-Transcript 
    
    Write-Host "Any Blocking Values are written to Blocks.TXT" 

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
    $InputFile,

    [string]
    $OutputFilePath
)
    Try {
        $pathOutput = "$($OutputFilePath)\$($InputFile.Name)_HUMANREADABLE.XML"
            $xml = @( 
            '<?xml version="1.0" encoding="UTF-8"?>', 
            '<WicaRun>', 
            '  <RunInfos>', 
            '    <RunInfo> ', 
            '      <Component TypeIdentifier="InventoryBinaryDeserializer" SpecificIdentifier="InventoryBinaryDeserializer" Type="Inventory">', 
            '        <Property Name="BinaryDeserializerTier" Value="Inventory" />', 
            '        <Property Name="BinaryDeserializerTier" Value="DataSource" />', 
            '        <Property Name="BinaryDeserializerTier" Value="DecisionMaker" />', 
            '        <Property Name="BinaryDeserializerTier" Value="DecisionAggregator" />', 
            "        <Property Name=`"BinaryDeserializerFilePath`" Value=`"$InputFile`" />", 
            '      </Component>', 
            '      <Component TypeIdentifier="OutputEverything" SpecificIdentifier="OutputEverything" Type="Outputter">', 
            "        <Property Name=`"OutputFilePath`" Value=`"$pathOutput`" />", 
            '      </Component>', 
            '    </RunInfo>', 
            '  </RunInfos>', 
            '</WicaRun>' ) 
    
        $xml | Out-File -FilePath "$($OutputFilePath)\Run.xml" -Encoding utf8
        Set-Location -Path $OutputFilePath
        & cmd /C "rundll32.exe appraiser.dll,RunTest Run.xml" 
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
    $path,
    
    [string]
    $OutputFilePath
) 
    Write-Host "`nChecking $path ...`n" 
 
    [System.Xml.XmlElement] $root = $AppraiserXML.get_DocumentElement() 
 
 
    $i = 0 ; $s = 0 ; $sdbSearch = @() ; $sdb = @{}; $x = 0; $match = 0; $gBlock =@{}; $sBlock = @{} 
    ############### Searching for DataSource Nodes Containing Sdb* Vlaues ############### 
    Do{ 
 
        $datasourceValues = @() 
 
        $datasourceValues = $root.Assets.Asset[$i].SelectNodes("PropertyList[@Type='DataSource']") 
 
        if($datasourceValues.Count -gt 0) 
            { 
                $sdbSearch = @() 
                $sdbSearch += $datasourceValues.SelectNodes("Property[@Name='SdbAppraiserData']") 
                $sdbSearch += $datasourceValues.SelectNodes("Property[@Name='SdbAppName']") 
                $sdbSearch += $datasourceValues.SelectNodes("Property[@Name='SdbEntryGuid']") 
                $sdbSearch += $datasourceValues.SelectNodes("Property[@Name='SdbBlockType']") 
 
                if($sdbSearch.Count -gt 0) 
                    { 
                        $sdb[$s] = $sdbSearch 
 
                        $s++ 
                    } 
 
            } 
        $count = $root.Assets.Asset.Count 
        Write-Progress -Activity "$count Items to Process" -PercentComplete (($i / $count) * 100) 
 
        $i++ 
 
    }Until($i -eq $count) 
        Write-Progress -Activity "$path ..." -Completed 
        $path | Out-File $OutputFilePath -Append
    ############### Match Appropriate Ordinals for GatedBlock############### 
    Write-Host "`nMatching `'GatedBlock`'...." -NoNewline   
  
    Do 
    { 
        $ordinal = ($sdb[$x] | Where-Object Value -EQ 'GatedBlock').Ordinal 
 
        if($ordinal.Count -gt 0) 
            { "`nMatching `'GatedBlock`'....FOUND!`n`nGatedBlock:`n==========" | Out-File $OutputFilePath -Append
                                                    $match = 1 
                                                        Write-Host "FOUND!"} 
        if($ordinal.Count -gt 1) 
            { $gBlock = ForEach($num in $ordinal){$sdb[$x] | Where-Object Ordinal -EQ $num} 
              $gBlock  | Out-File $OutputFilePath -Append
              Write-Output $gBlock }   
        if($ordinal.Count -eq 1)          
            { $gBlock = $sdb[$x] | Where-Object Ordinal -EQ $ordinal 
              $gBlock | Out-File $OutputFilePath -Append  
              Write-Output $gBlock } 
                       
    $x++ 
    }Until ($x -gt $sdb.Count) 
 
    if($match -ne 1){Write-Host "NONE FOUND." 
                                "`nMatching `'GatedBlock`'....NONE FOUND.`n"  | Out-File $OutputFilePath -Append} 
 
    ############### Match Appropriate Ordinals for BlockUpgrade############### 
    Write-Host "`nMatching `'BlockUpgrade`'...."  -NoNewline    
 
    $x=0 
 
        Do 
        {      
        $ordinal = ($sdb[$x] | Where Value -EQ 'BlockUpgrade').Ordinal 
 
            if($ordinal.Count -gt 0) 
                { "`nMatching `'BlockUpgrade`'....FOUND!`n`nBlockUpgrade:`n============"  | Out-File $OutputFilePath -Append  
                                                        $match = 2 
                                                            Write-Host "FOUND!"}  
            if($ordinal.Count -gt 1) 
                 { $sBlock = foreach($num in $ordinal){$sdb[$x] | Where Ordinal -EQ $num} 
                   $sBlock  | Out-File $OutputFilePath -Append
                   Write-Output $sBlock}  
                    Else { $sBlock = $sdb[$x] | Where Ordinal -EQ $ordinal  
                           $sBlock | Out-File $OutputFilePath -Append
                           Write-Output $sBlock} 
 
 
        $x++ 
        }Until ($x -gt $sdb.Count) 
 
        if($match -ne 2){Write-Host "NONE FOUND." 
                                    "`nMatching `'BlockUpgrade`'....NONE FOUND.`n" | Out-File $OutputFilePath -Append} 
 
    ############### Dumping All Sdb* Values ############### 
 #   Write-Host "`nWriting All Sdb* Values " -NoNewline 
 #   "For: $path" >> Sdbvalues_all.TXT 
 #   for($a=0; $a -lt $sdb.Count; $a++) 
 #       {   "Entry $a`:" >> Sdbvalues_all.TXT; 
 #           $sdb[$a] | ft >> Sdbvalues_all.TXT    
 #               Write-Host "." -NoNewline } 
 #   Write-Host "`n"  
 
}

& $Main