-- inspecting data
SELECT * FROM sales_data_sample;

-- Checking Unique values 
SELECT DISTINCT sales_data_sample.status FROM sales_data_sample; -- good to plot 
SELECT DISTINCT sales_data_sample.YEAR_ID FROM sales_data_sample; -- span of 3 years
SELECT DISTINCT sales_data_sample.PRODUCTLINE FROM sales_data_sample; -- good to plot
SELECT DISTINCT sales_data_sample.COUNTRY FROM sales_data_sample; --  good to plot 
SELECT DISTINCT sales_data_sample.DEALSIZE FROM sales_data_sample; -- good to plot
SELECT DISTINCT sales_data_sample.territory FROM sales_data_sample; -- good to plot 

SELECT DISTINCT sales_data_sample.MONTH_ID FROM sales_data_sample
WHERE YEAR_ID = 2003;
-- ANALYSIS 
-- Grouping sales by product line     
SELECT 
	PRODUCTLINE, 
    ROUND(SUM(sales),2) AS Revenue 
FROM 
	sales_data_sample
GROUP BY 
	PRODUCTLINE 
ORDER BY
	Revenue DESC;

SELECT 
	YEAR_ID, 
    ROUND(SUM(sales),2) AS Revenue 
FROM 
	sales_data_sample
GROUP BY 
	YEAR_ID 
ORDER BY
	Revenue DESC;

SELECT 
	DEALSIZE, 
    ROUND(SUM(sales),2) AS Revenue 
FROM 
	sales_data_sample
GROUP BY 
	DEALSIZE
ORDER BY
	Revenue DESC;
    
-- What was the best month for sales in a specific year? How much was earned that month?
SELECT 
	MONTH_ID, 
    ROUND(SUM(sales),2) AS Revenue ,
    COUNT(ORDERNUMBER) AS Frequency 
FROM 
	sales_data_sample
WHERE 
	YEAR_ID = 2004
GROUP BY 
	MONTH_ID
ORDER BY
	Revenue DESC;

-- November seems to be the best month.
-- What product do they sell the most in November, I believe classic cars
SELECT 
	MONTH_ID, 
    PRODUCTLINE,
    ROUND(SUM(sales),2) AS Revenue ,
    COUNT(ORDERNUMBER) AS Frequency 
FROM 
	sales_data_sample
WHERE 
	YEAR_ID = 2004 AND MONTH_ID = 11 
GROUP BY 
	MONTH_ID, PRODUCTLINE  
ORDER BY
	Revenue DESC; 
-- Who is our best customer (this could be answered with RFM)

DROP  table temp_rfm;
CREATE TEMPORARY TABLE temp_rfm
(
WITH rfm AS(
	SELECT 
		CUSTOMERNAME,
		ROUND(SUM(sales),2) AS MonetaryValue,
		ROUND(AVG(sales),2) AS AvgMonetaryValue,
		COUNT(ORDERNUMBER) AS Frequency,
		MAX(ORDERDATE) AS last_order_date,
		(SELECT
			MAX(ORDERDATE) 
		FROM 
			sales_data_sample) AS max_order_date,
		DATEDIFF((SELECT MAX(ORDERDATE) FROM sales_data_sample),MAX(ORDERDATE)) AS Recency 
	FROM 
		sales_data_sample
	GROUP BY 
		CUSTOMERNAME
        ),
rfm_calc as (
	SELECT 
		*,
		NTILE(4) OVER (ORDER BY Recency DESC) rfm_recency,
		NTILE(4) OVER (ORDER BY Frequency) rfm_frequency,
		NTILE(4) OVER (ORDER BY MonetaryValue) rfm_monetary
	FROM 
		rfm
    )
    SELECT 
		*,
        rfm_recency + rfm_frequency + rfm_monetary AS rfm_cell,
        CONCAT(CAST(rfm_recency AS CHAR ), CAST(rfm_frequency AS CHAR) , CAST(rfm_monetary AS CHAR)) AS rfm_cell_string
	FROM
		rfm_calc); 
        
SELECT 
	CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary,
    CASE 
		WHEN rfm_cell_string IN(111,112,121,122,123,211,212,114,141) THEN 'lost customer'-- lost customers
        WHEN rfm_cell_string IN(133,134,143,244,334,343,344,144,234) THEN 'slipping away, cannot lose'
        WHEN rfm_cell_string IN(311,411,331,421,412) THEN 'new customer'
        WHEN rfm_cell_string IN(222,223,233,322,232,221) THEN 'potential churners'
        WHEN rfm_cell_string IN(323,333,321,422,332,432,423) THEN 'active' -- customers who buy often and recently, but at low price points
        WHEN rfm_cell_string IN(433,434,443,444) THEN 'loyal'
	END rfm_segment 
FROM 
	temp_rfm;
-- What products are most often sold together? 
 SELECT * FROM sales_data_sample WHERE ORDERNUMBER = 10121;

SELECT 
	PRODUCTCODE
FROM 
	sales_data_sample
WHERE
	ORDERNUMBER IN 
		(SELECT ORDERNUMBER
		FROM (SELECT 
				ORDERNUMBER,
				COUNT(*) AS rn 
			FROM 
				sales_data_sample 
			WHERE 
				STATUS = 'SHIPPED'
			GROUP BY ORDERNUMBER) AS m 
		WHERE 
			rn = 2 
		);

SELECT 
	* 
FROM 
	sales_data_sample
GROUP BY 
	PRODUCTCODE
ORDER BY 
	ORDERNUMBER;


 SELECT A.PRODUCTCODE,B.PRODUCTCODE, COUNT(*) AS CNT
 FROM sales_data_sample A,
      sales_data_sample B
 WHERE A.ORDERNUMBER = B.ORDERNUMBER
 AND   A.PRODUCTCODE <> B.PRODUCTCODE
 GROUP BY A.PRODUCTCODE,
          B.PRODUCTCODE
 HAVING COUNT(*) > 1
 ORDER BY CNT DESC;
 
 SELECT COUNT(*)
    FROM sales_data_sample;
 SELECT *
 FROM  sales_data_sample
 WHERE ORDERNUMBER IN (
SELECT DISTINCT A.ORDERNUMBER
   FROM sales_data_sample A,
        sales_data_sample B
   WHERE A.PRODUCTCODE = 'S18_3232'
   AND   B.PRODUCTCODE = 'S18_2319'
   AND   A.ORDERNUMBER = B.ORDERNUMBER);
   
 
 
  SELECT A.PRODUCTCODE,B.PRODUCTCODE, COUNT(*) AS CNT
  FROM sales_data_sample A,
	sales_data_sample B
 WHERE A.ORDERNUMBER = B.ORDERNUMBER
-- AND   A.ORDERNUMBER = 10107
 AND   A.PRODUCTCODE <> B.PRODUCTCODE
 GROUP BY A.PRODUCTCODE,
          B.PRODUCTCODE
 HAVING COUNT(*) > 0
 ORDER BY CNT DESC;