# SQL-Maven-Fuzzy-Factory-Marketing-Breakthrough

## 🧠 Purpose
Analyze website traffic, user behavior, and sales conversion to support marketing decisions, optimize ad spending, improve website performance, and guide A/B testing and conversion funnel improvements.

## 🛠️ Tools and Techniques Used
- **Data filtering:** by date and campaign/source (`WHERE`, date casting)
- **Aggregation:** session/order counts with `SUM` , `COUNT` , and `GROUP BY`
- **Joins:** session-to-order conversion analysis (`LEFT JOIN`)
- **Conversion Rate calculation:** orders/sessions * 100%
- **Bounce Rate:** flag sessions with single pageview using `CASE` and window functions
- **Window Functions:** `ROW_NUMBER()` to find first pageview per session
- **Conditional Flags:** `CASE` for page flags and bounce detection
- **CTEs:** structure complex queries for clarity and stepwise analysis
- **Ordering:** sort results for insights (`ORDER BY DESC`)
- **Time functions:** EXTRACT YEAR & MONTH for trend analysis
- **Temporary tables & analytic queries:** User-level repeat session analysis

This approach enabled detailed traffic source evaluation, conversion tracking, device-based optimization, page performance analysis, and conversion funnel metrics.
