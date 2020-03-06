DECLARE @StartDate DATE = '19000101', @NumberOfYears INT = 400;

-- prevent set or regional settings from interfering with 
-- interpretation of dates / literals

SET DATEFIRST 1;
SET DATEFORMAT mdy;
SET LANGUAGE US_ENGLISH;

DECLARE @CutoffDate DATE = DATEADD(YEAR, @NumberOfYears, @StartDate);

DROP TABLE IF EXISTS [dbo].#dim
CREATE TABLE [dbo].#dim
(
  [date]       DATE PRIMARY KEY, 
  [day]        AS DATEPART(DAY,      [date]),
  [month]      AS DATEPART(MONTH,    [date]),
  [week]       AS DATEPART(WEEK,     [date]),
  [ISOweek]    AS DATEPART(ISO_WEEK, [date]),
  [DayOfWeek]  AS DATEPART(WEEKDAY,  [date]),
  [quarter]    AS DATEPART(QUARTER,  [date]),
  [year]       AS DATEPART(YEAR,     [date]),
);

-- use the catalog views to generate as many rows as we need

INSERT [dbo].#dim([date]) 
SELECT d
FROM
(
  SELECT d = DATEADD(DAY, rn - 1, @StartDate)
  FROM 
  (
    SELECT TOP (DATEDIFF(DAY, @StartDate, @CutoffDate)) 
      rn = ROW_NUMBER() OVER (ORDER BY s1.[object_id])
    FROM sys.all_objects AS s1
    CROSS JOIN sys.all_objects AS s2
    ORDER BY s1.[object_id]
  ) AS x
) AS y;

-- create all interesting attributes

DROP TABLE IF EXISTS [dbo].[D_DATE];
CREATE TABLE dbo.D_DATE (
   DATE_SID int  NOT NULL,
   EXT_REFR nvarchar(30) NOT NULL,
   DATE date NOT NULL,
   IS_WEEKEND bit  NOT NULL,
   DAY_OF_WEEK int  NOT NULL,
   DAY_OF_MONTH int  NOT NULL,
   DAY_OF_YEAR int  NOT NULL,
   WEEK int  NOT NULL,
   WEEK_ID int  NOT NULL,
   WEEK_DESC nvarchar(30)  NOT NULL,
   MONTH int  NOT NULL,
   MONTH_ID int  NOT NULL,
   MONTH_DESC nvarchar(30)  NOT NULL,
   MONTH_SPEC nvarchar(30)  NOT NULL,
   QUARTER int  NOT NULL,
   QUARTER_ID int  NOT NULL,
   QUARTER_DESC nvarchar(30)  NOT NULL,
   SEASON nvarchar(30)  NOT NULL,
   YEAR int  NOT NULL,
   PERIO nvarchar(7) NOT NULL,
   FIRST_DAY_OF_WEEK date  NOT NULL,
   LAST_DAY_OF_WEEK date  NOT NULL,
   FIRST_DAY_OF_MONTH date  NOT NULL,
   LAST_DAY_OF_MONTH date  NOT NULL,
   FIRST_DAY_OF_QUARTER date  NOT NULL,
   LAST_DAY_OF_QUARTER date  NOT NULL,
   FIRST_DAY_OF_YEAR date  NOT NULL,
   LAST_DAY_OF_YEAR date  NOT NULL,
   IS_FIRST_DAY_OF_WEEK bit  NOT NULL,
   IS_LAST_DAY_OF_WEEK bit  NOT NULL,
   IS_FIRST_DAY_OF_MONTH bit  NOT NULL,
   IS_LAST_DAY_OF_MONTH bit  NOT NULL,
   IS_FIRST_DAY_OF_QUARTER bit  NOT NULL,
   IS_LAST_DAY_OF_QUARTER bit  NOT NULL,
   IS_FIRST_DAY_OF_YEAR bit  NOT NULL,
   IS_LAST_DAY_OF_YEAR bit  NOT NULL,
   PY_DATE_ID int  NOT NULL,
   PY_DATE date  NOT NULL,
   PY_MONTH_ID int  NOT NULL,
   PY_MONTH_DESC nvarchar(30)  NOT NULL,
   PY_MONTH_SPEC nvarchar(30)  NOT NULL,
   PD_DATE_ID int  NOT NULL,
   PW_WEEK_ID int  NOT NULL,
   PM_MONTH_ID int  NOT NULL,
   PQ_QUARTER_ID int  NOT NULL,
   PY_YEAR int  NOT NULL,
   NY_DATE_ID int  NOT NULL,
   NY_DATE date  NOT NULL,
   NY_MONTH_ID int  NOT NULL,
   NY_MONTH_DESC nvarchar(30)  NOT NULL,
   NY_MONTH_SPEC nvarchar(30)  NOT NULL,
   ND_DATE_ID int  NOT NULL,
   NW_WEEK_ID int  NOT NULL,
   NM_MONTH_ID int  NOT NULL,
   NQ_QUARTER_ID int  NOT NULL,
   NY_YEAR int  NOT NULL,
   VLD_FM_DT date  NULL,
   VLD_TO_DT date  NULL,
   CONSTRAINT D_DATE_pk PRIMARY KEY  (DATE_SID)
)


