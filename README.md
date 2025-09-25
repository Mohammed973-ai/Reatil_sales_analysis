# Retail_Sales_Analysis

## Project Overview
Comprehensive retail sales analysis leveraging Microsoft SQL Server to extract actionable business insights from transaction data. This project demonstrates advanced SQL proficiency through data cleaning, exploratory data analysis (EDA), and complex query development. Features implementation of dynamic queries, CTEs, window functions, rolleup, cube ,pivot operations, and statistical analysis while developing a data-driven analytical mindset for business problem-solving.



## Objectives
1. Set up a retail sales database: Create and populate a retail sales database with the provided sales data.
2. Data Cleaning: Identify and remove any records with missing or null values if needed and handling  outliers.
3. Exploratory Data Analysis (EDA): Perform basic exploratory data analysis to understand the dataset.
4. Business Analysis: Use SQL to answer specific business questions and derive insights from the sales data.

<div align="center">
<img width="800" height="533" alt="image" src="https://github.com/user-attachments/assets/1ed7a6ef-67ad-4e7f-ab81-ac9790ed0527" />
</div>



## Project Structure

### 1.  Database Setup 
*  __Database_creation:__ The project starts with creating a database called Retail database.
*  __Table_creation:__  table called Retail_transactionsis created in the database
* __Data loading__:  the data then was added to the table using bulk insert. the data consists of transactions_id, sale_date, sale_time, customer_id, gender, age, category ,quantiy	 ,price_per_unit,cogs	,total_sale.
* __Data check__ : checks if the orginal data loaded correctly

 ```tsql 
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
);
```

```tsql
bulk insert  Retail_transaction
from 'my_data_path.csv'
WITH(fieldterminator =',',FIRSTROW = 2)
TRUNCATE TABLE Retail_transaction
```
```tsql
SELECT * FROM Retail_transaction
SELECT count(*) FROM Retail_transaction --same as the original file
SELECT * FROM Retail_transaction
WHERE transactions_id = 180 --same as the original table
```
### 2.  Data Exploration and cleaning

* __How many transactions do we have ?__
  ```tsql
    SELECT COUNT(*) as sales_number FROM Retail_transaction 
  ```
     ### Query Result

	<div style="margin-left: 70%;">
	  <table>
		<tr>
		  <th>sales_number</th>
		</tr>
		<tr>
		  <td>2000</td>
		</tr>
	  </table>
	</div>
 
*  __Count of each column__
  ```tsql
  	DECLARE @sql NVARCHAR(max)
	SELECT @sql = STRING_AGG('SELECT ''' + c.name + ''' AS [column name] , count('+c.name+') AS [count] FROM Retail_transaction',' UNION ALL ')
	FROM Sys.columns c
	WHERE c.object_id = OBJECT_ID('Retail_transaction')
	EXEC sp_executesql @sql;
  ```
   ### Query Result
<div style="margin-left: 70%;">
  <table>
    <tr>
      <th>Column name</th>
      <th>Count</th>
    </tr>
    <tr><td>transactions_id</td><td>2000</td></tr>
    <tr><td>sale_date</td><td>2000</td></tr>
    <tr><td>sale_time</td><td>2000</td></tr>
    <tr><td>customer_id</td><td>2000</td></tr>
    <tr><td>gender</td><td>2000</td></tr>
    <tr><td>age</td><td>1990</td></tr>
    <tr><td>category</td><td>2000</td></tr>
    <tr><td>quantiy</td><td>1997</td></tr>
    <tr><td>price_per_unit</td><td>1997</td></tr>
    <tr><td>cogs</td><td>1997</td></tr>
    <tr><td>total_sale</td><td>1997</td></tr>
  </table>
</div>


