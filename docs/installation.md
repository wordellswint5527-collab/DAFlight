# Hướng dẫn Cài đặt Hệ thống Hadoop-Hive

## Tổng quan
Tài liệu này hướng dẫn chi tiết cách cài đặt và cấu hình hệ thống Hadoop-Hive trên Azure VM để xử lý dữ liệu lớn.

## Yêu cầu Hệ thống

### Phần cứng tối thiểu
- **CPU**: 4 cores
- **RAM**: 8GB (khuyến nghị 16GB)
- **Disk**: 50GB trống (khuyến nghị 100GB)
- **Network**: Kết nối internet ổn định

### Hệ điều hành
- Ubuntu 18.04 LTS hoặc mới hơn
- Debian 10 hoặc mới hơn
- CentOS 7/8 (cần điều chỉnh một số lệnh)

### Phần mềm cần thiết
- Java 8 (OpenJDK hoặc Oracle JDK)
- MySQL Server 5.7+
- SSH Server
- Wget, Curl, Unzip

## Cài đặt Tự động (Khuyến nghị)

Ghi chú: Thư mục setup chính là scripts/setup (được Makefile sử dụng). Thư mục infra/setup chỉ là lớp tương thích cũ và đã được loại bỏ để tránh trùng lặp. Nếu gặp hướng dẫn cũ trỏ tới infra/setup, hãy dùng scripts/setup thay thế.

### Bước 1: Clone dự án
```bash
git clone <repository-url>
cd hadoop-hive-project
```

### Bước 2: Chạy script cài đặt tự động
```bash
# Giữ tương thích cấu trúc cũ
sudo chmod +x scripts/setup/master_setup.sh
sudo ./scripts/setup/master_setup.sh

# Hoặc dùng Makefile (khuyến nghị)
make install
```

Script này sẽ tự động:
1. Cài đặt các phần mềm cần thiết
2. Tạo user hadoop
3. Cài đặt và cấu hình Hadoop
4. Cài đặt và cấu hình Hive
5. Thiết lập dữ liệu mẫu

### Bước 3: Kiểm tra cài đặt
```bash
# Kiểm tra qua tiện ích hệ thống (sau cài đặt)
hadoop-hive-status

# Hoặc qua Makefile
make status
```

## Cài đặt Thủ công

### Bước 1: Cài đặt Prerequisites
```bash
sudo chmod +x scripts/setup/01_install_prerequisites.sh
sudo ./scripts/setup/01_install_prerequisites.sh
```

### Bước 2: Cài đặt Hadoop
```bash
sudo chmod +x scripts/setup/02_install_hadoop.sh
sudo ./scripts/setup/02_install_hadoop.sh
```

### Bước 3: Cài đặt Hive
```bash
sudo chmod +x scripts/setup/03_install_hive.sh
sudo ./scripts/setup/03_install_hive.sh
```

### Bước 4: Setup dữ liệu
```bash
# Đặt dữ liệu đầu vào theo cấu trúc mới:
# - Đặt airlines.csv, carrier.csv, plane-data.csv tại data/
# - Đặt flights_*.csv tại data/flights/

# Chạy bằng script cũ (tương thích)
sudo chmod +x scripts/setup/04_setup_data.sh
sudo ./scripts/setup/04_setup_data.sh

# Hoặc Makefile
make load-data
```

## Cấu hình Azure VM

### Tạo VM trên Azure
1. Đăng nhập vào Azure Portal
2. Tạo VM mới với cấu hình:
   - **Image**: Ubuntu 20.04 LTS
   - **Size**: Standard_D4s_v3 (4 vCPUs, 16GB RAM)
   - **Disk**: Premium SSD 128GB
   - **Network**: Cho phép SSH (port 22)

### Mở các port cần thiết
```bash
# Trong Azure Portal, vào Network Security Group
# Thêm các inbound rules:
- Port 22 (SSH)
- Port 9870 (HDFS NameNode Web UI)
- Port 8088 (YARN ResourceManager Web UI)
- Port 10002 (HiveServer2 Web UI)
- Port 19888 (MapReduce JobHistory Web UI)
```

### Kết nối SSH
```bash
ssh azureuser@<vm-public-ip>
```

## Xử lý Sự cố

### Lỗi thường gặp

#### 1. Java không được tìm thấy
```bash
# Kiểm tra Java
java -version

# Nếu chưa có, cài đặt:
sudo apt-get update
sudo apt-get install openjdk-8-jdk

# Thiết lập JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> ~/.bashrc
```

#### 2. MySQL connection failed
```bash
# Kiểm tra MySQL service
sudo systemctl status mysql

# Khởi động MySQL
sudo systemctl start mysql

# Reset password nếu cần
sudo mysql_secure_installation
```

