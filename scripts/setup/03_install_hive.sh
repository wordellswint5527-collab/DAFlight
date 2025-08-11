#!/bin/bash

# =====================================================
# Script: Cài đặt Apache Hive
# Mô tả: Download và cài đặt Hive 3.1.3
# =====================================================

set -e  # Exit on any error

echo "=========================================="
echo "Bắt đầu cài đặt Apache Hive..."
echo "=========================================="

# Biến cấu hình
HIVE_VERSION="3.1.3"
HIVE_URL="https://archive.apache.org/dist/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz"
HIVE_HOME="/opt/hive"
HADOOP_USER="hadoop"
MYSQL_CONNECTOR_VERSION="8.0.33"
MYSQL_CONNECTOR_URL="https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.tar.gz"

# Kiểm tra Hadoop đã được cài đặt
if [ ! -d "/opt/hadoop" ]; then
    echo "Hadoop chưa được cài đặt. Vui lòng chạy script 02_install_hadoop.sh trước."
    exit 1
fi

# =====================================================
# Download và cài đặt Hive
# =====================================================
if [ -x "${HIVE_HOME}/bin/hive" ]; then
    echo "Hive đã tồn tại tại ${HIVE_HOME}, bỏ qua download/giải nén."
else
echo "Download Hive ${HIVE_VERSION}..."
cd /tmp
wget -q --show-progress "$HIVE_URL" -O "apache-hive-${HIVE_VERSION}-bin.tar.gz"

echo "Giải nén Hive..."
tar -xzf "apache-hive-${HIVE_VERSION}-bin.tar.gz"

    echo "Chuẩn bị thư mục ${HIVE_HOME}..."
    sudo mkdir -p ${HIVE_HOME}
