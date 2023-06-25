CREATE DATABASE BrainsterDW2

USE BrainsterDW2
GO

-- Creating schemas

CREATE SCHEMA integration
GO

CREATE SCHEMA dimension
GO

CREATE SCHEMA fact
GO


-- Creating the dimension tables

CREATE TABLE dimension.Currency(
	[CurrencyKey] [int] IDENTITY(1,1) NOT NULL,
	[CurrencyID] [int] NOT NULL,
	[Code] [nvarchar](5) NULL,
	[Name] [nvarchar](100) NULL,
	[ShortName] [nvarchar](20) NULL,
	[CountryName] [nvarchar](100) NULL,
	CONSTRAINT PK_Currency PRIMARY KEY CLUSTERED ([CurrencyKey] ASC)
)
GO

CREATE TABLE dimension.Employee(
	[EmployeeKey] [int] IDENTITY(1,1) NOT NULL,
	[EmployeeID] [int] NOT NULL,
	[FirstName] [nvarchar](100) NOT NULL,
	[LastName] [nvarchar](100) NOT NULL,
	[NationalIDNumber] [nvarchar](15) NULL,
	[JobTitle] [nvarchar](50) NULL,
	[DateOfBirth] [date] NULL,
	[MaritalStatus] [nchar](1) NULL,
	[Gender] [nchar](1) NULL,
	[HireDate] [date] NULL,
	[CityName] [nvarchar](50) NOT NULL,
	[Region] [nvarchar](50) NOT NULL,
	[Population] [int] NOT NULL,
	CONSTRAINT PK_Employee PRIMARY KEY CLUSTERED ([EmployeeKey] ASC)
)
GO

CREATE TABLE dimension.Customer(
	[CustomerKey] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NOT NULL,
	[FirstName] [nvarchar](100) NOT NULL,
	[LastName] [nvarchar](100) NOT NULL,
	[Gender] [nchar](1) NULL,
	[NationalIDNumber] [nvarchar](15) NULL,
	[DateOfBirth] [date] NULL,
	[RegionName] [nvarchar](100) NULL,
	[PhoneNumber] [nvarchar](20) NULL,
	[isActive] [bit] NOT NULL,
	[CityName] [nvarchar](50) NOT NULL,
	[Region] [nvarchar](50) NOT NULL,
	[Population] [int] NOT NULL,
	CONSTRAINT PK_Customer PRIMARY KEY CLUSTERED ([CustomerKey] ASC)
)
GO

CREATE TABLE dimension.Account(
	[AccountKey] [int] IDENTITY(1,1) NOT NULL,
	[AccoountID] [int] NOT NULL,
	[AccountNumber] [nvarchar](20) NULL,
	[AllowedOverdraft] [decimal](18, 2) NULL,
	CONSTRAINT PK_Account PRIMARY KEY ([AccountKey] ASC)
)
GO

CREATE TABLE [dimension].[Date](
	[DateKey] [date] NOT NULL,
	[Day] [tinyint] NOT NULL,
	[DaySuffix] [char](2) NOT NULL,
	[Weekday] [tinyint] NOT NULL,
	[WeekDayName] [varchar](10) NOT NULL,
	[IsWeekend] [bit] NOT NULL,
	[IsHoliday] [bit] NOT NULL,
	[HolidayText] [varchar](64) SPARSE  NULL,
	[DOWInMonth] [tinyint] NOT NULL,
	[DayOfYear] [smallint] NOT NULL,
	[WeekOfMonth] [tinyint] NOT NULL,
	[WeekOfYear] [tinyint] NOT NULL,
	[ISOWeekOfYear] [tinyint] NOT NULL,
	[Month] [tinyint] NOT NULL,
	[MonthName] [varchar](10) NOT NULL,
	[Quarter] [tinyint] NOT NULL,
	[QuarterName] [varchar](6) NOT NULL,
	[Year] [int] NOT NULL,
	[MMYYYY] [char](6) NOT NULL,
	[MonthYear] [char](7) NOT NULL,
	[FirstDayOfMonth] [date] NOT NULL,
	[LastDayOfMonth] [date] NOT NULL,
	[FirstDayOfQuarter] [date] NOT NULL,
	[LastDayOfQuarter] [date] NOT NULL,
	[FirstDayOfYear] [date] NOT NULL,
	[LastDayOfYear] [date] NOT NULL,
	[FirstDayOfNextMonth] [date] NOT NULL,
	[FirstDayOfNextYear] [date] NOT NULL,
 CONSTRAINT [PK_Date] PRIMARY KEY CLUSTERED ( [DateKey] ASC )
)
GO


