/*
- This project analyzes sales and operational efficiency for a fictional global electronics retailer. Four questions were provided, and I performed additional analysis beyond the initial questions to do deeper dives into the data before interpreting my results.
- To prevent scope creep, I made a conscious effort to limit the analysis I performed to just the questions provided, and a specific deep dive into one or two topics per question. It was too easy to get lost in the data and keep digging into the numbers, and I had to limit myself to avoid going down multiple rabbit holes.
- This dataset, and the four intial questions, were provided by Maven Analytics. The data begins on Jun 2016 and ends in Feb 2021.
*/

-- Q1. What types of products does the company sell, and where are customers located?

-- List of products:

SELECT
	category AS product_categories,
    subcategory AS product_subcategories
FROM products
GROUP BY product_categories, product_subcategories;

-- Count of customers distribution by country and state (breaking down by city was too granular):

SELECT
	country,
    COUNT(customerkey) AS num_customers
FROM customers
GROUP BY country;

SELECT
	country,
    state,
    COUNT(customerkey) AS num_customers
FROM customers
GROUP BY country, state
ORDER BY num_customers DESC;

-- Layering in percentages:

SELECT
	country,
    COUNT(customerkey) AS num_customers,
    COUNT(customerkey) / (
		SELECT
			COUNT(customerkey)
        FROM customers
	) * 100 AS pct_customers
FROM customers
GROUP BY country
ORDER BY pct_customers DESC;

SELECT
	country,
    state,
    COUNT(customerkey) AS num_customers,
    COUNT(customerkey) / (
		SELECT
			COUNT(customerkey)
        FROM customers
	) * 100 AS pct_customers
FROM customers
GROUP BY country, state
ORDER BY pct_customers DESC;

/*
Initial analysis:
- This is an electronics store offering products similar to what you would expect a Best Buy to sell: electronics, home appliances, phone/computer accessories, etc.
- Almost half of customers are from the US. The company also has a significant presence in the UK, Canada, Germany, and Australia, and a smaller presence in the Netherlands, France, and Italy
- California and Florida (US) and Ontario (CA) represent the largest customer bases, all at over 3%
*/

-- Deep dive: count and revenue of sales by subcategory (doing this by just category was too broad)
-- Note: there are no products with 0 sales

SELECT
	products.category,
    products.subcategory,
    COUNT(sales.quantity) AS num_sales
FROM products
LEFT JOIN sales
	ON products.productkey = sales.productkey
GROUP BY products.category, products.subcategory
ORDER BY products.category, num_sales DESC, products.subcategory;

SELECT
	products.category,
    products.subcategory,
    SUM(products.unit_price_usd * sales.quantity) AS revenue
FROM products
LEFT JOIN sales
	ON products.productkey = sales.productkey
GROUP BY products.category, products.subcategory
ORDER BY products.category, products.subcategory, revenue DESC;

/*
Deep dive analysis:
- Computer products drive the most sales in terms of both volume and revenue, followed by Home Appliances
- Desktops are the unquestioned leader here for both volume and revenue by a significant margin
- Computers Accessories are the worst performer for revenue, although they are in the top half for sales volume within the Computers category
- For Home Appliances, Water Heaters are the clear winner for revenue, with Refrigerators and Washers & Dryers at #2 and #3
- However, sales volume for the mentioned appliances are on the lower end
- We can see that volume and revenue have somewhat of an inverse relationship. High-margin, expensive products drive most of the revenue, despite the lower sales, while the cheaper products contribute less
*/

-- Q2. Are there any seasonal patterns or trends for order volume or revenue?

-- Breakdown by volume by month:

SELECT
	MONTH(order_date) AS month,
    COUNT(*) AS num_sales
FROM sales
GROUP BY month;

-- Breakdown by volume by month and year:

SELECT
	YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    COUNT(*) AS num_sales
FROM sales
GROUP BY year, month
ORDER BY year, month;

-- Breakdown by revenue by month:

WITH total_sales AS (
	SELECT
		MONTH(sales.order_date) AS month,
		-- sales.productkey,
		-- sales.quantity,
		-- products.unit_price_usd,
		sales.quantity * products.unit_price_usd AS revenue
	FROM sales
	INNER JOIN products
		ON sales.productkey = products.productkey
	-- GROUP BY month, sales.productkey, sales.quantity
)

SELECT
	month,
    SUM(revenue) AS revenue
FROM total_sales
GROUP BY month
ORDER BY month;

