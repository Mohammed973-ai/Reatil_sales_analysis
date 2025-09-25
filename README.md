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

1. ### Database Setup 
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
2. ### Data Exploration and cleaning

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
	  AND c.name IN ('quantiy', 'total_sale');
	
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
    <tr><td>quantiy</td><td>0</td></tr>
    <tr><td>total_sale</td><td>0</td></tr>
  </table>
</div>

__We didnt find any outliers in quantity and total sale.__

* __How many cutomers do we have ?__
  
* __What is the date range span of the transaction dataset?__
*  __what kind of categories do we sell ?__
*  __what is min, max and avg of the total_sale?__
   

