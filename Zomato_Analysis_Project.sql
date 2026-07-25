--->>> ZOMATO DATA ANALYSIS PROJECT <<<---

DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS restaurants;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS riders;
DROP TABLE IF EXISTS deliveries;


CREATE TABLE customers (
	customer_id INT PRIMARY KEY,
	customer_name VARCHAR(30),
	reg_date DATE
);

CREATE TABLE restaurants (
	restaurant_id INT PRIMARY KEY,
	restaurant_name VARCHAR(55),
	city VARCHAR(30),
	opening_hours VARCHAR(55)
);

CREATE TABLE orders (
	order_id INT PRIMARY KEY,
	customer_id INT,				-- COMING FROM CUSTOMER TBLE
	restaurant_id INT,			-- COMING FROM RESTAURANT TABLE
	order_item VARCHAR(55),
	order_date DATE,
	order_time TIME,
	order_status VARCHAR(25),
	total_amount FLOAT
);

CREATE TABLE riders (
	rider_id INT PRIMARY KEY,
	rider_name VARCHAR(55),
	signup DATE
);

CREATE TABLE deliveries (
	delivery_id INT PRIMARY KEY,
	order_id INT,					-- COMING FROM ORDER TABLE
	delivery_status VARCHAR(35),	
	delivery_time TIME,
	rider_id INT					-- COMING FROM RIDERS
);

-->>> ADD FOREIGN KEYS CONSTRAINT <<<---

ALTER TABLE orders
ADD CONSTRAINT fk_orders_customers
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

ALTER TABLE orders
ADD CONSTRAINT fk_orders_restaurants
FOREIGN KEY (restaurant_id)
REFERENCES restaurants(restaurant_id);

ALTER TABLE deliveries
ADD CONSTRAINT fk_deliveries_orders
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

ALTER TABLE deliveries
ADD CONSTRAINT fk_deliveries_riders
FOREIGN KEY (rider_id)
REFERENCES riders(rider_id);


-- >>> INSERT DATA >>>>



-- EDA (Exploratory Data Analysis)

SELECT COUNT(*)
FROM customers;

SELECT COUNT(*)
FROM restaurants;

SELECT COUNT(*)
FROM riders;

SELECT COUNT(*)
FROM orders;

SELECT COUNT(*)
FROM deliveries;


-- >>>  DATA QUALITY CHECK >>>>

-- NULL CHECK
SELECT *
FROM customers
WHERE customer_id IS NULL
	OR customer_name IS NULL
	OR reg_date IS NULL;

SELECT *
FROM restaurants
WHERE restaurant_id IS NULL
	OR restaurant_name IS NULL
	OR city IS NULL
	OR opening_hours IS NULL;

SELECT *
FROM riders
WHERE rider_id IS NULL
	OR rider_name IS NULL
	OR signup IS NULL;

SELECT *
FROM orders
WHERE order_id IS NULL
	OR customer_id IS NULL
	OR restaurant_id IS NULL
	OR order_item IS NULL
	OR order_date IS NULL
	OR order_time IS NULL
	OR order_status IS NULL
	OR total_amount IS NULL;

SELECT *
FROM deliveries
WHERE delivery_id IS NULL
	OR order_id IS NULL
	OR delivery_status IS NULL
	OR delivery_time IS NULL
	OR rider_id IS NULL;


-- DUPLICATE CHECK
SELECT
	customer_id,
	COUNT(*)
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT
	restaurant_id,
	COUNT(*)
FROM restaurants
GROUP BY restaurant_id
HAVING COUNT(*) > 1;

SELECT
	rider_id,
	COUNT(*)
FROM riders
GROUP BY rider_id
HAVING COUNT(*) > 1;

SELECT
	order_id,
	COUNT(*)
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT
	delivery_id,
	COUNT(*)
FROM deliveries
GROUP BY delivery_id
HAVING COUNT(*) > 1;


--- Referential Integrity Checks

-- Orders without customers

SELECT *
FROM orders o
LEFT JOIN customers c
ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Orders without restaurants

SELECT *
FROM orders o
LEFT JOIN restaurants r
ON o.restaurant_id = r.restaurant_id
WHERE r.restaurant_id IS NULL;

-- Deliveries Without Orders

SELECT *
FROM deliveries d
LEFT JOIN orders o
ON d.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Deliveries wihtout Riders

SELECT *
FROM deliveries d
LEFT JOIN riders r
ON d.rider_id = r.rider_id
WHERE r.rider_id IS NULL


---->>>>  BUSINEESS PROBLEMS / ANALYSIS & REPORT <<<<---- 

-- Q. 1
-- Write a query to find the top 5 most frequently ordered dishes by customer called 'Aarav Sharma' in the last 1 year
-- 
	-- join customers and orders
	-- group by customer_id, dishes, count
	-- filter for last 1 year
	-- filter for 'Arav'

