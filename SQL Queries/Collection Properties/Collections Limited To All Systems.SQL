/*
Query name:   	Collections Limited To All Systems.SQL
Created on:    	9/26/2016
Author:        	Kevin Ott
Purpose:       	Returns details of collections that have their limiting
				collection set to "All Systmes". Might be useful if utilizing
				RBAC permissions tied to collections to identify non-compliance.
*/


SELECT
	SiteID
	,CollectionName
	,LimitToCollectionName
	,MemberCount
FROM vCollections
WHERE LimitToCollectionID = 'SMS00001'