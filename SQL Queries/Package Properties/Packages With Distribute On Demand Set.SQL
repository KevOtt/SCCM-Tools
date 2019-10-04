/*
Query name:   	Packages With Distribute On Demand Set.SQL
Created on:    	1/22/2016
Author:        	Kevin Ott
Purpose:       	Returns a list of packages which have the attribute "Distribute On Demand"
				set on as well as status messages for creator of the package. Creator
				information may not exist depending on how status messages are
				truncated based on site configuration.
*/


--MessageID column is indexed, nesting CTEs here so Pivot works efficiently
WITH RawStatus AS
(
	SELECT
		M.RecordID,
		S.InsStrIndex,
		S.InsStrValue
	FROM StatusMessages AS M
	INNER JOIN StatusMessageInsStrs AS S ON M.RecordID = S.RecordID
	WHERE M.MessageID = '30000' AND InsStrIndex < 3
),
PackageCreator AS
(
	SELECT
		P.[0] AS UserID,
		P.[1] AS PackageID
	FROM RawStatus
	PIVOT
	(
		MAX(InsStrValue) FOR InsStrIndex IN ([0],[1])
	) AS P
)



SELECT 
	V.PkgID,
	V.Name,
	COALESCE(P.UserID, 'No Data') AS PackageCreator
FROM v_SmsPackage AS V
LEFT OUTER JOIN PackageCreator AS P ON V.PkgID = P.PackageID
--Bitwise AND to evaluate pkgflag value for 0x40000000
WHERE ('1073741824' & V.PkgFlags) = '1073741824'