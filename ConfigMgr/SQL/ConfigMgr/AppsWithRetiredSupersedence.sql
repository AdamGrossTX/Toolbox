Declare @TaskSequenceID char(8); 
set @TaskSequenceID = 'YOURTSID'

SELECT
	CI.CI_ID,
	CI.CI_UniqueID,
	CI.Manufacturer,
	CI.DisplayName,
	CI.SoftwareVersion,
	ARF.ToApplication as RetiredSupersededApp
FROM
	v_TaskSequenceAppReferencesInfo INNER JOIN
	fn_ListLatestApplicationCIs(1033) CI ON CI.CI_ID = v_TaskSequenceAppReferencesInfo.RefAppCI_ID INNER JOIN
	(
		select 
			locpropFromapp.CI_ID as FromAppCI,
			locpropFromapp.DisplayName as FromApp,
			locpropFromDT.DisplayName as FromDeploymentType,
			locpropToapp.DisplayName as ToApplication, 
			locpropToDT.DisplayName as ToDeploymentType 
		from  
			vSMS_AppRelation_Flat as appflat
			JOIN v_LocalizedCIProperties as locpropFromapp ON locpropFromapp.CI_ID = appflat.FromApplicationCIID
			JOIN v_LocalizedCIProperties as locpropFromDT ON locpropFromDT.CI_ID = appflat.FromDeploymentTypeCIID
			JOIN v_LocalizedCIProperties as locpropToapp ON locpropToapp.CI_ID = appflat.ToApplicationCIID
			JOIN v_LocalizedCIProperties as locpropToDT ON locpropToDT.CI_ID = appflat.ToDeploymentTypeCIID
			JOIN v_ConfigurationItems as ciFrom ON locpropFromapp.CI_ID = ciFrom.CI_ID
			JOIN v_ConfigurationItems as ciTo ON locpropToapp.CI_ID = ciTo.CI_ID
		where 
		appflat.RelationType=15
		--AND ciFrom.IsTombstoned = 0
		AND ciFrom.IsLatest = 1
		AND ciFrom.IsExpired = 0
		--AND 
		--ciTo.IsTombstoned = 1
		--AND ciTo.IsLatest = 1
		AND 
		ciTo.IsExpired = 1
		) ARF ON ARF.FromAppCI = CI.CI_ID
WHERE 
	v_TaskSequenceAppReferencesInfo.PackageID = @TaskSequenceID	AND
	CI.ISSuperseding = 1

