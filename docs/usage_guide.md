# Hướng dẫn Sử dụng Hệ thống Hadoop-Hive (Cấu trúc mới)

Ghi chú: Thư mục setup chuẩn là scripts/setup (được Makefile sử dụng). Các wrapper infra/setup đã được gỡ bỏ để tránh trùng lặp. Với mọi hướng dẫn cũ trỏ vào infra/setup, hãy thay bằng scripts/setup.

## Tổng quan
Tài liệu này hướng dẫn cách sử dụng hệ thống Hadoop-Hive để phân tích dữ liệu hàng không, từ cơ bản đến nâng cao.

## Khởi động Hệ thống

### Kiểm tra Trạng thái
```bash
# Kiểm tra tổng thể
hadoop-hive-status

# Kiểm tra từng service
sudo systemctl status mysql
sudo systemctl status hadoop
sudo systemctl status hive
```

### Khởi động Services
```bash
# Khởi động tất cả
sudo systemctl start mysql
sudo systemctl start hadoop
sudo systemctl start hive

# Hoặc sử dụng script
start-hadoop
start-hive
```

### Dừng Services
```bash
# Dừng theo thứ tự
stop-hive
stop-hadoop
sudo systemctl stop mysql
```

## Làm việc với HDFS

### Các lệnh HDFS cơ bản
```bash
# Chuyển sang user hadoop
sudo su - hadoop

# Liệt kê files/directories
hdfs dfs -ls /
hdfs dfs -ls /user/hive/warehouse

# Tạo directory
hdfs dfs -mkdir /data/new_folder

# Upload file từ local lên HDFS
hdfs dfs -put local_file.csv /data/

# Download file từ HDFS về local
hdfs dfs -get /data/file.csv ./

# Copy file trong HDFS
hdfs dfs -cp /data/source.csv /data/destination.csv

# Xóa file/directory
hdfs dfs -rm /data/file.csv
hdfs dfs -rm -r /data/folder

# Xem nội dung file
hdfs dfs -cat /data/file.csv
hdfs dfs -head /data/file.csv
hdfs dfs -tail /data/file.csv

# Kiểm tra dung lượng
hdfs dfs -du -h /data
hdfs dfs -df -h
```

### Quản lý Permissions
```bash
# Thay đổi quyền
hdfs dfs -chmod 755 /data/file.csv
hdfs dfs -chmod -R 777 /user/hive/warehouse

# Thay đổi owner
hdfs dfs -chown hadoop:hadoop /data/file.csv
hdfs dfs -chown -R hadoop:hadoop /data/
```

## Làm việc với Hive

### Kết nối với Hive

#### Sử dụng Beeline (Khuyến nghị)
```bash
# Kết nối với HiveServer2
sudo -u hadoop /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000

# Kết nối với username/password (nếu có authentication)
sudo -u hadoop /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000 -n hadoop -p

# Chạy query từ file (khuyến nghị dùng run-hql trong repo)
./bin/run-hql sql/hive/ddl/01_create_database.hql
# Hoặc trực tiếp (chạy từ root repo):
sudo -u hadoop /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000 -f $(pwd)/sql/hive/ddl/01_create_database.hql

# Chạy query trực tiếp
sudo -u hadoop /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000 -e "SHOW DATABASES;"
```

#### Sử dụng Hive CLI (Deprecated)
```bash
sudo -u hadoop /opt/hive/bin/hive
```

### Quản lý Database

#### Tạo và sử dụng Database
```sql
-- Tạo database
CREATE DATABASE IF NOT EXISTS my_analytics
COMMENT 'Database for analytics'
LOCATION '/user/hive/warehouse/my_analytics.db';

-- Liệt kê databases
SHOW DATABASES;

-- Sử dụng database
USE my_analytics;

-- Xem thông tin database
DESCRIBE DATABASE my_analytics;

-- Xóa database
DROP DATABASE IF EXISTS my_analytics CASCADE;
```

### Quản lý Tables

#### Tạo Tables
```sql
-- External table (dữ liệu ở ngoài warehouse)
CREATE EXTERNAL TABLE flights_external (
    year INT,
    month INT,
    carrier STRING,
    origin STRING,
    dest STRING,
    distance INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/data/flights/'
TBLPROPERTIES ('skip.header.line.count'='1');

-- Managed table (dữ liệu trong warehouse)
CREATE TABLE flights_managed (
    year INT,
    month INT,
    carrier STRING,
    origin STRING,
    dest STRING,
    distance INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS ORC;

-- Partitioned table
CREATE TABLE flights_partitioned (
    carrier STRING,
    origin STRING,
    dest STRING,
    distance INT
)
PARTITIONED BY (year INT, month INT)
STORED AS ORC;

-- Bucketed table
CREATE TABLE flights_bucketed (
    year INT,
    month INT,
    carrier STRING,
    origin STRING,
    dest STRING,
    distance INT
)
CLUSTERED BY (carrier) INTO 4 BUCKETS
STORED AS ORC;
```

