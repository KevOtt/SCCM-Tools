/*
Query name:   	Packages With MSICode Not Distributed.SQL
Created on:    	12/3/2015
Author:        	Kevin Ott
Purpose:       	Returns a list of packages which have programs with
				imported MSI codes, which are not distributed to all DPs.
				These packages can be very problimatic, if MSIs are performing
				self heals they may cause undue processing as they may have to 
				query for a non-protected DP source location which is an expensive SQL
				query.
*/

SELECT Distinct
	pkgID AS PackageID,
	SUM(Assets) AS AssignedDPs
FROM PkgPrograms AS p
LEFT OUTER JOIN vSMS_DistributionStatus AS d ON p.PkgID = d.PackageID
WHERE MSIProductID <> ''
GROUP BY pkgID
HAVING SUM(Assets) < 1170
Order By PkgID