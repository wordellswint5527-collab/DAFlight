-- Script để setup Hive Metastore Database
-- Chạy script này trên MySQL server

-- Tạo database cho Hive Metastore
CREATE DATABASE IF NOT EXISTS hive_metastore;

-- Tạo user cho Hive
CREATE USER IF NOT EXISTS 'hive'@'localhost' IDENTIFIED BY 'hive123';
CREATE USER IF NOT EXISTS 'hive'@'%' IDENTIFIED BY 'hive123';

-- Cấp quyền cho user hive
GRANT ALL PRIVILEGES ON hive_metastore.* TO 'hive'@'localhost';
GRANT ALL PRIVILEGES ON hive_metastore.* TO 'hive'@'%';

-- Flush privileges
FLUSH PRIVILEGES;

-- Hiển thị thông tin
SELECT User, Host FROM mysql.user WHERE User = 'hive';
SHOW DATABASES LIKE 'hive%';

