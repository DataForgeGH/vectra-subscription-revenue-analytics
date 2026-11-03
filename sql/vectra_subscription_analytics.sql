-- checking the number of records in my dataset
SELECT COUNT(*) 
FROM vectra_analytics.stg_vectra_raw;

-- checking the structure of my data
DESCRIBE vectra_analytics.stg_vectra_raw; 

-- DISTINT VALUES IN status
SELECT DISTINCT status 
COLLATE utf8mb4_bin AS case_sensitive_status
FROM vectra_analytics.stg_vectra_raw;

SELECT status, COUNT(*) AS status_count
FROM vectra_analytics.stg_vectra_raw
WHERE status IN ('Downgraded','Churned', 'Active', 'CANCELLED', 'active')
GROUP BY  status;

-- checking for null values in status
SELECT status, COUNT(*) AS blank_status
FROM vectra_analytics.stg_vectra_raw
WHERE status IS NULL 
GROUP BY status;

-- Checking for whitespaces
SELECT status, COUNT(*) AS blank_status
FROM vectra_analytics.stg_vectra_raw
WHERE TRIM(status) = ''
GROUP BY status; 

-- checking cancellation_date
SELECT status, cancellation_date
FROM vectra_analytics.stg_vectra_raw
GROUP BY status, cancellation_date;

-- checking for number of empty and filled roow in the cancellation_column
SELECT 
SUM(CASE WHEN cancellation_date <>'' AND TRIM(status) = '' THEN 1 ELSE 0 END) AS filled_total,
SUM(CASE WHEN cancellation_date= '' AND TRIM(status) = '' THEN 1 ELSE 0 END) AS empty_total
FROM vectra_analytics.stg_vectra_raw;

-- checking for date inconsistency
SELECT status, signup_date
FROM vectra_analytics.stg_vectra_raw
 WHERE STR_TO_DATE(signup_date, '%d-%M-%Y')
GROUP BY status, signup_date;

-- INSERTING NULL INTO EMPTY VALUES
UPDATE vectra_analytics.stg_vectra_raw
SET status = NULL
WHERE TRIM(status) = ''
;

-- total status null count
SELECT status, COUNT(*) AS total_nulls
FROM vectra_analytics.stg_vectra_raw
WHERE status IS NULL
GROUP BY status;

-- total trim(status) count
SELECT 	status, COUNT(*) AS total_nulls
FROM vectra_analytics.stg_vectra_raw
WHERE TRIM(status) = ''
GROUP BY status;

-- counting total rows in the table
SELECT COUNT(*) AS total_rows
FROM vectra_analytics.stg_vectra_raw;

-- status that have have a cancelation date and  not
SELECT status,
SUM(CASE WHEN TRIM(cancellation_date) = '' THEN 1 ELSE 0 END) AS empty_values,
SUM(CASE WHEN cancellation_date <> '' THEN 1 ELSE 0 END) AS filled_values
FROM vectra_analytics.stg_vectra_raw
WHERE status IS NULL
GROUP BY status;

-- inspecting the null or empty values in mrr_amount
SELECT 
SUM(CASE WHEN mrr_amount IS NULL OR TRIM(mrr_amount) = '' THEN 1 ELSE 0 END) AS empty_or_null_values,
SUM(CASE WHEN mrr_amount IS NOT NULL AND TRIM(mrr_amount) <> '' THEN 1 ELSE 0 END) AS filled_values
FROM vectra_analytics.stg_vectra_raw;

-- looking for the $ currency
SELECT 
SUM(CASE WHEN mrr_amount LIKE '%$%' THEN 1 ELSE 0 END) AS currency_symbol,
SUM(CASE WHEN mrr_amount NOT LIKE '%$%' THEN 1 ELSE 0 END) AS non_currency_symbol
FROM vectra_analytics.stg_vectra_raw;

-- values that contain the comma signa
SELECT 
SUM(CASE WHEN mrr_amount LIKE '%,%' THEN 1 ELSE 0 END) AS comma_symbol,
SUM(CASE WHEN mrr_amount NOT LIKE '%,%' THEN 1 ELSE 0 END) AS non_comma_symbol
FROM vectra_analytics.stg_vectra_raw;

-- checking for negative values
SELECT
SUM(CASE WHEN mrr_amount LIKE '%-%' THEN 1 ELSE 0 END) AS negative_values,
SUM(CASE WHEN mrr_amount NOT LIKE '%-%' THEN 1 ELSE 0 END) AS non_negative_symbol_values
FROM vectra_analytics.stg_vectra_raw;

