/*
Query name:   	Packages Not Used Assigned to DP Group.SQL
Created on:    	4/7/2016
Author:        	Kevin Ott
Purpose:       	Returns a list of all packages assigned to a particular DP group which 
				are not deployed or used in any task sequence along with package info.  
				Package creator and creation time may be missing as status messages are truncated based
				on site configuration.  Driver packages, OS images, and Software Update packages are ignored 
				as they may be in use without being in a task sequence or deployed (such as if using auto apply drivers). 
				Specify group name as @DPGroupName.
*/


--DP Group we want to analyze
DECLARE @DPGroupName AS varchar(255) = 'DPGROUPNAME'


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
	PackageID AS Package_With_Dependency
	,LEFT([DependentProgram],8) AS DependencyPackageID
	FROM [dbo].[v_Program]
)

--First query to pull a list of packages that are not used in any TS and are not deployed
SELECT
	P.PkgID
	,PKG.Name
	,(PKG.SourceSize / 1024) AS Source_Size_MB
	,PD.Package_With_Dependency AS Dependent_Of_Pkg
	,COALESCE(C.UserID, 'No Data' ) AS PackageCreator
	,COALESCE(CONVERT(nvarchar(255), C.[Time], 20), 'Old') AS PackageCreationTime
FROM SMSPackages_G AS P
LEFT OUTER JOIN v_DeploymentSummary AS D ON P.PkgID = D.PackageID
LEFT OUTER JOIN v_TaskSequencePackageReferences AS T ON P.PkgID = T.RefPackageID
LEFT OUTER JOIN [v_ContDistStatSummary] AS CS ON P.PkgID = CS.PkgID
LEFT OUTER JOIN PackageDependency AS PD ON P.PkgID = PD.DependencyPackageID
LEFT OUTER JOIN SMSPackages_G AS PKG ON P.PkgID = PKG.PkgID
LEFT OUTER JOIN PackageCreator AS C ON PKG.PkgID = C.PackageID
WHERE P.PackageType NOT IN ('3','4','5','257','258') AND D.PackageID IS NULL AND T.RefPackageID IS NULL


INTERSECT


--Second query to pull all packages assigned to the DP group specified
SELECT
	P.PkgID
	,PKG.Name
	,(PKG.SourceSize / 1024) AS Source_Size_MB
	,PD.Package_With_Dependency AS Dependent_Of_Pkg
	,COALESCE(C.UserID, 'No Data' ) AS PackageCreator
	,COALESCE(CONVERT(nvarchar(255), C.[Time], 20), 'Old') AS PackageCreationTime
FROM [DPGroupPackages] AS P
INNER JOIN [DistributionPointGroup] AS G ON G.ID = P.GroupID
LEFT OUTER JOIN SMSPackages_G AS PKG ON P.PkgID = PKG.PkgID
LEFT OUTER JOIN PackageDependency AS PD ON P.PkgID = PD.DependencyPackageID
LEFT OUTER JOIN PackageCreator AS C ON PKG.PkgID = C.PackageID
WHERE G.Name = @DPGroupName


ORDER BY Source_Size_MB