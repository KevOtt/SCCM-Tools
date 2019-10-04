/*
Query name:   	Installed Features for Specific Server.SQL
Created on:    	3/15/2016
Author:        	Kevin Ott
Purpose:       	Returns a list of installed windows features for a specific server.  
				Specify the name of the server as @ServerName.
*/

Declare @ServerName AS nvarchar(255)
SET @ServerName = 'ServerName'

SELECT
	R.Name0
	,Name00
FROM [dbo].[SERVER_FEATURE_DATA] AS F
LEFT OUTER JOIN v_R_System AS R ON F.MachineID = R.ResourceID
WHERE Name0 = @ServerName