-- Creating Fact table

CREATE TABLE fact.AccountDetails(
	[AccountDetailsKey] [int] IDENTITY(1,1) NOT NULL,
	[CustomerKey] [int] NOT NULL,
	[CurrencyKey] [int] NOT NULL,
	[EmployeeKey] [int] NOT NULL,
	[AccountKey] [int] NOT NULL,
	[DateKey] [date] NOT NULL,
	[CurrentBalance] [decimal](18, 2) NULL,
	[InflowTransactionsQantity] [int] NULL,
	[InflowAmount] [decimal](18,2) NULL,
	[OutflowTransactionsQantity] [int] NULL,
	[OutflowAmount] [decimal](18,2) NULL,
	[OutflowTransactionsQantityATM] [int] NULL,
	[OutflowAmountATM] [decimal](18,2) NULL,
	CONSTRAINT PK_AccountDetails PRIMARY KEY CLUSTERED ([AccountDetailsKey] ASC)
)
GO

-- Adding Foreign keys

-- Customer
ALTER TABLE fact.AccountDetails
ADD CONSTRAINT FK_AccountDetails_Customer FOREIGN KEY ([CustomerKey])
REFERENCES dimension.Customer ([CustomerKey])

-- Currency
ALTER TABLE fact.AccountDetails
ADD CONSTRAINT FK_AccountDetails_Currency FOREIGN KEY ([CurrencyKey])
REFERENCES dimension.Currency ([CurrencyKey])

-- Employee
ALTER TABLE fact.AccountDetails
ADD CONSTRAINT FK_AccountDetails_Employee FOREIGN KEY ([EmployeeKey])
REFERENCES dimension.Employee([EmployeeKey])

-- Account
ALTER TABLE fact.AccountDetails
ADD CONSTRAINT FK_AccountDetails_Account FOREIGN KEY ([AccountKey])
REFERENCES dimension.Account ([AccountKey])

-- Date
ALTER TABLE fact.AccountDetails
ADD CONSTRAINT FK_AccountDetails_Date FOREIGN KEY ([DateKey])
REFERENCES dimension.Date ([DateKey])
GO

-- Prepearing procedures for inital data load

-- Loading Currency Table
CREATE OR ALTER PROCEDURE integration.LoadCurrencyTable
AS
BEGIN

INSERT INTO dimension.Currency(CurrencyID, Code, Name, ShortName, CountryName)

SELECT  c.id as CurrencyID, c.Code,c.Name,c.ShortName,c.CountryName
FROM BrainsterDB.dbo.Currency as c
END
GO

EXEC integration.LoadCurrencyTable

SELECT * FROM dimension.Currency
GO

-- Loading Employee Table
CREATE OR ALTER PROCEDURE integration.LoadEmployeeTable
AS
BEGIN

INSERT INTO dimension.Employee(EmployeeID, FirstName, LastName, NationalIDNumber, 
JobTitle, DateOfBirth, MaritalStatus, Gender, HireDate, CityName, Region, Population)

SELECT e.ID as EmployeeID, e.FirstName, e.LastName, e.NationalIDNumber, e.JobTitle,
e.DateOfBirth, e.MaritalStatus, e.Gender, e.HireDate, 
ISNULL(c.CityName,''),ISNULL(c.region,'')  as Region, ISNULL(c.population,0) as Population
FROM BrainsterDB.dbo.Employee as e
left join BrainsterDB.dbo.City as c on e.CityId = c.id
END
GO

EXEC integration.LoadEmployeeTable

SELECT * FROM dimension.Employee
GO

-- Loading Customer Table
CREATE OR ALTER PROCEDURE integration.LoadCustomerTable
AS
BEGIN

INSERT INTO dimension.Customer (CustomerID, FirstName, LastName, Gender, NationalIDNumber, DateOfBirth, 
RegionName, PhoneNumber, isActive, CityName, Region, Population)