#### Quản lý Tables
```sql
-- Liệt kê tables
SHOW TABLES;
SHOW TABLES LIKE 'flights*';

-- Xem cấu trúc table
DESCRIBE flights_managed;
DESCRIBE FORMATTED flights_partitioned;

-- Xem partitions
SHOW PARTITIONS flights_partitioned;

-- Thêm partition
ALTER TABLE flights_partitioned 
ADD PARTITION (year=2023, month=1);

-- Xóa partition
ALTER TABLE flights_partitioned 
DROP PARTITION (year=2023, month=1);

-- Đổi tên table
ALTER TABLE old_table_name RENAME TO new_table_name;

-- Thêm column
ALTER TABLE flights_managed 
ADD COLUMNS (delay_reason STRING);

-- Xóa table
DROP TABLE IF EXISTS flights_managed;
```

### Load Dữ liệu

#### Load từ HDFS
```sql
-- Load vào table thường
LOAD DATA INPATH '/data/flights.csv' 
OVERWRITE INTO TABLE flights_managed;

-- Load vào partitioned table
LOAD DATA INPATH '/data/flights_2023_01.csv' 
INTO TABLE flights_partitioned 
PARTITION (year=2023, month=1);

-- Load với dynamic partitioning
SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;

INSERT OVERWRITE TABLE flights_partitioned 
PARTITION (year, month)
SELECT carrier, origin, dest, distance, year, month
FROM flights_external;
```

#### Insert dữ liệu
```sql
-- Insert từ query
INSERT INTO TABLE flights_managed
SELECT * FROM flights_external
WHERE year = 2023;

-- Insert overwrite
INSERT OVERWRITE TABLE flights_managed
SELECT * FROM flights_external;

-- Insert với partition
INSERT INTO TABLE flights_partitioned 
PARTITION (year=2023, month=1)
SELECT carrier, origin, dest, distance
FROM flights_external
WHERE year = 2023 AND month = 1;
```

## Truy vấn Dữ liệu

### Truy vấn Cơ bản
```sql
-- Select cơ bản
SELECT * FROM flights_managed LIMIT 10;

-- Select với điều kiện
SELECT carrier, origin, dest, distance
FROM flights_managed
WHERE year = 2023 AND month = 1;

-- Aggregation
SELECT 
    carrier,
    COUNT(*) as flight_count,
    AVG(distance) as avg_distance
FROM flights_managed
GROUP BY carrier
ORDER BY flight_count DESC;

-- Join tables
SELECT 
    f.carrier,
    a.description,
    COUNT(*) as flight_count
FROM flights_managed f
JOIN airlines a ON f.carrier = a.code
GROUP BY f.carrier, a.description;
```

### Truy vấn Nâng cao
```sql
-- Window functions
SELECT 
    carrier,
    origin,
    dest,
    distance,
    ROW_NUMBER() OVER (PARTITION BY carrier ORDER BY distance DESC) as rank
FROM flights_managed;

-- CTE (Common Table Expression)
WITH carrier_stats AS (
    SELECT 
        carrier,
        COUNT(*) as total_flights,
        AVG(distance) as avg_distance
    FROM flights_managed
    GROUP BY carrier
)
SELECT * FROM carrier_stats
WHERE total_flights > 100;

-- Subquery
SELECT carrier, avg_distance
FROM (
    SELECT 
        carrier,
        AVG(distance) as avg_distance
    FROM flights_managed
    GROUP BY carrier
) t
WHERE avg_distance > 1000;
```

### Tối ưu hóa Truy vấn

#### Sử dụng Partition Pruning
```sql
-- Tốt: sử dụng partition columns trong WHERE
SELECT COUNT(*)
FROM flights_partitioned
WHERE year = 2023 AND month = 1;

-- Không tốt: không sử dụng partition columns
SELECT COUNT(*)
FROM flights_partitioned
WHERE carrier = 'AA';
```

#### Sử dụng Bucketing
```sql
-- Tốt: join trên bucketed columns
SELECT f1.carrier, COUNT(*)
FROM flights_bucketed f1
JOIN flights_bucketed f2 ON f1.carrier = f2.carrier
GROUP BY f1.carrier;
```

#### Sử dụng Vectorization
```sql
-- Bật vectorization
SET hive.vectorized.execution.enabled = true;
SET hive.vectorized.execution.reduce.enabled = true;

-- Query sẽ được tối ưu hóa
SELECT carrier, AVG(distance)
FROM flights_managed
WHERE year = 2023
GROUP BY carrier;
```

## Phân tích Dữ liệu Hàng không

### Các Truy vấn Phân tích Thường dùng

#### 1. Thống kê Tổng quan
```sql
-- Tổng số chuyến bay theo hãng
SELECT 
    f.carrier,
    a.description,
    COUNT(*) as total_flights
FROM flights_managed f
LEFT JOIN airlines a ON f.carrier = a.code
GROUP BY f.carrier, a.description
ORDER BY total_flights DESC;

-- Top 10 tuyến bay bận rộn nhất
SELECT 
    origin,
    dest,
    COUNT(*) as flight_count
FROM flights_managed
GROUP BY origin, dest
ORDER BY flight_count DESC
LIMIT 10;
```

