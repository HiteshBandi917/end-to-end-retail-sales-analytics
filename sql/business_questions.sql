CREATE DATABASE MyDatabase;
GO
USE MyDatabase;
GO   
CREATE TABLE sales_cleaned (
order_id VARCHAR(50) NOT NULL PRIMARY KEY,
    order_date varchar(50),
    customer_id VARCHAR(50),
    product_id VARCHAR(50),
    store_id VARCHAR(50),
    sales_channel VARCHAR(50),
    quantity VARCHAR(50),
    unit_price VARCHAR(50),
    discount_pct VARCHAR(50),
    total_amount VARCHAR(50)
);
BULK INSERT sales_cleaned
FROM 'C:\Users\hites\OneDrive\Desktop\Retail_Sales_Capstone\data\cleaned\sales_cleaned.csv'
WITH (
    FIRSTROW = 2,
  
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);
SELECT * FROM sales_cleaned ;
ALTER TABLE sales_cleaned
ALTER COLUMN order_date DATE;
ALTER TABLE sales_cleaned
ALTER COLUMN quantity INT;

ALTER TABLE sales_cleaned
ALTER COLUMN unit_price DECIMAL(10,2);

ALTER TABLE sales_cleaned
ALTER COLUMN discount_pct DECIMAL(5,2);

ALTER TABLE sales_cleaned
ALTER COLUMN total_amount DECIMAL(10,2);

EXEC sp_help sales_cleaned;
DELETE FROM sales_cleaned
WHERE order_id IS NULL
   OR order_date IS NULL
   OR quantity IS NULL
   OR total_amount IS NULL;
select * from sales_cleaned;

CREATE TABLE customers_cleaned (
customer_id     varchar(50) NOT NULL PRIMARY KEY,
first_name      varchar(50),
last_name       varchar(50),
gender          varchar(50),
age            varchar(50),
signup_date     varchar(50),
region          varchar(50),
);
BULK INSERT customers_cleaned
FROM 'C:\Users\hites\OneDrive\Desktop\Retail_Sales_Capstone\data\cleaned\customers_cleaned.csv'
WITH (
    FIRSTROW = 2,
  
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);
select * from customers_cleaned;
EXEC sp_help customers_cleaned;
UPDATE customers_cleaned
SET age = TRY_CAST(age AS INT);

UPDATE customers_cleaned
SET signup_date = TRY_CONVERT(DATE, signup_date, 101);
ALTER TABLE customers_cleaned
ALTER COLUMN signup_date DATE;
EXEC sp_help customers_cleaned;
  DELETE FROM customers_cleaned
WHERE customer_id IS NULL
   OR age IS NULL 
   OR first_name IS NULL 
   OR Last_name IS NULL 
   OR region IS NULL 
   OR gender IS NULL
   OR signup_date IS NULL;
SELECT * from customers_cleaned

CREATE TABLE products_cleaned(
product_id       varchar(50) NOT NULL PRIMARY KEY,
product_name     varchar(50),
category         varchar(50),
brand            varchar(50),
cost_price      varchar(50),
unit_price      varchar(50),
margin_pct      varchar(50),
);
BULK INSERT products_cleaned
FROM 'C:\Users\hites\OneDrive\Desktop\Retail_Sales_Capstone\data\cleaned\products_cleaned.csv'
WITH (
    FIRSTROW = 2,
  
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);
SELECT * from products_cleaned;
EXEC sp_help products_cleaned;
UPDATE products_cleaned
SET 
    cost_price = TRY_CAST(cost_price AS DECIMAL(10,2)),
    unit_price = TRY_CAST(unit_price AS DECIMAL(10,2)),
    margin_pct = TRY_CAST(margin_pct AS DECIMAL(5,2));
    ALTER TABLE products_cleaned ALTER COLUMN cost_price DECIMAL(10,2);

ALTER TABLE products_cleaned ALTER COLUMN unit_price DECIMAL(10,2);

ALTER TABLE products_cleaned ALTER COLUMN margin_pct DECIMAL(5,2);
    EXEC sp_help products_cleaned;
    DELETE FROM products_cleaned
WHERE product_id IS NULL
   OR cost_price IS NULL
   OR product_name IS NULL
   OR category IS NULL
   OR unit_price IS NULL
   OR brand IS NULL;
   SELECT * from products_cleaned;
    


CREATE TABLE returns_cleaned(
return_id               VARCHAR(50)NOT NULL PRIMARY KEY,
order_id                  VARCHAR(50),
return_date      VARCHAR(50),
return_reason          VARCHAR(50),
);
   BULK INSERT returns_cleaned
FROM 'C:\Users\hites\OneDrive\Desktop\Retail_Sales_Capstone\data\cleaned\returns_cleaned.csv'
WITH (
    FIRSTROW = 2,
  
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
); 

UPDATE returns_cleaned
SET return_date = TRY_CONVERT(DATE, return_date, 120);
ALTER TABLE returns_cleaned
ALTER COLUMN return_date DATE;
 EXEC sp_help returns_cleaned;
    DELETE FROM returns_cleaned
WHERE return_id IS NULL
   OR order_id IS NULL
   OR return_date IS NULL;
   select * from returns_cleaned;
   
select* from stores_cleaned;
 EXEC sp_help stores_cleaned;


   ALTER TABLE sales_cleaned