SELECT cu.Id as CustomerID, cu.FirstName,cu.LastName, cu.Gender, cu.NationalIDNumber, cu.DateOfBirth,
cu.RegionName, cu.PhoneNumber, cu.isActive,
ISNULL(c.CityName,''),ISNULL(c.region,'') AS Region,ISNULL(c.population,0) AS Population
FROM BrainsterDB.dbo.Customer AS cu
left join BrainsterDB.dbo.City AS c on cu.CityId = c.id

END
GO

EXEC integration.LoadCustomerTable

SELECT * FROM dimension.Customer
GO

-- Loading Account Table
CREATE OR ALTER PROCEDURE integration.LoadAccountTable
AS
BEGIN

INSERT INTO dimension.Account(AccoountID, AccountNumber, AllowedOverdraft)

SELECT a.Id AS AccooutnID,a.AccountNumber,a.AllowedOverdraft
FROM BrainsterDB.dbo.Account AS a

END
GO

EXEC integration.LoadAccountTable

SELECT * FROM dimension.Account
GO

-- Loading Data Table 

CREATE OR ALTER PROCEDURE [integration].[GenerateDimensionDate]
AS
BEGIN
	DECLARE
		@StartDate DATE = '2000-01-01'
	,	@NumberOfYears INT = 30
	,	@CutoffDate DATE;
	SET @CutoffDate = DATEADD(YEAR, @NumberOfYears, @StartDate);

	-- prevent set or regional settings from interfering with 
	-- interpretation of dates / literals
	SET DATEFIRST 7;
	SET DATEFORMAT mdy;
	SET LANGUAGE US_ENGLISH;

	-- this is just a holding table for intermediate calculations:
	CREATE TABLE #dim
	(
		[Date]       DATE        NOT NULL, 
		[day]        AS DATEPART(DAY,      [date]),
		[month]      AS DATEPART(MONTH,    [date]),
		FirstOfMonth AS CONVERT(DATE, DATEADD(MONTH, DATEDIFF(MONTH, 0, [date]), 0)),
		[MonthName]  AS DATENAME(MONTH,    [date]),
		[week]       AS DATEPART(WEEK,     [date]),
		[ISOweek]    AS DATEPART(ISO_WEEK, [date]),
		[DayOfWeek]  AS DATEPART(WEEKDAY,  [date]),
		[quarter]    AS DATEPART(QUARTER,  [date]),
		[year]       AS DATEPART(YEAR,     [date]),
		FirstOfYear  AS CONVERT(DATE, DATEADD(YEAR,  DATEDIFF(YEAR,  0, [date]), 0)),
		Style112     AS CONVERT(CHAR(8),   [date], 112),
		Style101     AS CONVERT(CHAR(10),  [date], 101)
	);

	-- use the catalog views to generate as many rows as we need
	--DECLARE @StartDate DATE = '2000-01-01',  @CutoffDate  DATE = '2010-01-01'
	-- SELECT @StartDate , @StartDate DATEDIFF(DAY, @StartDate, @CutoffDate)
	-- 10 godini * 365 -> 3653
	INSERT INTO #dim ([date]) 
	SELECT
		DATEADD(DAY, rn - 1, @StartDate) as [date]
	FROM 
	(
		SELECT TOP (DATEDIFF(DAY, @StartDate, @CutoffDate)) 
			rn = ROW_NUMBER() OVER (ORDER BY s1.[object_id])
		FROM
			-- on my system this would support > 5 million days
			sys.all_objects AS s1
			CROSS JOIN sys.all_objects AS s2
		ORDER BY
			s1.[object_id]
	) AS x;
	-- SELECT * FROM #dim

	INSERT dimension.[Date] ([DateKey], [Day], [DaySuffix], [Weekday], [WeekDayName], [IsWeekend], [IsHoliday], [HolidayText], [DOWInMonth], [DayOfYear], [WeekOfMonth], [WeekOfYear], [ISOWeekOfYear], [Month], [MonthName], [Quarter], [QuarterName], [Year], [MMYYYY], [MonthYear], [FirstDayOfMonth], [LastDayOfMonth], [FirstDayOfQuarter], [LastDayOfQuarter], [FirstDayOfYear], [LastDayOfYear], [FirstDayOfNextMonth], [FirstDayOfNextYear])
	SELECT
		--DateKey     = CONVERT(INT, Style112),
		[DateKey]        = [date],
		[Day]         = CONVERT(TINYINT, [day]),
		DaySuffix     = CONVERT(CHAR(2), CASE WHEN [day] / 10 = 1 THEN 'th' ELSE 
						CASE RIGHT([day], 1) WHEN '1' THEN 'st' WHEN '2' THEN 'nd' 
						WHEN '3' THEN 'rd' ELSE 'th' END END),
		[Weekday]     = CONVERT(TINYINT, [DayOfWeek]),
		[WeekDayName] = CONVERT(VARCHAR(10), DATENAME(WEEKDAY, [date])),
		[IsWeekend]   = CONVERT(BIT, CASE WHEN [DayOfWeek] IN (1,7) THEN 1 ELSE 0 END),
		[IsHoliday]   = CONVERT(BIT, 0),
		HolidayText   = CONVERT(VARCHAR(64), NULL),
		[DOWInMonth]  = CONVERT(TINYINT, ROW_NUMBER() OVER 
						(PARTITION BY FirstOfMonth, [DayOfWeek] ORDER BY [date])),
		[DayOfYear]   = CONVERT(SMALLINT, DATEPART(DAYOFYEAR, [date])),
		WeekOfMonth   = CONVERT(TINYINT, DENSE_RANK() OVER 
						(PARTITION BY [year], [month] ORDER BY [week])),
		WeekOfYear    = CONVERT(TINYINT, [week]),
		ISOWeekOfYear = CONVERT(TINYINT, ISOWeek),
		[Month]       = CONVERT(TINYINT, [month]),
		[MonthName]   = CONVERT(VARCHAR(10), [MonthName]),
		[Quarter]     = CONVERT(TINYINT, [quarter]),
		QuarterName   = CONVERT(VARCHAR(6), CASE [quarter] WHEN 1 THEN 'First' 
						WHEN 2 THEN 'Second' WHEN 3 THEN 'Third' WHEN 4 THEN 'Fourth' END), 
		[Year]        = [year],
		MMYYYY        = CONVERT(CHAR(6), LEFT(Style101, 2)    + LEFT(Style112, 4)),
		MonthYear     = CONVERT(CHAR(7), LEFT([MonthName], 3) + LEFT(Style112, 4)),
		FirstDayOfMonth     = FirstOfMonth,
		LastDayOfMonth      = MAX([date]) OVER (PARTITION BY [year], [month]),
		FirstDayOfQuarter   = MIN([date]) OVER (PARTITION BY [year], [quarter]),
		LastDayOfQuarter    = MAX([date]) OVER (PARTITION BY [year], [quarter]),
		FirstDayOfYear      = FirstOfYear,
		LastDayOfYear       = MAX([date]) OVER (PARTITION BY [year]),
		FirstDayOfNextMonth = DATEADD(MONTH, 1, FirstOfMonth),
		FirstDayOfNextYear  = DATEADD(YEAR,  1, FirstOfYear)
	FROM #dim
