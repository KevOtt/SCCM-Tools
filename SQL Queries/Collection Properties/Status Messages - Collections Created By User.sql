/*
Query name:   	Status Messages - Collections Created By User.SQL
Created on:    	1/21/2016
Author:        	Kevin Ott
Purpose:       	Returns status message strings for creation of collections
				by user. Use a LEFT OUTER JOIN if joining to other tables
				since status messages older than a few months may be truncated
				based on site configuration.
*/


;WITH RawStatus AS
(
	SELECT
		M.RecordID,
		S.InsStrIndex,
		S.InsStrValue
	FROM StatusMessages AS M
	INNER JOIN StatusMessageInsStrs AS S ON M.RecordID = S.RecordID
	WHERE M.MessageID = '30015' AND InsStrIndex < 3
),
CollectionCreator AS
(
	SELECT
		P.[0] AS UserID,
		P.[1] AS CollectionID
	FROM RawStatus
	PIVOT
	(
		MAX(InsStrValue) FOR InsStrIndex IN ([0],[1])
	) AS P
)
SELECT *
FROM CollectionCreator