SELECT
	customer_name,
	dishes,
	total_orders,
	top_dishes
FROM
(	SELECT
		c.customer_id,
		c.customer_name,
		o.order_item AS dishes,
		COUNT(*) AS total_orders,
		DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS top_dishes
	FROM orders o
	JOIN customers c
	ON o.customer_id = c.customer_id
	WHERE
		o.order_date >= CURRENT_DATE - INTERVAL ' 1 year'
		AND c.customer_name = 'Aarav Sharma'
	GROUP BY 1, 2, 3
	ORDER BY 1, 4 DESC
) t1
WHERE top_dishes <= 5;


-- Q. 2 Popular time slots
-- Identify the time slotes during which the most order are placed. based on 2 hours intervals.?

-- THIS IS 1ST APPROACH

SELECT
	CASE
		WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1 THEN '00:00 - 02:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3 THEN '02:00 - 04:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 AND 5 THEN '04:00 - 06:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 7 THEN '06:00 - 08:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 AND 9 THEN '08:00 - 10:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10:00 - 12:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12:00 - 14:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 AND 15 THEN '14:00 - 16:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 AND 17 THEN '16:00 - 18:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 19 THEN '18:00 - 20:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 AND 21 THEN '20:00 - 22:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 22 AND 23 THEN '22:00 - 00:00'
	END AS time_slot,
	COUNT(order_id) AS order_count
FROM orders
GROUP BY time_slot
ORDER BY order_count DESC;


-- TIME SLOT LOGIC
SELECT 00:59:59 AM -- 0
SELECT 01:59:59 AM -- 1

-- 2ND APPROACH -> WITH FLOOR FUNCTION

SELECT
	FLOOR(EXTRACT(HOUR FROM order_time) / 2) * 2 AS start_time,
	FLOOR(EXTRACT(HOUR FROM order_time) / 2) * 2 + 2 AS end_time,
	COUNT(*) AS total_orders
FROM orders
GROUP BY 1, 2
ORDER BY 3 DESC;


-- Q. 3 Order value analysis
-- Find the average order value(AOV) per customer who has placed more than 300 orders.
-- Return customer_name, and AOV

SELECT
	c.customer_name,
	AVG(total_amount) as aov
FROM orders o
JOIN customers c
ON c.customer_id = o.customer_id
GROUP BY 1
HAVING COUNT(order_id) > 300
ORDER BY aov DESC;


-- Q. 4 High-Value Customers
-- List the customers who have spent more thatn 400k in total ln food orders
-- Return customer_name, name customer_id;

SELECT
	c.customer_name,
	SUM(total_amount) as total_spent
FROM orders o
JOIN customers c
ON c.customer_id = o.customer_id
GROUP BY 1
HAVING SUM(total_amount) > 400000
ORDER BY total_spent DESC;


-- Q. 5 Orders without deliveries
-- Write a query to find orders that were placed but not delivered.
-- Return each restaurant name, city and number of not delivered orders
select * from orders

SELECT
	r.restaurant_name,
	r.city,
	COUNT(o.order_id) AS not_delivered_orders
FROM orders o
LEFT JOIN restaurants r
ON r.restaurant_id = o.restaurant_id
LEFT JOIN deliveries d
ON d.order_id = o.order_id
WHERE o.order_status = 'not delivered'
GROUP BY 1, 2
ORDER BY not_delivered_orders DESC;


-- Q. 6 Restaurant Revenue ranking:
-- Rank restaurants by tehir total revenue from the last year, including their name,
-- total_revenue, and rank within their city.
select * from restaurants;
select * from orders;

WITH ranking_table AS
(
	SELECT
		r.city,
		r.restaurant_name,
		SUM(o.total_amount) AS total_revenue,
		RANK() OVER(PARTITION BY r.city ORDER BY SUM(o.total_amount)DESC) AS rnk
	FROM orders o
	JOIN restaurants r
	ON o.restaurant_id = r.restaurant_id
	WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 year'
	GROUP BY 1, 2
)
SELECT *
FROM ranking_table
WHERE rnk = 1;


-- Q. 7.
-- Most popular dish by city
-- Identify the most popular dish in each city based on the number of orders.

WITH popular_dish AS
(
	SELECT
		r.city,
		o.order_item AS dish,
		COUNT(o.order_id) AS total_orders,
		ROW_NUMBER()OVER(PARTITION BY r.city ORDER BY COUNT(o.order_id) DESC) AS rnk
	FROM orders o
	JOIN restaurants r
	ON r.restaurant_id = o.restaurant_id
	GROUP BY 1, 2
)
SELECT *
FROM popular_dish
WHERE rnk = 1;


-- Q. 8 Customer Churn
-- Find customers who haven't placed an order in 2025 but did in 2024.?

