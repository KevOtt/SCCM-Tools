/*
Query name:   	Packages Not Used by Creator.SQL
Created on:    	2/16/2016
Author:        	Kevin ott
Purpose:       	Returns packages that are not deployed and not used
				in a task sequence, if is used as a dependency, and how 
				many DPs the package is assigned to. Package creator info
				may be truncated for older packages based on site configuration.
				Useful for finding old, unneeded packages and freeing space.
*/


--Nested CTEs for package creation information
;WITH RawStatus AS
(
	SELECT
		M.RecordID,
		S.InsStrIndex,
		S.InsStrValue,
		M.[Time]
	FROM StatusMessages AS M
	INNER JOIN StatusMessageInsStrs AS S ON M.RecordID = S.RecordID
	WHERE M.MessageID = '30000' AND InsStrIndex < 3
),
PackageCreator AS
(
	SELECT
		P.[0] AS UserID,
		P.[1] AS PackageID,
		P.Time
	FROM RawStatus
	PIVOT
	(
		MAX(InsStrValue) FOR InsStrIndex IN ([0],[1])
	) AS P
),
--CTE for package dependencies
PackageDependency AS
(
	SELECT DISTINCT
	LEFT([DependentProgram],8) AS DependencyPackageID
	FROM [dbo].[v_Program]
)


--Main Select Statement
SELECT
	P.PkgID
	,P.Name
	,PT.Name AS PkgType
	,(
		CASE COALESCE(PD.DependencyPackageID, '1')
			WHEN '1' THEN 'No'
			ELSE 'Yes'
		END
	) AS [PkgDependency?]
	,[TargeteddDPCount] AS TargetedDPs
	,COALESCE(C.UserID, 'No Data' ) AS PackageCreator
	,COALESCE(CONVERT(nvarchar(255), C.[Time], 20), 'Old') AS PackageCreationTime
FROM SMSPackages_G AS P
	LEFT OUTER JOIN v_DeploymentSummary AS D ON P.PkgID = D.PackageID
	LEFT OUTER JOIN v_TaskSequencePackageReferences AS T ON P.PkgID = T.RefPackageID
	LEFT OUTER JOIN PackageCreator AS C ON P.PkgID = C.PackageID
	LEFT OUTER JOIN PackageDependency AS PD ON P.PkgID = PD.DependencyPackageID
	LEFT OUTER JOIN [v_ContDistStatSummary] AS CS ON P.PkgID = CS.PkgID
	LEFT OUTER JOIN [SMSPackageTypes] AS PT ON P.PackageType = PT.PackageTypeID
WHERE P.PackageType NOT IN ('4','5','257','258') AND D.PackageID IS NULL AND T.RefPackageID IS NULL
ORDER BY PkgType, P.PkgID ASC