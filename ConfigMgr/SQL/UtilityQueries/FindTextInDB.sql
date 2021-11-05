--Change the USING to the DB you want to run this against. 
USE [CM_ASD]

--Change the value to your search term
DECLARE @Text nvarchar(1000)
SET @Text = 'TextToFind'


----Main Query--

DECLARE @newText varchar(1000)
SET @NewText = '%' + @Text + '%'

SELECT
	DISTINCT
	'TableOrView' AS 'ObjectType'
	,TABLE_NAME AS  'ObjectName'	
	,CASE WHEN COLUMN_NAME LIKE @NewText THEN COLUMN_NAME ELSE NULL END AS 'ColumnName'
	,NULL AS 'Excerpt'
	,NULL AS 'Definition'
FROM
	INFORMATION_SCHEMA.COLUMNS
WHERE
	TABLE_NAME LIKE @NewText OR
	COLUMN_NAME LIKE @NewText

UNION

SELECT
	DISTINCT
	'StoredProcedure' AS 'ObjectType'
	,SPECIFIC_NAME AS 'ObjectName'
	,NULL AS 'ColumnName'
	,SUBSTRING(ROUTINE_DEFINITION, CHARINDEX(@Text, ROUTINE_DEFINITION)-50, 100) AS 'Excerpt'	
	,ROUTINE_DEFINITION AS 'Definition'
FROM 
	INFORMATION_SCHEMA.ROUTINES
WHERE
	SPECIFIC_NAME LIKE @NewText OR
	ROUTINE_DEFINITION LIKE @NewText

UNION

SELECT
	DISTINCT
	'ViewDefinition' AS 'ObjectType'
	,TABLE_NAME AS 'ObjectName'
	,NULL AS 'ColumnName'
	,SUBSTRING(VIEW_DEFINITION, CHARINDEX(@text, VIEW_DEFINITION)-50, 100) as 'Excerpt'
	,VIEW_DEFINITION  AS 'Definition'
FROM 
	INFORMATION_SCHEMA.VIEWS
WHERE
	TABLE_NAME LIKE @NewText OR
	VIEW_DEFINITION LIKE @newText

UNION

SELECT
	DISTINCT
	'Function' AS 'ObjectType' 
	,TABLE_NAME AS  'ObjectName'
	,COLUMN_NAME AS 'ColumnName'
	,NULL AS 'Excerpt'
	,NULL AS 'Definition'
FROM 
	INFORMATION_SCHEMA.ROUTINE_COLUMNS
WHERE
	COLUMN_NAME LIKE @newText
ORDER BY
	ObjectType,
	ColumnName,
	ObjectName