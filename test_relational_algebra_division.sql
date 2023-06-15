USE WideWorldImporters
--all customers that are buy all item

select * from 
(select c.CustomerID ,c.CustomerName, st.StockItemID,st.StockItemName
from Sales.Customers as c, Sales.Orders as o, Sales.OrderLines as ol, Warehouse.StockItems as st
where 
--join
c.CustomerID=o.CustomerID and o.OrderID=ol.OrderID and ol.StockItemID=st.StockItemID) as T
where not exists (
	(select sst.StockItemID from Warehouse.StockItems sst)
	except
	(select sa.StockItemID from Sales.OrderLines as sa where sa.StockItemID=T.StockItemID)
	);

--SELECT * FROM R as sx
--WHERE NOT EXISTS (
--(SELECT p.y FROM S as p )
--EXCEPT
--(SELECT sp.y FROM  R as sp WHERE sp.x = sx.x ) );