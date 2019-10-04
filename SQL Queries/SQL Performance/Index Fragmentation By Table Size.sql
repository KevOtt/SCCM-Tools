/*
Query name:   	Index Fragmentation By Table Size.SQL
Created on:    	11/20/2015
Author:        	Kevin Ott
Purpose:       	Query returns various attributes for indexes where average fragmentation is over 30%
				within DB defined in @db_ID as a database ID.  Joins various tables to pull the	size 
				information for the assiciated and usage stats for each index.  Update @db_ID to use
				the proper db name, often this is CM_XXX where xxx is the site code.
*/

DECLARE @db_id SMALLINT = DB_ID(N'CM_XXX')

;WITH Index_Usage_Stats
	(
	[object_id],
	index_id,
	user_scans, 
	user_seeks, 
	user_updates, 
	last_user_scan, 
	last_user_seek  
	)
AS
	(
	SELECT
		[object_id],
		index_id,
		user_scans, 
		user_seeks, 
		user_updates, 
		last_user_scan, 
		last_user_seek
	FROM sys.dm_db_index_usage_stats
	WHERE database_id = @db_id
	)
SELECT
	OBJECT_NAME(i.[object_ID]) AS Table_Name,
	[index_type_desc] AS Index_Type,
	[Index_Level],
	[Avg_Fragmentation_in_Percent],
	[Avg_Fragment_Size_in_Pages],
	[Fragment_Count],
	[page_count] AS Index_Page_Count,
	SUM([Total_Pages]) AS Total_Table_Pages,
	CAST((SUM([Total_Pages]) * 8) AS Nvarchar) + ' KB' AS Total_Table_Size,
	SUM([Used_Pages]) AS Used_Table_Pages,
	SUM([Data_Pages]) AS Data_Table_Pages,
	[user_scans] AS Index_Scans_Since_Instance_Start, 
	[user_seeks] AS Index_Seeks_Since_Instance_Start, 
	[user_updates] AS Data_Updates_Since_Instance_Start, 
	[last_user_scan] AS Last_Index_Scan_Since_Instance_Start, 
	[last_user_seek] AS Last_User_Seek_Since_Instance_Start 
FROM sys.dm_db_index_physical_stats(@db_id, NULL, NULL, NULL , 'LIMITED') AS i
INNER JOIN sys.partitions AS p ON p.[object_id] = i.[object_id]
INNER JOIN sys.allocation_units AS a ON p.[partition_id] = a.container_id
INNER JOIN Index_Usage_Stats AS u ON u.[object_id] = i.[object_id] AND u.[index_id] = i.[index_id]
WHERE [avg_fragmentation_in_percent] >= '30'
GROUP BY
	i.[object_id],
	[index_type_desc],
	[Index_Level],
	[Avg_Fragmentation_in_Percent],
	[Avg_Fragment_Size_in_Pages],
	[Fragment_Count],
	[page_count],
	[user_scans], 
	[user_seeks], 
	[user_updates], 
	[last_user_scan], 
	[last_user_seek]
ORDER BY
	Total_Table_Pages DESC
	;