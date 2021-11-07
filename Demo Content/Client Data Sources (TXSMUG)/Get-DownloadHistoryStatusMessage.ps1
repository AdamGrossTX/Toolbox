$NameSpace = 'root\ccm\StateMsg'
$ClassName = 'CCM_StateMsg'
$TopicID = "STATE_STATEID_DOWNLOAD_AGGREGATE_DATA_UPLOAD"
$TopicType = 7202

Get-CIMInstance -Namespace $NameSpace -Class $ClassName -Filter "TopicType = $($TopicType)"
[XML]$StateDetails = $StateMessageInstance.StateDetails