-- checking for 0 values
SELECT mrr_amount 
FROM vectra_analytics.stg_vectra_raw
WHERE TRIM(mrr_amount) = '0';

-- checking for alphabet in mrr_amount
SELECT mrr_amount
FROM vectra_analytics.stg_vectra_raw
WHERE mrr_amount REGEXP '[A-Za-z]';

-- checking for decimal values
SELECT 
SUM(CASE WHEN TRIM(mrr_amount) LIKE '%.%' THEN 1 ELSE 0 END) AS decimal_values
FROM vectra_analytics.stg_vectra_raw;

-- checking for any relationship for negative values of mrr_amount
SELECT transaction_id, 
customer_id, 
signup_date, 
plan_type, 
mrr_amount, 
region_tier, 
acquisition_channel, 
status, cac_cost, 
cancellation_date
FROM vectra_analytics.stg_vectra_raw
WHERE mrr_amount LIKE '%-%'
GROUP BY transaction_id, 
customer_id, 
signup_date, 
plan_type, 
mrr_amount, 
region_tier, 
acquisition_channel, 
status, cac_cost, 
cancellation_date;

-- confirming the location of the negative soign
SELECT mrr_amount
FROM vectra_analytics.stg_vectra_raw
WHERE mrr_amount REGEXP '^-';

-- cleaning the mrr_amount
SELECT mrr_amount AS raw_value,
	CASE
    WHEN TRIM(mrr_amount) = '' OR mrr_amount IS NULL THEN NULL
    ELSE CAST(
    REPLACE(
		REPLACE(TRIM(mrr_amount), '$', ''),
        ',', '') AS DECIMAL(10, 2)
        ) END AS cleaned_value
FROM vectra_analytics.stg_vectra_raw;

-- checking validation to decimal
SELECT mrr_amount,
CASE
WHEN TRIM(mrr_amount) REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
THEN 'Safe'
ELSE 'Unsafe'
	END AS validation_status
FROM vectra_analytics.stg_vectra_raw;

-- REMOVING THE $ AND , fFROM THE TABLE
UPDATE vectra_analytics.stg_vectra_raw
SET mrr_amount = REPLACE(
	REPLACE(mrr_amount, '$' , ''),
    ',', '')
WHERE mrr_amount LIKE '%$%'
	OR mrr_amount LIKE '%,%';

-- CREATING A BACKUP FILE
CREATE TABLE vectra_analytics.stg_vectra_raw_backup
AS 
SELECT *
FROM vectra_analytics.stg_vectra_raw;

-- confirming unsafe before update
SELECT COUNT(mrr_amount) AS Unsafe
FROM vectra_analytics.stg_vectra_raw_backup
WHERE TRIM(mrr_amount) NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$';

-- confirming unsafe after update
SELECT COUNT(mrr_amount) AS Unsafe
FROM vectra_analytics.stg_vectra_raw
WHERE TRIM(mrr_amount) NOT REGEXP '^-?[0-9]+(\\.[0-9]+)?$';

-- removing the negative sign at the very first digit
UPDATE vectra_analytics.stg_vectra_raw
SET mrr_amount = REPLACE(mrr_amount,'-', '')
WHERE mrr_amount LIKE '-%';

-- confirming non-negative sign infront of numbers
SELECT COUNT(mrr_amount) AS Unsafe
FROM vectra_analytics.stg_vectra_raw
WHERE TRIM(mrr_amount) NOT REGEXP '^[0-9]+(\\.[0-9]+)?$';

-- comparing negative numbers to that of the positive numbers
SELECT COUNT(vs.mrr_amount) AS Positive, COUNT(vb.mrr_amount) AS Negative
FROM vectra_analytics.stg_vectra_raw  as vs
JOIN vectra_analytics.stg_vectra_raw_backup as vb
ON vs.transaction_id = vb.transaction_id
WHERE ABS(vb.mrr_amount) = vs.mrr_amount AND vb.mrr_amount LIKE '-%';

-- information of the empty columns
SELECT  mrr_amount, status, cancellation_date
FROM vectra_analytics.stg_vectra_raw_backup
WHERE TRIM(mrr_amount) = '' or NULL;

-- creating a backup table
CREATE TABLE vectra_analytics.stg_vectra_raw_backup2
AS
SELECT *
FROM vectra_analytics.stg_vectra_raw;

