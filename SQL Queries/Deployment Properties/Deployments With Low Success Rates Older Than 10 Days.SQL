/*
Query name:   	Deployments With Low Success Rates Older Than 10 Days.SQL
Created on:    	10/24/2016
Author:        	Kevin Ott
Purpose:       	Returns deployments with a success rate lower than 85% which are active and older than 10 days.
				Additionally, success rate is based only on those clients which have actively run the deployment
				filtering out unknown clients and clients which only have the deployment as available. Identifies
				packages that are likely to have reliability issues.
*/


SELECT
	P.PkgID
	,P.Name
	,CASE
		WHEN (NumberSuccess <> 0) THEN ROUND(((CAST(NumberSuccess AS float) / CAST(
			(
			/*Adding these together here to account for available deployments which will
			always show the total targeted in a collection as the NumberTotal*/
			NumberSuccess + NumberErrors + NumberInProgress + NumberOther
			) 
		AS float)) * 100),2,2)
		ELSE 0
	END AS PercentSuccessful
	,D.CollectionName 
	,D.CollectionID
	,D.DeploymentTime AS DeploymentStartTime
	,D.NumberSuccess
	,D.NumberErrors
	,D.NumberInProgress
	,D.NumberUnknown
	,D.NumberOther
	,(NumberSuccess + NumberErrors + NumberInProgress + NumberOther) AS NumberAttempted
	,D.NumberTotal AS DevicesInCollection
	,P.PackageType
FROM vDeploymentSummary AS D
LEFT OUTER JOIN v_SmsPackage AS P ON P.PkgID = D.PackageID
LEFT OUTER JOIN v_Advertisement AS A ON A.AdvertisementID = D.OfferID
WHERE
P.PackageType <> 5
AND 
	(CASE
		WHEN (NumberSuccess <> 0) THEN ROUND(((CAST(NumberSuccess AS float) / CAST(
			(
			/*Adding these together here to account for available deployments which will
			always show the total targeted in a collection as the NumberTotal*/
			NumberSuccess + NumberErrors + NumberInProgress + NumberOther
			) 
		AS float)) * 100),2,2)
		ELSE 0
	END) < 85
AND DeploymentTime < (GETUTCDATE() - 10)
/*Again adding these to get a proper total*/
AND (NumberSuccess + NumberErrors + NumberInProgress + NumberOther) > 25
AND A.ExpirationTimeEnabled = 0
ORDER BY PercentSuccessful