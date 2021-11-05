SELECT
	* 
FROM 
	Collection_Rules_SQL
WHERE
	SQL like '%CollectedFile%' OR
	SQL like '%LastSoftwareScan%' OR
	SQL like '%Mapped_Add_Remove_Programs%' OR
	SQL like '%SoftwareFile%' OR
	SQL like '%SoftwareProduct%' OR
	SQL like '%UnknownFile%' OR
	SQL like '%ProductFileInfo%' OR
	SQL like '%SoftwareFile%' OR
	SQL like '%SoftwareProduct%'