ADD CONSTRAINT fk_customer
FOREIGN KEY (customer_id) REFERENCES customers_cleaned(customer_id);

ALTER TABLE sales_cleaned
ADD CONSTRAINT fk_product
FOREIGN KEY (product_id) REFERENCES products_cleaned(product_id);

ALTER TABLE sales_cleaned
ADD CONSTRAINT fk_store
FOREIGN KEY (store_id) REFERENCES stores_cleaned(store_id);

ALTER TABLE returns_cleaned
ADD CONSTRAINT fk_order
FOREIGN KEY (order_id) REFERENCES sales_cleaned(order_id);

------BUSINESS QUESTIONS
---QUESTION 1
---total revenue generated in the last 12 months
SELECT 
    SUM(total_amount) AS [Sales for Last 12 Months]
FROM sales_cleaned
WHERE order_date >= DATEADD(MONTH, -12, GETDATE());
 
---QUESTION 2

print'Top 5 Best selling products by category';
SELECT 
    p.product_name,
    SUM(s.quantity) AS total_quantity
FROM sales_cleaned s
JOIN products_cleaned p
    ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_quantity DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;
 
 ---QUESTION 3
 print'Customers from each Region';
 SELECT 
    region,
    COUNT(DISTINCT customer_id) AS customer_count
FROM customers_cleaned
GROUP BY region
ORDER BY customer_count DESC;

---QUESTION 4
PRINT'Store with the highest Profit in the past Year';
SELECT TOP 1
    st.store_name,
    SUM(s.profit) AS total_profit
FROM sales_cleaned s
JOIN stores_cleaned st
    ON s.store_id = st.store_id
WHERE s.order_date >= DATEADD(MONTH, -12, GETDATE())
GROUP BY st.store_name
ORDER BY total_profit DESC;


---QUESTION 5
PRINT'Return Rate by Product category';
SELECT 
    p.category,
    ROUND(
        COUNT(DISTINCT r.order_id) * 100.0 
        / COUNT(DISTINCT s.order_id), 2
    ) AS return_rate_pct
FROM sales_cleaned s
LEFT JOIN returns_cleaned r
    ON s.order_id = r.order_id
JOIN products_cleaned p
    ON s.product_id = p.product_id
GROUP BY p.category
ORDER BY return_rate_pct DESC;

---QUESTION 6
PRINT'Average Revenue per Customer by Age Group'; 
  SELECT 
    CASE 
        WHEN age < 25 THEN 'Under 25'
        WHEN age BETWEEN 25 AND 40 THEN '25-40'
        WHEN age BETWEEN 41 AND 60 THEN '41-60'
        ELSE '60+'
    END AS age_group,
    AVG(total_spent) AS avg_revenue
FROM (
    SELECT 
        c.customer_id,
        c.age,
        SUM(s.total_amount) AS total_spent
    FROM customers_cleaned c
    JOIN sales_cleaned s 
        ON c.customer_id = s.customer_id
    GROUP BY c.customer_id, c.age
) t
GROUP BY 
    CASE 
        WHEN age < 25 THEN 'Under 25'
        WHEN age BETWEEN 25 AND 40 THEN '25-40'
        WHEN age BETWEEN 41 AND 60 THEN '41-60'
        ELSE '60+'
    END;
 
 ---QUESTION 7
 PRINT'Sales Channel (Online vs In-Store) is more Profitable on Average';
 SELECT 
    sales_channel,
    AVG(profit) AS avg_profit
FROM sales_cleaned
GROUP BY sales_channel
ORDER BY avg_profit DESC;

---QUESTION 8
PRINT'Monthly Profit changed over the last 2 Years by Region';
SELECT 
    DATEFROMPARTS(YEAR(s.order_date), MONTH(s.order_date), 1) AS month,
    c.region,
    SUM(s.profit) AS total_profit
FROM sales_cleaned s
JOIN customers_cleaned c
    ON s.customer_id = c.customer_id
WHERE s.order_date >= DATEADD(YEAR, -2, GETDATE())
GROUP BY 
    DATEFROMPARTS(YEAR(s.order_date), MONTH(s.order_date), 1),
    c.region
ORDER BY 
    month, c.region;

---QUESTION 9
PRINT'Top 3 Products with the highest Return rate in each Category';
WITH return_rates AS (
    SELECT 
        p.category,
        p.product_name,
        COUNT(DISTINCT r.return_id) * 1.0 
        / COUNT(DISTINCT s.order_id) AS return_rate
    FROM sales_cleaned s
    LEFT JOIN returns_cleaned r
        ON s.order_id = r.order_id
    JOIN products_cleaned p
        ON s.product_id = p.product_id
    GROUP BY p.category, p.product_name
),

ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY category ORDER BY return_rate DESC) AS rnk
    FROM return_rates
)

SELECT *
FROM ranked
WHERE rnk <= 3
ORDER BY category, rnk;

---QUESTION 10

PRINT'Top 5 customers by profit';
SELECT TOP 5
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM((s.unit_price - p.cost_price) * s.quantity) AS total_profit,
    DATEDIFF(YEAR, c.signup_date, GETDATE()) AS tenure_years
FROM customers_cleaned c
JOIN sales_cleaned s 
    ON c.customer_id = s.customer_id
JOIN products_cleaned p 
    ON s.product_id = p.product_id
GROUP BY 
    c.customer_id, c.first_name, c.last_name, c.signup_date
ORDER BY total_profit DESC;

---END