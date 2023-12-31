
--Question 5:
-------------
--Q5. In the database SQLPlayground, write a SQL query selecting all the customers' data who have purchased all the products AND have bought more than 50 products in total (sum of all purchases).
--Resultset enclosed in Q5-Resultset.csv


--SQL Query:
----------

-- division Query to find all customers who bought all products
select * from Customer as C
where not exists (
	select * from Product as Pr
	where not exists (
		select * from Purchase as Pu1
		where C.CustomerId = Pu1.CustomerId
		and Pr.ProductId = Pu1.ProductId 
		-- sub Query to filter customer based on their overall purchases
		-- if we set purchase threshold to 11 instead of 50 we can also include Leo to Sebastien
		and ( select SUM(Pu2.Qty) from Purchase as Pu2
		where C.CustomerId = Pu2.CustomerId
		group by Pu2.CustomerId ) >= 50
		));