--Question 2:
-------------
--Q2. For the CustomerId = 1060 (CustomerName = 'Anand Mudaliyar')
--Identify the first InvoiceLine of his first Invoice, where "first" means the lowest respective IDs, and write an update query increasing the UnitPrice of this InvoiceLine by 20.
--A re-run of the query in Q1 gives the resultset in Q2-Resultset_Corrected.csv (corrected on 15th April 2018 - Summed values in columns OrdersTotalValue & InvoicesTotalValue were incorrect) .

--If you haven't managed to answer Q1, add the following selection query to the previous update query: CustomerId, CustomerName, InvoiceTotal. The latter is the sum of all invoice lines for the target invoice. The target InvoiceID is purposefully not shown, but the resultset post-update is given in Q2-Alternative-Resultset.csv 

--SQL Query:
----------

-- Let's first identify for customerID 1060 the first invoice line of the first invoice
select  I.CustomerID, I.InvoiceID,Il.InvoiceLineID, Il.Quantity, Il.UnitPrice
from	Sales.Invoices as I,
		Sales.InvoiceLines as Il
where	I.InvoiceID = Il.InvoiceID
		and I.CustomerID = 1060
order by I.InvoiceID, Il.InvoiceLineID

-- this gives us the appropriate InvoiceLineID 225394 where to modify the UnitPrice from 240 to 260 as requested
-- CustomerID	| InvoiceID	| InvoiceLineID	| Quantity	| UnitPrice
-- 1060		| 69627		| 225394	| 2		| 240.00

update Sales.InvoiceLines
set UnitPrice = 260 where InvoiceLineID = 225394

-- rerunning the First query gives us the expected Result Set