-- UPDATING THE EMPTY ROWS IN THE mrr_amount coluimn
UPDATE vectra_analytics.stg_vectra_raw
SET mrr_amount = NULL
WHERE TRIM(mrr_amount) = '';

-- counting null values
SELECT COUNT(*) AS NULL_COUNT
FROM vectra_analytics.stg_vectra_raw
WHERE mrr_amount IS NULL;

-- checking the pattern for active status
SELECT status, region_tier, signup_date
FROM vectra_analytics.stg_vectra_raw_backup2
WHERE BINARY status = 'active';

-- checking the pattern for Active status
SELECT status, region_tier, signup_date
FROM vectra_analytics.stg_vectra_raw_backup2
WHERE BINARY status = 'Active';

-- creating a backup file
CREATE TABLE vectra_analytics.stg_vectra_raw_backup3
	AS
SELECT *
FROM vectra_analytics.stg_vectra_raw;

-- Changing the text casing of status column
UPDATE vectra_analytics.stg_vectra_raw
SET status = CONCAT(
    UPPER(LEFT(status, 1)),
    LOWER(SUBSTRING(status, 2))
    );
    
-- confirming upper case doesn't exist
SELECT COUNT(status)
FROM vectra_analytics.stg_vectra_raw
WHERE BINARY status = UPPER(status)
AND BINARY status REGEXP BINARY '[A-Z]';

-- investigating the acquisition_channel 
SELECT acquisition_channel, plan_type,region_tier,cancellation_date
FROM vectra_analytics.stg_vectra_raw;

-- counting for empty rows in acquisation_chanel
SELECT COUNT(acquisition_channel)
FROM vectra_analytics.stg_vectra_raw
WHERE TRIM(acquisition_channel)= '';

-- checking for any relation of acquisition_channel and plan_type
SELECT plan_type, COUNT(acquisition_channel) AS total_acquisition_channel
FROM vectra_analytics.stg_vectra_raw
WHERE TRIM(acquisition_channel) = ''
GROUP BY plan_type;

-- checking for any relation of acquisition_channel and plan_type
SELECT plan_type, COUNT(acquisition_channel) AS total_acquisition_channel
FROM vectra_analytics.stg_vectra_raw
GROUP BY plan_type;

-- checking for any relation of acquisition_channel and region_tier
SELECT region_tier, COUNT(acquisition_channel) AS total_acquisition_channel
FROM vectra_analytics.stg_vectra_raw
GROUP BY region_tier;

-- checking for any relation of acquisition_channel and plan_type
SELECT region_tier, COUNT(acquisition_channel) AS total_acquisition_channel
FROM vectra_analytics.stg_vectra_raw
WHERE TRIM(acquisition_channel) = ''
GROUP BY region_tier;

-- creating backup 4
CREATE TABLE vectra_analytics.stg_vectra_raw_backup4
	AS
SELECT *
FROM vectra_analytics.stg_vectra_raw;

-- Filling empty rows in acquisition rows with Unknown
UPDATE vectra_analytics.stg_vectra_raw
SET acquisition_channel = 'Unknown'
WHERE TRIM(acquisition_channel) = '';

-- Counting total number of unknown
SELECT COUNT(acquisition_channel) AS total
FROM vectra_analytics.stg_vectra_raw
WHERE acquisition_channel = 'Unknown';

-- Checking for lower capitalization
SELECT plan_type
FROM vectra_analytics.stg_vectra_raw
WHERE plan_type REGEXP '[a-z]' COLLATE utf8mb4_bin;

-- checking for upper capitalization
SELECT plan_type
FROM vectra_analytics.stg_vectra_raw
WHERE plan_type REGEXP '[A-Z]' COLLATE utf8mb4_bin;

-- creating backup 5
CREATE TABLE vectra_analytics.stg_vectra_raw_backup5
	AS
SELECT *
FROM vectra_analytics.stg_vectra_raw;

-- UPDATING plan_type
UPDATE vectra_analytics.stg_vectra_raw
SET plan_type = CASE
	WHEN Lower(TRIM(plan_type)) LIKE 'start%' THEN 'Starter'
    WHEN Lower(TRIM(plan_type)) LIKE 'growth%' THEN 'Growth'
    WHEN Lower(TRIM(plan_type)) LIKE 'enterprise%'
    OR Lower(TRIM(plan_type)) LIKE 'ent_l1%' THEN 'Enterprise'
    WHEN Lower(TRIM(plan_type)) = '' THEN NULL
