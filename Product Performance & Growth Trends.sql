-- Case Maven Fuzzy Factory
-- The Maven company launched their buy-sell goods platform website on April 19, 2012. To build market awareness, they placed ads on several social media platforms. Over the next period, they will conduct analysis to see the traffic and performance of the website they own.
-- As a data analyst, you are asked to assist the stakeholders in the company.

-- CASE 1: Analyzing Traffic Source
-- Overview Table Orders
SELECT * FROM orders;
SELECT * FROM website_sessions;

-- Case 1.1 Traffic Source
-- After almost one month running, the company wants to evaluate which source brings the most traffic to the website.
-- Note: The company wants to see traffic before April 13, 2012.
-- The company wants to see traffic details based on utm source, utm campaign, and http referer.
SELECT utm_source, utm_campaign, http_referer, count(website_session_id)
FROM website_sessions
WHERE created_at::date < '2012-04-13'
GROUP BY 1,2,3
ORDER BY 4 DESC;
-- The largest traffic was obtained from gsearch nonbrand with 3757 sessions
-- From this result, the company wants to know if traffic coming from gsearch nonbrand generates sales for the company.

-- Case 1.2 Conversion Rate Top Traffic Source
-- On April 14, 2012, the company asked you to calculate the conversion rate (CVR) from session to order. Based on the ad budget calculation, they need a minimum CVR of 5% from that traffic.
-- This analysis result will be used as a reference whether the company will increase or decrease the marketing budget for gsearch nonbrand.
-- CVR = orders / total sessions * 100%
SELECT
	COUNT(ws.website_session_id) AS total_session,
	COUNT(order_id) AS total_order,
	COUNT(order_id)::FLOAT/COUNT(ws.website_session_id) * 100 AS cvr
FROM website_sessions AS ws
LEFT JOIN orders AS o ON ws.website_session_id = o.website_session_id
WHERE ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand'
	AND ws.created_at::date < '2012-04-14';
-- The CVR from gsearch nonbrand is around 2.8% (<5%)
-- Therefore, the marketing budget for gsearch nonbrand was reduced from April 15, 2012.

-- Case 1.3 Trend Analysis of Top Traffic Source
-- The company contacted you again on May 11, 2012, asking you to analyze the weekly session volume trend.
-- The company wants to see if the marketing budget changes caused the session volume to decrease overall.
SELECT 
	EXTRACT('WEEK' FROM created_at) AS "week",
	MIN(created_at::date) AS week_date_start,
	COUNT(website_session_id) AS volume_session
FROM website_sessions AS ws
WHERE ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand'
	AND ws.created_at::date < '2012-05-11'
GROUP BY 1
ORDER BY 1;
-- A decrease in session volume is seen since the marketing budget was reduced.
-- This result becomes a reference for the company to make a new strategy to maximize traffic volume but without spending a lot on ads.

-- Case 1.4 Bid Optimization for Paid Traffic
-- The company received feedback from users that the mobile website often experiences errors/issues. Therefore, on May 12, 2012, the company contacted you again.
-- They asked you to calculate the conversion rate (session to order) based on the device type used by users.
-- This is done to see opportunities to optimize gsearch nonbrand ads based on the device type used.
SELECT
	device_type,
	COUNT(ws.website_session_id) AS total_session,
	COUNT(order_id) AS total_order,
	COUNT(order_id)::FLOAT/COUNT(ws.website_session_id) * 100 AS cvr
FROM website_sessions AS ws
LEFT JOIN orders AS o ON ws.website_session_id = o.website_session_id
WHERE ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand'
	AND ws.created_at::date < '2012-05-12'
GROUP BY 1;
-- The CVR on desktop is higher than on mobile.
-- Based on this analysis, the company decided to increase the ad spend for gsearch nonbrand on desktop devices.

-- CASE 2: Analyzing Website Performance
-- Case 2.1 Top Website Pages
-- The website manager contacted you on June 10, 2012, wanting to know which website pages have been viewed the most since the website launched.
-- Hint: The most viewed page can be known through the number of sessions on that page.
SELECT pageview_url, COUNT(website_session_id)
FROM website_pageviews
WHERE created_at::date < '2012-06-10'
GROUP BY 1
ORDER BY 2 DESC;
-- Homepage, products page, and the Mr. Fuzzy page are the most frequently viewed pages by users.

-- Case 2.2 Top Entry Pages
-- On June 13, 2012, the website manager contacted you again, wanting to see the first page most viewed/opened by users every time they enter the website.
-- Find the first page for each session (pageview_id)
-- Number of sessions based on pageview_url
SELECT * FROM website_pageviews AS wp;

WITH first_page AS (
	SELECT *,
		ROW_NUMBER() OVER(PARTITION BY website_session_id ORDER BY created_at) AS rank
	FROM website_pageviews AS wp
	WHERE created_at::date < '2012-06-13'
)
SELECT pageview_url AS first_page, COUNT(website_session_id) AS total_session
FROM first_page
WHERE rank = 1
GROUP BY 1;
-- It appears all traffic enters the homepage when visiting the website
-- From this result, the website manager wants to know the performance of the homepage.

-- Case 2.3 Bounce Rate Analysis
-- Based on the previous analysis, on June 14, 2012, the website manager contacted you again.
-- He asked you to calculate the bounce rate of the homepage. He wants information on the number of sessions entering the homepage, the number of bounce sessions, and the bounce rate of the homepage.
-- For each session, if bounce = flag 1, else 0
-- Calculate total sessions, total bounce sessions, and bounce rate (bounce/total)
SELECT * FROM website_pageviews wp;

