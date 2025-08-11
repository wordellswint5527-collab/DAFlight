#!/bin/bash

# =====================================================
# Script: Master Setup - Cài đặt toàn bộ hệ thống
# Mô tả: Chạy tất cả các script setup theo thứ tự
# =====================================================

set -e  # Exit on any error

echo "=========================================="
echo "BẮT ĐẦU CÀI ĐẶT HỆ THỐNG HADOOP-HIVE"
echo "=========================================="

# Lấy thư mục hiện tại
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Kiểm tra quyền root
if [[ $EUID -ne 0 ]]; then
   echo "Script này cần chạy với quyền root (sudo)"
   exit 1
fi

# Hiển thị thông tin hệ thống
echo "Thông tin hệ thống:"
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $4}') available"
echo ""

# Xác nhận từ người dùng
read -p "Bạn có muốn tiếp tục cài đặt? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Hủy cài đặt."
    exit 1
fi

# =====================================================
# Bước 1: Cài đặt prerequisites
# =====================================================
echo ""
echo "=========================================="
echo "BƯỚC 1: CÀI ĐẶT PREREQUISITES"
echo "=========================================="

if [ -f "${SCRIPT_DIR}/01_install_prerequisites.sh" ]; then
    chmod +x "${SCRIPT_DIR}/01_install_prerequisites.sh"
    "${SCRIPT_DIR}/01_install_prerequisites.sh"
else
    echo "Không tìm thấy script 01_install_prerequisites.sh"
    exit 1
fi

echo "✓ Hoàn thành cài đặt prerequisites"
sleep 2

# =====================================================
# Bước 2: Cài đặt Hadoop
# =====================================================
echo ""
echo "=========================================="
echo "BƯỚC 2: CÀI ĐẶT HADOOP"
echo "=========================================="

if [ -f "${SCRIPT_DIR}/02_install_hadoop.sh" ]; then
    chmod +x "${SCRIPT_DIR}/02_install_hadoop.sh"
    "${SCRIPT_DIR}/02_install_hadoop.sh"
else
    echo "Không tìm thấy script 02_install_hadoop.sh"
    exit 1
fi

echo "✓ Hoàn thành cài đặt Hadoop"
sleep 2

# =====================================================
# Bước 3: Cài đặt Hive
# =====================================================
echo ""
echo "=========================================="
echo "BƯỚC 3: CÀI ĐẶT HIVE"
echo "=========================================="

if [ -f "${SCRIPT_DIR}/03_install_hive.sh" ]; then
    chmod +x "${SCRIPT_DIR}/03_install_hive.sh"
    "${SCRIPT_DIR}/03_install_hive.sh"
else
    echo "Không tìm thấy script 03_install_hive.sh"
    exit 1
fi

echo "✓ Hoàn thành cài đặt Hive"
sleep 2

# =====================================================
# Bước 4: Setup dữ liệu
# =====================================================
echo ""
echo "=========================================="
echo "BƯỚC 4: SETUP DỮ LIỆU"
echo "=========================================="

if [ -f "${SCRIPT_DIR}/04_setup_data.sh" ]; then
    chmod +x "${SCRIPT_DIR}/04_setup_data.sh"
    "${SCRIPT_DIR}/04_setup_data.sh"
else
    echo "Không tìm thấy script 04_setup_data.sh"
    exit 1
fi

echo "✓ Hoàn thành setup dữ liệu"

# =====================================================
# Kiểm tra trạng thái các service
# =====================================================
echo ""
echo "=========================================="
echo "KIỂM TRA TRẠNG THÁI HỆ THỐNG"
echo "=========================================="

echo "Trạng thái các service:"
echo "MySQL: $(systemctl is-active mysql)"
echo "Hadoop: $(systemctl is-active hadoop)"
echo "Hive: $(systemctl is-active hive)"

echo ""
echo "Kiểm tra port đang lắng nghe:"
netstat -tlnp | grep -E ':(9000|9870|8088|10000|10002|9083|3306)' || echo "Một số port có thể chưa mở"

# =====================================================
# Tạo script status check
# =====================================================
echo ""
echo "Tạo script kiểm tra trạng thái..."
tee /usr/local/bin/hadoop-hive-status << 'EOF'
#!/bin/bash
echo "=========================================="
echo "TRẠNG THÁI HỆ THỐNG HADOOP-HIVE"
echo "=========================================="

echo "Services:"
echo "  MySQL: $(systemctl is-active mysql)"
echo "  Hadoop: $(systemctl is-active hadoop)"
echo "  Hive: $(systemctl is-active hive)"

echo ""
echo "Processes:"
echo "  NameNode: $(pgrep -f NameNode > /dev/null && echo 'Running' || echo 'Stopped')"
echo "  DataNode: $(pgrep -f DataNode > /dev/null && echo 'Running' || echo 'Stopped')"
echo "  ResourceManager: $(pgrep -f ResourceManager > /dev/null && echo 'Running' || echo 'Stopped')"
echo "  NodeManager: $(pgrep -f NodeManager > /dev/null && echo 'Running' || echo 'Stopped')"
echo "  HiveServer2: $(pgrep -f hiveserver2 > /dev/null && echo 'Running' || echo 'Stopped')"
echo "  Metastore: $(pgrep -f metastore > /dev/null && echo 'Running' || echo 'Stopped')"

echo ""
echo "Web UIs:"
echo "  HDFS NameNode: http://localhost:9870"
echo "  YARN ResourceManager: http://localhost:8088"
echo "  MapReduce JobHistory: http://localhost:19888"
echo "  HiveServer2: http://localhost:10002"

echo ""
echo "Connection Commands:"
echo "  Beeline: sudo -u hadoop /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000"
echo "  HDFS: sudo -u hadoop /opt/hadoop/bin/hdfs dfs -ls /"
echo "  Demo: hive-demo"
EOF

chmod +x /usr/local/bin/hadoop-hive-status

# =====================================================
# Hoàn thành
# =====================================================
echo ""
echo "=========================================="
echo "CÀI ĐẶT HOÀN TẤT!"
echo "=========================================="

echo "Hệ thống Hadoop-Hive đã được cài đặt thành công!"
echo ""
echo "Các lệnh hữu ích:"
echo "  hadoop-hive-status  - Kiểm tra trạng thái hệ thống"
echo "  hive-demo          - Chạy demo với dữ liệu mẫu"
echo "  start-hadoop       - Khởi động Hadoop"
echo "  start-hive         - Khởi động Hive"
echo "  stop-hadoop        - Dừng Hadoop"
echo "  stop-hive          - Dừng Hive"
echo ""
echo "Web UIs:"
echo "  HDFS: http://localhost:9870"
echo "  YARN: http://localhost:8088"
echo "  HiveServer2: http://localhost:10002"
echo ""
echo "Để kết nối với Hive:"
echo "  sudo -u hadoop /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000"
echo ""
echo "Database đã tạo: airline_analytics"
echo "Dữ liệu mẫu đã được load sẵn."
echo ""
echo "Chạy 'hadoop-hive-status' để kiểm tra trạng thái hệ thống."
