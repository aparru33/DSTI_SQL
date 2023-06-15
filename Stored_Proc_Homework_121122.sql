--Design a stored procedure which generates a report of the total number of 
--	1. Invoiced orders (one column)
--	2. Non-invoiced orders (one column)
--	3. All per year, over a range of year.
--The output must have only one row and the number of columns of years between start and end. 
--The procedures receives a "start" and "end" year, which must be valid (end >= start) and constructs a dynamic query.
CREATE OR ALTER PROCEDURE GENERATE_REPORT
	@startDate int, @endDate int

AS
BEGIN
	SET NOCOUNT ON;
	DECLARE
	@nb_invoiced_order int,
	@nb_non_invoiced_order int,
	@filter NVARCHAR(MAX),
	@query NVARCHAR(MAX),
	@finalQuery NVARCHAR(MAX),
	@iterativeYear int,
	@minYear int,
	@maxYear int,
	@year int,
	@ordered int,
	@not_ordered int,
	@tot int,

	--method3
	@year_str nvarchar(5),
	@select_query nvarchar(max),
	@from_query nvarchar(max)

	BEGIN
		--2 solutions:
		-- 1) select result of multiple query, one for each year --> n request on all table of the db for n year
		-- 2) select all the useful data with one query --> n query on the n line of the database for n year
		-- --> see the efficiency of the two method to compare
		select @minYear=min(Year(o.OrderDate)), @maxYear=max(Year(o.OrderDate)) from Sales.Orders as o; 
		set @finalQuery='SELECT * from ';
		IF @endDate>@startDate
		BEGIN
		if @startDate<@minYear
			set @startDate=@minYear;
		if @maxYear< @endDate
			set @endDate=@maxYear;

		set @iterativeYear=@startDate;

		--methode 1:
		while @iterativeYear<=@endDate
		BEGIN
			set @query ='(select count(invoiced_orderID) as nb_invoiced_order_'+CAST(@iterativeYear AS nvarchar)+', count(non_invoiced_orderID) as nb_not_invoiced_order_'+CAST(@iterativeYear AS nvarchar)+', count(*) as total_'+CAST(@iterativeYear AS nvarchar)+' 
			from (
				select o_invoiced.OrderID as invoiced_orderID,IIF(o_non_invoiced.OrderID is null,o.OrderID,NULL) as non_invoiced_orderID,YEAR(o.OrderDate) year_ordered 
				from Sales.Orders as o
				left join Sales.Invoices as o_invoiced on o.OrderID=o_invoiced.OrderID
				left join Sales.Invoices as o_non_invoiced on o.OrderID=o_non_invoiced.OrderID 
				where YEAR(o.OrderDate)=' + CAST(@iterativeYear AS nvarchar) +') as T
				group by year_ordered ) as ['+CAST(@iterativeYear AS nvarchar)+'],'
			set @finalQuery=CONCAT(@finalQuery,@query );
			set @iterativeYear+=1;
		END
		SET @finalQuery=LEFT(@finalQuery, LEN(@finalQuery) - 1);
		execute sp_executesql @finalQuery;
		END;

		----methode 2
		
		--	CREATE TABLE #temp_tab( year_ordered INT, nb_invoiced_order int, nb_not_invoiced_order int, total int);
			
		--	declare curs cursor for 
		--	(select year_ordered,count(invoiced_orderID) as nb_invoiced_order, count(non_invoiced_orderID) as nb_not_invoiced_order, count(*) as total
		--	from (
		--		select o_invoiced.OrderID as invoiced_orderID,IIF(o_non_invoiced.OrderID is null,o.OrderID,NULL) as non_invoiced_orderID,YEAR(o.OrderDate) as year_ordered 
		--		from Sales.Orders as o
		--		left join Sales.Invoices as o_invoiced on o.OrderID=o_invoiced.OrderID
		--		left join Sales.Invoices as o_non_invoiced on o.OrderID=o_non_invoiced.OrderID 
		--		where YEAR(o.OrderDate)>= @startDate and YEAR(o.OrderDate)<=@endDate) as T
		--		group by year_ordered);
			
		--	OPEN curs
		--	FETCH NEXT FROM curs into @year,@ordered,@not_ordered, @tot
		--	WHILE @@FETCH_STATUS=0
		--	BEGIN
		--		insert into #temp_tab values (@year,@ordered,@not_ordered, @tot);
		--		FETCH NEXT FROM curs into @year,@ordered,@not_ordered, @tot
		--	END
		--	close curs;
		--	DEALLOCATE curs;
		--	while @iterativeYear<=@endDate
		--	BEGIN
		--		set @query ='(select nb_invoiced_order as nb_invoiced_order_'+CAST(@iterativeYear AS nvarchar)+', nb_not_invoiced_order as nb_not_invoiced_order_'+CAST(@iterativeYear AS nvarchar)
		--			+', total as total_'+CAST(@iterativeYear AS nvarchar)
		--			+' from #temp_tab'
		--			+' where year_ordered=' + CAST(@iterativeYear AS nvarchar) +') as ['+CAST(@iterativeYear AS nvarchar)+'],';
		--		set @finalQuery=CONCAT(@finalQuery,@query );
		--		set @iterativeYear+=1;
		--	END;

		--	SET @finalQuery=LEFT(@finalQuery, LEN(@finalQuery) - 1);
		--	Print @finalQuery;
		--	execute sp_executesql @finalQuery;
		--END;
			--end method 2

		--method 3 whith key word with for declaring temporary table
		--to do and test
		--set @query='with '+
		--'src as (select year_ordered,count(invoiced_orderID) as nb_invoiced_order, count(non_invoiced_orderID) as nb_not_invoiced_order, count(*) as total
		--			from (
		--				select o_invoiced.OrderID as invoiced_orderID,IIF(o_non_invoiced.OrderID is null,o.OrderID,NULL) as non_invoiced_orderID,YEAR(o.OrderDate) as year_ordered 
		--				from Sales.Orders as o
		--				left join Sales.Invoices as o_invoiced on o.OrderID=o_invoiced.OrderID
		--				left join Sales.Invoices as o_non_invoiced on o.OrderID=o_non_invoiced.OrderID 
		--				where YEAR(o.OrderDate)>='+CAST( @startDate as varchar)+' and YEAR(o.OrderDate)<='+cast(@endDate as varchar)+') as T
		--				group by year_ordered)'
		--set @select_query ='select '
		--set @from_query=' from '
		--while @iterativeYear<=@endDate
		--BEGIN
		--	set @year_str=cast(@iterativeYear as varchar)
		--	set @select_query =CONCAT(@select_query,
		--	'nb_invoiced_order_'+@year_str+',nb_not_invoiced_order_'+@year_str+',total_'+@year_str+',' );
		--	set @from_query=CONCAT(@from_query,
		--		'(select nb_invoiced_order as nb_invoiced_order_'+@year_str+' , nb_not_invoiced_order as nb_not_invoiced_order_'+@year_str
		--		+',total as total_'+@year_str+' from src where year_ordered='+@year_str+') as T'+@year_str+', ')
		--	set @iterativeYear+=1;
		--END
		--SET @select_query=LEFT(@select_query, LEN(@select_query) - 1);
		--SET @from_query=LEFT(@from_query, LEN(@from_query) - 1);
		--set @finalQuery=@query+@select_query+@from_query
		--print @finalQuery
		--execute sp_executesql @finalQuery;
		--END
		
		ELSE
		BEGIN
			-- KO, date range is invalid
			PRINT CONCAT('Start date: ' , CAST(@startDate AS nvarchar) , ' is greater than End Date: ', CAST(@endDate AS nvarchar));
			THROW 51000, 'Invalid date range in procedure GENERATE_RAPPORT.', 1;   
		END;
	END;
END;
GO
EXECUTE [dbo].[GENERATE_REPORT] 2014 , 2020