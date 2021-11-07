param([int]$ErrorCode=0x87d00664)
[void][System.Reflection.Assembly]::LoadFrom("c:\temp\errorLookup\SrsResources.dll")
$Message = [SrsResources.Localization]::GetErrorMessage($ErrorCode,"en-US")

Return $Message



#'-2147467262'
#
#Invoke-RestMethod -URI "https://asdwinerrorlookup.azurewebsites.net/api/ErrorLookup?ErrorCode=0xc00000f"
#
#$Code = 0xc00000f
#
#$ex = New-Object System.ComponentModel.Win32Exception('0x800700C1')
#return $ex.Message
#
#0x80000002 | gm
#-2147483646 -eq 0x80000002
#2147483650 | gm
#"{0:X0}" -f ([int64]2147483650)
#
#$hex = "{0:X0}" -f ([int32]$code)
#                $int64 = [Convert]::ToInt64($hex,16)
#                $int32 = $code
#
#$code = 0x80000002

