USE WideWorldImporters
--Question 1:
-----------
--Using the database WideWorldImporters, write a SQL query which reports the consistency between orders and their attached invoices.
--The resultset should report for each (CustomerID, CustomerName)
-- a. the total number of orders: TotalNBOrders
-- b. the number of invoices converted from an order: TotalNBInvoices
-- c. the total value of orders: OrdersTotalValue
-- d. the total value of invoices: InvoicesTotalValue
-- f. the absolute value of the difference between c - d: AbsoluteValueDifference
 
-- The resultset must be sorted by highest values of AbsoluteValueDifference, then by smallest to highest values of TotalNBOrders and CustomerName is that order.
 
-- Please note that all values in a & b must be identical by definition of the query, as we are observing orders converted into invoices.
--We are looking for potential differences between c & d.
--BUT, you must find them consistent as the data is clean in WideWorldImporters.
--Resultset enclosed in Q1-Resultset_Corrected.csv 


--------------verify if orderTotal equals OrderLines.Quantity * OrderLines.UnitPrice or OrderLines.UnitPrice*OrderLines.Quantity*(1+OrderLines.TaxRate/100)
-------------- and if invoiceTotal equals InvoiceLines.ExtendedPrice or InvoiceLines.Quantity * InvoiceLines.UnitPrice
--methode 1
select *, abs(OrdersTotalValue - InvoicesTotalValue) as AbsoluteValueDifference from (
select c.CustomerID, c.CustomerName,count(distinct(o.OrderID)) as TotalNBOrders, count(distinct(i.InvoiceID)) as TotalNBInvoices, 
	sum( cast( ol.UnitPrice*ol.Quantity*(1+ol.TaxRate/100) as numeric(10,2) )) as OrdersTotalValue, sum(il.ExtendedPrice) as InvoicesTotalValue
from Sales.Customers as c, Sales.Orders as o,  Sales.Invoices as i, Sales.OrderLines as ol,Sales.InvoiceLines as il 
where c.CustomerID=o.CustomerID and o.OrderID=i.OrderID and o.OrderID=ol.OrderID and i.InvoiceID=il.InvoiceID
group by c.CustomerID, c.CustomerName
) as T
order by AbsoluteValueDifference desc, TotalNBOrders, CustomerName;

--methode 2, faster
select *, abs(OrdersTotalValue - InvoicesTotalValue) as AbsoluteValueDifference from (
select c.CustomerID, c.CustomerName,
	count(o.OrderID) as TotalNBOrders, count(i.InvoiceID) as TotalNBInvoices, 
	sum(individualOrderTotal.orderTotal)  as OrdersTotalValue, 
	sum(individualInvoiceTotal.invoiceTotal) as InvoicesTotalValue
from Sales.Customers as c, Sales.Orders as o,  Sales.Invoices as i, 
(
select Ol.OrderID as OrderID, sum( cast( ol.UnitPrice*ol.Quantity*(1+ol.TaxRate/100) as numeric(10,2) )) as orderTotal
from Sales.OrderLines  as Ol
group by Ol.OrderID
) as individualOrderTotal 
, 
(
select Il.InvoiceID as InvoiceID, sum(il.ExtendedPrice) as invoiceTotal
from Sales.InvoiceLines  as Il
group by Il.InvoiceID
) as individualInvoiceTotal 
where c.CustomerID=o.CustomerID and o.OrderID=i.OrderID and o.OrderID=individualOrderTotal.OrderID and i.InvoiceID=individualInvoiceTotal.InvoiceID
group by c.CustomerID, c.CustomerName
) as T
order by AbsoluteValueDifference desc, TotalNBOrders, CustomerName;


--Question 2:
-------------
--Q2. For the CustomerId = 1060 (CustomerName = 'Anand Mudaliyar')
--Identify the first InvoiceLine of his first Invoice, where "first" means the lowest respective IDs, and write an update query increasing the UnitPrice of this InvoiceLine by 20.
--A re-run of the query in Q1 gives the resultset in Q2-Resultset_Corrected.csv (corrected on 15th April 2018 - Summed values in columns OrdersTotalValue & InvoicesTotalValue were incorrect) .
--methode 1
select TOP 1 i.InvoiceID, il.InvoiceLineID,  il.UnitPrice
from Sales.Invoices as i, Sales.InvoiceLines as il
where i.InvoiceID=il.InvoiceID and i.CustomerID=1060
order by InvoiceID, InvoiceLineID;
--methode 2
select min(InvoiceLineID) 
from Sales.InvoiceLines
where InvoiceID = (select min(i.InvoiceID) 
from Sales.Invoices as i, Sales.InvoiceLines as il
where i.InvoiceID=il.InvoiceID and i.CustomerID=1060);