ELSE NULL
END;

-- confirming succesful clean plan_type
SELECT DISTINCT plan_type
FROM vectra_analytics.stg_vectra_raw;

-- Counting every plan_type in the column
SELECT plan_type, COUNT(*) AS total_count
FROM vectra_analytics.stg_vectra_raw
GROUP BY plan_type;

-- checking for distint in region_tier
SELECT DISTINCT region_tier, count(region_tier)
FROM vectra_analytics.stg_vectra_raw
GROUP BY region_tier;

-- Creating backup 6
CREATE TABLE vectra_analytics.stg_vectra_raw_backup6
AS
SELECT *
FROM vectra_analytics.stg_vectra_raw;

-- creating two new columns
ALTER TABLE vectra_analytics.stg_vectra_raw
ADD COLUMN region VARCHAR(20) AFTER region_tier,
ADD COLUMN tier VARCHAR(20) AFTER region;

-- creating backup 7
CREATE TABLE vectra_analytics.stg_vectra_raw_backup7
AS 
SELECT *
FROM vectra_analytics.stg_vectra_raw;

-- UPDATING region column
UPDATE vectra_analytics.stg_vectra_raw
SET region = SUBSTRING_INDEX(
	SUBSTRING_INDEX(region_tier, '_', 1),
	'|', 1);
    
-- confirming a succesful change
SELECT region
FROM vectra_analytics.stg_vectra_raw
WHERE region = region_tier;

SELECT region, COUNT(*) AS total_count
FROM vectra_analytics.stg_vectra_raw
GROUP BY region;

-- filling up the tier column
UPDATE vectra_analytics.stg_vectra_raw
SET tier = 
CASE
	WHEN UPPER(TRIM(region_tier)) = 'UNKNOWN' THEN 'UNKNOWN'
    ELSE
	CONCAT('TIER_', RIGHT(TRIM(region_tier), 1))
END;

-- Confirming a succesful change
SELECT region, tier, COUNT(*) AS total_count
FROM vectra_analytics.stg_vectra_raw
GROUP BY region, tier;

-- create backup 8
CREATE TABLE vectra_analytics.stg_vectra_raw_backup8
	AS
SELECT *
FROM vectra_analytics.stg_vectra_raw;

-- DROPPING region_tier column
ALTER TABLE vectra_analytics.stg_vectra_raw
DROP COLUMN region_tier;

-- confirming succesful drop
SELECT *
FROM vectra_analytics.stg_vectra_raw;

-- DISTINCT COUNT OF customer_id
SELECT
COUNT(CASE
 WHEN customer_id COLLATE utf8mb4_bin LIKE 'CUST-%'
 THEN 1
 END) AS UPPERCASE,
 COUNT(CASE
 WHEN customer_id COLLATE utf8mb4_bin LIKE 'cust-%'
 THEN 1
 END) AS LOWERCASE,
 COUNT(CASE
 WHEN customer_id COLLATE utf8mb4_bin REGEXP '^[0-9]+$'
 THEN 1
 END) AS NUMERICS
 FROM vectra_analytics.stg_vectra_raw;
 
 -- creating backup 9
 CREATE TABLE vectra_analytics.stg_vectra_raw_backup9
	AS
SELECT *
FROM vectra_analytics.stg_vectra_raw;

SELECT COUNT(DISTINCT(customer_id))
 FROM vectra_analytics.stg_vectra_raw;
 
 -- updating the customer_id column
 UPDATE vectra_analytics.stg_vectra_raw
SET customer_id = CONCAT('CUST-', RIGHT(TRIM(customer_id), 4));

-- comparing real file to backup file for customer_id
SELECT COUNT(r.customer_id) AS original, COUNT(b.customer_id) AS backup
FROM vectra_analytics.stg_vectra_raw r
JOIN vectra_analytics.stg_vectra_raw_backup9 b
ON r.transaction_id = b.transaction_id
WHERE RIGHT(r.customer_id,4) != RIGHT(b.customer_id,4);

-- pulling 30 values from signup_date
SELECT signup_date 
FROM vectra_analytics.stg_vectra_raw
LIMIT 30;

-- creating backup_10
CREATE TABLE vectra_analytics.stg_vectra_raw_backup10
	AS
SELECT *
FROM vectra_analytics.stg_vectra_raw;

