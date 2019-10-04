/*
Query name:   	Collections With No Deployments or Dependencies.SQL
Created on:    	9/26/2016
Author:        	Kevin Ott
Purpose:       	Returns details of collections that do not have any
				deployments assigned and that do not have any other collections
				limited to them.  Useful for identifying unneeded collections.
*/

SELECT
	C.CollectionID
	,C.Name
	,REPLACE(REPLACE(C.Comment,char(10),''),char(13),'') AS [Description]
	,C.MemberCount
FROM v_DeploymentSummary AS D
RIGHT OUTER JOIN v_Collection AS C ON D.CollectionID = C.CollectionID
LEFT OUTER JOIN Collections_G AS CG ON D.CollectionID = CG.LimitToCollectionID
WHERE CG.LimitToCollectionID IS NULL AND C.CollectionID NOT LIKE 'SMS%'
GROUP BY
	C.CollectionID
	,D.SoftwareName
	,CG.LimitToCollectionID
	,C.Name
	,C.Comment
	,C.MemberCount
HAVING
	MAX(D.AssignmentID) IS NULL
ORDER BY C.CollectionID