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