-- ALTERING TABLE
ALTER TABLE vectra_analytics.stg_vectra_raw
ADD COLUMN signup_date1 DATE AFTER signup_date;

-- creating backup11
CREATE TABLE vectra_analytics.stg_vectra_raw_backup11
	AS
SELECT *
FROM vectra_analytics.stg_vectra_raw;

-- checking for / dates difference
SELECT signup_date
FROM vectra_analytics.stg_vectra_raw
WHERE signup_date LIKE '%/%/%'
AND (SUBSTRING_INDEX
		(SUBSTRING_INDEX(
	signup_date, '/', 2),
'/', -1)) > 12;

-- checking for the difference range
SELECT
    COUNT(*) AS total_slash_dates,

    SUM(
        CAST(SUBSTRING_INDEX(signup_date, '/', 1) AS UNSIGNED)
        BETWEEN 1 AND 12
    ) AS first_part_1_to_12,

    SUM(
        CAST(
            SUBSTRING_INDEX(
                SUBSTRING_INDEX(signup_date, '/', 2),
                '/', -1
            ) AS UNSIGNED
        ) BETWEEN 13 AND 31
    ) AS second_part_13_to_31

FROM vectra_analytics.stg_vectra_raw
WHERE signup_date REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$';

-- making preview of no NULL values
SELECT signup_date
FROM vectra_analytics.stg_vectra_raw
WHERE signup_date IS NOT NULL
  AND TRIM(signup_date) <> ''
  AND CASE
        WHEN signup_date LIKE '%-%-%'
             AND signup_date REGEXP '[a-zA-Z]'
            THEN STR_TO_DATE(signup_date, '%d-%b-%Y')

        WHEN signup_date LIKE '%-%-%'
            THEN STR_TO_DATE(signup_date, '%Y-%m-%d')

        WHEN signup_date LIKE '%/%/%'
            THEN STR_TO_DATE(signup_date, '%m/%d/%Y')

        ELSE NULL
      END IS NULL;

-- UPDATING signup_date1
UPDATE vectra_analytics.stg_vectra_raw
SET signup_date1=
 CASE
	 WHEN signup_date LIKE '%-%-%' AND signup_date REGEXP '[a-zA-Z]' THEN STR_TO_DATE(signup_date, '%d-%b-%Y')
	WHEN signup_date LIKE '%-%-%' THEN STR_TO_DATE(signup_date, '%Y-%m-%d')
    WHEN signup_date LIKE '%/%/%' THEN STR_TO_DATE(signup_date, '%m/%d/%Y')
	ELSE NULL 
END;

-- creating backup 12
CREATE TABLE vectra_analytics.stg_vectra_raw_backup12
	AS
SELECT *
FROM vectra_analytics.stg_vectra_raw;

-- Dropping signup_date column
ALTER TABLE vectra_analytics.stg_vectra_raw
DROP COLUMN signup_date;

-- renaming signup_date1 to signup_date
ALTER TABLE vectra_analytics.stg_vectra_raw
RENAME COLUMN signup_date1 TO signup_date;

-- COUNTING signup_date values
SELECT COUNT(*) AS total_rows
FROM vectra_analytics.stg_vectra_raw_backup12;

-- Checkin signup_date data type
DESCRIBE vectra_analytics.stg_vectra_raw signup_date;

-- coomparaing signup_date for intergrity
SELECT signup_date,
	   signup_date1,
SUBSTRING_INDEX(signup_date, '/', 1) AS original_part,
MONTH(signup_date1) AS cleaned_month
FROM vectra_analytics.stg_vectra_raw_backup12
WHERE signup_date LIKE '%/%/%'
LIMIT 20;

-- comparing signup_date and cancellation_date
SELECT signup_date, cancellation_date
FROM vectra_analytics.stg_vectra_raw
WHERE signup_date > cancellation_date;

-- checking blank values in  cancellation_date
SELECT COUNT(cancellation_date)
FROM vectra_analytics.stg_vectra_raw
WHERE cancellation_date = '';

-- counting different date format in cancellation_date
SELECT
SUM(CASE WHEN STR_TO_DATE(cancellation_date, '%m%d%Y') IS NOT NULL THEN 1 ELSE 0 END) AS 'YYYY-MM-DD',
SUM(CASE WHEN STR_TO_DATE(cancellation_date, '%d-%m-%Y') IS NOT NULL THEN 1 ELSE 0 END) AS 'DD-MM-YYYY',
SUM(CASE WHEN STR_TO_DATE(cancellation_date, '%Y-%m-%d') IS NOT NULL THEN 1 ELSE 0 END) AS 'DD-MM-YYYY'
FROM vectra_analytics.stg_vectra_raw;

