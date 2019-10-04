/*
Query name:   	Packages Not Assigned to All DPs in DP Group.SQL
Created on:    	1/29/2015
Author:        	Kevin Ott
Purpose:       	Returns a list of packages which are assigned to a specific DP Group, 
				but are not assigned to all DPs in a specific DP group.  Useful for 
				finding	packages that were removed from a DP after it was assigned
				to a particular DP group. Specify group name as @DPGroup
*/

DECLARE @DPGroup AS varchar(255)
SET @DPGroup = 'DOGROUPNAME';

WITH SourceDPs (DPs)
AS
(
	SELECT
		M.DPNALPath
	FROM [DistributionPointGroup_L] AS L
	INNER JOIN [DistributionPointGroup] AS G ON L.UniqueID = G.ID
	INNER JOIN [DPGroupMembers] AS M ON L.UniqueID = M.GroupID
	WHERE G.Name = @DPGroup
)


SELECT
	P.PkgID
	,COUNT(NALPath) AS Assigned_Number_of_DPs
	,(SELECT COUNT(DPs) FROM SourceDPs) AS Number_of_DPs_in_DPGroup
FROM [PkgServers_G] AS P
INNER JOIN [DPGroupPackages] AS DP ON P.PkgID = DP.PkgID
INNER JOIN [DistributionPointGroup] AS DG ON DG.ID = DP.GroupID
WHERE DG.Name = @DPGroup AND P.NALPath IN (SELECT * FROM SourceDPs)
GROUP BY P.PkgID
HAVING COUNT(NALPath) < (SELECT COUNT(DPs) FROM SourceDPs)