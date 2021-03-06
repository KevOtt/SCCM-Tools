/*
Query name:   	Computers Manually Imported and Uncliented.SQL
Created on:    	3/17/2016
Author:        	Kevin Ott
Purpose:       	Returns a list of all systems which were imported manually 
                  but which do not have clients. Useful for identifying systems
                  that may have been imported improperly, or systems that were not
                  properly imaged.
*/


SELECT
      A.[ResourceId]
      ,A.[AgentName]
      ,A.[AgentSite]
      ,A.[AgentTime]
	  ,S.Name0
	  ,S.Client0
	  ,M.MAC_Addresses0
  FROM v_AgentDiscoveries AS A
  LEFT OUTER JOIN System_DISC AS S ON A.ResourceId = S.ItemKey
  LEFT OUTER JOIN v_RA_System_MACAddresses AS M ON A.ResourceId = M.ResourceID
  WHERE AgentName = 'Manual Machine Entry' AND S.Client0 = '0'