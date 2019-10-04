/*
Query name:   	OS Images Not Used.SQL
Created on:    	2/19/2016
Author:        	Kevin Ott
Purpose:       	Returns a list of OS images that are not used in any
				task sequences. Creation time status messages may be truncated
				based on the site configuration and will be shown as "old". Useful
				for identifying old and unneeded boot images.
*/

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


SELECT
	P.PkgID
	,Name
	,CS.[TargeteddDPCount] AS TargetedDPs
	,COALESCE(C.UserID, 'No Data' ) AS PackageCreator
	,COALESCE(CONVERT(nvarchar(255), C.[Time], 20), 'Old') AS PackageCreationTime
FROM SMSPackages_G AS P
LEFT OUTER JOIN v_TaskSequencePackageReferences AS T ON P.PkgID = T.RefPackageID
LEFT OUTER JOIN PackageCreator AS C ON PkgID = C.PackageID
LEFT OUTER JOIN [v_ContDistStatSummary] AS CS ON P.PkgID = CS.PkgID
WHERE PackageType = '257'
GROUP BY
	P.PkgID
	,Name
	,C.UserID
	,C.[Time]
	,CS.[TargeteddDPCount]
	,T.RefPackageID
HAVING COUNT(T.PackageID) = 0