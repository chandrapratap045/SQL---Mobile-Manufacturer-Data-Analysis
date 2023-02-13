USE db_SQLCaseStudies;

select * from DIM_DATE;
select * from DIM_CUSTOMER;
select * from DIM_MODEL;
select * from DIM_MANUFACTURER;
select * from DIM_LOCATION;
select * from FACT_TRANSACTIONS;

-- 1.List all the states in which we have customers who have bought cellphones from 2005 till today.
select STATE
from DIM_LOCATION A inner join FACT_TRANSACTIONS B on A.IDLocation = B.IDLocation
where datepart(year,date) >= 2005
group by State;

--2. What state in the US is buying more 'samsung' cell phones?
select top 1 * from(
select
A.COUNTRY,
A.STATE,
D.MANUFACTURER_NAME,
count(quantity) as TOT_QTY
from DIM_LOCATION A inner join FACT_TRANSACTIONS B on A.IDLocation = B.IDLocation
inner join DIM_MODEL C on B.IDModel = C.IDModel
inner join DIM_MANUFACTURER D on C.IDManufacturer = D.IDManufacturer
where D.Manufacturer_Name = 'Samsung' and A.Country = 'US'
group by 
A.country,
A.state,
D.manufacturer_name ) as t1
order by TOT_QTY desc;

--3. Show the number of transactions for each model per zip code per state.
select 
MODEL_NAME,
ZIPCODE,
STATE,
count(B.idmodel) NO_OF_TRANS
from DIM_MODEL A left join FACT_TRANSACTIONS B on A.IDModel = B.IDModel
inner join DIM_LOCATION C on B.IDLocation = C.IDLocation
group by model_name,ZipCode,state;

--4. Show the cheapest cellphone
select top 1
MANUFACTURER_NAME,
MODEL_NAME,
UNIT_PRICE
from dim_model A inner join DIM_MANUFACTURER B on A.IDManufacturer = B.IDManufacturer
order by unit_price;

--5. Find out the average price for each model in the top 5 manufacturers in terms of sales quantity and order by average price
select
A.IDModel,
MODEL_NAME,
avg(totalprice) [AVG PRICE]
from dim_model A left join FACT_TRANSACTIONS B on A.idmodel = B.idmodel
inner join DIM_MANUFACTURER C on A.IDManufacturer = C.IDManufacturer
where A.IDManufacturer in
(
select top 5 A.IDManufacturer
from DIM_MANUFACTURER A inner join DIM_MODEL B on A.IDManufacturer = B.IDManufacturer
inner join FACT_TRANSACTIONS C on B.IDModel = C.IDModel
group by A.IDManufacturer
order by count(C.Quantity) desc
)
group by A.IDModel, MODEL_NAME
order by [AVG PRICE];

--6. list the names of the customers and the average amount spent in 2009, where the average is higher than 500
select CUSTOMER_NAME, avg(totalprice) [AVG AMOUNT]
from DIM_CUSTOMER A left join FACT_TRANSACTIONS B on A.IDCustomer = B.IDCustomer
inner join DIM_DATE C on B.DATE = C.DATE
where C.YEAR = 2009
group by customer_name
having avg(totalprice) > 500;

--7. List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008,2009,2010
select t1.IDModel , t1.Model_Name from (
	select top 5 A.IDModel , Model_Name
	from FACT_TRANSACTIONS A inner join DIM_MODEL B
	on A.IDModel = B.IDModel
	where year(date) = 2008
	group by A.IDModel,Model_Name
	order by sum(quantity) desc ) t1
inner join
	(select top 5 A.IDModel , Model_Name
	from FACT_TRANSACTIONS A inner join DIM_MODEL B
	on A.IDModel = B.IDModel
	where year(date) = 2009
	group by A.IDModel,Model_Name
	order by sum(quantity) desc) t2
on t1.IDModel = t2.IDModel
inner join
	(select top 5 A.IDModel , Model_Name
	from FACT_TRANSACTIONS A inner join DIM_MODEL B
	on A.IDModel = B.IDModel
	where year(date) = 2010
	group by A.IDModel,Model_Name
	order by sum(quantity) desc) t3
on t2.IDModel = t3.IDModel;

--8. Show the manufacturers with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010.
select
C.IDManufacturer,
C.Manufacturer_Name,
Date,
TotalPrice from
(
select
row_number() over(partition by year(date) order by totalprice desc) RNUM,
*
from FACT_TRANSACTIONS
where datepart(year,date) in (2009,2010)
) as T1
inner join DIM_MODEL as B on T1.IDModel = B.IDModel
inner join DIM_MANUFACTURER as C on B.IDManufacturer = C.IDManufacturer
where rnum = 2;

--9. Show the manufacturers that sold cellphones in 2010 but didn't in 2009.
select
C.IDManufacturer,
Manufacturer_Name from
DIM_MANUFACTURER C
inner join
(
select IDManufacturer from dim_model A inner join FACT_TRANSACTIONS B on A.IDModel = B.IDModel where datepart(year,date) = 2010
except
select IDManufacturer from dim_model A inner join FACT_TRANSACTIONS B on A.IDModel = B.IDModel where datepart(year,date) = 2009
)
as D on C.IDManufacturer = D.IDManufacturer;

-- Find top 10 customers and their average spend, average quantity by each year. Also find the percentage of change in their spend.
select T1.[CUSTOMER NAME],
T1.[YEAR],
T1.[AVERAGE QTY],
T1.[AVERAGE SPEND],
case
	when T2.[YEAR] is not null
    then format(Round((T1.[AVERAGE SPEND]-T2.[AVERAGE SPEND])/T2.[AVERAGE SPEND],2),'P') ELSE '-' 
    end [% of CHANGE]
from
(
select customer_name [CUSTOMER NAME],
Round(avg(Cast(totalprice as float)),2) [AVERAGE SPEND],
Round(avg(Cast(quantity as float)),2) [AVERAGE QTY],
DATEPART(year,A.date) [YEAR]
from FACT_TRANSACTIONS A inner join DIM_CUSTOMER B 
on A.IDCustomer = B.IDCustomer
where A.IDCustomer in (
select top 10 IDCustomer from FACT_TRANSACTIONS group by IDCustomer order by sum(TotalPrice) desc
)
group by customer_name , DATEPART(year,A.date)
) as T1
left join
(
select customer_name [CUSTOMER NAME],
Round(avg(Cast(totalprice as float)),2) [AVERAGE SPEND],
Round(avg(Cast(quantity as float)),2) [AVERAGE QTY],
DATEPART(year,A.date) [YEAR]
from FACT_TRANSACTIONS A inner join DIM_CUSTOMER B 
on A.IDCustomer = B.IDCustomer
where A.IDCustomer in (
select top 10 IDCustomer from FACT_TRANSACTIONS group by IDCustomer order by sum(TotalPrice) desc
)
group by customer_name , DATEPART(year,A.date)
) as T2
on T1.[CUSTOMER NAME] = T2.[CUSTOMER NAME] and T2.[YEAR] = T1.[YEAR] - 1
order by T1.[CUSTOMER NAME];