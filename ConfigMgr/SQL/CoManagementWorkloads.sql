--spGetMDMWorkloadEnabledCount
--AdminUI.CoManagement.dll - CoManagementFlags
--CoManagementFlags
/*
    None = 0, 0x0
    Inventory = 1, 0x1
    CompliancePolicy = 2, 0x2
    ResourceAccess = 4, 0x4
    ConfigurationSettings = 8, 0x8
    WUfB = 16, 0x10
    Security = 32, 0x20
    ModernApps = 64, 0x40
    Office365 = 128, 0x80
    DiskEncryption = 4096, 0x1000
    EpSplit = 8192, 0x2000
    Default = 8193 0x2001
*/

SELECT 
	s.ResourceID,
	MDMEnrolled = cms.MDMEnrolled,
	Authority = cms.Authority,
	MDMWorkloads = cms.MDMWorkloads,
	ComgmtPolicyPresent = cms.ComgmtPolicyPresent,
	Name = cms.Name,
	SiteCode = cms.SiteCode,
	AADDeviceID = cms.AADDeviceID,
	MDMProvisioned = cms.MDMProvisioned,
	HybridAADJoined = cms.HybridAADJoined,
	AADJoined = cms.AADJoined,
	EnrollmentFailed = cms.EnrollmentFailed,
	PendingLogon = cms.PendingLogon,
	EnrollmentScheduled = cms.EnrollmentScheduled,
	EnrollmentStatusCode = cms.EnrollmentStatusCode,
	EnrollmentErrorDetail = cms.EnrollmentErrorDetail,
	None					= CASE WHEN ISNULL(TRY_convert(bigint, MDMWorkloads), 2147483647) & 0x0 = 0x0 THEN 1 ELSE 0 END,
	Inventory				= CASE WHEN ISNULL(TRY_convert(bigint, MDMWorkloads), 2147483647) & 0x1 = 0x1 THEN 1 ELSE 0 END,
	CompliancePolicy			= CASE WHEN ISNULL(TRY_convert(bigint, MDMWorkloads), 2147483647) & 0x2 = 0x2 THEN 1 ELSE 0 END,
	ResourceAccess			= CASE WHEN ISNULL(TRY_convert(bigint, MDMWorkloads), 2147483647) & 0x4 = 0x4 THEN 1 ELSE 0 END,
	ConfigurationSettings	      = CASE WHEN ISNULL(TRY_convert(bigint, MDMWorkloads), 2147483647) & 0x8 = 0x8 THEN 1 ELSE 0 END,
	WUfB					= CASE WHEN ISNULL(TRY_convert(bigint, MDMWorkloads), 2147483647) & 0x10 = 0x10 THEN 1 ELSE 0 END,
	Security				= CASE WHEN ISNULL(TRY_convert(bigint, MDMWorkloads), 2147483647) & 0x20 = 0x20 THEN 1 ELSE 0 END,
	ModernApps				= CASE WHEN ISNULL(TRY_convert(bigint, MDMWorkloads), 2147483647) & 0x40 = 0x40 THEN 1 ELSE 0 END,
	Office365				= CASE WHEN ISNULL(TRY_convert(bigint, MDMWorkloads), 2147483647) & 0x80 = 0x80 THEN 1 ELSE 0 END,
	DiskEncryption			= CASE WHEN ISNULL(TRY_convert(bigint, MDMWorkloads), 2147483647) & 0x1000 = 0x1000 THEN 1 ELSE 0 END,
	EndpointProtection		= CASE WHEN ISNULL(TRY_convert(bigint, MDMWorkloads), 2147483647) & 0x2000 = 0x2000 THEN 1 ELSE 0 END,
	[Default]				= CASE WHEN ISNULL(TRY_convert(bigint, MDMWorkloads), 2147483647) & 0x2001 = 0x2001 THEN 1 ELSE 0 END,
	Intune				= CASE WHEN ISNULL(TRY_convert(bigint, MDMWorkloads), 2147483647) & 0xFFFFFFFF = 0xFFFFFFFF THEN 1 ELSE 0 END
FROM 
	(SELECT ResourceID = MAX(ResourceID) FROM v_r_system WHERE Operating_System_Name_and0 like 'Microsoft Windows NT Workstation%' AND Client0 = 1 GROUP BY Name0) s LEFT OUTER JOIN
	v_ClientCoManagementState cms ON s.ResourceID = cms.ResourceID
ORDER BY
	MDMWorkloads 
DESC
     