sudo rm -rf ${HIVE_HOME}/*
sudo mv "apache-hive-${HIVE_VERSION}-bin"/* ${HIVE_HOME}/
sudo chown -R ${HADOOP_USER}:${HADOOP_USER} ${HIVE_HOME}

# Dọn dẹp file tạm
rm -f "apache-hive-${HIVE_VERSION}-bin.tar.gz"
rm -rf "apache-hive-${HIVE_VERSION}-bin"
fi

# Đảm bảo thư mục cấu hình và logs tồn tại
sudo mkdir -p ${HIVE_HOME}/conf ${HIVE_HOME}/logs
sudo chown -R ${HADOOP_USER}:${HADOOP_USER} ${HIVE_HOME}

# =====================================================
# Download MySQL Connector (ưu tiên Maven Central), fallback dev.mysql.com
# =====================================================
echo "Download MySQL Connector..."
cd /tmp
# Ensure Hive lib dir exists
sudo mkdir -p ${HIVE_HOME}/lib
if ls "${HIVE_HOME}/lib"/mysql-connector-*.jar >/dev/null 2>&1; then
    echo "MySQL Connector jar đã tồn tại trong ${HIVE_HOME}/lib, bỏ qua download."
else
    ART1="mysql-connector-j"
    ART2="mysql-connector-java"
    BASE="https://repo1.maven.org/maven2/com/mysql"
    GOT=""
    for ART in "$ART1" "$ART2"; do
        URL="${BASE}/${ART}/${MYSQL_CONNECTOR_VERSION}/${ART}-${MYSQL_CONNECTOR_VERSION}.jar"
        echo "Thử tải từ Maven Central: ${URL}"
        if wget -q --show-progress --tries=3 --timeout=30 "$URL" -O "/tmp/${ART}-${MYSQL_CONNECTOR_VERSION}.jar"; then
            sudo cp "/tmp/${ART}-${MYSQL_CONNECTOR_VERSION}.jar" "${HIVE_HOME}/lib/"
            sudo chown ${HADOOP_USER}:${HADOOP_USER} "${HIVE_HOME}/lib/${ART}-${MYSQL_CONNECTOR_VERSION}.jar"
            rm -f "/tmp/${ART}-${MYSQL_CONNECTOR_VERSION}.jar"
            GOT="yes"
            echo "✓ Tải JAR ${ART}-${MYSQL_CONNECTOR_VERSION}.jar từ Maven Central thành công"
            break
        fi
    done
    if [ -z "$GOT" ]; then
        echo "! Tải từ Maven Central thất bại, thử tarball từ dev.mysql.com..."
        TAR1="mysql-connector-j-${MYSQL_CONNECTOR_VERSION}.tar.gz"
        TAR2="mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.tar.gz"
        for TAR_URL in \
          "https://dev.mysql.com/get/Downloads/Connector-J/${TAR1}" \
          "https://dev.mysql.com/get/Downloads/Connector-J/${TAR2}"; do
          TAR_FILE="/tmp/$(basename "$TAR_URL")"
          if wget -q --show-progress --tries=3 --timeout=30 "$TAR_URL" -O "$TAR_FILE"; then
            tar -xzf "$TAR_FILE" -C /tmp
            JAR_PATH=$(find /tmp -maxdepth 2 -type f -name "mysql-connector-*.jar" | head -1 || true)
            if [ -n "$JAR_PATH" ]; then
              sudo cp "$JAR_PATH" "${HIVE_HOME}/lib/"
              sudo chown ${HADOOP_USER}:${HADOOP_USER} "${HIVE_HOME}/lib/$(basename "$JAR_PATH")"
              echo "✓ Đã copy $(basename "$JAR_PATH") vào ${HIVE_HOME}/lib"
              rm -f "$TAR_FILE"
              # cleanup extracted dir
              DIR_TO_CLEAN=$(dirname "$JAR_PATH")
              rm -rf "$DIR_TO_CLEAN"
              GOT="yes"
              break
            fi
          fi
        done
    fi
    if [ -z "$GOT" ]; then
        echo "✗ Không thể tải MySQL Connector. Vui lòng tải thủ công và đặt file mysql-connector-*.jar vào ${HIVE_HOME}/lib"
        exit 1
    fi
fi

# =====================================================
# Thiết lập biến môi trường
# =====================================================
echo "Thiết lập biến môi trường Hive..."

# Thêm Hive environment vào hadoop user
sudo -u ${HADOOP_USER} tee -a /home/${HADOOP_USER}/.hadoop_env << 'EOF'

# Hive Environment Variables
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HIVE_HOME/bin
export CLASSPATH=$CLASSPATH:$HADOOP_HOME/lib/*:$HIVE_HOME/lib/*
EOF

# =====================================================
# Copy file cấu hình Hive
# =====================================================
echo "Copy file cấu hình Hive..."

# Xác định thư mục cấu hình (ưu tiên cấu trúc mới infra/hive, fallback config/hive)
# Resolve script and project directories robustly (independent of current working directory)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CONFIG_DIR_NEW="${PROJECT_DIR}/infra/hive"
CONFIG_DIR_OLD="${PROJECT_DIR}/config/hive"
if [ -d "$CONFIG_DIR_NEW" ] && [ -f "$CONFIG_DIR_NEW/hive-site.xml" ]; then
    sudo cp "$CONFIG_DIR_NEW"/hive-site.xml ${HIVE_HOME}/conf/
    sudo chown ${HADOOP_USER}:${HADOOP_USER} ${HIVE_HOME}/conf/hive-site.xml
    echo "Đã copy file cấu hình từ $CONFIG_DIR_NEW"
elif [ -d "$CONFIG_DIR_OLD" ] && [ -f "$CONFIG_DIR_OLD/hive-site.xml" ]; then
    sudo cp "$CONFIG_DIR_OLD"/hive-site.xml ${HIVE_HOME}/conf/
    sudo chown ${HADOOP_USER}:${HADOOP_USER} ${HIVE_HOME}/conf/hive-site.xml
    echo "Đã copy file cấu hình từ $CONFIG_DIR_OLD"
else
    echo "Không tìm thấy thư mục cấu hình. Tạo cấu hình cơ bản."
    
    # Tạo cấu hình cơ bản
    sudo -u ${HADOOP_USER} tee ${HIVE_HOME}/conf/hive-site.xml << 'EOF'
<?xml version="1.0"?>
<configuration>
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://localhost:3306/hive_metastore?createDatabaseIfNotExist=true&amp;useSSL=false</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>com.mysql.cj.jdbc.Driver</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>hive</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>hive123</value>
    </property>
    <property>
        <name>hive.metastore.uris</name>
        <value>thrift://localhost:9083</value>
    </property>
    <property>
        <name>hive.server2.thrift.bind.host</name>
        <value>0.0.0.0</value>
    </property>
    <property>
        <name>hive.server2.thrift.port</name>
        <value>10000</value>
    </property>
</configuration>
EOF
fi

# =====================================================
# Khởi tạo Hive Metastore Schema
# =====================================================
echo "Khởi tạo Hive Metastore Schema..."

# Đảm bảo MySQL đang chạy
sudo systemctl start mysql

# Khởi tạo schema
sudo -u ${HADOOP_USER} bash -c 'source ~/.hadoop_env && $HIVE_HOME/bin/schematool -dbType mysql -initSchema'

# =====================================================
# Tạo script khởi động Hive
# =====================================================
echo "Tạo script khởi động Hive..."

sudo tee /usr/local/bin/start-hive << 'EOF'
#!/bin/bash
echo "Khởi động Hive services..."

# Kiểm tra Hadoop đã chạy chưa
if ! sudo -u hadoop bash -c 'source ~/.hadoop_env && $HADOOP_HOME/bin/hdfs dfsadmin -report' &>/dev/null; then
    echo "Hadoop chưa chạy. Khởi động Hadoop trước..."
    start-hadoop
    sleep 10
fi

# Tạo thư mục warehouse trên HDFS
sudo -u hadoop bash -c 'source ~/.hadoop_env && $HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/hive/warehouse'
sudo -u hadoop bash -c 'source ~/.hadoop_env && $HADOOP_HOME/bin/hdfs dfs -chmod 777 /user/hive/warehouse'

# Khởi động Hive Metastore
echo "Khởi động Hive Metastore..."
sudo -u hadoop bash -c 'source ~/.hadoop_env && nohup $HIVE_HOME/bin/hive --service metastore > /opt/hive/logs/metastore.log 2>&1 &'

sleep 5

# Khởi động HiveServer2
echo "Khởi động HiveServer2..."
sudo -u hadoop bash -c 'source ~/.hadoop_env && nohup $HIVE_HOME/bin/hive --service hiveserver2 > /opt/hive/logs/hiveserver2.log 2>&1 &'

echo "Hive services đã được khởi động!"
echo "Metastore log: /opt/hive/logs/metastore.log"
echo "HiveServer2 log: /opt/hive/logs/hiveserver2.log"
EOF

sudo tee /usr/local/bin/stop-hive << 'EOF'
#!/bin/bash
echo "Dừng Hive services..."

# Dừng HiveServer2
pkill -f "hive.*hiveserver2" || true

# Dừng Metastore
pkill -f "hive.*metastore" || true

echo "Hive services đã được dừng!"
EOF

sudo chmod +x /usr/local/bin/start-hive
sudo chmod +x /usr/local/bin/stop-hive

# =====================================================
# Tạo systemd service cho Hive
# =====================================================
echo "Tạo systemd service cho Hive..."
sudo tee /etc/systemd/system/hive.service << 'EOF'
[Unit]
Description=Apache Hive
After=hadoop.service mysql.service
Requires=hadoop.service mysql.service

[Service]
Type=forking
User=hadoop
Group=hadoop
ExecStart=/usr/local/bin/start-hive
ExecStop=/usr/local/bin/stop-hive
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable hive

# =====================================================
# Tạo script test kết nối
# =====================================================
echo "Tạo script test kết nối..."
sudo tee /usr/local/bin/test-hive << 'EOF'
#!/bin/bash
echo "Testing Hive connection..."

# Test Metastore
echo "1. Testing Metastore connection..."
sudo -u hadoop bash -c 'source ~/.hadoop_env && $HIVE_HOME/bin/hive -e "SHOW DATABASES;"'

# Test HiveServer2 với Beeline
echo "2. Testing HiveServer2 connection..."
sudo -u hadoop bash -c 'source ~/.hadoop_env && $HIVE_HOME/bin/beeline -u jdbc:hive2://localhost:10000 -e "SHOW DATABASES;"'

echo "Hive connection test completed!"
EOF

sudo chmod +x /usr/local/bin/test-hive

echo "=========================================="
echo "Hoàn thành cài đặt Apache Hive!"
echo "=========================================="

echo "Thông tin cài đặt:"
echo "Hive Home: ${HIVE_HOME}"
echo "Hive Version: ${HIVE_VERSION}"
echo "MySQL Connector: ${MYSQL_CONNECTOR_VERSION}"
echo ""
echo "Để khởi động Hive:"
echo "  sudo systemctl start hive"
echo "  hoặc: start-hive"
echo ""
echo "Để test kết nối:"
echo "  test-hive"
echo ""
echo "Để kết nối với Beeline:"
echo "  sudo -u hadoop /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000"
echo ""
echo "Web UI:"
echo "  HiveServer2: http://localhost:10002"
echo ""
echo "Tiếp theo, chạy script 04_setup_data.sh để load dữ liệu mẫu"
