Superstore Data Analysis SQL Project
This project involves analyzing sales data from a Superstore dataset using MySQL. The dataset provides insights into customer behavior, sales trends, product performance, and profitability. The analysis is performed through SQL queries that focus on data cleaning, table creation, loading data, and in-depth exploratory data analysis (EDA).

Project Overview
Data Loading and Table Creation
The superstore_sales table is created in MySQL with fields representing various sales, customer, and product attributes. Data is loaded from a CSV file using the LOAD DATA INFILE method, ensuring proper character encoding (UTF-8) and handling errors such as invalid character sets.

Data Cleaning

Handling Missing Values: Identifying and selecting rows with missing data in critical fields such as row_id, order_id, order_date, and sales.

Duplicate Data: Detecting and displaying duplicate rows based on order_id and row_id to ensure data integrity.

Exploratory Data Analysis (EDA)

Revenue and Profit Calculations: Calculating total sales revenue and total profit across various dimensions.

Units Sold, Revenue, and Profit by Category, Shipping Mode, and Region: Aggregating and analyzing sales data by different attributes such as product category, shipping mode, and region.

Time-Based Analysis: Breaking down data by year to track yearly trends in sales and profitability.

Advanced Analysis Using Window Functions

Most Profitable Regions: Using window functions to rank regions by profitability within each year, showing only the most profitable regions.

Most Profitable Categories by Region and Year: Identifying top-performing product categories across regions and years.

Top Products by Revenue per Year: Extracting the top 5 products with the highest revenue for each year using window functions for ranking.

State and Customer Insights

Top 20 Most Profitable States: Aggregating sales and profit by state, highlighting the most profitable regions.

Customer Count by City: Analyzing customer distribution across cities.

Key Techniques Used
SQL Window Functions: For ranking and partitioning data by year, region, and category.

Data Aggregation: Using GROUP BY to summarize data by different attributes like region, category, and time.

Data Cleaning: Ensuring the integrity of the dataset by handling missing values and duplicates.

Exploratory Data Analysis (EDA): Providing insights into sales, profits, and other key business metrics.

Tools and Technologies
MySQL: For database creation, table management, and querying.

CSV File: The dataset is loaded from a CSV file containing sales data.

