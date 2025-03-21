/*
Description:
This script is designed to cleanup records from specified tables in a database. It uses a cursor to loop through the table names ordered by size (Data + Index) and calls a stored procedure to archive records based on the provided parameters.

Parameters:
- @SkipTables: List of tables to be SKip(comma separated)
- @MaxArchivingDate: Maximum archiving date
- @Simulation: Set to 1 for simulation mode, 0 for actual deletion
- @LE: List of legal entities

The script performs the following steps:
1. Prints the legal entities and date range.
2. Inserts table names, row counts, and total space into a temporary table.
3. Loops through the table names using a cursor and calls the stored procedure to cleanup records.
4. Drops the stored procedure at the end.
*/

DECLARE @SkipTables NVARCHAR(MAX) = 'INVENTREPORTDIMHISTORY' -- Replace with your list of tables (comma separated)
DECLARE @MaxArchivingDate DATE = '2024-01-01' -- Replace with your max archiving date
DECLARE @Simulation BIT = 1 -- Set to 1 for simulation mode, 0 for actual deletion
DECLARE @LE NVARCHAR(Max) = '445I,BRMF,CNMF,DAT,DEMF,FRRT,FRSI,GBPM,GBSI,GLCO,GLMF,GLRT,GLSI,INMF,ITCO,JPMF,MXMF,MYMF,RUMF,RURT,SAMF,THMF,THPM,us01,USMF,USP2,USPI,USPM,USRT,USSI'

DECLARE @TableName NVARCHAR(255)
DECLARE @TotalSpace BigINt
DECLARE @StartDate DATE
DECLARE @EndDate DATE

BEGIN
    PRINT 'LE :' + @LE + ' StartDate :' + CONVERT(NVARCHAR, @StartDate, 120) + ' EndDate :' + CONVERT(NVARCHAR, @EndDate, 120)
    
    -- Cursor to loop through the table names ordered by size (Data + Index)
    DECLARE @TableList TABLE (TableName NVARCHAR(255), RowCounts bigint, TotalSpace Bigint ) 
    INSERT INTO @TableList (TableName, RowCounts, TotalSpace)
        SELECT 
            t.name AS TableName,
            SUM(p.rows) AS RowCounts,
            SUM(a.total_pages) * 8 AS TotalSpaceKB
        FROM 
            sys.tables t
        INNER JOIN      
            sys.indexes i ON t.object_id = i.object_id
        INNER JOIN 
            sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
        INNER JOIN 
            sys.allocation_units a ON p.partition_id = a.container_id
        WHERE 
            t.name IN (
                SELECT distinct SQLNAME
                FROM SQLDICTIONARY a
                JOIN TABLEMETADATATABLE b ON a.TABLEID = b.TABLEID
                -- Transaction (4), WorksheetHeader (5), WorksheetLine (6), Worksheet (9), TransactionHeader (10), TransactionLine (11), Staging (12)
                WHERE (a.fieldid = 0 AND a.array = 0 AND b.TABLEGROUP IN (4, 5, 6, 9, 10, 11)
                -- Tables WHSASNITEM, WHSASNITEMRECEIPT, WHSUOMSTRUCTURE  / you can add your customtables to this list
                or a.NAME in ('WHSASNITEM', 'WHSASNITEMRECEIPT', 'WHSUOMSTRUCTURE') )
				and a.Name not in (@SkipTables)
            )
        GROUP BY 
            t.name

    DECLARE TableCursor CURSOR FOR
    SELECT TableName, TotalSpace FROM @TableList
    ORDER BY TotalSpace DESC

    OPEN TableCursor
    FETCH NEXT FROM TableCursor INTO @TableName, @TotalSpace
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Call stored procedure to archive records for the current table
		EXEC KeepOnlyRecordsSp @TableName, @LE, @MaxArchivingDate, @Simulation
		FETCH NEXT FROM TableCursor INTO @TableName, @TotalSpace
        
    END
    
    CLOSE TableCursor
    DEALLOCATE TableCursor

END

-- Drop the stored procedure at the end
DROP PROCEDURE dbo.KeepOnlyRecordsSp;
