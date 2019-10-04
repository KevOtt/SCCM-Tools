/*
Query name:   	Task Sequence Reference Package Distribution.SQL
Created on:    	3/14/2016
Author:        	Kevin Ott
Purpose:       	Returns a list of all packages for a specific task sequence
				and their distribution status. Specify package ID as @PackageID.
				Useful for troubleshooting failing task sequences.
*/

Declare @PackageID AS nchar(8)
SET @PackageID = 'EX100001'

SELECT 
	RefPackageID
	,P.Name
	,D.NumberErrors
	,D.NumberInProgress
	,D.NumberInstalled
	,D.NumberTotal
	,D.NumberUnknown
FROM v_TaskSequencePackageReferences AS T
LEFT OUTER JOIN SMSPackages_G AS P ON T.RefPackageID = P.PkgID
LEFT OUTER JOIN ContentDistributionByPkg AS D ON T.RefPackageID = D.PkgID
WHERE PackageID = @PackageID
