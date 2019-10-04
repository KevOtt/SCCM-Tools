/*
Query name:   	Application Installs Per Device.SQL
Created on:    	9/14/2016
Author:        	Kevin Ott
Purpose:       	Returns devices that have a product installed & product 
				attributes based a specific product display name in ARP.
				Set the product display name as @ProductName.
*/

Declare @ProductName as Nvarchar(255)
SET @ProductName = 'ProductNameQueryHere'

SELECT
	R.Name0 AS DeviceName
	,A.ProdID0 AS ProductGUID
	,A.DisplayName0 AS DisplayName
	,A.InstallDate0 AS InstallDate
	,A.Publisher0 AS Publisher
	,A.Version0 AS ApplicationVersion
FROM v_Add_Remove_Programs AS A
INNER JOIN v_R_System AS R ON A.ResourceID = R.ResourceID
WHERE DisplayName0 LIKE @ProductName
ORDER BY DeviceName