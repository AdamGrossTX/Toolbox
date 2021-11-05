SELECT * FROM
(select
Name,
machineid,
CountMachineID = COUNT(*) OVER (PARTITION BY MachineID),
CountName = COUNT(*) OVER (PARTITION BY Name),
c.*
FROM
CollectionMembers cm LEFT OUTER JOIN
collections c ON cm.SiteID = c.SiteID
--where machineid = 16789646
) a where a.CountMachineID <> a.CountName