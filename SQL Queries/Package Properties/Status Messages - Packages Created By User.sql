/*
Query name:   	Status Messages - Packages Created By User.SQL
Created on:    	1/22/2016
Author:        	Kevin Ott
Purpose:       	Returns all status message strings for creation of packages
				by user.  Use a LEFT OUTER JOIN if joining to other tables
				since status messages older than a few months will be cleared.
				If you do not want duplicates from packages imported more than once,
				use an aggregate MAX() on the time field or omit it and SELECT DISTINCT.
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
SELECT *
FROM PackageCreator