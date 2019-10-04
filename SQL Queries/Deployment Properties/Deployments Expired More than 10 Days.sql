/*
Query name:   	Deployments Expired More than 10 Days.SQL
Created on:    	10/24/2016
Author:        	Kevin Ott
Purpose:       	Returns deployments which have an expiration time set
				that is more than 10 days in the past to identify unneeded deployments.
*/

SELECT
	A.PackageID
	,D.[Description]
	,A.ProgramName
	,A2.CollectionName
	,A.PresentTime AS DeploymentStartTime
	,A.ExpirationTime
FROM v_Advertisement AS A
LEFT OUTER JOIN v_AdvertisementInfo AS A2 ON A.AdvertisementID = A2.AdvertisementID
LEFT OUTER JOIN DeploymentSummary AS D ON A.AdvertisementID = D.OfferID
WHERE ExpirationTimeEnabled <> 0 AND A.ExpirationTime < (GETUTCDATE() - 10)
ORDER BY ExpirationTime
