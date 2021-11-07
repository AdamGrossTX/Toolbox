select DISTINCT
	--s.ResourceID,
	s.Operating_System_Name_and0,
	os.Caption0,
	v.VersionNumberFull,
	v.VersionNumberBuild,
	v.VersionNumberMajor,
	v.VersionNumberMinor,
	VersionNumberVersion,
	v.VersionNumberUBR,
	ServicePack = os.CSDVersion0,
	LocalizedName = WSLN.Value,
	OSBranchID = s.Osbranch01,
	OSType = CASE 
		WHEN os.ProductType0 = 1 OR s.Operating_System_Name_and0 like '%Workstation%' THEN 'Workstation'
		WHEN os.ProductType0 in (2,3) OR s.Operating_System_Name_and0 like '%Server%' THEN 'Server'
		ELSE NULL
	END,
	SKU = CASE 
		WHEN os.Caption0 LIKE '%Enterprise%' THEN 'Enterprise'
		WHEN os.Caption0 LIKE '%Professional%' THEN 'Professional'
		WHEN os.Caption0 LIKE '%Ultimate%' THEN 'Ultimate'
		WHEN os.Caption0 LIKE '%Pro%' THEN 'Professional'
		WHEN os.Caption0 LIKE '%Home%' THEN 'Home'
		WHEN os.Caption0 LIKE '%Datacenter%' THEN 'Datacenter'
		WHEN os.Caption0 LIKE '%Standard%' THEN 'Standard'
		WHEN os.Caption0 LIKE '%Hyper-V%' THEN 'Hyper-V'
		ELSE NULL
	END,
	SupportStateID = wss.State,
	SupportState = 
		CASE WHEN WSS.state = '2' THEN 'Current'
			WHEN WSS.state = '3' THEN 'Expiring Soon' 
			WHEN WSS.state = '4' THEN 'Expired'
			ELSE NULL
		END,
	OSLanguage = CASE WHEN WSLN.LocaleID IS NULL THEN os.OSLanguage0 ELSE WSLN.LocaleID END,
	Windows10ReleaseName = wss.Name,
	GroupName = CASE WHEN pg.GroupName IS NULL THEN p.GroupName ELSE pg.GroupName END,
	Category = CASE WHEN pg.Category IS NULL THEN p.Category ELSE pg.Category END,
	MainstreamSupportEndDateAsDate = CASE WHEN pg.MainstreamSupportEndDateAsDate IS NULL THEN p.MainstreamSupportEndDateAsDate ELSE pg.MainstreamSupportEndDateAsDate END,
	ExtendedSupportEndDateAsDate = CASE WHEN pg.ExtendedSupportEndDateAsDate IS NULL THEN p.ExtendedSupportEndDateAsDate ELSE pg.ExtendedSupportEndDateAsDate END,
	LastUpdated = CASE WHEN pg.LastUpdated IS NULL THEN p.LastUpdated ELSE pg.LastUpdated END,
	RecordStatus = 
		CASE 
			WHEN s.Client0 = 0 THEN 'No Client'
			WHEN s.Obsolete0 = 1 THEN 'Obselete'
			WHEN s.Operating_System_Name_and0 IS NULL OR s.build01 IS NULL THEN 'Discovery Data'
			WHEN os2.Version0 IS NOT NULL AND s.Build01 <> os2.Version0 THEN 'Version Mismatch'
			WHEN os2.Version0 IS NULL THEN 'Missing HWInv Data' 
			ELSE 'Valid' 
		END
FROM 
	v_r_system s LEFT OUTER JOIN
	(SELECT a.* FROM v_GS_OPERATING_SYSTEM A INNER JOIN 
	(SELECT ResourceID, MAX(TimeStamp) as MaxTimeStamp FROM v_GS_OPERATING_SYSTEM GROUP BY resourceID) B ON a.ResourceID = b.ResourceID and a.TimeStamp = b.MaxTimeStamp) os ON s.ResourceID = os.ResourceID AND s.Build01 = os.Version0 LEFT OUTER JOIN
	(SELECT a.* FROM v_GS_OPERATING_SYSTEM A INNER JOIN 
	(SELECT ResourceID, MAX(TimeStamp) as MaxTimeStamp FROM v_GS_OPERATING_SYSTEM GROUP BY resourceID) B ON a.ResourceID = b.ResourceID and a.TimeStamp = b.MaxTimeStamp) os2 ON s.ResourceID = os2.ResourceID FULL OUTER JOIN
    v_WindowsServicingStates wss ON wss.Build = (CASE WHEN os.Version0 IS NULL THEN s.Build01 ELSE os.Version0 END) AND COALESCE(wss.Branch, 0) = COALESCE(s.OSBranch01, 0) LEFT OUTER JOIN
	vSMS_WindowsServicingLocalizedNames WSLN ON WSS.NAME = WSLN.NAME LEFT OUTER JOIN
    v_LU_LifecycleProductGroups pg ON wss.Name = pg.ScanData0 AND dbo.fn_LifecycleOSCaptionToSku(os.Caption0) = pg.ScanData1 LEFT OUTER JOIN
	(
	SELECT 
		s.ResourceID,
		VersionNumberFull = CASE WHEN s.BuildExt IS NULL THEN s.Build01 ELSE s.BuildExt END,
		VersionNumberBuild = s.Build01,
		VersionNumberMajor = MAX(CASE WHEN id = 1 THEN data ELSE NULL END) OVER (PARTITION BY ResourceID),
		VersionNumberMinor = MAX(CASE WHEN id = 2 THEN data ELSE NULL END) OVER (PARTITION BY ResourceID),
		VersionNumberVersion = MAX(CASE WHEN id = 3 THEN data ELSE NULL END) OVER (PARTITION BY ResourceID),
		VersionNumberUBR = MAX(CASE WHEN id = 4 THEN data ELSE NULL END) OVER (PARTITION BY ResourceID)
	FROM
		v_R_System s CROSS APPLY
		fnSplitString(CASE WHEN s.BuildExt IS NULL THEN s.Build01 ELSE s.BuildExt END,'.') v
	) v ON v.ResourceID = s.ResourceID LEFT OUTER JOIN
	(
	SELECT 
		DISTINCT
		ldp.ResourceID,
		lpg.GroupName,
		lpg.Category,
		lpg.MainstreamSupportEndDateAsDate,
		lpg.ExtendedSupportEndDateAsDate,
		lpg.LastUpdated
	FROM 
		v_LifecycleDetectedProducts ldp LEFT OUTER JOIN
		v_LU_LifecycleProductHashes lph ON lph.SoftwarePropertiesHash = ldp.SoftwarePropertiesHash LEFT OUTER JOIN
		v_LU_LifecycleProductGroups lpg ON lph.GroupID = lpg.GroupId
	WHERE 
		ldp.ProductName like '%Windows%'
	) p
	ON p.ResourceID = s.ResourceID 
WHERE
	s.ResourceID IS NOT NULL
ORDER BY
	1,2,4,3