* __Count of null values__
  ```tsql
  	DECLARE @sql NVARCHAR(MAX) = '';
	SELECT @sql = STRING_AGG( 'SELECT ''' + c.name + ''' AS ColumnName, COUNT(*) AS NullCount 
	     FROM Retail_transaction WHERE ' + c.name + ' IS NULL ',' UNION ALL ')
	FROM sys.columns c
	WHERE c.object_id = OBJECT_ID('Retail_transaction');
	EXEC sp_executesql @sql;
  ```
	 ### Query Result
  <div style="margin-left: 70%;">
  <table>
    <tr>
      <th>Column name</th>
      <th>Null Count</th>
    </tr>
    <tr><td>transactions_id</td><td>0</td></tr>
    <tr><td>sale_date</td><td>0</td></tr>
    <tr><td>sale_time</td><td>0</td></tr>
    <tr><td>customer_id</td><td>0</td></tr>
    <tr><td>gender</td><td>0</td></tr>
    <tr><td>age</td><td>10</td></tr>
    <tr><td>category</td><td>0</td></tr>
    <tr><td>quantiy</td><td>3</td></tr>
    <tr><td>price_per_unit</td><td>3</td></tr>
    <tr><td>cogs</td><td>3</td></tr>
    <tr><td>total_sale</td><td>3</td></tr>
  </table>
</div>

 __here we may not drop the null count if it won't affect our analysis but to drop them we may use :__

```tsql
	DECLARE @sql NVARCHAR(max) = ''
	SELECT @sql = STRING_AGG('DELETE FROM Retail_transaction
	WHERE ' + sc.name + ' is NULL',';')
	FROM sys.columns sc
	WHERE sc.object_id = OBJECT_ID('Retail_transaction')
	EXEC sp_executesql @sql
```
	

* __Checking ouliers using IQR method__
  ```tsql
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
	  AND c.name IN ('quantiy', 'total_sale');
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
  ```
     ### Query Result
  
<div style="margin-left: 70%;">
  <table>
    <tr>
      <th>Column name</th>
      <th>Number of Outliers</th>
    </tr>
	      <tr><td>age</td><td>0</td></tr>
		  <tr><td>quantiy</td><td>0</td></tr>
		   <tr><td>total_sale</td><td>0</td></tr>
  </table>
</div>

  __We didn’t find any outliers.__


* __How many cutomers do we have ?__
  ```tsql
  	SELECT count(DISTINCT(customer_id))
  	FROM Retail_transaction
  ```
     ### Query Result
   <div style="margin-left: 70%;">
  <table>
    <tr>
      <th>Number of Customers</th>
    </tr>
    <tr>
      <td>155</td>
    </tr>
  </table>
</div>


* __What is the date range span of the transaction dataset?__
  ```tsql
	SELECT MIN(sale_date)[first date] , MAX(sale_date) AS [last date]
	FROM Retail_transaction
  ```
   ### Query Result
  <div style="margin-left: 70%;">
  <table>
    <tr>
      <th>First Date</th>
      <th>Last Date</th>
    </tr>
    <tr>
      <td>2022-01-01</td>
      <td>2023-12-31</td>
    </tr>
  </table>
</div>

  
*  __what kind of categories do we sell ?__
  ```tsql
	SELECT DISTINCT(category) 
	FROM Retail_transaction
  ```
   ### Query Result
  <div style="margin-left: 70%;">
  <table>
    <tr>
      <th>category</th>
    </tr>
    <tr>
      <td>Beauty</td>
   </tr>
	 <tr>
	  <td>Electronics</td>
   </tr>
	<tr>
      <td>Clothing</td>
   </tr>
  </table>
</div>
  
*  __what is min, max and avg of the total_sale?__
  ```tsql
	SELECT year(sale_date) AS[year] ,
	MIN(total_sale) [min total_sale] ,
	MAX(total_sale) [max total_sale] ,
	AVG(total_sale) [avg total_sale] FROM Retail_transaction
	GROUP BY (year(sale_date))
  ```
### Query Result
  <div style="margin-left: 70%;">
  <table>
    <tr>
      <th>year</th>
      <th>min total_sale</th>
      <th>max total_sale</th>
      <th>avg total_sale</th>	
    </tr>
    <tr>
	  <td>2022</td>
      <td>25.00</td>
      <td>2000.00</td>
      <td>463.96</td>
	  
		
   </tr>
   <tr>
	  <td>2023</td>
      <td>25.00</td>
      <td>2000.00</td>
      <td>449.4564</td> 
   </tr>
  </table>
</div>

### 3.  Data analysis and Findings

*  __What is our annual revenue performance and how does it break down by product category?__
  ```tsql
	SELECT isnull(format(sale_date,'yyyy'),'total sales for ')AS [year],
	isnull(isnull(category,'subtotal for '
	+format(sale_date,'yyyy')),'all caregories ') 
	AS[category],sum(total_sale) AS [total sales]
	,count(*) AS [number of orders]
	FROM Retail_transaction
	GROUP BY cube(category,format(sale_date,'yyyy'))
  ```
