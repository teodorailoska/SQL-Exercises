USE BrainsterDW2

-- Dodavame koloni ValidFrom,ValidTo,ModifiedOn vo dimesnions tabelite

-- Kreiranje  Integration.InsertDimensionAccount_Incremental

alter table BrainsterDW2.dimension.Account add ValidFrom date
alter table BrainsterDW2.dimension.Account add ValidTo date
alter table BrainsterDW2.dimension.Account add ModifiedOn date



-- dodavame default vrednosti za ValidFrom i ValidTo

update BrainsterDW2.dimension.Account
set ValidFrom = '1753-01-01', ValidTo = '9999-12-31'
GO



CREATE OR ALTER PROCEDURE integration.InsertDimensionAccount_Incremental(@WorkDay date)
AS
BEGIN
	-- Kreirame temporary tabela #TempAccount vo koja ke se cuvaat promenetite podatoci od tabelata Account
	CREATE TABLE #TempAccount
	(	
		[AccountKey] [int] IDENTITY NOT NULL,
		[AccoountID] [int] NOT NULL,
		[AccountNumber] [nvarchar](20) NULL,
		[AllowedOverdraft] [decimal](18, 2) NULL
	)

	-- Ja popolnuvame #TempAccount
	insert into #TempAccount([AccoountID],[AccountNumber],[AllowedOverdraft])

	select a.Id as AccountID, a.AccountNumber, a.AllowedOverdraft
	from BrainsterDB.dbo.Account as a 
	inner join BrainsterDW2.dimension.Account as ad on a.Id = ad.AccoountID
	where	ad.ValidTo = '9999-12-31' AND
			ad.ValidFrom <= @WorkDay AND
			@WorkDay < ad.ValidTo AND
			ISNULL(a.AllowedOverdraft,0) <> ISNULL(ad.AllowedOverdraft,0)

	--SCD Type1

	UPDATE ad
	set ad.AccountNumber = a.AccountNumber,
		ad.ModifiedOn = GetDate()
	from dimension.Account as ad
	inner join BrainsterDB.dbo.Account as a on ad.AccoountID = a.Id
	where	ad.ValidTo = '9999-12-31' AND
			ad.ValidFrom <= @WorkDay AND
			@WorkDay < ad.ValidTo AND
			HASHBYTES('SHA1',ad.AccountNumber) <> HASHBYTES('SHA1',a.AccountNumber)
	-- Gi menuvame starite validacii
	UPDATE ad
	SET ad.ValidTo = @WorkDay,
		ad.ModifiedOn = GETDATE()

	from dimension.Account as ad
	inner join #TempAccount as t on ad.AccoountID = t.AccoountID
	where	ad.ValidTo = '9999-12-31' AND
			ad.ValidFrom <= @WorkDay AND
			@WorkDay < ad.ValidTo


	-- Gi vnesuvame novite vrednosti
	insert into dimension.Account(AccoountID, AccountNumber, AllowedOverdraft, ValidFrom, ValidTo, ModifiedOn)

	select	t.AccoountID,t.AccountNumber,t.AllowedOverdraft,
			@WorkDay as ValidFrom, '9999-12-31' as ValidTo, GETDATE() as ModifiedOn
	from dimension.Account as ad
	inner join #TempAccount as t on ad.AccoountID = t.AccoountID

	-- Vnesuvame nova dimenzija
	insert into dimension.Account(AccoountID, AccountNumber, AllowedOverdraft, ValidFrom, ValidTo, ModifiedOn)

	select	a.Id as AccoountID, a.AccountNumber,a.AllowedOverdraft,
			@WorkDay as ValidFrom, '9999-12-31' as ValidTo, GETDATE() as ModifiedOn	
	from BrainsterDB.dbo.Account as a
	WHERE NOT EXISTS
	(
		select 1 from BrainsterDW2.dimension.Account as ad where ad.AccoountID = a.Id and ad.ValidTo = '9999-12-31'
	)


END
GO



update BrainsterDB.dbo.Account 
set AllowedOverdraft = 10601
where Id = 6


EXEC integration.InsertDimensionAccount_Incremental @WorkDay = '2019-04-30'

select * 
from BrainsterDW2.dimension.Account
where AccoountID = 6

-- Kreiranje  integration.InsertFactAccountDetails_Incremental
create table integration.LastAgregation
(
	FactName nvarchar(50),
	LastAgreagtion date
)
go

create or alter procedure integration.InsertFactAccountDetails_Incremental(@WorkDay date)
as
begin
	declare @lastAgr date = 
	(
		select top 1 LastAgreagtion
		from integration.LastAgregation
		where FactName = 'fact.AccountDetails'
	)
	
	create table #TmpAccountDetails
	(
		[AccountDetailsKey] [int] IDENTITY(1,1) NOT NULL,
		[CustomerKey] [int] NOT NULL,
		[CurrencyKey] [int] NOT NULL,
		[EmployeeKey] [int] NOT NULL,
		[AccountKey] [int] NOT NULL,
		[DateKey] [date] NOT NULL,
		[CurrentBalance] [decimal](18, 2) NULL,
		[InflowTransactionsQantity] [int] NULL,
		[InflowAmount] [decimal](18, 2) NULL,
		[OutflowTransactionsQantity] [int] NULL,
		[OutflowAmount] [decimal](18, 2) NULL,
		[OutflowTransactionsQantityATM] [int] NULL,
		[OutflowAmountATM] [decimal](18, 2) NULL
	)


;WITH CTE AS(
SELECT a.CustomerId,a.CurrencyId,a.EmployeeId,a.AccountNumber,ad.AccountId,a.CurrentBalance,d.DateKey,d.FirstDayOfMonth,d.LastDayOfMonth,
ROW_NUMBER () OVER (PARTITION BY a.AccountNumber, d.LastDayOfMonth ORDER BY ad.TransactionDate) AS RN
FROM BrainsterDB.dbo.Account AS a
inner join BrainsterDB.dbo.AccountDetails AS ad on a.Id = ad.AccountId
inner join dimension.Date AS d on ad.TransactionDate = d.DateKey
where	@lastAgr < ad.TransactionDate and
		ad.TransactionDate <= @WorkDay
)

INSERT INTO #TmpAccountDetails (CustomerKey, CurrencyKey, EmployeeKey, AccountKey, DateKey, 
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
order by AccountKey

delete ad
from fact.AccountDetails as ad
where exists
(
	select * from #TmpAccountDetails as t
	where ad.AccountKey = t.AccountKey and
	ad.CurrencyKey = t.CustomerKey and
	ad.CurrencyKey = t.CurrencyKey and
	ad.DateKey = t.DateKey and
	ad.EmployeeKey = t.EmployeeKey
)

insert into fact.AccountDetails (AccountDetailsKey, CustomerKey, CurrencyKey, EmployeeKey, AccountKey, DateKey, CurrentBalance, 
InflowTransactionsQantity, InflowAmount, OutflowTransactionsQantity, OutflowAmount, OutflowTransactionsQantityATM, OutflowAmountATM)

select t.AccountDetailsKey,t.CustomerKey,t.CurrencyKey,t.EmployeeKey,t.AccountKey,t.DateKey,t.CurrentBalance,
t.InflowTransactionsQantity,t.InflowAmount,t.OutflowTransactionsQantity,t.OutflowAmount,t.OutflowTransactionsQantityATM,t.OutflowAmountATM
from #TmpAccountDetails as t

update integration.LastAgregation
set LastAgreagtion = @WorkDay
where FactName = 'fact.AccountDetails'
	
end

exec integration.InsertFactAccountDetails_Incremental @WorkDay = '03-02-2023'




