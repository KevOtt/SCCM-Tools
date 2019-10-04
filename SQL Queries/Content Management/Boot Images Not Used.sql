/*
Query name:   	Boot Images Not Used.SQL
Created on:    	2/19/2016
Author:        	Kevin Ott
Purpose:       	Returns a list of boot images that are not used in any
				task sequences. Creation time status messages may be truncated
				based on the site configuration and will be shown as "old". Useful
				for identifying old and unneeded boot images.
*/

--CTEs
;WITH RawStatus AS
(
	SELECT
		M.RecordID,
		S.InsStrIndex,
		S.InsStrValue,
		M.[Time]
	FROM StatusMessages AS M
	INNER JOIN StatusMessageInsStrs AS S ON M.RecordID = S.RecordID
	WHERE M.MessageID = '30000' AND InsStrIndex < 3
),
PackageCreator AS
(
	SELECT
		P.[0] AS UserID,
		P.[1] AS PackageID,
		P.Time
	FROM RawStatus
	PIVOT
	(
		MAX(InsStrValue) FOR InsStrIndex IN ([0],[1])
	) AS P
)

--Main select
SELECT 
	PkgID
	,Name
	,PackageType
	,COALESCE(C.UserID, 'No Data' ) AS PackageCreator
	,COALESCE(CONVERT(nvarchar(255), C.[Time], 20), 'Old') AS PackageCreationTime
FROM SMSPackages_G AS P
LEFT OUTER JOIN TS_TaskSequence AS T ON PkgID = BootImageID
LEFT OUTER JOIN PackageCreator AS C ON PkgID = PackageID
WHERE PackageType = '258'
GROUP BY
	PkgID
	,Name
	,PackageType
	,BootImageID
	,C.UserID
	,C.[Time]
HAVING COUNT(TS_ID) = 0
