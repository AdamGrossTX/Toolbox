SELECT
	BoundaryGroupName = BG.Name,
	Boundaryname = B.Name,
	DeviceName = S.Name0,
	CountOfIPs = Count(s.ResourceID) OVER (PARTITION BY a.ResourceID),
	S.ResourceID,
	IPAddress = ip_addresses0,
	B.*,
	bg.*
FROM
	v_R_System s LEFT OUTER JOIN
	v_RA_System_IPAddresses A ON s.ResourceID = A.ResourceID AND A.ip_addresses0 NOT LIKE '%:%' LEFT OUTER JOIN
	v_RA_System_IPSubnets sub ON sub.ResourceID = S.ResourceID LEFT OUTER JOIN
	BoundaryEx B ON dbo.fnGetNumericIPAddress(A.ip_addresses0) BETWEEN B.NumericValueLow AND B.NumericValueHigh LEFT OUTER JOIN
	BoundaryGroupMembers m ON m.BoundaryID = B.BoundaryID LEFT OUTER JOIN
	BoundaryGroup bg ON bg.GroupID = M.GroupID
WHERE
	S.Operating_System_Name_and0 like 'Microsoft Windows NT Workstation%'
ORDER BY
	S.Name0,A.IP_Addresses0