-- Breakdown by revenue by month and year:

WITH total_sales AS (
	SELECT
		YEAR(sales.order_date) AS year,
        MONTH(sales.order_date) AS month,
		-- sales.productkey,
		-- sales.quantity,
		-- products.unit_price_usd,
		sales.quantity * products.unit_price_usd AS revenue
	FROM sales
	INNER JOIN products
		ON sales.productkey = products.productkey
	-- GROUP BY year, month, sales.productkey, sales.quantity
)

SELECT
	year,
    month,
    SUM(revenue) AS revenue
FROM total_sales
GROUP BY year, month
ORDER BY year, month;

/*
Initial analysis:
- In terms of sales volume, Dec through Feb are the biggest months for the company by a wide margin
	- The holidays likely play a factor for Dec; however, this isn't the case for Jan/Feb
    - One possible reason could be that Jan/Feb is when people have additional money to spend from holiday bonuses
- Apr is a terrible month (the worst month every year), with Mar not looking great either
- 2019 was the best year for the company, with 10 months out of the year in the top 13 months all time by volume
- In terms of revenue, the numbers paint a similar picture, with Dec through Feb looking really good and Apr and Mar looking dismal
- Again, 2019 was an amazing year for revenue
*/

-- Deep dive 1: AOV
-- AOV by month:

WITH total_sales AS (
	SELECT
        MONTH(sales.order_date) AS month,
		-- sales.productkey,
		sales.quantity,
		-- products.unit_price_usd,
		sales.quantity * products.unit_price_usd AS revenue
	FROM sales
	INNER JOIN products
		ON sales.productkey = products.productkey
	-- GROUP BY month, sales.productkey, sales.quantity
)

SELECT
	month,
    SUM(revenue) / SUM(quantity) AS aov_month
FROM total_sales
GROUP BY month
ORDER BY month;

-- AOV by month and year:

WITH total_sales AS (
	SELECT
		YEAR(sales.order_date) AS year,
        MONTH(sales.order_date) AS month,
		-- sales.productkey,
		sales.quantity,
		-- products.unit_price_usd,
		sales.quantity * products.unit_price_usd AS revenue
	FROM sales
	INNER JOIN products
		ON sales.productkey = products.productkey
	-- GROUP BY year, month, sales.productkey, sales.quantity
)

SELECT
	year,
    month,
    SUM(revenue) / SUM(quantity) AS aov_month
FROM total_sales
GROUP BY year, month
ORDER BY year, month;

/*
Deep dive 1 analysis:
- Q1 and Q2 (besides Jun) have higher AOVs than average, which is interesting considering how poor performance is in Mar/Apr. Mar is actually the month with the highest AOV
- There are very few orders in Mar/Apr, but those orders are for more expensive products
	- The company should lean into this to try to boost performance during these months
- Dec has a very low AOV, which is likely due to holiday shoppers purchasing cheap presents
- Summer months are poor
- As for year, 2016-2017 had high AOVs (but low revenue), and vice versa for 2019-2020. The company may have introduced new, cheaper products around 2018, and was rewarded with a significant sales volume increase
*/

-- Deep dive 2: product performance by month
-- Rankings by volume by month:

WITH subcategory_monthly_sales AS (
	SELECT
		MONTH(sales.order_date) AS month,
		products.subcategory,
		COUNT(sales.order_number) AS num_sales,
        SUM(products.unit_price_usd * sales.quantity) AS revenue
	FROM sales
	INNER JOIN products
		ON sales.productkey = products.productkey
	GROUP BY month, products.subcategory
)

SELECT
	month,
    subcategory,
    num_sales,
    ROW_NUMBER() OVER(
		PARTITION BY month
        ORDER BY num_sales DESC
        ) AS ranking
FROM subcategory_monthly_sales
ORDER BY month, ranking;
    
-- Rankings by revenue by month:
    
WITH subcategory_monthly_sales AS (
	SELECT
		MONTH(sales.order_date) AS month,
		products.subcategory,
		COUNT(sales.order_number) AS num_sales,
        SUM(products.unit_price_usd * sales.quantity) AS revenue
	FROM sales
	INNER JOIN products
		ON sales.productkey = products.productkey
	GROUP BY month, products.subcategory
)

SELECT
	month,
    subcategory,
    revenue,
    ROW_NUMBER() OVER(
		PARTITION BY month
        ORDER BY revenue DESC
        ) AS ranking
FROM subcategory_monthly_sales
ORDER BY month, ranking;