INSERT dbo.D_DATE
SELECT  year * 10000 + month * 100 + day as date_sid
        , CAST(DATE AS VARCHAR) as EXT_REFR
        , DATE AS DATE
        , case when DayOfWeek > 5 then 1 else 0 end as IS_WEEKEND
        , DayOfWeek as DAY_OF_WEEK
        , day as DAY_OF_MONTH
        , cast(DATEPART(dy, date) as int) as DAY_OF_YEAR
        
        , ISOweek as WEEK
        , year * 100 + ISOweek AS week_id 
        , case when ISOweek < 10 then CONCAT('W.0',ISOweek,'/',DATEPART(yy, date)) else CONCAT('W.',ISOweek,'/',DATEPART(yy, date)) end as week_desc
        , month as MONTH
        , year * 100 + month as MONTH_ID
        , FORMAT(date,'MMM.yyyy') as MONTH_DESC
        , FORMAT(date,'yyyy-MM') as MONTH_SPEC
        , quarter as QUARTER
        , year * 100 + quarter as QUARTER_ID
        , CONCAT('Q', quarter, '.', FORMAT(date,'yyyy')) as quarter_desc
        , CASE WHEN month BETWEEN 4 AND 9 THEN 'Summer' ELSE 'Winter' END AS SEASON 
        , year as year 
             , CONCAT(FORMAT(date,'yyyy'), '0',FORMAT(date,'MM')) as PERIO
        
        , DATEADD(DAY, 1-DATEPART(dw, date), date) as first_day_of_week
        , DATEADD(DAY, 7-DATEPART(dw, date), date) as last_day_of_week

        , DATEADD(DAY,1,EOMONTH(date,-1)) as first_day_of_month    
        , DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,date)+1,0)) as last_day_of_month
        , DATEADD(qq, DATEDIFF(qq, 0, date), 0) as first_day_of_quarter
        , DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, date) +1, 0)) as last_day_of_quarter
        , DATEADD(yy, DATEDIFF(yy, 0, date), 0) as first_day_of_year
        , DATEADD (dd, -1, DATEADD(yy, DATEDIFF(yy, 0, date) +1, 0)) as last_day_of_year
        
        , CASE WHEN DayOfWeek = 1 THEN 1 ELSE 0 END AS IS_FIRST_DAY_OF_WEEK
        , CASE WHEN DayOfWeek = 7 THEN 1 ELSE 0 END AS IS_LAST_DAY_OF_WEEK
        , CASE WHEN DATE = DATEADD(DAY,1,EOMONTH(date,-1)) THEN 1 ELSE 0 END AS IS_FIRST_DAY_OF_MONTH
        , CASE WHEN DATE = DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,date)+1,0)) THEN 1 ELSE 0 END AS IS_LAST_DAY_OF_MONTH
        , CASE WHEN DATE = DATEADD(qq, DATEDIFF(qq, 0, date), 0) THEN 1 ELSE 0 END AS is_first_day_of_quarter
        , CASE WHEN DATE = DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, date) +1, 0)) THEN 1 ELSE 0 END AS is_last_day_of_quarter
        , CASE WHEN DATE = DATEADD(yy, DATEDIFF(yy, 0, date), 0) THEN 1 ELSE 0 END AS IS_FIRST_DAY_OF_YEAR
        , CASE WHEN DATE = DATEADD (dd, -1, DATEADD(yy, DATEDIFF(yy, 0, date) +1, 0)) THEN 1 ELSE 0 END AS IS_LAST_DAY_OF_YEAR
            
        , YEAR(DATEADD(year, -1, DATE))*10000 + MONTH(DATEADD(year, -1, DATE))*100 + DAY(DATEADD(year, -1, DATE)) AS PY_DATE_ID
        , DATEADD(YEAR, -1, DATE) AS PY_DATE
        , YEAR(DATEADD(YEAR, -1, DATE) )*100 + MONTH(DATEADD(YEAR, -1, DATE) ) AS PY_MONTH_ID
        , FORMAT(DATEADD(YEAR, -1, DATE) ,'MMM.yyyy') as PY_MONTH_DESC
        , FORMAT(DATEADD(YEAR, -1, DATE) ,'yyyy-MM') as PY_month_spec
        
        , DATEPART(yy, date) * 10000 + DATEPART(mm, date) * 100 + DATEPART(d, date)-1 as pd_date_id
        , YEAR(DATEADD(day, 26 - DATEPART(isoww, (DATEADD(WEEK, -1, DATE))), (DATEADD(WEEK, -1, DATE)))) * 100 + DATEPART(isowk, (DATEADD(WEEK, -1, DATE))) AS pw_week_id
        , YEAR(DATEADD(MONTH, -1, DATE)) * 100 + MONTH(DATEADD(MONTH, -1, DATE)) AS pm_month_id
        , YEAR(DATEADD(QUARTER, -1, DATE)) * 100 + DATEPART(qq, (DATEADD(QUARTER, -1, DATE))) AS pq_quarter_id
        , DATEPART(yy, date)-1 AS py_year 
        
        , YEAR(DATEADD(year, 1, DATE))*10000 + MONTH(DATEADD(year, 1, DATE))*100 + DAY(DATEADD(year, 1, DATE)) AS NY_DATE_ID
        , DATEADD(YEAR, 1, DATE) AS ny_date
        , YEAR(DATEADD(YEAR, 1, DATE))*100 + MONTH(DATEADD(YEAR, 1, DATE)) AS ny_month_id
        , FORMAT(DATEADD(YEAR, 1, DATE),'MMM.yyyy') as nY_MONTH_DESC
        , FORMAT(DATEADD(YEAR, 1, DATE),'yyyy-MM') as nY_month_spec
        
        , DATEPART(yy, date) * 10000 + DATEPART(mm, date) * 100 + DATEPART(d, date)+1 as nd_date_id
        , YEAR(DATEADD(day, 26 - DATEPART(isoww, (DATEADD(WEEK, 1, DATE))), (DATEADD(WEEK, 1, DATE)))) * 100 + DATEPART(isowk, (DATEADD(WEEK, 1, DATE))) AS nw_week_id
        , YEAR(DATEADD(MONTH, 1, DATE)) * 100 + MONTH(DATEADD(MONTH, 1, DATE)) AS nm_month_id
        , YEAR(DATEADD(QUARTER, 1, DATE)) * 100 + DATEPART(qq,(DATEADD(QUARTER, 1, DATE))) AS nq_quarter_id
        , DATEPART(yy, date)+1 AS ny_year 
    
        , cast('1900-01-01' as datetime) as vld_fm_dt
        , cast('9999-12-31' as datetime) as vld_to_dt
FROM #dim


DROP TABLE IF EXISTS [dbo].#dim
