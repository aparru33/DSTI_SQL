--Question 4:
-------------
--Q4. In the database WideWorldImporters, write a SQL query which reports the highest loss of money from orders not being converted into invoices, by customer category. The name and id of the customer who generated this highest loss must also be identified. The resultset is ordered by highest loss.
--You should be able to write it in pure SQL, but if too challenging, you may use T-SQL and cursors.
--Resultset enclosed in Q4-Resultset.csv


--SQL Query:
------------

-- CTE: Common Table Expression
-- first we aggregate the loss for all the customers 
with LostCustomersDeals as (
	SELECT	o.CustomerID,
			c.CustomerName,
			cg.CustomerCategoryName,
			sum(ol.Quantity*ol.UnitPrice) as TotalLoss
	FROM
		Sales.Orders as o,
		Sales.OrderLines as ol,
		Sales.Customers as c,
		Sales.CustomerCategories as cg
	WHERE NOT EXISTS
		(	
			SELECT *
			FROM Sales.Invoices as i
			WHERE
				o.OrderID = i.OrderID
		)	
		and ol.OrderID = o.OrderID
		and c.CustomerID = o.CustomerID
		and c.CustomerCategoryID = cg.CustomerCategoryID

	group by o.CustomerID, c.CustomerName,cg.CustomerCategoryName
)
-- then we "auto-join" this table with the one where the max loss is identified
-- based on category grouping, this is to identify the max loss responsible customer 
select	lc1.CustomerCategoryName,
		lc1.TotalLoss,
		lc1.CustomerName,
		lc1.CustomerID

from LostCustomersDeals as lc1
	join (
		select	lc.CustomerCategoryName, 
				max(lc.TotalLoss) as maxLoss
		from LostCustomersDeals as lc
		group by lc.CustomerCategoryName
		) as lc2 
		on lc1.CustomerCategoryName = lc2.CustomerCategoryName
		and lc1.TotalLoss = lc2.maxLoss
order by lc1.TotalLoss desc