#### 3. HDFS NameNode không khởi động
```bash
# Kiểm tra log
sudo -u hadoop cat /opt/hadoop/logs/hadoop-hadoop-namenode-*.log

# Format lại NameNode (CHÚ Ý: sẽ mất dữ liệu)
sudo -u hadoop /opt/hadoop/bin/hdfs namenode -format -force
```

#### 4. HiveServer2 không kết nối được
```bash
# Kiểm tra log
sudo -u hadoop cat /opt/hive/logs/hiveserver2.log

# Kiểm tra port
netstat -tlnp | grep 10000

# Restart Hive
sudo systemctl restart hive
```

#### 5. Không đủ bộ nhớ
```bash
# Kiểm tra memory
free -h

# Điều chỉnh cấu hình YARN trong yarn-site.xml:
yarn.nodemanager.resource.memory-mb = 2048
yarn.scheduler.maximum-allocation-mb = 2048
```

### Kiểm tra Log Files

#### Hadoop Logs
```bash
# NameNode logs
sudo -u hadoop tail -f /opt/hadoop/logs/hadoop-hadoop-namenode-*.log

# DataNode logs
sudo -u hadoop tail -f /opt/hadoop/logs/hadoop-hadoop-datanode-*.log

# ResourceManager logs
sudo -u hadoop tail -f /opt/hadoop/logs/yarn-hadoop-resourcemanager-*.log
```

#### Hive Logs
```bash
# HiveServer2 logs
sudo -u hadoop tail -f /opt/hive/logs/hiveserver2.log

# Metastore logs
sudo -u hadoop tail -f /opt/hive/logs/metastore.log
```

## Kiểm tra Cài đặt

### Kiểm tra Hadoop
```bash
# Kiểm tra HDFS
sudo -u hadoop /opt/hadoop/bin/hdfs dfs -ls /

# Kiểm tra YARN
sudo -u hadoop /opt/hadoop/bin/yarn node -list

# Web UI
# HDFS: http://<vm-ip>:9870
# YARN: http://<vm-ip>:8088
```

### Kiểm tra Hive
```bash
# Kết nối với Beeline
sudo -u hadoop /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000

# Trong Beeline:
SHOW DATABASES;
USE airline_analytics;
SHOW TABLES;
SELECT COUNT(*) FROM flights_raw;
```

### Chạy Test Demo
```bash
# Chạy demo
hive-demo

# Kiểm tra trạng thái tổng thể
hadoop-hive-status
```

## Bảo trì và Monitoring

### Lệnh quản lý hệ thống
```bash
# Khởi động tất cả services
sudo systemctl start mysql
sudo systemctl start hadoop
sudo systemctl start hive

# Dừng tất cả services
sudo systemctl stop hive
sudo systemctl stop hadoop
sudo systemctl stop mysql

# Kiểm tra trạng thái
sudo systemctl status mysql hadoop hive
```

### Backup và Restore
```bash
# Backup HDFS data
sudo -u hadoop /opt/hadoop/bin/hdfs dfs -get /user/hive/warehouse /backup/

# Backup MySQL Metastore
mysqldump -u hive -p hive_metastore > metastore_backup.sql

# Restore MySQL Metastore
mysql -u hive -p hive_metastore < metastore_backup.sql
```

### Performance Tuning
```bash
# Điều chỉnh JVM heap size trong hadoop-env.sh
export HADOOP_HEAPSIZE=2048

# Điều chỉnh YARN memory trong yarn-site.xml
yarn.nodemanager.resource.memory-mb=6144
yarn.scheduler.maximum-allocation-mb=6144

# Điều chỉnh Hive memory
export HADOOP_HEAPSIZE=2048
```

## Tài nguyên Tham khảo

### Documentation
- [Apache Hadoop Documentation](https://hadoop.apache.org/docs/)
- [Apache Hive Documentation](https://hive.apache.org/docs/)
- [Azure Virtual Machines Documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/)

### Troubleshooting
- [Hadoop Troubleshooting Guide](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/Troubleshooting.html)
- [Hive Troubleshooting](https://cwiki.apache.org/confluence/display/Hive/Troubleshooting)

### Community
- [Hadoop User Mailing List](https://hadoop.apache.org/mailing_lists.html)
- [Hive User Mailing List](https://hive.apache.org/mailing_lists.html)
- [Stack Overflow - Hadoop](https://stackoverflow.com/questions/tagged/hadoop)
- [Stack Overflow - Hive](https://stackoverflow.com/questions/tagged/hive)
