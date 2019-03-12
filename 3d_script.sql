
-- Return Filtered Set Needed for Metric Calculations
DROP TABLE IF EXISTS OVERALL_EVENTS;
CREATE TEMP TABLE OVERALL_EVENTS AS
SELECT 
       timestamp
       ,data->>'supplier_id' AS supplier_id
       ,data->>'order_id' AS order_id
       ,name
       ,data->>'review_value_speed' AS review_value_speed
       ,data->>'review_value_print_quality' AS review_value_print_quality
FROM public."MY_TABLE"
WHERE name IN ('node/review/created', 'node/review/deleted', 'node/review/updated', 'order/execute/customer/status/processing', 'order/execute/customer/status/payment');


/*****************************************
  Section for Calculating Acceptance Ratio
*****************************************/

-- Table of Order Processing
DROP TABLE IF EXISTS ORDER_EVENTS_PROCESSING;
CREATE TEMP TABLE ORDER_EVENTS_PROCESSING AS
SELECT 
    DATE(timestamp) as date
    , supplier_id
    , order_id
    , name
FROM OVERALL_EVENTS
WHERE name = 'order/execute/customer/status/processing'
ORDER BY supplier_id, timestamp;


-- Table of Order Payments
DROP TABLE IF EXISTS ORDER_EVENTS_PAYMENT;
CREATE TEMP TABLE ORDER_EVENTS_PAYMENT AS
SELECT 
    DATE(timestamp) as date
    , supplier_id
    , order_id
    , name
FROM OVERALL_EVENTS
WHERE name = 'order/execute/customer/status/payment'
ORDER BY supplier_id, timestamp;


-- Merge Tables and only include processing date so we match processes 
-- with payments even if they happened on different dates
DROP TABLE IF EXISTS ORDER_EVENTS_MERGED;
CREATE TEMP TABLE ORDER_EVENTS_MERGED AS
SELECT oepr.date, oepr.supplier_id, oepr.order_id, oepr.name AS process_name, oepa.name AS payment_name
FROM ORDER_EVENTS_PROCESSING oepr
LEFT JOIN ORDER_EVENTS_PAYMENT oepa 
ON oepr.supplier_id = oepa.supplier_id 
AND oepr.order_id = oepa.order_id;

-- Change to integer values to help do the sum
DROP TABLE IF EXISTS ORDER_EVENTS_VALUED;
CREATE TEMP TABLE ORDER_EVENTS_VALUED AS
SELECT 
    date
    , supplier_id
    , 1 as ordered
    , CASE WHEN payment_name IS NOT NULL THEN 1 ELSE 0 END AS accepted
FROM ORDER_EVENTS_MERGED;

--  Create Final Acceptance Ratio Table by Supplier
DROP TABLE IF EXISTS AVERAGE_ORDER_ACCEPTED;
CREATE TEMP TABLE AVERAGE_ORDER_ACCEPTED AS
SELECT 
    date AS calculated_at
    , supplier_id
    , 'acceptance_ratio' as metric
    , SUM(CAST(accepted AS FLOAT))/SUM(CAST(ordered AS FLOAT))*100 AS accept_ratio
FROM  ORDER_EVENTS_VALUED
GROUP BY date, supplier_id;


/*****************************************
  Section for Calculating Supplier Reviews
*****************************************/

-- Table of Most Recent Order Event by Day
DROP TABLE IF EXISTS RECENT_EVENTS;
CREATE TEMP TABLE RECENT_EVENTS AS
SELECT 
      MAX(timestamp) as timestamp
    , DATE(timestamp) as date
    , supplier_id
    , order_id
FROM OVERALL_EVENTS
WHERE name IN ('node/review/created', 'node/review/deleted', 'node/review/updated')
GROUP BY supplier_id, order_id, DATE(timestamp)
ORDER BY order_id, timestamp  ASC;


-- Merge Recent Events with Overall Events to get values
-- Convert timestamp to date
DROP TABLE IF EXISTS MERGED_EVENTS;
CREATE TEMP TABLE MERGED_EVENTS AS
SELECT 
      DATE(o.timestamp) as calculated_at
    , o.supplier_id
    , o.name
    , CAST(o.review_value_speed AS INT) 
    , CAST(o.review_value_print_quality AS INT)
FROM OVERALL_EVENTS o
INNER JOIN RECENT_EVENTS r
ON o.timestamp = r.timestamp
AND o.supplier_id = r.supplier_id
AND o.order_id = r.order_id;

-- Remove entries for deletion 
-- Remove entries for updates to blank
DELETE
FROM MERGED_EVENTS
WHERE name = 'node/review/deleted' 
OR (review_value_speed IS NULL AND review_value_print_quality IS NULL);


-- Calculate Daily Averages for supplier by metric
DROP TABLE IF EXISTS AVERAGED_EVENTS;
CREATE TEMP TABLE AVERAGED_EVENTS AS
SELECT 
    calculated_at
    , supplier_id
    , AVG(review_value_speed) AS avg_review_value_speed
    , AVG(review_value_print_quality) AS avg_review_value_print_quality
FROM MERGED_EVENTS 
GROUP BY calculated_at, supplier_id
ORDER BY calculated_at;


-- Calculate Daily Total Averages
DROP TABLE IF EXISTS AVERAGED_REVIEW_RATING;
CREATE TEMP TABLE AVERAGED_REVIEW_RATING AS
SELECT 
    calculated_at
    , supplier_id
    , 'average_rating' as metric
    , (SELECT AVG(c)FROM (VALUES(avg_review_value_speed), (avg_review_value_print_quality)) T (c)) AS average_rating
FROM AVERAGED_EVENTS
ORDER BY calculated_at;


/*****************************************
  Join Metrics in this Section
*****************************************/

DROP TABLE IF EXISTS SUPPLIER_SCORE_METRICS;
CREATE TABLE SUPPLIER_SCORE_METRICS AS
SELECT * 
FROM(
  SELECT calculated_at, supplier_id, metric , average_rating AS value 
  FROM AVERAGED_REVIEW_RATING
  UNION ALL 
  SELECT calculated_at, supplier_id, metric , accept_ratio AS value 
  FROM AVERAGE_ORDER_ACCEPTED) AS joined
 ORDER BY calculated_at, supplier_id, metric;