#### 2. Phân tích Theo Thời gian
```sql
-- Xu hướng theo tháng
SELECT 
    year,
    month,
    COUNT(*) as flight_count
FROM flights_managed
GROUP BY year, month
ORDER BY year, month;

-- So sánh theo năm
SELECT 
    year,
    COUNT(*) as total_flights,
    COUNT(DISTINCT carrier) as unique_carriers
FROM flights_managed
GROUP BY year;
```

#### 3. Phân tích Khoảng cách
```sql
-- Phân loại chuyến bay theo khoảng cách
SELECT 
    CASE 
        WHEN distance < 500 THEN 'Short haul'
        WHEN distance < 1500 THEN 'Medium haul'
        ELSE 'Long haul'
    END as flight_type,
    COUNT(*) as flight_count,
    AVG(distance) as avg_distance
FROM flights_managed
GROUP BY 
    CASE 
        WHEN distance < 500 THEN 'Short haul'
        WHEN distance < 1500 THEN 'Medium haul'
        ELSE 'Long haul'
    END;
```

### Sử dụng Views
```sql
-- Tạo view cho phân tích thường dùng
CREATE VIEW flight_summary AS
SELECT 
    year,
    month,
    carrier,
    COUNT(*) as flight_count,
    AVG(distance) as avg_distance,
    MIN(distance) as min_distance,
    MAX(distance) as max_distance
FROM flights_managed
GROUP BY year, month, carrier;

-- Sử dụng view
SELECT * FROM flight_summary
WHERE year = 2023 AND flight_count > 50;
```

## Performance Monitoring

### Phân tích Execution Plan
```sql
-- Xem execution plan
EXPLAIN SELECT carrier, COUNT(*) 
FROM flights_managed 
GROUP BY carrier;

-- Xem detailed plan
EXPLAIN EXTENDED SELECT carrier, COUNT(*) 
FROM flights_managed 
GROUP BY carrier;

-- Xem vectorization details
EXPLAIN VECTORIZATION DETAIL SELECT carrier, AVG(distance)
FROM flights_managed 
GROUP BY carrier;
```

### Monitoring Query Performance
```sql
-- Bật query logging
SET hive.server2.logging.operation.enabled = true;

-- Hiển thị thống kê
SET hive.exec.post.hooks = org.apache.hadoop.hive.ql.hooks.PostExecTezSummaryPrinter;

-- Chạy query và xem stats
SELECT carrier, COUNT(*) as cnt
FROM flights_managed
GROUP BY carrier;
```

### Table Statistics
```sql
-- Tạo table statistics
ANALYZE TABLE flights_managed COMPUTE STATISTICS;

-- Tạo column statistics
ANALYZE TABLE flights_managed COMPUTE STATISTICS FOR COLUMNS;

-- Xem statistics
DESCRIBE FORMATTED flights_managed;
```

## Troubleshooting

### Lỗi thường gặp

#### 1. Table not found
```sql
-- Kiểm tra database hiện tại
SELECT current_database();

-- Chuyển database
USE airline_analytics;

-- Liệt kê tables
SHOW TABLES;
```

#### 2. Permission denied
```bash
# Kiểm tra quyền HDFS
hdfs dfs -ls -la /user/hive/warehouse

# Cấp quyền
hdfs dfs -chmod -R 777 /user/hive/warehouse
```

#### 3. Out of memory
```sql
-- Giảm memory usage
SET mapreduce.map.memory.mb = 512;
SET mapreduce.reduce.memory.mb = 1024;

-- Tăng parallelism
SET mapreduce.job.reduces = 4;
```

#### 4. Slow queries
```sql
-- Bật compression
SET hive.exec.compress.output = true;
SET hive.exec.compress.intermediate = true;

-- Bật vectorization
SET hive.vectorized.execution.enabled = true;

-- Sử dụng CBO
SET hive.cbo.enable = true;
```

## Best Practices

### 1. Table Design
- Sử dụng partitioning cho time-based queries
- Sử dụng bucketing cho join operations
- Chọn file format phù hợp (ORC, Parquet)
- Thiết lập compression

### 2. Query Optimization
- Sử dụng partition pruning
- Tránh SELECT *
- Sử dụng appropriate joins
- Limit kết quả khi test

### 3. Data Management
- Thường xuyên ANALYZE tables
- Cleanup old partitions
- Monitor storage usage
- Backup important data

### 4. Performance Tuning
- Tune memory settings
- Enable vectorization
- Use appropriate parallelism
- Monitor query execution plans

## Tài nguyên Tham khảo

### HQL Reference
- [Hive Language Manual](https://cwiki.apache.org/confluence/display/Hive/LanguageManual)
- [Hive Functions](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+UDF)

### Performance Tuning
- [Hive Performance Tuning](https://cwiki.apache.org/confluence/display/Hive/Configuration+Properties)
- [Hadoop Performance Tuning](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/ClusterSetup.html)

### Troubleshooting
- [Hive Troubleshooting](https://cwiki.apache.org/confluence/display/Hive/Troubleshooting)
- [HDFS Commands Guide](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSCommands.html)