END


EXEC integration.GenerateDimensionDate

SELECT * FROM dimension.Date
GO

-- Loading Fact table

-- Loading AccountDetails Table

SELECT * FROM fact.AccountDetails
GO

CREATE OR ALTER PROCEDURE integration.LoadAccountDetails
AS
BEGIN

WITH CTE AS(
SELECT a.CustomerId,a.CurrencyId,a.EmployeeId,a.AccountNumber,ad.AccountId,a.CurrentBalance,d.DateKey,d.FirstDayOfMonth,d.LastDayOfMonth,
ROW_NUMBER () OVER (PARTITION BY a.AccountNumber, d.LastDayOfMonth ORDER BY ad.TransactionDate) AS RN
FROM BrainsterDB.dbo.Account AS a
inner join BrainsterDB.dbo.AccountDetails AS ad on a.Id = ad.AccountId
inner join dimension.Date AS d on ad.TransactionDate = d.DateKey
)

INSERT INTO fact.AccountDetails(CustomerKey, CurrencyKey, EmployeeKey, AccountKey, DateKey, 
CurrentBalance, InflowTransactionsQantity, InflowAmount, OutflowTransactionsQantity, 
OutflowAmount, OutflowTransactionsQantityATM, OutflowAmountATM)

SELECT c.CustomerKey,cr.CurrencyKey,e.EmployeeKey,a.AccountKey,DateKey,
-- Current Balance
(
	SELECT SUM(Amount) 
	FROM BrainsterDB.dbo.Account AS a
	inner join BrainsterDB.dbo.AccountDetails AS ad on a.Id = ad.id
	WHERE CTE.AccountNumber = a.AccountNumber
	AND ad.TransactionDate <= CTE.lastDayOfMonth
) AS CurrentBalance,
(
	SELECT COUNT(Amount) 
	FROM BrainsterDB.dbo.AccountDetails AS ad
	inner join BrainsterDB.dbo.Account AS a on ad.AccountId = a.Id
	WHERE ad.Amount > 0 AND CTE.AccountNumber = a.AccountNumber AND
	ad.TransactionDate BETWEEN CTE.FirstDayOfMonth AND CTE.lastDayOfMonth
) AS InflowTransactionsQuantity,

