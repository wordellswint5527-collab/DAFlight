#!/bin/bash

# =====================================================
# Script: Cài đặt các phần mềm cần thiết
# Mô tả: Cài đặt Java, MySQL, và các dependencies
# Hệ điều hành: Ubuntu/Debian
# =====================================================

set -e  # Exit on any error

echo "=========================================="
echo "Bắt đầu cài đặt các phần mềm cần thiết..."
echo "=========================================="

# Cập nhật package list
echo "Cập nhật package list..."
sudo apt-get update

# Cài đặt các packages cơ bản
echo "Cài đặt các packages cơ bản..."
sudo apt-get install -y \
    wget \
    curl \
    vim \
    unzip \
    tar \
    ssh \
    rsync \
    net-tools \
    htop

# =====================================================
# Cài đặt Java 8 (yêu cầu cho Hadoop/Hive)
# =====================================================
echo "Cài đặt OpenJDK 8..."
sudo apt-get install -y openjdk-8-jdk

# Thiết lập JAVA_HOME
echo "Thiết lập JAVA_HOME..."
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' >> ~/.bashrc

# Kiểm tra Java version
echo "Kiểm tra Java version..."
java -version
javac -version

# =====================================================
# Cài đặt MySQL Server
# =====================================================
echo "Cài đặt MySQL Server..."
sudo apt-get install -y mysql-server mysql-client

# Khởi động MySQL service
echo "Khởi động MySQL service..."
sudo systemctl start mysql
sudo systemctl enable mysql

# Tạo user và database cho Hive Metastore
echo "Thiết lập MySQL cho Hive Metastore..."
sudo mysql -e "CREATE DATABASE IF NOT EXISTS hive_metastore;"
sudo mysql -e "CREATE USER IF NOT EXISTS 'hive'@'localhost' IDENTIFIED BY 'hive123';"
sudo mysql -e "CREATE USER IF NOT EXISTS 'hive'@'%' IDENTIFIED BY 'hive123';"
sudo mysql -e "GRANT ALL PRIVILEGES ON hive_metastore.* TO 'hive'@'localhost';"
sudo mysql -e "GRANT ALL PRIVILEGES ON hive_metastore.* TO 'hive'@'%';"
sudo mysql -e "FLUSH PRIVILEGES;"

# =====================================================
# Tạo user hadoop
# =====================================================
echo "Tạo user hadoop..."
sudo adduser --disabled-password --gecos "" hadoop || true
sudo usermod -aG sudo hadoop

# Thiết lập SSH key cho user hadoop
echo "Thiết lập SSH key cho user hadoop..."
sudo -u hadoop ssh-keygen -t rsa -P '' -f /home/hadoop/.ssh/id_rsa || true
# Ensure correct ownership and permissions on .ssh
sudo chown -R hadoop:hadoop /home/hadoop/.ssh
sudo chmod 700 /home/hadoop/.ssh
# Append public key as hadoop (avoid root-owned file due to redirection)
sudo -u hadoop bash -c 'cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys'
sudo chown hadoop:hadoop /home/hadoop/.ssh/authorized_keys
sudo chmod 0600 /home/hadoop/.ssh/authorized_keys

# =====================================================
# Tạo thư mục cho Hadoop và Hive
# =====================================================
echo "Tạo thư mục cho Hadoop và Hive..."
sudo mkdir -p /opt/hadoop
sudo mkdir -p /opt/hive
sudo mkdir -p /opt/hadoop/logs
sudo mkdir -p /opt/hadoop/tmp
sudo mkdir -p /opt/hadoop/hdfs/namenode
sudo mkdir -p /opt/hadoop/hdfs/datanode
sudo mkdir -p /opt/hadoop/yarn/local
sudo mkdir -p /opt/hive/logs

# Cấp quyền cho user hadoop
sudo chown -R hadoop:hadoop /opt/hadoop
sudo chown -R hadoop:hadoop /opt/hive

# =====================================================
# Cài đặt Python và pip (cho các script hỗ trợ)
# =====================================================
echo "Cài đặt Python và pip..."
sudo apt-get install -y python3 python3-pip

# =====================================================
# Thiết lập firewall (mở các port cần thiết)
# =====================================================
echo "Cấu hình firewall..."
sudo ufw allow 22      # SSH
sudo ufw allow 9000    # HDFS NameNode
sudo ufw allow 9870    # HDFS NameNode Web UI
sudo ufw allow 8088    # YARN ResourceManager Web UI
sudo ufw allow 19888   # MapReduce JobHistory Web UI
sudo ufw allow 10000   # HiveServer2
sudo ufw allow 10002   # HiveServer2 Web UI
sudo ufw allow 9083    # Hive Metastore
sudo ufw allow 3306    # MySQL

echo "=========================================="
echo "Hoàn thành cài đặt các phần mềm cần thiết!"
echo "=========================================="

# Hiển thị thông tin hệ thống
echo "Thông tin hệ thống:"
echo "Java version: $(java -version 2>&1 | head -n 1)"
echo "MySQL status: $(sudo systemctl is-active mysql)"
echo "Available memory: $(free -h | grep Mem | awk '{print $2}')"
echo "Available disk: $(df -h / | tail -1 | awk '{print $4}')"

echo ""
echo "Tiếp theo, chạy script 02_install_hadoop.sh để cài đặt Hadoop"