/*
Deep dive 2 analysis:
- Desktops rank #1 year-round for both volume and revenue, and Movie DVD ranks last year-round (except in April for volume)
- Products related to temperature (Air Conditioners, Water Heaters, Fans) do not show significant fluctuation between months
	- This could possibly mean customers don't wait until it's hot/cold to replace/purchase these items, and just replace/purchase immediately
- Giftable items (Bluetooth Headphones, Cell Phone Accessories, Computer Accessories) see spikes in sales volume in Dec, but interestingly do not deviate much in volume rankings
	- Bluetooth Headphones in particular remain steady at #2 in volume year-round, despite sales increasing Dec through Feb
- Overall there doesn't seem to be much seasonality in terms of product categories
*/

-- Q3. How long is the average delivery time in days? Has that changed over time?

-- Avg delivery time by month:

WITH delivery_time AS (
	SELECT
		order_date,
		delivery_date,
		DATEDIFF(delivery_date, order_date) AS delivery_time
	FROM sales
	WHERE delivery_date IS NOT NULL
)

SELECT
	MONTH(order_date) AS month,
    AVG(delivery_time) AS avg_delivery_time
FROM delivery_time
GROUP BY month;

-- Avg delivery time by month and year:

WITH delivery_time AS (
	SELECT
		order_date,
		delivery_date,
		DATEDIFF(delivery_date, order_date) AS delivery_time
	FROM sales
	WHERE delivery_date IS NOT NULL
)

SELECT
	YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    AVG(delivery_time) AS avg_delivery_time
FROM delivery_time
GROUP BY year, month;

/*
Initial analysis:
- Overall avg delivery time is consistently between 4-5 days year round
- Over time, however, we can see that the company has been streamlining delivery, with 6-8 days in 2016 down to 3-4 days in Q1 2021
*/

-- Deep dive: delivery time info by regions
-- Avg delivery time by state:

SELECT 
	customers.country,
    customers.state,
    COUNT(sales.order_number) AS num_sales,
    AVG(DATEDIFF(sales.delivery_date, sales.order_date)) AS avg_delivery_time
FROM sales
INNER JOIN customers
	ON sales.customerkey = customers.customerkey
WHERE sales.storekey = 0
GROUP BY customers.country, customers.state
ORDER BY customers.country, avg_delivery_time;

-- Delivery time ranges by country:

WITH avg_delivery_times_country AS (
	SELECT 
		customers.country,
		customers.state,
		COUNT(sales.order_number) AS num_sales,
		AVG(DATEDIFF(sales.delivery_date, sales.order_date)) AS delivery_time
	FROM sales
	INNER JOIN customers
		ON sales.customerkey = customers.customerkey
	WHERE sales.storekey = 0
	GROUP BY customers.country, customers.state
)

SELECT
	country,
    MIN(delivery_time) AS min_delivery,
    MAX(delivery_time) AS max_delivery,
    AVG(delivery_time) AS avg_delivery
FROM avg_delivery_times_country
GROUP BY country
ORDER BY country;

-- Countries that have an average delivery time higher than the overall average delivery time:

SELECT
	customers.country,
    AVG(DATEDIFF(delivery_date, order_date)) AS avg_delivery_time
FROM sales
INNER JOIN customers
	ON sales.customerkey = customers.customerkey
WHERE sales.storekey = 0
GROUP BY customers.country
HAVING AVG(DATEDIFF(delivery_date, order_date)) > (
		SELECT
			AVG(DATEDIFF(delivery_date, order_date))
		FROM sales
        WHERE storekey = 0
		)
ORDER BY avg_delivery_time DESC;

/*
Deep dive analysis:
- Australia, Canada, Germany, the Netherlands, and the US don't have a wide range of delivery times (<4 days variance)
- France, Italy, and the UK have a wide range of delivery times (>6 days)
	- However, these three countries have a minimum delivery time less than that of most of the other countries (1-2 days for these countries, compared to the others). Delivery is inconsistent but not necessarily slow
    - Australia has the smallest range, shortest delivery time, and smallest avg, and looks to be the most consistent country within this metric
- Italy, Canada, the UK, and France have longer deliveries than avg, although all countries have a range of avg delivery times within 1 day
*/

-- Q4. Is there a difference in average order value (AOV) for online vs. in-store sales?

-- Avg AOV by store type:

SELECT
    SUM(sales.quantity * products.unit_price_usd) / SUM(quantity) AS aov_month,
	CASE
		WHEN sales.storekey = 0 THEN 'online'
		ELSE 'in_store'
		END AS store_type
FROM sales
INNER JOIN products
	ON sales.productkey = products.productkey
GROUP BY store_type;

-- Avg AOV by store type by month:

SELECT
    MONTH(sales.order_date) AS month,
    SUM(sales.quantity * products.unit_price_usd) / SUM(quantity) AS aov_month,
	CASE
		WHEN sales.storekey = 0 THEN 'online'
		ELSE 'in_store'
		END AS store_type
FROM sales
INNER JOIN products
	ON sales.productkey = products.productkey
GROUP BY store_type, month;

-- Avg AOV by store type by month and year:

SELECT
	YEAR(sales.order_date) AS year,
    MONTH(sales.order_date) AS month,
    SUM(sales.quantity * products.unit_price_usd) / SUM(quantity) AS aov_month,
	CASE
		WHEN sales.storekey = 0 THEN 'online'
		ELSE 'in_store'
		END AS store_type
FROM sales
INNER JOIN products
	ON sales.productkey = products.productkey
GROUP BY store_type, year, month
ORDER BY year, month, store_type;

/*
Analysis:
- In-store has a higher AOV on average
- Months where in-store AOV is higher than online: Jan, Feb, Mar, May, Jul, Sep, Dec
- Months where online AOV is higher than in-store: Apr, Jun, Aug, Oct, Nov
	- The difference in AOV is negligible (difference of <5) for the months of Feb, Apr, Aug
- Previously I discovered that Q1 AOV is strong, and these results show that AOV is boosted by in-store purchases
*/

-- Deep dive: customer spending distribution
-- Dividing customers into quartiles and looking at revenue per quartile:

WITH customer_revenue AS (
	SELECT
		sales.customerkey,
		SUM(sales.quantity) AS num_orders,
		SUM(products.unit_price_usd * sales.quantity) AS revenue
	FROM sales
	INNER JOIN products
		ON sales.productkey = products.productkey
	GROUP BY sales.customerkey
),
quartiles AS (
	SELECT
		customerkey,
		revenue,
		NTILE(4) OVER (
			ORDER BY revenue DESC
			) AS quartile
	FROM customer_revenue
)

SELECT
	quartile,
    COUNT(*) AS num_customers,
    SUM(revenue) AS quartile_revenue
FROM quartiles
GROUP BY quartile
ORDER BY quartile;

/*
Deep dive analysis:
- Each quartile has the same number of customers, making for a perfectly even spread
- Revenue pct by quartile:
	- Q1: 62.79%
    - Q2: 23.66%
    - Q3: 10.67%
    - Q4: 2.87%
- The top quartile of customers represents a massive share of the company's revenue
- The top half represents over 85% of revenue; keeping these customers satisfied is essential
- The bottom quartile is almost negligible at this point; we need to know if it's worth it to spend time/resources on boosting this customer base
- The company could work on diversifying its customer base, as revenue is incredibly top heavy
*/

/*
Summary:
- This company saw steady growth through Q1 2020, with sales and revenue growing YoY. However, overall numbers drastically dip beginning Mar 2020, likely due to COVID, and does not seem to have recovered
- Almost 45% of the company's sales come from the US, with strong customer bases in the UK, Canada, Germany, and Australia as well
- Performace appears cyclical as a whole, with sales and revenue seeing spikes every Sep through Feb before dipping again every Mar
- Revenue is buoyed by high-margin, expecnsive products such as computers and appliances; despite the low sales volume, these drive significant revenue
- In contrast, products with high sales such as accessories contribute very little to revenue
- Delivery times are consistent year-round, and have been streamlined down from 7-8 days in 2016 to 3-4 days in 2020/2021. COVID does not seem to have had an impact on this
- Australia has, on average, the shortest delivery times at less than 4 days; all other countries fall between 4-5 days
- Canda, Germany, and the US have the smalleest delivery windows of just over 2 days; the UK has the greatest variance at 2 days, followed by France at 7 days
- However, countries with wider delivery windows still have quick delivery times on the lower end of the scale, with the UK being the only country with a 1-day delivery time
- AOV is slightly higher for in-store purchases, compared to online purchases, throughout the year--although it's important to note the difference is quite small
- Sales revenue is incredibly top-heavy, with the top quartile responsible for almost two-thirds of total revenue; the bottom quartile contributes less than 3% of revenue
*/