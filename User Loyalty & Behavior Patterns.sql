-- The company Maven launched their goods buying-selling platform website on April 19, 2012. To build market awareness, they placed ads on several social media platforms. For the next period, they will conduct analysis to observe traffic and the performance of their website.
-- As a data analyst, you are asked to assist the stakeholders in the company.
-- The website built by Maven records every user activity coming to the platform.

-- CASE 1: Product Analysis
-- Case 1.1 Case Trend Analysis
-- At the beginning of 2013, the company planned to add new products. But before that, they want to see the monthly trend of sales, revenue, and margin/profit.
-- On January 5, 2013, they requested you to find that information.

-- number_of_sales = count order
-- total revenue = sum price
-- total margin = price - cogs
SELECT
	EXTRACT(YEAR FROM created_at) AS yr,
	EXTRACT(MONTH FROM created_at) AS mo,
	COUNT(DISTINCT order_id) AS number_of_sales,
	SUM(price_usd) AS total_revenue,
	SUM(price_usd - cogs_usd) AS total_margin
FROM orders
WHERE created_at < '2013-01-05'
GROUP BY 1,2;
-- It can be seen that sales, revenue, and margin/profit increase every month.


-- Case 1.2 Analyzing Effect of New Product
-- The company launched a new product starting from January 6, 2013.
-- On April 5, 2013, you were contacted to analyze order volume, conversion rate, and the number of each product (old and new) sold monthly.
-- Conduct analysis on data starting from April 1, 2012.
-- Note: Old product is valued 1 in the primary_product_id column and new product is valued 2.
-- Count session, count order, cvr, total_product1, total_product2
SELECT
	EXTRACT(YEAR FROM ws.created_at) AS yr,
	EXTRACT(MONTH FROM ws.created_at) AS mo,
	COUNT(order_id) AS total_order,
	COUNT(order_id)::float/COUNT(ws.website_session_id) * 100 AS cvr,
	SUM(CASE WHEN primary_product_id = 1 THEN 1 ELSE 0 END) AS count_product_1,
	SUM(CASE WHEN primary_product_id = 2 THEN 1 ELSE 0 END) AS count_product_2
FROM website_sessions AS ws
LEFT JOIN orders AS o ON ws.website_session_id = o.website_session_id
WHERE ws.created_at::date BETWEEN '2012-04-01' AND '2013-04-05'
GROUP BY 1,2;
-- It appears that the new product is beginning to increase overall product sales.


-- Case 1.3 Identifying Number of Each Cross-Sell
-- Since September 25, 2013, the company implemented a cross-sell strategy to increase sales.
-- Until the end of 2013, they also added 1 new product, so there are 3 products sold on the website.
-- On January 2, 2014, you were asked to analyze cross-sell performance from the first implementation until the end of 2013. The company wants to know how many cross-sell products were sold per main product purchase.

-- Identify goods purchased from cross sales.
-- If primary item = 0 then it is cross sales
-- Count order, cross sell prod 1,2,3
SELECT * FROM order_items AS oi
WHERE order_id = 7300;

SELECT
	orders.primary_product_id,
	COUNT(DISTINCT orders.order_id) AS orders,
	COUNT(CASE WHEN order_items.product_id = 1 THEN 1 ELSE NULL END) AS x_sell_product_1,
	COUNT(CASE WHEN order_items.product_id = 2 THEN 1 ELSE NULL END) AS x_sell_product_2,
	COUNT(CASE WHEN order_items.product_id = 3 THEN 1 ELSE NULL END) AS x_sell_product_3
FROM orders
LEFT JOIN order_items
	ON orders.order_id = order_items.order_id
	AND order_items.is_primary_item = 0
WHERE orders.created_at BETWEEN '2013-09-25' AND '2013-12-31'
GROUP BY 1;
-- The number of goods sold from cross-sell throughout 2013.
-- There is a decrease in session volume since the marketing budget was reduced.
-- This result serves as a reference for the company to create a new strategy to maximize traffic volume without spending much on ads.