SELECT DISTINCT customer_id FROM orders
WHERE
	EXTRACT(YEAR FROM order_date) = '2024'
	AND	customer_id
	NOT IN (
		SELECT DISTINCT customer_id
		FROM orders
		WHERE EXTRACT (YEAR FROM order_date) = '2025');
		

-- Q. 9 Cancellation rate comparison:
-- Calculate and compare the order cancellation rate for each restaurant
-- between the current year and the previous year.

WITH cancel_ratio_2025 AS
(
    SELECT
        o.restaurant_id,
        COUNT(o.order_id) AS total_orders,
        COUNT(
            CASE
                WHEN d.delivery_status = 'not delivered'
                THEN 1
            END
        ) AS not_delivered

    FROM orders o
    JOIN deliveries d
    ON o.order_id = d.order_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2025
    GROUP BY 1
),

cancel_ratio_2026 AS
(
    SELECT
        o.restaurant_id,
        COUNT(o.order_id) AS total_orders,
        COUNT(
            CASE
                WHEN d.delivery_status = 'not delivered'
                THEN 1
            END
        ) AS not_delivered
    FROM orders o
    JOIN deliveries d
    ON o.order_id = d.order_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2026
    GROUP BY 1
),

last_year_data AS
(
    SELECT
        restaurant_id,
        total_orders,
        not_delivered,
        ROUND((not_delivered::numeric / total_orders::numeric * 100),2) AS cancel_ratio
    FROM cancel_ratio_2025
),

current_year_data AS
(
    SELECT
        restaurant_id,
        total_orders,
        not_delivered,
        ROUND((not_delivered::numeric / total_orders::numeric * 100) ,2) AS cancel_ratio
    FROM cancel_ratio_2026
)

SELECT
    c.restaurant_id AS rest_id,
    c.cancel_ratio AS cur_yr_cancel_ratio,
    l.cancel_ratio AS last_yr_cancel_ratio
FROM current_year_data c
JOIN last_year_data l
ON c.restaurant_id = l.restaurant_id
ORDER BY rest_id;


-- Q. 10 Rider average delivery time
-- Determine each rider's average delivery time
select * from riders

SELECT
	o.order_id,
	d.rider_id,
	o.order_time,
	d.delivery_time,
	o.order_time - d.delivery_time AS time_diff,
	ROUND(EXTRACT(EPOCH FROM (d.delivery_time - o.order_time +
		CASE
			WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day'
			ELSE  INTERVAL '0 day'
		END )) / 60, 2) AS time_diff_in_min
FROM orders o
JOIN deliveries d
ON o.order_id = d.order_id
WHERE d.delivery_status = 'delivered';



-- Q 11. Monthly restaurant growth ratio
-- Calculate each restaurant's growth ratio based on the total number of delivered orders since its joining

WITH growth_ratio AS
(
	SELECT
		o.restaurant_id,
		TO_CHAR(o.order_date, 'mm-yy') AS month,
		COUNT(o.order_id) AS curr_month_orders,
		LAG(COUNT(o.order_id), 1) OVER(PARTITION BY o.restaurant_id ORDER BY TO_CHAR(o.order_date, 'mm-yy')) AS pre_month_orders
	FROM orders o
	JOIN deliveries d
	ON o.order_id = d.order_id
	WHERE d.delivery_status = 'delivered'
	GROUP BY 1, 2
	ORDER BY 1, 2
)
SELECT
	restaurant_id,
	month,
	curr_month_orders,
	pre_month_orders,
	ROUND((curr_month_orders::numeric - pre_month_orders::numeric) / pre_month_orders * 100, 2) AS growth_ra
FROM growth_ratio;



-- Q. 12 Customer Segmentation

-- Customer Segmentation : Segment customers into 'Gold' or 'Silver' groups based on their total spending comapared to the average order value.
-- if a customer's total spending exceeds the AOV lebel them as 'Gold'; otherwise, lebel them as 'Silver'.
-- Write an query to detenmine each segment's total number of orders and total revenue

-- customer total spend
-- aov
-- gold
-- silver
-- each category and total orders and total revenue


SELECT
	customer_category,
	SUM(total_orders) AS total_orders,
	SUM(total_spent) AS total_revenue
FROM
(
	SELECT 
		customer_id,
		SUM(total_amount) AS total_spent,
		COUNT(order_id) AS total_orders,
		CASE
			WHEN SUM(total_amount) > (SELECT AVG(total_amount) FROM orders) THEN 'Gold'
			ELSE 'Silver'
		END AS customer_category
	FROM orders
	GROUP BY 1
) t1
GROUP BY 1;



-- Q. 13 Rider Monthly Earnings;
-- Calculate each rider's total monthly earning, assuming they earn 8% of the order amount.



SELECT
	d.rider_id,
	TO_CHAR(o.order_date, 'mm-yy') AS month,
	SUM(o.total_amount) AS total_revenue,
	SUM(o.total_amount) * 0.08 AS riders_earning