( 	
	SELECT ISNULL(SUM(Amount), 0)
	FROM BrainsterDB.dbo.AccountDetails ad 
	INNER JOIN BrainsterDB.dbo.Account a ON ad.AccountId = a.Id
	WHERE ad.Amount > 0 AND CTE.AccountNumber = a.AccountNumber
	AND ad.TransactionDate BETWEEN CTE.firstDayOfMonth AND CTE.LastDayOfMonth
) AS InflowAmount,
(
	SELECT COUNT(Amount) 
	FROM BrainsterDB.dbo.AccountDetails AS ad
	inner join BrainsterDB.dbo.Account AS a on ad.AccountId = a.Id
	WHERE 
	ad.Amount < 0 AND 
	CTE.AccountNumber = a.AccountNumber AND
	ad.TransactionDate BETWEEN CTE.FirstDayOfMonth AND CTE.lastDayOfMonth
) AS OutflowTransactionsQuantity,

( 	
	SELECT ISNULL(SUM(ABS(Amount)), 0)
	FROM BrainsterDB.dbo.Account AS a
	INNER JOIN BrainsterDB.dbo.AccountDetails AS ad ON a.Id = ad.AccountId
	WHERE ad.Amount < 0 AND 
	CTE.AccountNumber = a.AccountNumber AND 
	ad.TransactionDate <= CTE.LastDayOfMonth
) AS OutflowAmount,

(
	SELECT COUNT(Amount) 
	FROM BrainsterDB.dbo.AccountDetails AS ad
	inner join BrainsterDB.dbo.Account AS a ON ad.AccountId = a.Id
	inner join BrainsterDB.dbo.Location AS l ON ad.LocationId = l.Id
	inner join BrainsterDB.dbo.LocationType AS lt ON lt.Id = l.LocationTypeId 
	WHERE ad.Amount < 0 AND
	CTE.AccountNumber = a.AccountNumber AND 
	ad.TransactionDate BETWEEN CTE.firstDayOfMonth AND CTE.LastDayOfMonth AND
	lt.Name = 'ATM'
) AS OutflowTransactionsQuantity,

(
	SELECT ISNULL(ABS(SUM(Amount)),0)
	FROM BrainsterDB.dbo.AccountDetails AS ad
	inner join BrainsterDB.dbo.Account AS a ON ad.AccountId = a.Id
	inner join BrainsterDB.dbo.Location AS l ON ad.LocationId = l.Id
	inner join BrainsterDB.dbo.LocationType AS lt ON lt.Id = l.LocationTypeId 
	WHERE ad.Amount < 0 AND 
	CTE.AccountNumber = a.AccountNumber AND 
	ad.TransactionDate BETWEEN CTE.firstDayOfMonth AND CTE.LastDayOfMonth AND
	lt.Name = 'ATM'
) AS OutflowTransactionsQuantity

FROM CTE
left outer join dimension.Customer AS c ON CTE.CustomerId = c.CustomerID
left outer join dimension.Employee AS e ON CTE.EmployeeId = e.EmployeeID
left outer join dimension.Currency AS cr ON CTE.CurrencyId = cr.CurrencyID
left outer join dimension.Account AS a ON CTE.AccountId = a.AccoountID
WHERE RN = 1
ORDER BY InflowTransactionsQuantity ASC

END
GO

BEGIN TRAN
EXEC integration.LoadAccountDetails

SELECT * FROM fact.AccountDetails

COMMIT
ROLLBACK