### Query Result
<div style="margin-left: 70%;">
  <table>
    <tr>
      <th>Year</th>
      <th>Category</th>
      <th>Total Sales</th>
      <th>Number of Orders</th>
    </tr>
    <tr><td>2022</td><td>Beauty</td><td>151510.00</td><td>314</td></tr>
    <tr><td>2022</td><td>Clothing</td><td>149855.00</td><td>334</td></tr>
    <tr><td>2022</td><td>Electronics</td><td>151460.00</td><td>331</td></tr>
    <tr><td>2022</td><td><strong>Subtotal for 2022</strong></td><td><strong>452825.00</strong></td><td><strong>979</strong></td></tr>
    <tr><td>2023</td><td>Beauty</td><td>135330.00</td><td>300</td></tr>
    <tr><td>2023</td><td>Clothing</td><td>161215.00</td><td>368</td></tr>
    <tr><td>2023</td><td>Electronics</td><td>162350.00</td><td>353</td></tr>
    <tr><td>2023</td><td><strong>Subtotal for 2023</strong></td><td><strong>458895.00</strong></td><td><strong>1021</strong></td></tr>
    <tr><td colspan="2"><strong>Total sales for all categories</strong></td><td><strong>911720.00</strong></td><td><strong>2000</strong></td></tr>
    <tr><td colspan="2"><strong>Total sales for Beauty</strong></td><td><strong>286840.00</strong></td><td><strong>614</strong></td></tr>
    <tr><td colspan="2"><strong>Total sales for Clothing</strong></td><td><strong>311070.00</strong></td><td><strong>702</strong></td></tr>
    <tr><td colspan="2"><strong>Total sales for Electronics</strong></td><td><strong>313810.00</strong></td><td><strong>684</strong></td></tr>
  </table>
</div>

* __what is the most selling category ? in terms of total sale__
  ```tsql
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
  ```
  ### Query Result
	<div style="margin-left: 70%;">
	  <table>
	    <tr>
	      <th>Year</th>
	      <th>Category</th>
	      <th>Total Sale</th>
	    </tr>
	    <tr><td>2022</td><td>Beauty</td><td>151510.00</td></tr>
	    <tr><td>2023</td><td>Electronics</td><td>162350.00</td></tr>
	  </table>
	</div>

* __what is the most selling category ? in terms of  number of orders__

  ```tsql
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
  ```
  ### Query Result
  <div style="margin-left: 70%;">
  <table>
    <tr>
      <th>Year</th>
      <th>Category</th>
      <th>Number of Orders</th>
    </tr>
    <tr><td>2022</td><td>Clothing</td><td>334</td></tr>
    <tr><td>2023</td><td>Clothing</td><td>368</td></tr>
  </table>
</div>


*  __What is the net profit we made ?__
    ```tsql
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
    
    ```
      ### Query Result
    <div style="margin-left: 40%;">
  <table>
    <tr>
      <th>Year</th>
      <th>Category</th>
      <th>Net Profit</th>
      <th>Number of Orders</th>
    </tr>
    <tr><td>2022</td><td>Beauty</td><td>118369.50</td><td>314</td></tr>
    <tr><td>2022</td><td>Clothing</td><td>118550.15</td><td>334</td></tr>
    <tr><td>2022</td><td>Electronics</td><td>119895.95</td><td>331</td></tr>
    <tr><td>2022</td><td><strong>Subtotal for 2022</strong></td><td><strong>356815.60</strong></td><td><strong>979</strong></td></tr>
    <tr><td>2023</td><td>Beauty</td><td>110260.65</td><td>300</td></tr>
    <tr><td>2023</td><td>Clothing</td><td>128129.35</td><td>368</td></tr>
    <tr><td>2023</td><td>Electronics</td><td>126751.70</td><td>353</td></tr>
    <tr><td>2023</td><td><strong>Subtotal for 2023</strong></td><td><strong>365141.70</strong></td><td><strong>1021</strong></td></tr>
    <tr><td colspan="2"><strong>Total Net Profit for all categories</strong></td><td><strong>721957.30</strong></td><td><strong>2000</strong></td></tr>
    <tr><td colspan="2"><strong>Total Net Profit for Beauty</strong></td><td><strong>228630.15</strong></td><td><strong>614</strong></td></tr>
    <tr><td colspan="2"><strong>Total Net Profit for Clothing</strong></td><td><strong>246679.50</strong></td><td><strong>702</strong></td></tr>
    <tr><td colspan="2"><strong>Total Net Profit for Electronics</strong></td><td><strong>246647.65</strong></td><td><strong>684</strong></td></tr>
  </table>
