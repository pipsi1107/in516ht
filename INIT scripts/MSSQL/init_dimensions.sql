
EXEC dbo.InitializeDimension 'dbo', 'D_CUSTOMER';
EXEC dbo.InitializeDimension 'dbo', 'D_EMPLOYEE';
EXEC dbo.InitializeDimension 'dbo', 'D_INIT_QUANTITY';
EXEC dbo.InitializeDimension 'dbo', 'D_ITEM';
EXEC dbo.InitializeDimension 'dbo', 'D_PROJECT';
EXEC dbo.InitializeDimension 'dbo', 'D_PUBLIC_CONTRACT';
EXEC dbo.InitializeDimension 'dbo', 'D_PUBLIC_CONTRACT_DETAIL';
EXEC dbo.InitializeDimension 'dbo', 'D_PURCH_CASE_HEAD';
EXEC dbo.InitializeDimension 'dbo', 'D_PURCH_CASE_LINE';
EXEC dbo.InitializeDimension 'dbo', 'D_PURCH_CONTRACT_HEAD';
EXEC dbo.InitializeDimension 'dbo', 'D_PURCH_CONTRACT_LINE';
EXEC dbo.InitializeDimension 'dbo', 'D_PURCH_ORDER_HEAD';
EXEC dbo.InitializeDimension 'dbo', 'D_PURCH_ORDER_LINE';
EXEC dbo.InitializeDimension 'dbo', 'D_PURCH_REQUEST_HEAD';
EXEC dbo.InitializeDimension 'dbo', 'D_PURCH_REQUEST_LINE';
EXEC dbo.InitializeDimension 'dbo', 'D_RESPONSE_HEAD';
EXEC dbo.InitializeDimension 'dbo', 'D_RESPONSE_LINE';
EXEC dbo.InitializeDimension 'dbo', 'D_SUPPLIER';
EXEC dbo.InitializeDimension 'dbo', 'D_WAREHOUSE';




DROP PROCEDURE dbo.InitializeDimension;
-- ################################################################################ --
-- #####                 Procedure: dbo.InitializeDimension                 ##### --
-- ################################################################################ --
CREATE PROCEDURE dbo.InitializeDimension
    @Schema nvarchar(128)
    ,@TableName nvarchar(128)
    ,@Identity bit = 0
AS
    DECLARE
        @ColumnName nvarchar(128),
        @DataType nvarchar(128),
        @OrdinalPosition int,
        @StringInsertInto nvarchar(max),
        @StringInsertValue nvarchar(max),
        @ColumnValue nvarchar(128),
        @ExecString nvarchar(max)
    DECLARE TableCursor CURSOR FOR
        SELECT
            COLUMN_NAME,
            DATA_TYPE,
            ORDINAL_POSITION
        FROM
            INFORMATION_SCHEMA.COLUMNS
        WHERE
            TABLE_SCHEMA = @Schema
            AND TABLE_NAME = @TableName
        ORDER BY
            ORDINAL_POSITION
    OPEN TableCursor
    FETCH NEXT FROM TableCursor INTO @ColumnName, @DataType, @OrdinalPosition
    SET @StringInsertInto = N'INSERT INTO ' + @Schema + N'.' + @TableName + N' ('
    SET @StringInsertValue = N'VALUES ('
    SET @ExecString = N''
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @StringInsertInto = @StringInsertInto + QUOTENAME(@ColumnName) + N','
        SET @ColumnValue =
            CASE @DataType
                WHEN 'bit' THEN '-1'
                WHEN 'tinyint' THEN '-1'
                WHEN 'smallint' THEN '-1'
                WHEN 'int' THEN '-1'
                WHEN 'bigint' THEN '-1'
                WHEN 'numeric' THEN '-1'
                WHEN 'decimal' THEN '-1'
                WHEN 'smallmoney' THEN '-1'
                WHEN 'money' THEN '-1'
                WHEN 'float' THEN '-1'
                WHEN 'real' THEN '-1'
            --
                WHEN 'datetime' THEN '19000101'
                WHEN 'smalldatetime' THEN '19000101'
                WHEN 'date' THEN '19000101'
                WHEN 'time' THEN '00:00'
                WHEN 'datetimeoffset' THEN '19000101'
                WHEN 'datetime2' THEN '19000101'
            --
                WHEN 'char' THEN 'N/A'
                WHEN 'varchar' THEN 'N/A'
                WHEN 'text' THEN 'N/A'
                WHEN 'nchar' THEN 'N/A'
                WHEN 'nvarchar' THEN 'N/A'
                WHEN 'ntext' THEN 'N/A'
            END
        IF @OrdinalPosition = 1
            SET @StringInsertValue = @StringInsertValue + N'-1,'
        ELSE
            BEGIN
                IF @DataType IN ('bit', 'tinyint', 'smallint', 'int', 'bigint', 'numeric', 'decimal', 'smallmoney', 'money', 'float', 'real')
                     SET @StringInsertValue = @StringInsertValue + N' ' + @ColumnValue + N','
                ELSE
                     SET @StringInsertValue = @StringInsertValue + N' ''' + @ColumnValue + N''','
            END
        FETCH NEXT FROM TableCursor INTO @ColumnName, @DataType, @OrdinalPosition
    END
    CLOSE TableCursor
    DEALLOCATE TableCursor
    SET @StringInsertInto = SUBSTRING(@StringInsertInto, 1, LEN(@StringInsertInto) - 1) + ')'
    SET @StringInsertValue = SUBSTRING(@StringInsertValue, 1, LEN(@StringInsertValue) - 1) + ')'
    IF @Identity = 1
        SET @ExecString = N'SET IDENTITY_INSERT ' + @Schema + N'.' + @TableName + N' ON '
    SET @ExecString = @ExecString + @StringInsertInto + N' '
    SET @ExecString = @ExecString + @StringInsertValue + N';'
    IF @Identity = 1
        SET @ExecString = @ExecString + N'SET IDENTITY_INSERT ' + @Schema + N'.' + @TableName + N' OFF'
    EXEC sp_executesql @stmt = @ExecString
--PRINT @ExecString
;