WITH is_bounce AS (
	SELECT website_session_id,
	CASE
		WHEN COUNT(website_session_id) = 1 THEN 1
		ELSE 0
	END AS is_bounce
	FROM website_pageviews AS wp
	WHERE created_at::date < '2012-06-14'
	GROUP BY 1
)
SELECT
	COUNT(DISTINCT website_session_id) AS total_session,
	SUM(is_bounce) AS total_bounce,
	SUM(is_bounce)::FLOAT/COUNT(website_session_id) * 100 AS br 
FROM is_bounce;
-- The bounce rate of the homepage is almost 60%.
-- The website manager considers this a very high number.
-- To reduce the bounce rate on the main page, the website manager plans to create a custom landing page and run an A/B testing experiment over a certain period.

-- Case 2.4 Landing Page Test Analysis
-- After running the A/B test experiment, the website manager contacted you again on July 20, 2012.
-- He asked you to analyze the results of the A/B test conducted.

-- The website manager ran a custom landing page (/lander-1) and conducted an A/B test against the homepage (/home) for traffic coming from gsearch nonbrand.
-- Compare the bounce rate of the two pages to know their performance comparison.
-- Ensure sessions used on both pages to calculate bounce rate are those coming from the period /lander-1 started/displayed.

-- A/B test, 2012-07-29, gsearch nonbrand.
-- When did /lander appear? 2012-06-19 00:25:54
-- a. Find first page for each session (rank)
-- b. Find the page URL name (filter /home and /lander)
-- c. Determine if the session bounced or not, if number of pages = 1 then bounce (Y=1 / N=0)
-- d. Join first_page info (b) and bounce flag (c)
-- e. For home and lander, find number of sessions, bounces, bounce rate
-- Period 2012-06-19 to 2012-07-29

WITH first_page AS (
	SELECT wp.*,
		ROW_NUMBER() OVER(PARTITION BY website_session_id ORDER BY wp.created_at) AS rank
	FROM website_pageviews AS wp
	JOIN website_sessions AS ws USING(website_session_id)
	WHERE wp.created_at::date BETWEEN '2012-06-19' AND '2012-07-29' AND
		ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand'
),
session_first_page AS (
	SELECT website_session_id AS session_id, pageview_url AS first_page
	FROM first_page
	WHERE rank = 1 AND pageview_url IN ('/home', '/lander-1')
),
is_bounce AS (
	SELECT sfp.session_id,
	CASE
		WHEN COUNT(website_session_id) = 1 THEN 1
		ELSE 0
	END AS is_bounce
	FROM website_pageviews AS wp
	JOIN session_first_page AS sfp ON wp.website_session_id = sfp.session_id
	GROUP BY 1
)
SELECT first_page,
	COUNT(session_id) AS total_session,
	SUM(is_bounce) AS total_bounce,
	ROUND(SUM(is_bounce)::numeric/COUNT(session_id), 2) * 100 AS bounce_rate
FROM is_bounce
JOIN session_first_page USING(session_id)
GROUP BY 1;
-- It can be seen that /lander-1 performs better because it has a lower bounce rate.
-- From this result, the website manager decided to use /lander-1 as the main website page for users coming from paid ads gsearch nonbrand.

-- Case 2.5 Conversion Funnel Analysis
-- After making improvements to the main page for users coming from gsearch nonbrand, the website manager wants to see the performance of each page in the conversion funnels.
-- On September 5, 2012, you were asked to analyze the click rate of each page in the conversion funnels. The website manager asked you to analyze data for the last month.
-- a. Assign a flag value for each page view (e.g. product -> product(1) fuzzy(0) etc.)
-- b. Select max value for each flag page (e.g. if all 1 1 1 1 1 at end)
-- c. Calculate CR for each flag page
-- cr_product = SUM(next_page)/SUM(product_page) etc.
-- SELECT DISTINCT(pageview_url) FROM website_pageviews
-- /home, /products, /the-original-mr-fuzzy, /cart, /shipping, /billing, /thank-you-for-your-order
SELECT * FROM website_pageviews AS wp;

WITH access_page AS (
	SELECT
		wp.website_session_id, pageview_url,
		CASE
			WHEN pageview_url = '/products' THEN 1 ELSE 0
		END AS p_product,
		CASE
			WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0
		END AS p_fuzzy,
		CASE
			WHEN pageview_url = '/cart' THEN 1 ELSE 0
		END AS p_cart,
		CASE 
			WHEN pageview_url = '/shipping' THEN 1 ELSE 0
		END AS p_shipping,
		CASE 
			WHEN pageview_url = '/billing' THEN 1 ELSE 0
		END AS p_billing,
		CASE
			WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0
		END AS p_thanks
	FROM website_pageviews AS wp
	JOIN website_sessions AS ws USING(website_session_id)
	WHERE wp.created_at::date BETWEEN '2012-08-05' AND '2012-09-05' AND
		ws.utm_source = 'gsearch' AND ws.utm_campaign = 'nonbrand'
),
summary_session AS (
SELECT website_session_id,
	MAX(p_product) AS p_product,
	MAX(p_fuzzy) AS p_fuzzy,
	MAX(p_cart) AS p_cart,
	MAX(p_billing) AS p_billing,
	MAX(p_thanks) AS p_thanks
FROM access_page
GROUP BY 1
)
SELECT
	COUNT(website_session_id) AS sessions,
	SUM(p_fuzzy)::float/SUM(p_product) AS cr_product,
	SUM(p_cart)::float/SUM(p_fuzzy) AS cr_fuzzy,
	SUM(p_billing)::float/SUM(p_cart) AS cr_cart,
	SUM(p_thanks)::float/SUM(p_billing) AS cr_billing
FROM summary_session;
-- It can be seen that the mrfuzzy page and billing page have lower click rates compared to other pages.
-- This result can be a reference for the website manager to improve the mrfuzzy and billing pages.