</div>

*  __What is the net profit per quarter__
    ```tsql
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
    ```
      ### Query Result
   <div style="margin-left: 100%;">
  <table border="1" cellpadding="5" cellspacing="0">
    <tr>
      <th>Year</th>
      <th>Q1</th>
      <th>Q2</th>
      <th>Q3</th>
      <th>Q4</th>
    </tr>
    <tr>
      <td>2022</td>
      <td>53469.85</td>
      <td>61838.25</td>
      <td>83752.00</td>
      <td>157755.50</td>
    </tr>
    <tr>
      <td>2023</td>
      <td>58250.05</td>
      <td>61406.20</td>
      <td>104940.10</td>
      <td>140545.35</td>
    </tr>
  </table>
</div>


*  __what is our profit margins by product category__
    ```tsql
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
    ```
   ### Query Result
<div style="margin-left: 70%;">
  <table border="1" cellpadding="5" cellspacing="0">
    <tr>
      <th>Category</th>
      <th>Total Revenue</th>
      <th>Total Profit</th>
      <th>Profit_Margin_percent</th>
    </tr>
    <tr>
      <td>Beauty</td>
      <td>286,840.00</td>
      <td>228,630.15</td>
      <td>79.71%</td>
    </tr>
    <tr>
      <td>Clothing</td>
      <td>311,070.00</td>
      <td>246,679.50</td>
      <td>79.30%</td>
    </tr>
    <tr>
      <td>Electronics</td>
      <td>313,810.00</td>
      <td>246,647.65</td>
      <td>78.60%</td>
    </tr>
  </table>
</div>


*  __all transactions where the total_sale is greater than 1000.__
    ```tsql
    SELECT	COUNT(*) from Retail_transaction
	WHERE total_sale >= 1000
    ```
    ### Query Result
    <div style="margin-left: 70%;">
  <table border="1" cellpadding="5" cellspacing="0">
    <tr>
      <th>premium transactions</th>
    </tr>
    <tr>
      <td>404</td>
    </tr>
  </table>
</div>


 ```tsql
     SELECT CONCAT(ROUND(AVG(total_sale),2),' ','$')
	FROM Retail_transaction
 ```
      
### Query Result
   <div style="margin-left: 70%;">
  <table border="1" cellpadding="5" cellspacing="0">
    <tr>
      <th>Avg Total Sale</th>
    </tr>
    <tr>
      <td>456.54 $</td>
    </tr>
  </table>
</div>


*  __the total number of transactions and total sale made by each gender in each category__
    ```tsql
    SELECT isnull(gender,'gross total') AS[gender],
	isnull(isnull(category,'subtotal for ' + gender) 
	,'all categories')AS [category],COUNT(*) AS [number of category],
	sum(total_sale) AS [total sale]
	FROM Retail_transaction
	GROUP BY rollup(gender,category)
    ```
     ### Query Result
   <div style="margin-left: 70%;">
  <table border="1" cellpadding="5" cellspacing="0">
    <tr>
      <th>Gender</th>
      <th>Category</th>
      <th>Number of Category</th>
      <th>Total Sale</th>
    </tr>
    <tr>
      <td>Female</td>
      <td>Beauty</td>
      <td>332</td>
      <td>149470.00</td>
    </tr>
    <tr>
      <td>Female</td>
      <td>Clothing</td>
      <td>348</td>
      <td>162460.00</td>
    </tr>
    <tr>
      <td>Female</td>
      <td>Electronics</td>
      <td>340</td>
      <td>153470.00</td>
    </tr>
    <tr>
      <td>Female</td>
      <td><strong>Subtotal for Female</strong></td>
      <td><strong>1020</strong></td>
      <td><strong>465400.00</strong></td>
    </tr>
    <tr>
      <td>Male</td>
      <td>Beauty</td>
      <td>282</td>
      <td>137370.00</td>
    </tr>
    <tr>
      <td>Male</td>
      <td>Clothing</td>
      <td>354</td>
      <td>148610.00</td>
    </tr>
    <tr>
      <td>Male</td>
      <td>Electronics</td>
      <td>344</td>
      <td>160340.00</td>
    </tr>
    <tr>
      <td>Male</td>
      <td><strong>Subtotal for Male</strong></td>
      <td><strong>980</strong></td>
      <td><strong>446320.00</strong></td>
    </tr>
    <tr>
      <td colspan="2"><strong>Gross Total (All Categories)</strong></td>
      <td><strong>2000</strong></td>
      <td><strong>911720.00</strong></td>
    </tr>
  </table>