FROM orders o
JOIN deliveries d
ON o.order_id = d.order_id
GROUP BY 1, 2
ORDER BY 1, 2 DESC;



-- Q. 14 Rider Rating Analyssis
-- Find the number of 5-star, 4-star, and 3-star raing each rider has.
-- Riders receive this rating based on delivery time.
-- If orders are delivered less than 15 minutes of order received time the rider get 5 star rating,
-- If they deliver 15 and 20 minute they get 4 star rating
-- If they deliver after 20 minute they get 3 star rating


SELECT
	rider_id,
	ratings,
	COUNT(*) AS total_ratings
FROM
(
	SELECT
		rider_id,
		delivery_took_time,
		CASE
			WHEN delivery_took_time < 15 THEN '5-STAR'
			WHEN delivery_took_time BETWEEN 15 AND 20 THEN '4-STAR'
			ELSE '3-STAR'
		END AS ratings
	FROM
	(
		SELECT
			o.order_id,
			o.order_time,
			d.delivery_time,
			d.rider_id,
			EXTRACT(EPOCH FROM (d.delivery_time - o.order_time +
				CASE
					WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day'
					ELSE INTERVAL '0 day'
				END )) / 60 AS delivery_took_time
		FROM orders o
		JOIN deliveries d
		ON o.order_id = d.order_id
		WHERE delivery_status = 'delivered'
	) t1
) t2

GROUP BY 1, 2
ORDER BY 1, 3 DESC;



-- Q. 15 Order Frequency by day:
-- Analyze order grequency per day of the week and identify the peak day for each restaurant.

SELECT *
FROM
(
	SELECT
		r.restaurant_name,
		TO_CHAR(o.order_date, 'Day') AS days,
		COUNT(o.order_id) AS total_orders,
		RANK() OVER(PARTITION BY r.restaurant_name ORDER BY COUNT(o.order_id) DESC) AS rnk
	FROM orders o
	JOIN restaurants r
	ON o.restaurant_id = r.restaurant_id
	GROUP BY 1, 2
	ORDER BY 1, 3 DESC
) t1

WHERE rnk = 1;



-- Q. 16 Customer Lifetime Value (CLV):
-- Calculate the total revenue generated by each customer over all their orders

SELECT
	o.customer_id,
	c.customer_name,
	SUM(o.total_amount) AS clv
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY 1, 2;
 

-- Q. 17 Monthly Sales Trend 
-- Identify sales trends by comparing each month's total sales to the previous month.

SELECT
	EXTRACT(YEAR FROM order_date) AS year,
	EXTRACT(MONTH FROM order_date) AS month,
	SUM(total_amount) AS total_sales,
	LAG(SUM(total_amount), 1) OVER(ORDER BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)) AS prev_month_sales
FROM orders
GROUP BY 1, 2;


-- Q. 18 Rider Efficiency:
-- Evaluate rider efficiency by determining average delivery times and identifying those with the lowest and highest average.

WITH rider_effi AS
(
	SELECT
		d.rider_id AS riders_id,
		EXTRACT(EPOCH FROM (d.delivery_time - o.order_time + 
		CASE
			WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day'
			ELSE INTERVAL '0 day'
		END)) / 60 AS time_deliver
	FROM orders o
	JOIN deliveries d
	ON o.order_id = d.order_id
	WHERE d.delivery_status = 'delivered'
),
riders_time AS
(
	SELECT
		riders_id,
		AVG(time_deliver) avg_time
	FROM rider_effi
	GROUP BY 1
)
SELECT
	MIN(avg_time),
	MAX(avg_time)
FROM riders_time;


-- Q. 19 Order time Polulartiy:
-- Track the popularity of specific order items over time and idendify seasonal demand spikes.

SELECT
	order_item,
	seasons,
	COUNT(order_id) AS total_orders
FROM
(
	SELECT *,
		EXTRACT(MONTH FROM order_date) AS month,
		CASE
			WHEN EXTRACT(MONTH FROM order_date) BETWEEN 4 AND 6 THEN 'Spring'
			WHEN EXTRACT(MONTH FROM order_date) > 6 AND EXTRACT(MONTH FROM order_date) < 9 THEN 'Summer'
			ELSE 'Winter'
		END AS seasons
	FROM orders
) t1
GROUP BY 1, 2
ORDER BY 1, 3 DESC


-- Q. 20 Rank each city based on the total revenue for last year 2023


SELECT
	r.city,
	SUM(o.total_amount) AS total_revenue,
	RANK() OVER(ORDER BY SUM(o.total_amount) DESC) AS city_rank
FROM orders o
JOIN restaurants r
ON o.restaurant_id = r.restaurant_id
GROUP BY 1



--- >>>> END PROJECT <<<< ---- 

