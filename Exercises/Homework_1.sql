create database MyPersonalDB
go

use MyPersonalDB
go

-- Creating table Person with columns(id,name,dateOfBirth,age)
create table Person (
	id int identity(1,1),
	name nvarchar(20) not null,
	dateBirth date not null,
	age int not null,
	constraint pk_Person primary key clustered(id)
)
go


-- Creating table Comapny with columns(id,name,NumOfEmployees,EDB,phoneNum)
create table Company(
	id int identity(1,1),
	name nvarchar(30) not null,
	NumEmp int not null,
	EDB nvarchar(30),
	phoneNo nvarchar(13),
	constraint pk_Company primary key clustered (id)
)
go

-- Droping table Person and creating it again with companyId
drop table Person
go

create table Person (
	id int identity(1,1),
	--adding companyId column
	comapnyId int not null,
	name nvarchar(20) not null,
	dateBirth date not null,
	age int not null,
	constraint pk_Person primary key clustered(id)
)
go

-- Adding foreign key in table Person 

alter table dbo.Person with check
add constraint fk_companyId
foreign key (comapnyId) references dbo.Company (id)
go

-- Inserting 3 companies 

insert into dbo.Company(name, NumEmp, EDB, phoneNo)
values ('Influitive',120,'999112229','+389 111 111'),
	   ('Spinfluence',200,'99911228','+389 222 222'),
	   ('Perficient',60,'99911227','+389 333 333')
go



-- Inserting 6 persons 
insert into dbo.Person(comapnyId, name, dateBirth, age)
values (1,'Petar','2002-01-10',20),
	   (1,'Sara','2000-01-02',22),
	   (2,'John','1991-01-01',31),
	   (2,'Kaya','1997-12-10',25),
	   (3,'Maja','1995-05-13',37),
	   (3,'Teodor','1993-04-24',29)
go



/* Prepare simple query that will show all persons together with the name of
   the companies where they work and the phoneNum of the company
*/

select p.*,c.name,c.phoneNo 
from dbo.Person as p
inner join dbo.Company as c on p.comapnyId = c.id
go
