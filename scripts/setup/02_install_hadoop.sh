#!/bin/bash

# =====================================================
# Script: Cài đặt Apache Hadoop
# Mô tả: Download và cài đặt Hadoop 3.3.4
# =====================================================

set -e  # Exit on any error

echo "=========================================="
echo "Bắt đầu cài đặt Apache Hadoop..."
echo "=========================================="

# Biến cấu hình
HADOOP_VERSION="3.3.4"
HADOOP_URL="https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"
HADOOP_HOME="/opt/hadoop"
HADOOP_USER="hadoop"

# Kiểm tra user hadoop
if ! id "$HADOOP_USER" &>/dev/null; then
    echo "User hadoop không tồn tại. Vui lòng chạy script 01_install_prerequisites.sh trước."
    exit 1
fi

# =====================================================
# Download và cài đặt Hadoop
# =====================================================
if [ -x "${HADOOP_HOME}/bin/hdfs" ]; then
    echo "Hadoop đã tồn tại tại ${HADOOP_HOME}, bỏ qua bước download/giải nén."
else
    echo "Download Hadoop ${HADOOP_VERSION}..."
    cd /tmp
    wget -q --show-progress "$HADOOP_URL" -O "hadoop-${HADOOP_VERSION}.tar.gz"

    echo "Giải nén Hadoop..."
    tar -xzf "hadoop-${HADOOP_VERSION}.tar.gz"

    echo "Di chuyển Hadoop đến ${HADOOP_HOME}..."
    sudo rm -rf ${HADOOP_HOME}/*
    sudo mv "hadoop-${HADOOP_VERSION}"/* ${HADOOP_HOME}/
    sudo chown -R ${HADOOP_USER}:${HADOOP_USER} ${HADOOP_HOME}

    # Dọn dẹp file tạm
    rm -f "hadoop-${HADOOP_VERSION}.tar.gz"
    rm -rf "hadoop-${HADOOP_VERSION}"
fi

# =====================================================
# Thiết lập biến môi trường
# =====================================================
echo "Thiết lập biến môi trường..."

# Tạo file environment cho hadoop user
sudo -u ${HADOOP_USER} tee /home/${HADOOP_USER}/.hadoop_env << 'EOF'
# Hadoop Environment Variables
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export YARN_HOME=$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
EOF

# Thêm vào .bashrc
sudo -u ${HADOOP_USER} bash -c 'echo "source ~/.hadoop_env" >> ~/.bashrc'

# Thiết lập JAVA_HOME trong hadoop-env.sh
echo "Cấu hình hadoop-env.sh..."
sudo -u ${HADOOP_USER} sed -i 's|# export JAVA_HOME=.*|export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64|' ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh

# =====================================================
# Copy file cấu hình từ dự án
# =====================================================
echo "Copy file cấu hình Hadoop..."

# Kiểm tra xem file cấu hình có tồn tại không
# Xác định thư mục cấu hình (ưu tiên cấu trúc mới infra/hadoop, fallback config/hadoop)
# Resolve script and project directories robustly (independent of current working directory)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CONFIG_DIR_NEW="${PROJECT_DIR}/infra/hadoop"
CONFIG_DIR_OLD="${PROJECT_DIR}/config/hadoop"

if [ -d "$CONFIG_DIR_NEW" ] && compgen -G "$CONFIG_DIR_NEW/*.xml" > /dev/null; then
    sudo cp "$CONFIG_DIR_NEW"/*.xml ${HADOOP_HOME}/etc/hadoop/
    sudo chown ${HADOOP_USER}:${HADOOP_USER} ${HADOOP_HOME}/etc/hadoop/*.xml
    echo "Đã copy file cấu hình từ $CONFIG_DIR_NEW"
elif [ -d "$CONFIG_DIR_OLD" ] && compgen -G "$CONFIG_DIR_OLD/*.xml" > /dev/null; then
    sudo -u ${HADOOP_USER} cp "$CONFIG_DIR_OLD"/*.xml ${HADOOP_HOME}/etc/hadoop/
    echo "Đã copy file cấu hình từ $CONFIG_DIR_OLD"
else
    echo "Không tìm thấy thư mục cấu hình. Sử dụng cấu hình mặc định."
    
    # Tạo cấu hình cơ bản
    sudo -u ${HADOOP_USER} tee ${HADOOP_HOME}/etc/hadoop/core-site.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/opt/hadoop/tmp</value>
    </property>
</configuration>
EOF

    sudo -u ${HADOOP_USER} tee ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/opt/hadoop/hdfs/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/opt/hadoop/hdfs/datanode</value>
    </property>
</configuration>
EOF

    sudo -u ${HADOOP_USER} tee ${HADOOP_HOME}/etc/hadoop/mapred-site.xml << 'EOF'
<?xml version="1.0"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
</configuration>
EOF

    sudo -u ${HADOOP_USER} tee ${HADOOP_HOME}/etc/hadoop/yarn-site.xml << 'EOF'
<?xml version="1.0"?>
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>localhost</value>
    </property>
</configuration>
EOF
fi

# =====================================================
# Format HDFS NameNode
# =====================================================
echo "Format HDFS NameNode..."
sudo -u ${HADOOP_USER} bash -c 'source ~/.hadoop_env && $HADOOP_HOME/bin/hdfs namenode -format -force'

# =====================================================
# Tạo script khởi động
# =====================================================
echo "Tạo script khởi động Hadoop..."
sudo tee /usr/local/bin/start-hadoop << 'EOF'
#!/bin/bash
echo "Khởi động Hadoop services..."
sudo -u hadoop bash -c 'source ~/.hadoop_env && $HADOOP_HOME/sbin/start-dfs.sh'
sudo -u hadoop bash -c 'source ~/.hadoop_env && $HADOOP_HOME/sbin/start-yarn.sh'
sudo -u hadoop bash -c 'source ~/.hadoop_env && $HADOOP_HOME/bin/mapred --daemon start historyserver'
echo "Hadoop services đã được khởi động!"
EOF

sudo tee /usr/local/bin/stop-hadoop << 'EOF'
#!/bin/bash
echo "Dừng Hadoop services..."
sudo -u hadoop bash -c 'source ~/.hadoop_env && $HADOOP_HOME/bin/mapred --daemon stop historyserver'
sudo -u hadoop bash -c 'source ~/.hadoop_env && $HADOOP_HOME/sbin/stop-yarn.sh'
sudo -u hadoop bash -c 'source ~/.hadoop_env && $HADOOP_HOME/sbin/stop-dfs.sh'
echo "Hadoop services đã được dừng!"
EOF

sudo chmod +x /usr/local/bin/start-hadoop
sudo chmod +x /usr/local/bin/stop-hadoop

# =====================================================
# Tạo systemd service
# =====================================================
echo "Tạo systemd service cho Hadoop..."
sudo tee /etc/systemd/system/hadoop.service << 'EOF'
[Unit]
Description=Apache Hadoop
After=network.target

[Service]
Type=forking
User=hadoop
Group=hadoop
ExecStart=/usr/local/bin/start-hadoop
ExecStop=/usr/local/bin/stop-hadoop
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable hadoop

echo "=========================================="
echo "Hoàn thành cài đặt Apache Hadoop!"
echo "=========================================="

echo "Thông tin cài đặt:"
echo "Hadoop Home: ${HADOOP_HOME}"
echo "Hadoop Version: ${HADOOP_VERSION}"
echo "Hadoop User: ${HADOOP_USER}"
echo ""
echo "Để khởi động Hadoop:"
echo "  sudo systemctl start hadoop"
echo "  hoặc: start-hadoop"
echo ""
echo "Để kiểm tra trạng thái:"
echo "  sudo systemctl status hadoop"
echo ""
echo "Web UI:"
echo "  NameNode: http://localhost:9870"
echo "  ResourceManager: http://localhost:8088"
echo "  JobHistory: http://localhost:19888"
echo ""
echo "Tiếp theo, chạy script 03_install_hive.sh để cài đặt Hive"
