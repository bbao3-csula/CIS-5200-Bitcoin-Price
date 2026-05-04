-- Upload file to Linux file systems
scp btcusd_1-min_data.csv [your_user]@132.226.148.236:~

-- Make BitcoinPrice directory in HDFS
hdfs dfs -mkdir BitcoinPrice

-- Put Linux file system dataset into HDFS
hdfs dfs -put btcusd_1-min_data.csv BitcoinPrice

-- Remove dataset in Linux file system
rm btcusd_1-min_data.csv

-- Enter beeline client
beeline

-- Use personal database
use your_user;

-- Create table
CREATE EXTERNAL TABLE bitcoin_price (
	ts BIGINT, 
	open DOUBLE,
	high DOUBLE,
	low DOUBLE,
	close DOUBLE,
	volume DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/user/your_user/BitcoinPrice'
TBLPROPERTIES ("skip.header.line.count"="1");

-- Convert unix time to iso time
CREATE TABLE bitcoin_price_clean AS
SELECT
    from_unixtime(ts) AS ts,
    open,
    high,
    low,
    close,
    volume
FROM bitcoin_price;

-- Export to HDFS
INSERT OVERWRITE DIRECTORY '/user/your_user/BitcoinPriceClean'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
SELECT * FROM bitcoin_price_clean;

-- Download to local systems
scp [your_user]@132.226.148.236:/home/your_user/BitcoinPriceClean/000000_0 ~/Downloads/bitcoin_price.csv

-- Cleaned view
CREATE VIEW bitcoin_price_simple AS
SELECT
	ts,
	close,
	volume
FROM bitcoin_price_clean;

-- Test cleaned view
SELECT * FROM bitcoin_price_simple LIMIT 10;

-- Price Trend over Time Analysis
SELECT
	substr(ts, 1, 10) AS dt,
	ROUND(AVG(close), 2) AS avg_price
FROM bitcoin_price_simple
GROUP BY substr(ts, 1, 10)
ORDER BY dt;

-- Volume vs Price Analysis
SELECT 
	substr(ts, 1, 13) AS hr,
	ROUND(AVG(close), 2), AS avg_price,
	ROUND(SUM(volume), 2), AS total_volume
FROM bitcoin_price_simple
GROUP BY substr(ts, 1, 13)
ORDER BY hr;

-- Volatility Analysis
SELECT 
	substr(ts, 1, 10) AS dt,
	ROUND(STDDEV(close), 2) AS volatility
FROM bitcoin_price_simple
GROUP BY substr(ts, 1, 10)
ORDER BY dt;

-- Time-of-Day Pattern Analysis
SELECT 
	hour(ts) AS hr,
	ROUND(AVG(close), 2) AS avg_price, 
	ROUND(SUM(volume), 2) AS total_volume
FROM bitcoin_price_simple
GROUP BY hour(ts)
ORDER BY hr;