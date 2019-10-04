/*
Query name:   	DP Messages - DP Uprade Complete Last Three Days.SQL
Created on:    	4/20/2016
Author:        	Kevin Ott
Purpose:       	Returns DP messages for upgrade/install success message ID for
				each DP in the last three days.  Intended for tracking DP update status
				for CU or SP updates, although note that for Pull DPs often this message
				indicates that they have begun the upgrade process, not that they have actually
				completed the process successfully. Framework version is often a better indication
				that the DP has properly upgraded.
*/

;WITH DistributionPointUpgrade AS
(
	SELECT DISTINCT
		InsStr1
		,LastStatusTime
		,MessageID
		,MessageCategory
	FROM DistributionPointMessages
	WHERE (MessageID = 2399 OR MessageID = 2370)
	AND LastStatusTime > (GETDATE() - 5)
), CCMFramework AS
(

SELECT 
	R.Name0 AS Name
	,R.Resource_Domain_OR_Workgr0 AS Domain
	,[DisplayName0]
	,[Version0]
  FROM v_GS_SMS_ADVANCED_CLIENT_STATE AS CS
  LEFT OUTER JOIN V_R_System AS R ON R.ResourceID = CS.ResourceID
  WHERE DisplayName0 = 'CCM Framework'
)


SELECT 
	ServerName
	,UpdateStatus =
		CASE 
			WHEN MAX(MessageID) = 2399 THEN 'Success'
			WHEN MAX(MessageID) = 2370 THEN 'Failed'
			ELSE 'Not Run'
	END
	,LastStatusTime AS StatusMesssageTime
	,CF.Version0 AS CCMFrameWorkVersion
	,VR.Operating_System_Name_and0
FROM DistributionPoints AS DP
LEFT OUTER JOIN DistributionPointUpgrade AS DM ON DP.NALPath = DM.InsStr1
LEFT OUTER JOIN V_R_System AS VR ON DP.ServerName LIKE (VR.Name0 + '.%')
LEFT OUTER JOIN CCMFramework AS CF ON DP.ServerName LIKE (CF.Name + '.%')
GROUP BY
	ServerName
	,LastStatusTime
	,MessageCategory
	,CF.Version0
	,VR.Operating_System_Name_and0
ORDER BY UpdateStatus DESC, CCMFrameWorkVersion DESC