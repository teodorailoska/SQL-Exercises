/*
Design query that will list Customer First and Last Name,
accountNumber, Current account balance and Currency name. For
current balance column use the CurrentBalance from Account table
*/


select c.FirstName,c.LastName,a.AccountNumber,a.CurrentBalance,cu.Name
from Customer c
inner join Account a on c.Id = a.CustomerId
inner join Currency cu on cu.id = a.CurrencyId
go


/*
Change the previous query to read the current balance from
AccauntDetails table and Amount column
*/


select c.FirstName,c.LastName,a.AccountNumber,sum(ad.Amount) as CurrentBalance,cu.Name
from Customer c
inner join Account a on c.Id = a.CustomerId
inner join Currency cu on cu.id = a.CurrencyId
left join AccountDetails ad on a.Id = ad.AccountId
group by c.FirstName,c.LastName,a.AccountNumber,cu.Name
go


-- Extra points: Extend the previous query to show only balance from
-- ATM transactions

select c.FirstName,c.LastName,a.AccountNumber,sum(ad.Amount) as CurrentBalance,cu.Name
from Customer c
inner join Account a on c.Id = a.CustomerId
inner join Currency cu on a.CurrencyId=cu.id
left join AccountDetails ad on ad.AccountId = a.Id
where ad.LocationId in (select lt.Id from Location lt where lt.Name like '%ATM%')
group by c.FirstName,c.LastName,a.AccountNumber,cu.Name
go


