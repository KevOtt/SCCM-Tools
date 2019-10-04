/*
Query name:   	Collections With Only Direct Members With Updates Enabled.SQL
Created on:    	9/26/2016
Author:        	Kevin Ott
Purpose:       	Returns details of collections with only direct members and updates 
				enabled. These are collections that are potentially wasting collection
				evaluator tim and possibly should have updates turned off. Also attempts to
				return the details of the collection creator from status messages, if the status
				messages have not been already truncated, which occurs based on site configuration.
				
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


--MessageID column is indexed, nesting CTEs here so Pivot works efficiently
SELECT 
	G.SiteID AS [Collection ID],
	G.CollectionName,
	G.Flags,
	CASE (G.Flags)
		WHEN 6 THEN 'Full & Incremental'
		WHEN 4 THEN 'Incremental'
		WHEN 2 THEN 'Full'
		END
	AS [Refresh Type],
	COALESCE(C.UserID,'No Data') AS Creator
FROM Collections_G AS G
INNER JOIN [Collection_Rules] AS R ON G.CollectionID = R.CollectionID
LEFT OUTER JOIN CollectionCreator AS C ON G.SiteID = C.CollectionID
WHERE G.Flags = 6 OR G.Flags = 4 OR G.Flags = 2
GROUP BY
	G.SiteID,
	G.CollectionName,
	G.Flags,
	C.UserID
HAVING
	(Max(R.RuleType) = 1)