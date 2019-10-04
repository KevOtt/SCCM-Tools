/*
Query name:   	Items With Multiple Deployments Older than 15 Days.SQL
Created on:    	10/24/2016
Author:        	Kevin Ott
Purpose:       	Returns packages & task sequences with more than one deployment older than 15 days.
				This query will excludes software update packages, and will count deployments per 
				program where applicable.
*/

SELECT
	P.PkgID
	,P.Name
	,A.ProgramName
	,COUNT(A.ProgramName) AS NumberOfDeployments
	,T.Name AS PackageType
FROM v_AdvertisementInfo AS A
LEFT OUTER JOIN v_Advertisement AS A2 ON A.AdvertisementID = A2.AdvertisementID
LEFT OUTER JOIN SMSPackages AS P ON A.PackageID = P.PkgID
INNER JOIN SMSPackageTypes AS T ON P.PackageType = T.PackageTypeID
WHERE 
	A.PresentTime < (GETUTCDATE() - 15)
	AND A2.ExpirationTimeEnabled = 0
	AND P.PackageType <> 5
GROUP BY
	A.ProgramName
	,P.PkgID
	,P.Name
	,P.PackageType
	,T.Name
HAVING COUNT(A.ProgramName) > 1
ORDER BY NumberOfDeployments DESC