-- checking relationship between cancellation_date and status
SELECT mrr_amount, cancellation_date
FROM vectra_analytics.stg_vectra_raw
WHERE cancellation_date = ''
GROUP BY  mrr_amount, cancellation_date;

-- creating backup13
CREATE TABLE vectra_analytics.stg_vectra_raw_backup13
AS
SELECT *
FROM vectra_analytics.stg_vectra_raw;

-- changing empty rowsmin cancellation_date to NULL values
UPDATE  vectra_analytics.stg_vectra_raw
SET cancellation_date = NULL
WHERE cancellation_date = '';

-- changing data type of cancellation_date
ALTER TABLE vectra_analytics.stg_vectra_raw
MODIFY cancellation_date DATE;

-- Counting rows with NULL in cancellation date
SELECT COUNT(*)
FROM vectra_analytics.stg_vectra_raw
WHERE cancellation_date IS NULL;

-- -- Counting rows with date in cancellation date
SELECT COUNT(*)
FROM vectra_analytics.stg_vectra_raw
WHERE cancellation_date IS NOT NULL;

-- Creating backup 14
CREATE TABLE vectra_analytics.stg_vectra_raw_backup14
AS
SELECT *
FROM vectra_analytics.stg_vectra_raw;

-- changing empty rows to NULL values for cac_cost
UPDATE vectra_analytics.stg_vectra_raw
SET cac_cost = NULL
WHERE cac_cost = '';

-- checking for any fail NULL run
SELECT COUNT(*)
FROM vectra_analytics.stg_vectra_raw
WHERE cac_cost = '';

-- changing data type of cac_cost
ALTER TABLE vectra_analytics.stg_vectra_raw
MODIFY cac_cost DECIMAL(10,2);

-- checking for duplicates
SELECT transaction_id, customer_id, signup_date, plan_type, mrr_amount, region
FROM vectra_analytics.stg_vectra_raw
WHERE customer_id = 'CUST-1280' AND signup_date = '2021-08-25';

-- dropping every duplicate
WITH RankedDuplicate AS(
	SELECT transaction_id,
    ROW_NUMBER() OVER(
    PARTITION BY transaction_id, customer_id, signup_date, plan_type, mrr_amount, region
    ) AS row_num
FROM vectra_analytics.stg_vectra_raw
)
DELETE FROM vectra_analytics.stg_vectra_raw
WHERE transaction_id IN (
	SELECT transaction_id
    FROM RankedDuplicate
    WHERE row_num >1
);

-- confirming for a succesful deduction
SELECT customer_id, signup_date, plan_type, mrr_amount, region, COUNT(*) AS repeat_count
FROM vectra_analytics.stg_vectra_raw
GROUP BY customer_id, signup_date, plan_type, mrr_amount, region
HAVING COUNT(*) > 1;



-- CREATING THE DATA MODEL/STAR SCHEMA

-- creating a table for fact_subscriptions
CREATE TABLE fact_subscriptions
	AS
SELECT transaction_id,
	customer_id,
	signup_date,
	plan_type,
	mrr_amount,
	cac_cost,
	status,
	cancellation_date
FROM vectra_analytics.stg_vectra_raw
GROUP BY transaction_id,
	customer_id,
	signup_date,
	plan_type,
	mrr_amount,
	cac_cost,
	status,
	cancellation_date;
    
-- Altering fact_subscriptions
ALTER TABLE fact_subscriptions
ADD PRIMARY KEY (transaction_id),
ADD FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id);

-- making customer_id the primary key by sorting it using the latest signup date to prevent any duplication
CREATE TABLE dim_customers AS
SELECT customer_id, region, tier, acquisition_channel
FROM (
    SELECT 
        customer_id, 
        region, 
        tier, 
        acquisition_channel,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY signup_date DESC) AS row_num
    FROM vectra_analytics.stg_vectra_raw
) ranked_customers
WHERE row_num = 1;

-- Now add your primary key
ALTER TABLE dim_customers
ADD PRIMARY KEY (customer_id);

-- counting all rows in dim_customers
SELECT COUNT(*)
FROM dim_customers;