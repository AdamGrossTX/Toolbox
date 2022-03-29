SELECT
	AssignmentID,
	MachineName,
	MachineID,
	UserName,
	AppName,
	DTName,
	CollectionName
FROM
	fn_AppDeploymentErrorAssetDetails(1033) 
WHERE 
	ErrorCode = N'-2146889721'