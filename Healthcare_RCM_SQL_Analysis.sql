
--1.How are the 30,000 claims distributed across different claim statuses?

select CLaimStatus, count(*) as TotalClaims
from factclaims
group by ClaimStatus
order by ClaimStatus desc;

------------------------------------------------------
--2.Business Question 2: How much are we billing by claim status?

SELECT claimstatus, sum(BilledAmount) as TotalBilledAmount
from factclaims
group by claimstatus
order by TotalBilledAmount desc;

---------------------------------------------------------
--3.Business Question 3: Which payers generate the highest billed amount?

Select p.payername,
sum(f.billedamount) as TotalBilledAmount
from factclaims as f
join dimpayer as p
on f.payerID = p.payerID
group by p.payername
order by TotalBilledAmount desc;

-------------------------------------------------------------
--4.Which providers generate the highest billed amount?

select p.providername, sum(f.billedamount) as TotalBilledAmount
from FactClaims as f
join DimProvider as p
on f.ProviderID = p.ProviderID
group by p.ProviderName
order by TotalBilledAmount desc;

---------------------------------------------------------------
--5.Which payers have the highest number of claims?

select p.payername, count(*) as TotalClaims
from FactClaims as f
join DimPayer as p
on f.PayerID = p.PayerID
group by p.PayerName
order by TotalClaims desc;

----------------------------------------------------------------

--6.How can we classify claims by billed amount?

select claimID,billedamount,
case when billedamount >=5000 then 'high value'
when billedamount >=2000 then 'medium value'
else 'low value'
end as ClaimValueCategory
from factclaims;

-----------------------------------------------------------------

--7.Which denial reasons cause the most denied claims?


use Healthcare_RCM;
go
SELECT
    d.DenialReason,
    COUNT(*) AS DeniedClaims
FROM FactClaims f
JOIN DimDenialReason d
    ON f.DenialReasonID = d.DenialReasonID
WHERE f.ClaimStatus = 'Denied'
GROUP BY d.DenialReason
ORDER BY DeniedClaims DESC;

------------------------------------------------------------------

--8. which payer has the highest percentage of claims being denied.

select p.payername, count(*) as totalclaims,
sum(case when f.claimstatus = 'denied' then 1 else 0 end) as deniedclaims,
cast(sum(case when f.claimstatus = 'denied' then 1 else 0 end)*100.00/count(*) as decimal(5,2)) as denialrate
from FactClaims as f
join DimPayer as p
on f.PayerID = p.PayerID
group by p.PayerName
order by denialrate desc;

---------------------------------------------------------------------

--9.Which payers have the highest collection rate?

select p.payername, 
sum(f.BilledAmount) as Totalbilledamount,
sum(f.paidamount) as Totalpaidamount,
cast(sum(f.paidamount)*100.00/sum(f.billedamount) as decimal (5,2)) as collectionrate
from FactClaims as f
join DimPayer as p
on f.PayerID = p.PayerID
group by p.Payername
order by collectionrate desc;

---------------------------------------------------------------------

--10.How is outstanding AR distributed by aging bucket?

	select 	count(*) as totalclaims,
	sum(outstandingAR) as OutstandingAR,
	case
	when ARDays <=30 then '0-30 days'
    when ARDays <=60 then '31-60 days'
	when ardays <=90 then '61-90 days'
	else '90+ days' end as ARBucket
	from FactClaims

	group by 
	case 
	when ardays <=30 then '0-30 days'
	when ardays<=60 then '31-60 days'
	when ARDays <=90 then '61-90 days'
	else '90+ days' end;

	-----------------------------------------------------

--11. How do billed and paid amounts trend by month?

select
d.year, d.month, d.monthnumber,
sum(f.billedamount) as totalbilledamount,
sum(f.paidamount) as totalpaidamount
from factclaims as f
join dimdate as d
on f.ServiceDate = d.Date
group by
d.Year,d.Month,d.MonthNumber
order by
d.MonthNumber;

---------------------------------------------------------

--12.Which providers have the highest denial rates?

