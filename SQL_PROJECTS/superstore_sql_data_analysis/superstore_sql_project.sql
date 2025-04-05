/* Creating the superstore table on MySQL*/

CREATE TABLE analyst_raph.superstore_sales (
    row_id INT PRIMARY KEY,
    order_id VARCHAR(20),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(50),
    customer_id VARCHAR(20),
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    country VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    region VARCHAR(50),
    product_id VARCHAR(20),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(255),
    sales DECIMAL(10, 2),
    quantity INT,
    discount DECIMAL(5, 2),
    profit DECIMAL(10, 2)
);

SHOW FULL COLUMNS FROM analyst_raph.superstore_sales ;

/* Enable local_infile for the current session so that we can load our data which is in a local directory*/
SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';



 
/* If the above error throws this error:*/
/* Error Code: 1290. The MySQL server is running with the --secure-file-priv option so it cannot execute this statement*/
/*run the below code to check the allowed directory and move the file to that diectory*/
# Example:
#'secure_file_priv', 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\'

/* My thoughts on some of the errors I encountered*/

SHOW VARIABLES LIKE 'secure_file_priv';
-- Check the current character set of the database
SHOW VARIABLES LIKE 'character_set_%';
-- If not utf8mb4, change the database to utf8mb4
ALTER DATABASE analyst_raph CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- Check the character set of the column
-- Update the column to utf8mb4 if necessary
ALTER TABLE analyst_raph.superstore_sales MODIFY COLUMN product_name TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
SET NAMES 'utf8mb4';

/* IF you keep getting this error Error Code: 1300. Invalid utf8mb4 character string: '...'*/
/* Just open the file on notepad and save the file with the encoding to utf-8 and then rerun the code below*/

/* Load data using the MySQL infile method*/
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Superstore.csv'
INTO TABLE analyst_raph.superstore_sales
CHARACTER SET utf8mb4 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(row_id, order_id, order_date, ship_date, ship_mode,
 customer_id, customer_name, segment, country, city, state, postal_code,
 region, product_id, category, sub_category, product_name,
 sales, quantity, discount, profit);
 
 --  EDA
 -- check if the data loaded successfuly
 SELECT *
 FROM analyst_raph.superstore_sales 
 LIMIT 10;
 
 --  Check for Missing Values
SELECT *
FROM  analyst_raph.superstore_sales
WHERE row_id IS NULL 
	OR order_id IS NULL 
    OR order_date IS NULL 
    OR ship_date IS NULL 
    OR sales IS NULL;

--  Check for duplicate rows
WITH DuplicateRows AS (
    SELECT order_id, row_id
    FROM analyst_raph.superstore_sales
    GROUP BY order_id, row_id
    HAVING COUNT(*) > 1
)
SELECT s.*
FROM analyst_raph.superstore_sales s
JOIN DuplicateRows d
    ON s.order_id = d.order_id
    AND s.row_id = d.row_id
ORDER BY s.order_id, s.row_id;

/*Further Analysis*/
/* Revenue & Profit Calculations*/
-- Total Sales Revenue
SELECT ROUND(SUM(sales),2)
FROM analyst_raph.superstore_sales;

-- Total Profit
SELECT ROUND(SUM(profit),2)
FROM analyst_raph.superstore_sales;

-- Units_sold, Revenue, Profit by Order_Year
SELECT 
    EXTRACT(YEAR FROM order_date) AS order_year,
    ROUND(SUM(quantity), 2) AS units_sold,
    ROUND(SUM(sales), 2) AS total_sales_revenue,
    ROUND(SUM(profit),2) AS total_profit
FROM 
    analyst_raph.superstore_sales
GROUP BY 
    EXTRACT(YEAR FROM order_date)
ORDER BY 
    order_year;

-- Units_sold, Revenue, Profit by Category
SELECT 
    category,
    ROUND(SUM(quantity), 2) AS units_sold,
    ROUND(SUM(sales), 2) AS total_sales_revenue,
    ROUND(SUM(profit),2) AS total_profit
