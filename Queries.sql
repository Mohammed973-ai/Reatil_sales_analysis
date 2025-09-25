--Table definition
CREATE TABLE Retail_transaction(
	transactions_id	int PRIMARY KEY, 
	sale_date	DATE , 
	sale_time	TIME , 
	customer_id	INT,
	gender VARCHAR(10),
	age	tinyint , 
	category VARCHAR(50),
	quantiy	INT ,
	price_per_unit money,
	cogs	money,
	total_sale money
)
-- load data
bulk insert  Retail_transaction
from 'MY_DATA_PATH .csv'
WITH(fieldterminator =',',FIRSTROW = 2)
TRUNCATE TABLE Retail_transaction
-- check if it matches the original data
SELECT * FROM Retail_transaction
SELECT count(*) FROM Retail_transaction --same as the original file
SELECT * FROM Retail_transaction
WHERE transactions_id = 180 --same as the original table
------------------------------------------------------
-- count of each columns
DECLARE @sql NVARCHAR(max)
SELECT @sql = STRING_AGG('SELECT ''' + c.name + ''' AS [column name] , count('+c.name+') AS [count] FROM Retail_transaction',' UNION ALL ')
FROM Sys.columns c
WHERE c.object_id = OBJECT_ID('Retail_transaction')
EXEC sp_executesql @sql;
GO
-- Checking for null values
DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql = STRING_AGG( 'SELECT ''' + c.name + ''' AS ColumnName, COUNT(*) AS NullCount 
     FROM Retail_transaction WHERE ' + c.name + ' IS NULL ',' UNION ALL ')
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('Retail_transaction');
EXEC sp_executesql @sql;
/*we may leave them since I dont want them to affect some questions..
and in case we want to delete them : */
GO
DECLARE @sql NVARCHAR(max) = ''
SELECT @sql = STRING_AGG('DELETE FROM Retail_transaction
WHERE ' + sc.name + ' is NULL',';')
FROM sys.columns sc
WHERE sc.object_id = OBJECT_ID('Retail_transaction')
EXEC sp_executesql @sql
-- Next we check outliers
GO
DECLARE @sql NVARCHAR(MAX) = '';
DECLARE @cte_part NVARCHAR(MAX) = '';
DECLARE @select_part NVARCHAR(MAX) = '';
SELECT @cte_part = STRING_AGG( 
    'quartiles_' + c.name + ' AS (
        SELECT TOP(1)
            PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY ' + c.name + ') OVER () AS Q1,
            PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY ' + c.name + ') OVER () AS Q3
        FROM Retail_transaction
    ),
    iqr_fences_' + c.name + ' AS (
        SELECT 
            Q1 - 1.5 * (Q3 - Q1) AS lower_fence,
            Q3 + 1.5 * (Q3 - Q1) AS upper_fence
        FROM quartiles_' + c.name + '
    )',', ')
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('Retail_transaction')
  AND c.name IN ('quantiy', 'total_sale','age');
SELECT @select_part = STRING_AGG(
    'SELECT ''' + c.name + ''' AS [column name],
           COUNT(*) AS [number of outliers]
    FROM Retail_transaction, iqr_fences_' + c.name + '
    WHERE ' + c.name + ' < lower_fence OR ' + c.name + ' > upper_fence'
    , ' UNION ALL ')
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('Retail_transaction')
  AND c.name IN ('quantiy', 'total_sale','age');

SET @sql = 'WITH ' + @cte_part +' ' + @select_part;

EXEC(@sql);
-- We didnt find any outliers in quantity and total sale.
-- Data Exploration
--1.  How many transactions do we have ? 
SELECT COUNT(*) as sales_number FROM Retail_transaction 
--2. How many cutomers do we have ? 
SELECT count(DISTINCT(customer_id)) AS [number of customers]
FROM Retail_transaction
--3. what is the time period range for these transaction  ?
SELECT MIN(sale_date)[first date] , MAX(sale_date) AS [last date]
FROM Retail_transaction
--4. what kind of categories do we sell ?
SELECT DISTINCT(category) 
FROM Retail_transaction
--5. what is min and max total_sale
SELECT year(sale_date) AS[year] ,
MIN(total_sale) [min total_sale] ,
MAX(total_sale) [max total_sale] ,
AVG(total_sale) [avg total_sale] FROM Retail_transaction
GROUP BY (year(sale_date))
------------------------------------------------------------------------
--------------------Data analysis & findings----------------------------
------------------------------------------------------------------------
/* What is our annual revenue performance and how does it break down by product category?*/
GO
SELECT isnull(format(sale_date,'yyyy'),'total sales for ')AS [year],
isnull(isnull(category,'subtotal for '
+format(sale_date,'yyyy')),'all caregories ') 
AS[category],sum(total_sale) AS [total sales]
,count(*) AS [number of orders]
FROM Retail_transaction
GROUP BY cube(category,format(sale_date,'yyyy'))
/*what is the most selling category ? in terms of total sale
and number of orders */
GO
WITH sales_summary
AS 
(SELECT isnull(format(sale_date,'yyyy'),'total sales for ')AS [year],
isnull(isnull(category,'subtotal for '
+format(sale_date,'yyyy')),'all caregories ') 
AS[category],sum(total_sale) AS [total sales]
,count(*) AS [number of orders]
FROM Retail_transaction
GROUP BY category,format(sale_date,'yyyy'))
SELECT year , category ,[total sales] 
FROM (SELECT *, ROW_NUMBER()OVER(Partition by year Order by [total sales] desc)
AS RN 
FROM sales_summary) AS t
where RN = 1
--most selling category in terms of total sale
-- in 2022 is Beauty with 151510.00$
-- in 2023 is Electronics with total sales 162350$
WITH sales_summary
AS 
(SELECT isnull(format(sale_date,'yyyy'),'total sales for ')AS [year],
isnull(isnull(category,'subtotal for '
+format(sale_date,'yyyy')),'all caregories ') 
AS[category],sum(total_sale) AS [total sales]
,count(*) AS [number of orders]
FROM Retail_transaction
GROUP BY category,format(sale_date,'yyyy'))
SELECT year , category ,[number of orders]
FROM (SELECT *, ROW_NUMBER()OVER(Partition by year Order by [number of orders] desc)
AS RN 
FROM sales_summary) AS t
where RN = 1
-- most selling category in terms of number of orders
-- in 2022 is Clothing with  334 order
-- in 2023 is Clothing with  368 order
/* What is the net profit we made ? */
WITH netprofit
AS( SELECT * ,  (quantiy * price_per_unit)-cogs as [profit]
	FROM Retail_transaction
)
SELECT isnull(format(sale_date,'yyyy'),'total sales for ')AS [year],
isnull(isnull(category,'subtotal for '
+format(sale_date,'yyyy')),'all caregories ') 
AS[category],sum(profit) AS [net profit]
,count(*) AS [number of orders]
FROM netprofit
GROUP BY cube(category,format(sale_date,'yyyy'))
-- net profit in 2022 is			356815.60 $
-- net profit in 2023 is			365141.70 $
-- total net profit is				721957.30 $
-- net profit for Beauty is			228630.15 $
-- net profit for Clothing is 		246679.50 $
-- net profit for Electronics is	246647.65 $
/*What is the net profit per quarter */
GO
WITH add_quarter
AS (
	SELECT *, CASE 
	WHEN DATEPART(QUARTER, sale_date)  = 1 THEN 'Q1'
	WHEN DATEPART(QUARTER, sale_date)  = 2 THEN 'Q2'
	WHEN DATEPART(QUARTER, sale_date)  = 3 THEN 'Q3'
	WHEN DATEPART(QUARTER, sale_date)  = 4 THEN 'Q4'
	END AS [quarter] ,(quantiy*price_per_unit)-cogs AS [profit]
FROM Retail_transaction
),
profit_quarter
AS
(SELECT year(sale_date) as [year] ,quarter , sum(profit) AS [net profit] FROM add_quarter
GROUP BY year(sale_date) , quarter)
SELECT * FROM profit_quarter
PIVOT(SUM([net profit]) for quarter in ([Q1],[Q2],[Q3],[Q4]))
AS pvt
GO
/*what is our profit margins by product category */
SELECT 
    category,
    SUM(total_sale) as total_revenue,
    SUM((quantiy * price_per_unit) - cogs) as total_profit,
    concat(ROUND(
        SUM((quantiy * price_per_unit) - cogs) *100 / 
        SUM(total_sale), 2
    ),'%') as profit_margin_percent
FROM Retail_transaction
GROUP BY category
ORDER BY profit_margin_percent DESC;
-- all transactions where the total_sale is greater than 1000.
SELECT	COUNT(*) AS [premium transactions] from Retail_transaction
WHERE total_sale >= 1000
SELECT CONCAT(ROUND(AVG(total_sale),2),' ','$') AS avg_total_sale
FROM Retail_transaction
-- these kind of transactions may represent premium purchases
-- as the average sale is 456.54 $
/*the total number of transactions made by each gender in each category. with total sale*/
SELECT isnull(gender,'gross total') AS[gender],
isnull(isnull(category,'subtotal for ' + gender) 
,'all categories')AS [category],COUNT(*) AS [number of category],
sum(total_sale) AS [total sale]
FROM Retail_transaction
GROUP BY rollup(gender,category)
--Find out best selling month in each year
SELECT year , month , [total sale] FROM (SELECT year(sale_date) as [year],month(sale_date) as [month], sum(total_sale) as [total sale] , DENSE_RANK() over (partition by year(sale_date)  order by sum(total_sale) DESC) AS DR
FROM Retail_transaction
GROUP BY year(sale_date),month(sale_date)) as t
WHERE DR =1
-- it is december in both years maybe because it is chrismas season , also the clothing was the most selled category which is reasonable to say it is because of the chrismas season
-- who are our top 5 loyal customers ?
SELECT TOP(5)customer_id,Count(*) AS [Number of interaction],Sum(total_sale) AS [money spent] 
FROM Retail_transaction
GROUP BY customer_id
ORDER BY [Number of interaction] DESC
/*top 5 customers based on the highest total sales  */
SELECT TOP(5)customer_id , sum(total_sale) as [total sale per customer]
FROM Retail_transaction
GROUP BY customer_id
ORDER BY [total sale per customer] DESC
--find the number of unique customers who purchased items from each category.
GO
SELECT category , COUNT(DISTINCT(Customer_id)) AS [number of purchasers]
FROM Retail_transaction
GROUP BY category
--What are the orders in each shift ?  (Example Morning <12, Afternoon Between 12 & 17, Evening >17):
GO
WITH shifts AS (
    SELECT *,
           CASE
               WHEN sale_time < '12:00:00' THEN 'Morning'
               WHEN sale_time BETWEEN '12:00:00' AND '17:00:00' THEN 'Afternoon' 
               ELSE 'Evening'  -- Using ELSE instead of third condition
           END AS [shift]
    FROM Retail_transaction
)
SELECT shift , count(*) AS [number transaction] FROM shifts
GROUP BY shift

-- workload is heavy at evening
