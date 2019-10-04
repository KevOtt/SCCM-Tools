/*
Query name:   	Page Life Expectancy.SQL
Created on:    	10/31/2016
Author:        	Kevin Ott
Purpose:       	Returns page life expectancy counter from SQL.
*/

SELECT
	@@SERVERNAME AS 'Instance'
	,[counter_name]
	,[cntr_value] AS 'PLE_SECS'
	,[cntr_value] / 60 AS 'PLE_MINS'
	,[cntr_value] / 3600 AS 'PLE_HOURS'
	,[cntr_value] / 86400 AS 'PLE_DAYS'
FROM sys.dm_os_performance_counters
WHERE [Object_Name] = 'SQLServer:Buffer Manager' AND counter_name = 'Page life expectancy'