FROM 
    analyst_raph.superstore_sales
GROUP BY 
    category
;

-- Units_sold, Revenue, Profit by Shipping Mode
SELECT 
    ship_mode,
    ROUND(SUM(quantity), 2) AS units_sold,
    ROUND(SUM(sales), 2) AS total_sales_revenue,
    ROUND(SUM(profit),2) AS total_profit
FROM 
    analyst_raph.superstore_sales
GROUP BY 
    ship_mode
ORDER BY
	total_profit DESC
;
-- Units_sold, Revenue, Profit by region,year 
SELECT 
    EXTRACT(YEAR FROM order_date) AS order_year,
    region,
    ROUND(SUM(quantity), 2) AS units_sold,
    ROUND(SUM(sales), 2) AS total_sales_revenue,
    ROUND(SUM(profit), 2) AS total_profit
FROM 
    analyst_raph.superstore_sales
GROUP BY 
    order_year, region
ORDER BY 
    order_year, total_profit DESC;
    
-- Most profitable regions by year
WITH ranked_regions AS (
    SELECT 
        EXTRACT(YEAR FROM order_date) AS order_year,
        region,
        ROUND(SUM(quantity), 2) AS units_sold,
        ROUND(SUM(sales), 2) AS total_sales_revenue,
        ROUND(SUM(profit), 2) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM order_date) ORDER BY SUM(profit) DESC) AS region_rank
    FROM 
        analyst_raph.superstore_sales
    GROUP BY 
        order_year, region
)
SELECT 
    order_year,
    region,
    units_sold,
    total_sales_revenue,
    total_profit
FROM 
    ranked_regions
WHERE 
    region_rank = 1
ORDER BY 
    order_year;
-- most profitable categories by region and year
WITH RankedCategories AS (
    SELECT 
        EXTRACT(YEAR FROM order_date) AS order_year,
        region,
        category,
        ROUND(SUM(quantity), 2) AS units_sold,
        ROUND(SUM(sales), 2) AS total_sales_revenue,
        ROUND(SUM(profit), 2) AS total_profit,
        ROW_NUMBER() OVER (
            PARTITION BY EXTRACT(YEAR FROM order_date), region 
            ORDER BY SUM(profit) DESC
        ) AS category_rank
    FROM 
        analyst_raph.superstore_sales
    GROUP BY 
        order_year, region, category
)
SELECT 
    order_year,
    region,
    category,
    units_sold,
    total_sales_revenue,
    total_profit
FROM 
    RankedCategories
WHERE 
    category_rank = 1
ORDER BY 
    order_year, region;

-- top 20 most profitable states --all time
SELECT 
    state,
    ROUND(SUM(quantity), 2) AS units_sold,
    ROUND(SUM(sales), 2) AS total_sales_revenue,
    ROUND(SUM(profit),2) AS total_profit
FROM 
    analyst_raph.superstore_sales
GROUP BY 
    state
ORDER BY
	total_profit DESC
LIMIT 20
;
-- Customer count by state
SELECT city,
		COUNT(DISTINCT customer_id) AS customer_count
FROM analyst_raph.superstore_sales
GROUP BY 1
ORDER BY 2 DESC
;

-- top 5 products by revenue in each year
WITH RankedProducts AS (
    SELECT 
        EXTRACT(YEAR FROM order_date) AS order_year,
        product_name,
        category,
        ROUND(SUM(sales), 2) AS total_sales_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY EXTRACT(YEAR FROM order_date) 
            ORDER BY SUM(sales) DESC
        ) AS product_rank
    FROM 
        analyst_raph.superstore_sales
    GROUP BY 
        order_year, product_name, category
)
SELECT 
    order_year,
    product_name,
    category,
    total_sales_revenue
FROM 
    RankedProducts
WHERE 
    product_rank <= 5
ORDER BY 
    order_year, total_sales_revenue DESC;