-- CASE 2: User Analysis
-- Case 2.1 Identifying Repeat Visitors
-- The website manager is interested to know whether users who have visited the website will come back at another time.
-- On June 1, 2014, you were asked by the website manager to find out how many users repeat/come back to the website.

-- Step 1: Identifying relevant new sessions, is_repeat_session = 0
-- Step 2: Use the user_id from step 1 to find any repeat sessions, is_repeat_session = 1
-- Step 3: Analyze data, how many sessions did each user have?
-- Step 4: Aggregate the user-level analysis, group by repeat_sessions count user

-- Identifying Repeat Visitors
CREATE TEMPORARY TABLE sessions_w_repeats AS
WITH new_sessions AS (
SELECT user_id, website_session_id
FROM website_sessions
WHERE created_at < '2014-11-01' AND created_at >= '2014-01-01' AND is_repeat_session = 0
)
SELECT
	new_sessions.user_id,
	new_sessions.website_session_id AS new_session_id,
	website_sessions.website_session_id AS repeat_session_id
FROM new_sessions
LEFT JOIN website_sessions
	ON website_sessions.user_id = new_sessions.user_id
	AND website_sessions.is_repeat_session = 1
	AND website_sessions.website_session_id > new_sessions.website_session_id
	AND website_sessions.created_at < '2014-06-01'
	AND created_At >= '2014-01-01';

SELECT * FROM sessions_w_repeats;

WITH user_level AS(
	SELECT user_id,
		COUNT(DISTINCT new_session_id) AS new_sessions,
		COUNT(DISTINCT repeat_session_id) AS repeat_sessions
	FROM sessions_w_repeats
	GROUP BY 1
	ORDER BY 1
)
SELECT repeat_sessions, COUNT(DISTINCT user_id) AS users
FROM user_level
GROUP BY 1;
-- It appears quite a lot of customers come back to the website after their first visit.



-- Case 2.2 Repeat Channel Behaviour Analysis
-- The previous analysis result attracted the manager's attention, he is interested in looking deeper into repeat customers. He contacted you on June 8, 2014.
-- The marketing manager wants to know which channel/source is used by users when visiting again.
-- He wants to see if they come via direct type-in or via paid campaigns held by the company.
-- You are asked to compare the number of new and repeat sessions based on channel/source.

-- is_repeat_session = 0 means new session,
-- is_repeat_session = 1 means repeat session
SELECT
	CASE
		WHEN utm_source IS NULL AND (
			http_referer LIKE '%gsearch.com%' OR
			http_referer LIKE '%bsearch.com%'
		) THEN 'organic_search'
		WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
		WHEN utm_campaign = 'brand' THEN 'paid_brand'
		WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
		WHEN utm_source = 'socialbook' THEN 'paid_social'
		ELSE 'other'
	END AS channel_group,
	COUNT(CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS new_sessions,
	COUNT(CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END) AS repeat_sessions
FROM website_sessions
WHERE created_at < '2014-06-05' AND created_at >= '2014-01-01'
GROUP BY 1
ORDER BY 3 DESC;
-- The first page most viewed by each user entering the website.
-- It appears when users revisit, they come from organic search, direct type-in, and paid brand.



-- Case 2.3 Analyzing New and Repeat Conversion Rate
-- The website manager wants to see if repeat customers are valuable enough to the company.
-- He asked you to compare the conversion rates of new sessions and repeat sessions.
-- Note: Use data from 2014.
SELECT is_repeat_session,
	COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
	COUNT(DISTINCT orders.order_id)::float/COUNT(DISTINCT website_sessions.website_session_id) * 100 AS conv_rate
FROM website_sessions
LEFT JOIN orders USING(website_session_id)
WHERE website_sessions.created_at < '2014-06-08'
	AND website_sessions.created_at >= '2014-01-01'
GROUP BY 1;
-- Homepage bounce rate
-- It appears repeat users convert/purchase more.
-- Based on this result, the website manager plans to recommend to the marketing manager to increase paid campaigns targeting users who have potential to repeat.
