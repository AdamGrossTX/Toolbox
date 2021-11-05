SELECT 
	s.Name0,
	s.ResourceID
	,Build01
		,CASE 
			LEFT(BUILD01,Charindex('.',Build01)-1)
			WHEN 5 THEN 'XP'
			WHEN 6 THEN '7'
			WHEN 10 THEN '10'
			ELSE NULL
		END as OSBaseVersion
	,BuildExt
	,Operating_System_Name_and0
	,os.Version0
	,BuildNumber0
	,Caption0
	,CSDVersion0
	,ProductType0
	,Version0
	,ss.*
	,ln.*
	,c.*
FROM
	v_r_system s LEFT OUTER JOIN
	v_GS_OPERATING_SYSTEM os ON s.ResourceID = os.ResourceID AND s.Build01 = os.Version0 LEFT OUTER JOIN
	--v_GS_OPERATING_SYSTEM os2 ON s.ResourceID = os2.ResourceID FULL OUTER JOIN
	fn_GetWindowsServicingStates() ss ON s.Build01 = ss.Build AND s.OSBranch01 = ss.Branch LEFT OUTER JOIN
	fn_GetWindowsServicingLocalizedNames() ln ON ln.Name = ss.Name
Where Caption0 like '%pro%' and BUILD01 like '10.%'