select p.providername,
count(*) as totalclaims,
sum(case when f.claimstatus = 'denied' then 1 else 0 end) as deniedclaims,
cast(sum(case when f.claimstatus = 'denied' then 1 else 0 end)*100.00 / count(*) as decimal(5,2)) as denialrate
from factclaims as f
join dimprovider as p
on f.ProviderID = p.ProviderID
group by p.ProviderName
order by denialrate desc;

----------------------------------------------------------

--13.How do payers rank by total billed amount?

select p.payername,
sum(f.billedamount) as totalbilledamount,
RANK() over ( order by sum(f.billedamount) desc) as payerrank
from factclaims as f
join dimpayer as p
on f.PayerID = p.PayerID
group by p.payername;

------------------------------------------------------------

--14.How does monthly paid amount compare with the previous month?

with monthlypaid as (
select d.year,d.month,d.monthnumber,sum(f.paidamount) as totalpaidamount
from factclaims as f
join dimdate as d
on f.ServiceDate = d.Date
group by
d.year, d.month, d.MonthNumber)

select year, 
month,
monthnumber,
totalpaidamount,
lag(totalpaidamount) over(order by year, monthnumber) as previousmonthpaid
from monthlypaid
order by monthnumber asc;

-------------------------------------------------------------------

--15.Which payers have a denial rate higher than the overall denial rate?

with payerdenial as (
select p.payername,
count(*) as totalclaims,
sum(case when f.claimstatus = 'denied' then 1 else 0 end) as deniedclaims,
cast(sum(case when f.claimstatus = 'denied' then 1 else 0 end)*100.00 / count(*) as decimal(5,2) )as denialrate
from factclaims as f
join dimpayer as p
on f.payerID = p.payerID
group by p.PayerName)

select payername,totalclaims,deniedclaims,denialrate from payerdenial where denialrate > (
select 
cast(sum(case when claimstatus = 'denied' then 1 else 0 end)*100.00 / count(*) as decimal(5,2)) as denialrate
from FactClaims)
order by denialrate desc;

------------------------------------------------------------------------

--16.Who are the top 5 providers within each specialty by billed amount?

with providerperformance as (
select p.specialty,p.providername,sum(f.billedamount) as totalbilledamount
from factclaims as f
join DimProvider as p
on f.ProviderID = p.ProviderID
group by p.Specialty,p.ProviderName)

select specialty, providername,totalbilledamount,
ROW_NUMBER () over (partition by specialty order by totalbilledamount desc) as providerrank
from providerperformance
order by Specialty, providerrank;

----------------------------------------------------------------------------

--17.How do payers rank by total billed amount using DENSE_RANK()?

select p.payername, sum(f.billedamount) as totalbilledamount,
DENSE_RANK() over (order by sum(f.billedamount) desc) as payerrank
from FactClaims as f
join DimPayer as p
on f.PayerID = p.PayerID
group by p.PayerName
order by payerrank;

---------------------------------------------------------------------------

--18.Which providers have both a high denial rate and significant denied amount?

with providerperformance as (
select p.providername, count(*) as totalclaims,
sum(case when f.claimstatus = 'denied' then 1 else 0 end) as deniedclaims,
sum(case when f.claimstatus = 'denied' then f.BilledAmount else 0 end) as deniedamount,
cast(sum(case when f.claimstatus = 'denied' then 1 else 0 end)*100.00 / count(*) as decimal(5,2)) as denialrate
from factclaims as f
join dimprovider as p
on f.ProviderID = p.ProviderID
group by p.ProviderName),

benchmark as (
select
avg(denialrate) as AverageProviderDenialRate,
avg(deniedamount) as AverageProviderDeniedAmount
from providerperformance)

select
pp.providername,pp.totalclaims,pp.deniedclaims,pp.deniedamount,pp.denialrate
from providerperformance as pp
cross join benchmark as b
where pp.denialrate >b.AverageProviderDenialRate and pp.deniedamount >b.AverageProviderDeniedAmount
order by pp.denialrate desc;