update Sales.InvoiceLines set UnitPrice=UnitPrice+20 
where InvoiceLineID=  (select min(InvoiceLineID) 
							from Sales.InvoiceLines
							where InvoiceID = (select min(i.InvoiceID) 
							from Sales.Invoices as i, Sales.InvoiceLines as il
							where i.InvoiceID=il.InvoiceID and i.CustomerID=1060));

--If you haven't managed to answer Q1, add the following selection query to the previous update query: CustomerId, CustomerName, InvoiceTotal. The latter is the sum of all invoice lines for the target invoice. The target InvoiceID is purposefully not shown, but the resultset post-update is given in Q2-Alternative-Resultset.csv 

--Question 3:
-------------
--Q3.
--Using the database WideWorldImporters, write a T-SQL stored procedure called ReportCustomerTurnover.
--This procedure takes two parameters: Choice and Year, both integers.

--When Choice = 1 and Year = <aYear>, ReportCustomerTurnover selects all the customer names and their total monthly turnover (invoiced value) for the year <aYear>.

--When Choice = 2 and Year = <aYear>, ReportCustomerTurnover  selects all the customer names and their total quarterly (3 months) turnover (invoiced value) for the year <aYear>.

--When Choice = 3, the value of Year is ignored and ReportCustomerTurnover  selects all the customer names and their total yearly turnover (invoiced value).

--When no value is provided for the parameter Choice, the default value of Choice must be 1.
--When no value is provided for the parameter Year, the default value is 2013. This doesn't impact Choice = 3.

--For Choice = 3, the years can be hard-coded within the range of [2013-2016].

--NULL values in the resultsets are not acceptable and must be substituted to 0.

--All output resultsets are ordered by customer names alphabetically.

--Example datasets are provided for the following calls:
--EXEC dbo.ReportCustomerTurnover;
--EXEC dbo.ReportCustomerTurnover 1, 2014;
--EXEC dbo.ReportCustomerTurnover 2, 2015;
--EXEC dbo.ReportCustomerTurnover 3;

--cf file Q3_proc.sql


--Question 4:
-------------
--Q4. In the database WideWorldImporters, write a SQL query which reports the highest loss of money from orders not being converted into invoices, 
--by customer category. The name and id of the customer 
--who generated this highest loss must also be identified. The resultset is ordered by highest loss.
--You should be able to write it in pure SQL, but if too challenging, you may use T-SQL and cursors.
--Resultset enclosed in Q4-Resultset.csv
with 
cust_loss as (select o.CustomerID,c.CustomerName,c.CustomerCategoryID ,sum(ol.Quantity*ol.UnitPrice) loss from Sales.Orders as o
join Sales.Customers as c on o.CustomerID=c.CustomerID
join Sales.OrderLines as ol on o.OrderID=ol.OrderID
left join Sales.Invoices as i on o.OrderID= i.OrderID
where i.OrderID is null
group by o.CustomerID,c.CustomerName,c.CustomerCategoryID
)

select c.CustomerID, c.CustomerName, cl.loss, cc.CustomerCategoryName
from Sales.Customers as c, cust_loss as cl, Sales.CustomerCategories as cc
where c.CustomerID in (select CustomerID from cust_loss where loss in (select max(loss) from cust_loss group by CustomerCategoryID))
and c.CustomerID=cl.CustomerID and cc.CustomerCategoryID=cl.CustomerCategoryID
;


--Question 5:
-------------
--Q5. In the database SQLPlayground, write a SQL query selecting all the customers' data who have purchased all the products AND have bought more than 50 products in total (sum of all purchases).
--Resultset enclosed in Q5-Resultset.csv
USE SQLPlayground
select c.* 
from Customer as c
where not exists 
(select * from Product as pr
	where not exists(
	select * from Purchase as p
	where p.ProductId=pr.ProductId and c.CustomerId=p.CustomerId
	and (select sum(p2.Qty) from purchase as p2 where c.CustomerId=p2.CustomerId group by p2.CustomerId )>=50));