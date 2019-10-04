/*
Query name:   	All OS Images.SQL
Created on:    	2/19/2016
Author:        	Kevin Ott
Purpose:       	Returns all image packages, targeted, DPs, and creator.
				Creator and creation time data may not exist depending on
				status message truncation config settings for the site.
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
	,COALESCE(CONVERT(nvarchar(255), C.[Time], 20), 'No Data') AS PackageCreationTime
FROM SMSPackages_G AS P
LEFT OUTER JOIN PackageCreator AS C ON PkgID = C.PackageID
LEFT OUTER JOIN [v_ContDistStatSummary] AS CS ON P.PkgID = CS.PkgID
