/*
Query name:   	Packages Using Legacy Share.SQL
Created on:    	9/21/2016
Author:        	Kevin Ott
Purpose:       	Returns all packages with the option set to use the legacy
				package share instead of the content library. Useful
				when trying to convert items to use the content library.
*/


SELECT
	P.PkgID
	,PT.Name AS PackageType
	,P.Name
	,P.[Version]
	,P.SourceSize
FROM SMSPackages AS P
LEFT OUTER JOIN SMSPackageTypes AS PT ON P.PackageType = PT.PackageTypeID
WHERE (PkgFlags & 128) = 128