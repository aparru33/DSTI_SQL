--Question 1:
-------------
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

--SQL Query:
----------

-- CTE: Common Table Expression
-- let's first group all orderline per orderID to compute the total for each order
-- regardless of the customer
with
individualOrderTotal as (
select Ol.OrderID as OrderID, sum(Ol.Quantity * Ol.UnitPrice) as orderTotal
from Sales.OrderLines  as Ol
group by Ol.OrderID
),
-- CTE: Common Table Expression 
-- we do the same for the invoiceline and group it per invoiceID and compute the total
individualInvoiceTotal as (
select Il.InvoiceID as InvoiceID, sum(Il.Quantity * Il.UnitPrice) as invoiceTotal
from Sales.InvoiceLines  as Il
group by Il.InvoiceID
) 
-- Now we can form the query Result set
select	O.CustomerID, 
		C.CustomerName ,
		COUNT(O.OrderID) as TotalNBOrders ,
		COUNT(I.OrderID) as TotalNBInvoices,
		SUM(orderTotal) as OrdersTotalValue,
		SUM(invoiceTotal) as InvoicesTotalValue,
		ABS(SUM(orderTotal) - SUM(invoiceTotal)) as AbsoluteValueDifference
		
from	Sales.Orders as O,
		individualOrderTotal as Ol,		-- CTE reused
		Sales.Invoices as I,
		individualInvoiceTotal as Il,	-- CTE reused
		Sales.Customers as C
where	O.CustomerID = C.CustomerID
		-- only order transformed into invoice are considered by this filter
		and O.OrderID = I.OrderID
		and O.OrderID = Ol.OrderID
		and I.InvoiceID = Il.InvoiceID

group by O.CustomerID, C.CustomerName
order by AbsoluteValueDifference desc, TotalNBOrders, C.CustomerName