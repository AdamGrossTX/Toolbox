	SELECT
		DISTINCT 
		--ResourceID = s.ResourceID
		--,DeviceName = s.Name0
		--,
		OSCaption = CASE WHEN os.caption0 IS NULL THEN NULL ELSE os.Caption0 END
		,OSName = s.Operating_System_Name_and0
		,OSMarketVersion = kk.value
		,OSRelease = ln.Value
		,OSEdition = ll.value
		,OSType = g.value
		,OSVersionBase = xx.value
		,OSVersion = f.value
		,OSVersionFull = CASE WHEN os.Version0 IS NULL THEN s.Build01 ELSE os.Version0 END
		--,OSVersionExt = s.BuildExt
		,OSBuildNumber = CONVERT(int,os.BuildNumber0)
		--,OSBuildExtNumber = CONVERT(int,ext.value)
		,RecordStatus = 
			CASE 
				WHEN s.Operating_System_Name_and0 IS NULL OR s.build01 IS NULL THEN 'Discovery Data'
				WHEN os2.Version0 IS NOT NULL AND s.Build01 <> os2.Version0 THEN 'Version Mismatch'
				WHEN os2.Version0 IS NULL THEN 'Missing HWInv Data' 
				ELSE 'Valid' 
			END
	FROM
		v_r_system s LEFT OUTER JOIN
		v_GS_OPERATING_SYSTEM os ON s.ResourceID = os.ResourceID AND s.Build01 = os.Version0 LEFT OUTER JOIN
		v_GS_OPERATING_SYSTEM os2 ON s.ResourceID = os2.ResourceID FULL OUTER JOIN
		fn_GetWindowsServicingStates() ss ON s.Build01 = ss.Build AND s.OSBranch01 = ss.Branch LEFT OUTER JOIN
		fn_GetWindowsServicingLocalizedNames() ln ON ln.Name = ss.Name
		--OSType
		CROSS APPLY (SELECT CASE WHEN Operating_System_Name_and0 = ' ' THEN NULL ELSE Operating_System_Name_and0 END as value) a0
		CROSS APPLY (SELECT REPLACE(a0.value,'Microsoft Windows NT ','') AS value) a
		CROSS APPLY (SELECT REPLACE(a.value,'(Tablet Edition)','') AS value) b
		CROSS APPLY (SELECT REPLACE(b.value,'(Embedded)','') AS value) c
		CROSS APPLY (SELECT RTRIM(LTRIM(c.value)) AS value) d
		CROSS APPLY (SELECT CASE WHEN os.ProductType0 = 1 THEN LEFT(d.value,CHARINDEX(' ',d.value)-1) ELSE d.value END AS value) e
		CROSS APPLY (SELECT REVERSE(SUBSTRING(REVERSE(d.value),0,CHARINDEX(' ',REVERSE(d.value)))) as value) f
		CROSS APPLY (SELECT LEFT(c.value,len(c.value) - len(f.value)-1) AS value) g
		--OSEdition, OSMarketVersion
		CROSS APPLY (SELECT REPLACE(os.caption0,'(R)','') AS value) aa
		CROSS APPLY (SELECT REPLACE(aa.value,'®','') AS value) bb
		CROSS APPLY (SELECT REPLACE(bb.value,'Microsoft Windows ','') AS value) cc
		CROSS APPLY (SELECT REPLACE(cc.value,'Server ','') AS value) dd
		CROSS APPLY (SELECT REPLACE(dd.value,'Storage ','') AS value) ff
		CROSS APPLY (SELECT REPLACE(ff.value,',','') AS value) gg
		CROSS APPLY (SELECT CASE 
							WHEN gg.value not like '% %' THEN gg.value
							WHEN os.ProductType0 = 1 THEN LEFT(gg.value,CHARINDEX(' ',gg.value)-1)
							WHEN os.ProductType0 in (2,3) THEN LEFT(gg.value,LEN(gg.value) - LEN(REVERSE(SUBSTRING(REVERSE(gg.value),0,CHARINDEX(' ',REVERSE(gg.value)))))-1) ELSE gg.value 
							END as value) hh
		CROSS APPLY (SELECT CASE 
						WHEN hh.value not like '% %' THEN hh.value
						WHEN os.ProductType0 = 1 THEN LEFT(hh.value,CHARINDEX(' ',hh.value)-1)
						WHEN os.ProductType0 in (2,3) THEN LEFT(hh.value,LEN(hh.value) - LEN(REVERSE(SUBSTRING(REVERSE(hh.value),0,CHARINDEX(' ',REVERSE(hh.value)))))-1) ELSE hh.value 
						END as value) ii
		CROSS APPLY (SELECT CASE 
						WHEN os.ProductType0 in (2,3) THEN REPLACE(hh.value,' Standard','')
						ELSE hh.value 
						END as value) jj
		CROSS APPLY (SELECT RTRIM(LTRIM(jj.value)) AS value) kk
		CROSS APPLY (SELECT CASE WHEN ff.value not like '% %' THEN ff.value ELSE REVERSE(SUBSTRING(REVERSE(ff.value),0,CHARINDEX(' ',REVERSE(ff.value)))) END as value) ll
		CROSS APPLY (SELECT Convert(int,SUBSTRING(s.Build01,0,CHARINDEX('.',(s.Build01)))) as value) xx
		CROSS APPLY (SELECT REVERSE(SUBSTRING(REVERSE(s.BuildExt),0,CHARINDEX('.',REVERSE(s.BuildExt)))) value) ext
		
WHERE CASE 
				WHEN s.Operating_System_Name_and0 IS NULL OR s.build01 IS NULL THEN 'Discovery Data'
				WHEN os2.Version0 IS NOT NULL AND s.Build01 <> os2.Version0 THEN 'Version Mismatch'
				WHEN os2.Version0 IS NULL THEN 'Missing HWInv Data' 
				ELSE 'Valid' 
			END = 'Valid'