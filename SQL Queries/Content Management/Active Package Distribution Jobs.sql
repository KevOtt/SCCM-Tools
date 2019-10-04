/*
Query name:   	Active Package Distribution Jobs.SQL
Created on:    	1/29/2015
Author:        	Kevin Ott
Purpose:       	Three queries pull an aggregate of active distribution jobs per DP,
				a full list of all active distribution jobs, and an aggregate of jobs
				per package.
*/

SELECT 
	SUBSTRING([NALPath], 13,24) AS [Distribution Point Name], 
	COUNT([JobID]) AS [Number of Active Jobs]
FROM [vSMS_DistributionJob]
GROUP BY [NALPath];

SELECT
	[JobID],
	SUBSTRING([NALPath], 13,25)NALPath,
	J.PkgID,
	G.Name,
	G.[Priority],
	PackageVersion,
	[State],
	CreationTime,
	StartTime,
	LastUpdateTime,
	SendAction,
	RetryCount,
	G.SourceSize
FROM vSMS_DistributionJob AS J
LEFT OUTER JOIN SMSPackages_G AS G ON J.PkgID = G.PkgID
ORDER BY SendAction;

SELECT
	D.PkgID
	,P.Name
	,COUNT(JobID)
FROM vSMS_DistributionJob AS D
LEFT OUTER JOIN SMSPackages_G AS P ON D.PkgID = P.PkgID
GROUP BY
	D.PkgID,
	Name;