</div>

*  __what is the best selling month in each year?__
    ```tsql
    SELECT year , month , [total sale] FROM (SELECT year(sale_date) as [year],month(sale_date) as [month], sum(total_sale) as [total sale] , DENSE_RANK() over (partition by year(sale_date)  order by sum(total_sale) DESC) AS DR
	FROM Retail_transaction
	GROUP BY year(sale_date),month(sale_date)) as t
	WHERE DR =1
    ```
     ### Query Result
   <div style="margin-left: 40%;">
  <table border="1" cellpadding="5" cellspacing="0">
    <tr>
      <th>Year</th>
      <th>Month</th>
      <th>Total Sale</th>
    </tr>
    <tr>
      <td>2022</td>
      <td>12</td>
      <td>72880.00</td>
    </tr>
    <tr>
      <td>2023</td>
      <td>12</td>
      <td>69145.00</td>
    </tr>
  </table>
</div>


__it is december in both years maybe because it is chrismas season , also the clothing was the most selled category which is reasonable to say it is because of the chrismas season__

*  __who are our top 5 loyal customers ?__
    ```tsql
    SELECT TOP(5)customer_id,Count(*) AS [Number of interaction],Sum(total_sale) AS [money spent] 
	FROM Retail_transaction
	GROUP BY customer_id
	ORDER BY [Number of interaction] DESC
    ```
     ### Query Result
   <div style="margin-left: 40%;">
  <table border="1" cellpadding="5" cellspacing="0">
    <tr>
      <th>Customer ID</th>
      <th>Number of Interactions</th>
      <th>Money Spent</th>
    </tr>
    <tr>
      <td>3</td>
      <td>76</td>
      <td>38440.00</td>
    </tr>
    <tr>
      <td>1</td>
      <td>76</td>
      <td>30750.00</td>
    </tr>
    <tr>
      <td>4</td>
      <td>73</td>
      <td>23580.00</td>
    </tr>
    <tr>
      <td>2</td>
      <td>69</td>
      <td>25295.00</td>
    </tr>
    <tr>
      <td>5</td>
      <td>63</td>
      <td>30405.00</td>
    </tr>
  </table>
</div>

*  __top 5 customers based on the highest total sales__
    ```tsql
    SELECT TOP(5)customer_id , sum(total_sale) as [total sale per customer]
	FROM Retail_transaction
	GROUP BY customer_id
	ORDER BY [total sale per customer] DESC
    ```
     ### Query Result
   <div style="margin-left: 40%;">
  <table border="1" cellpadding="5" cellspacing="0">
    <tr>
      <th>Customer ID</th>
      <th>Highest Total Sale</th>
    </tr>
    <tr>
      <td>3</td>
      <td>38440.00</td>
    </tr>
    <tr>
      <td>1</td>
      <td>30750.00</td>
    </tr>
    <tr>
      <td>5</td>
      <td>30405.00</td>
    </tr>
    <tr>
      <td>2</td>
      <td>25295.00</td>
    </tr>
    <tr>
      <td>4</td>
      <td>23580.00</td>
    </tr>
  </table>
</div>

*  __What are the orders in each shift ?  (Example Morning <12, Afternoon Between 12 & 17, Evening >17):__
    ```tsql
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
    ```
 ### Query Result
<div style="margin-left: 70%;">
  <table border="1" cellpadding="5" cellspacing="0">
    <tr>
      <th>Shift</th>
      <th>Number of Interactions</th>
    </tr>
    <tr>
      <td>Evening</td>
      <td>1275</td>
    </tr>
    <tr>
      <td>Morning</td>
      <td>561</td>
    </tr>
    <tr>
      <td>Afternoon</td>
      <td>164</td>
    </tr>
  </table>
</div>

   

