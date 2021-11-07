SELECT
	ScriptName,
	Script,
	Base64Script,
	CAST (Script as nvarchar(max)),
	ScriptText = 
		CASE WHEN Base64Script like 'FFFE%' THEN
			CAST( CAST( Base64Script as XML ).value('.','varbinary(max)') AS nvarchar(max) )
		ELSE
			CONVERT(NVARCHAR(MAX),CAST( CAST( Base64Script as XML ).value('.','varbinary(max)') AS nvarchar(max) ))
		END
FROM
	Scripts
	CROSS APPLY (SELECT CONVERT(NVARCHAR(MAX),Script,2) AS '*' FOR XML PATH('')) T (Base64Script)
ORDER BY
	Script