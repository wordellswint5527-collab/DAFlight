#!/bin/bash

# =====================================================
# Script: Setup dữ liệu mẫu cho dự án
# Mô tả: Upload dữ liệu lên HDFS và tạo bảng trong Hive
# =====================================================

set -e  # Exit on any error

echo "=========================================="
echo "Bắt đầu setup dữ liệu mẫu..."
echo "=========================================="

HADOOP_USER="hadoop"
# Resolve script and project directories robustly (independent of current working directory)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Sử dụng cấu trúc dữ liệu mới: đặt dữ liệu trực tiếp trong data/ và data/flights/
DATA_DIR="${PROJECT_DIR}/data"

# Chỉ sử dụng cấu trúc mới (sql/hive); fail-fast nếu thiếu
SCRIPTS_ROOT="${PROJECT_DIR}/sql/hive"
DDL_DIR="${SCRIPTS_ROOT}/ddl"
DML_DIR="${SCRIPTS_ROOT}/dml"
ANALYSIS_DIR="${SCRIPTS_ROOT}/analysis"
if [ ! -d "${SCRIPTS_ROOT}" ] || [ ! -d "${DDL_DIR}" ] || [ ! -d "${DML_DIR}" ]; then
    echo "Lỗi: Thiếu thư mục sql/hive (ddl|dml). Vui lòng kiểm tra repo."
    exit 1
fi

# Kiểm tra các service đã chạy
echo "Kiểm tra trạng thái các service..."
if ! sudo systemctl is-active --quiet hadoop; then
    echo "Khởi động Hadoop..."
    sudo systemctl start hadoop
    sleep 15
fi

if ! sudo systemctl is-active --quiet hive; then
    echo "Khởi động Hive..."
    sudo systemctl start hive
    sleep 15
fi

# =====================================================
# Tạo thư mục trên HDFS
# =====================================================
echo "Tạo thư mục trên HDFS..."
sudo -u ${HADOOP_USER} bash -c 'source ~/.hadoop_env && $HADOOP_HOME/bin/hdfs dfs -mkdir -p /data'
sudo -u ${HADOOP_USER} bash -c 'source ~/.hadoop_env && $HADOOP_HOME/bin/hdfs dfs -mkdir -p /data/flights'
sudo -u ${HADOOP_USER} bash -c 'source ~/.hadoop_env && $HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/hive/warehouse'

# =====================================================
# Upload dữ liệu lên HDFS
# =====================================================
echo "Upload dữ liệu lên HDFS..."

if [ -d "$DATA_DIR" ]; then
    # Upload các file CSV
    if [ -f "${DATA_DIR}/airlines.csv" ]; then
        sudo -u ${HADOOP_USER} bash -c "source ~/.hadoop_env && \$HADOOP_HOME/bin/hdfs dfs -put -f ${DATA_DIR}/airlines.csv /data/"
        echo "Uploaded airlines.csv"
    fi
    
    if [ -f "${DATA_DIR}/carrier.csv" ]; then
        sudo -u ${HADOOP_USER} bash -c "source ~/.hadoop_env && \$HADOOP_HOME/bin/hdfs dfs -put -f ${DATA_DIR}/carrier.csv /data/"
        echo "Uploaded carrier.csv"
    fi
    
    if [ -f "${DATA_DIR}/plane-data.csv" ]; then
        sudo -u ${HADOOP_USER} bash -c "source ~/.hadoop_env && \$HADOOP_HOME/bin/hdfs dfs -put -f ${DATA_DIR}/plane-data.csv /data/"
        echo "Uploaded plane-data.csv"
    fi
    
    # Upload flight data
    if [ -d "${DATA_DIR}/flights" ]; then
        sudo -u ${HADOOP_USER} bash -c "source ~/.hadoop_env && \$HADOOP_HOME/bin/hdfs dfs -put -f ${DATA_DIR}/flights/* /data/flights/"
        echo "Uploaded flight data"
    fi
else
    echo "Không tìm thấy thư mục data. Tạo dữ liệu mẫu..."
    
    # Tạo dữ liệu mẫu trực tiếp trên HDFS
    sudo -u ${HADOOP_USER} bash -c 'source ~/.hadoop_env && echo "Code,Description
AA,American Airlines Inc.
DL,Delta Air Lines Inc.
UA,United Air Lines Inc.
WN,Southwest Airlines Co." | $HADOOP_HOME/bin/hdfs dfs -put - /data/airlines.csv'

    sudo -u ${HADOOP_USER} bash -c 'source ~/.hadoop_env && echo "Code,Description
AA,American Airlines Inc.
DL,Delta Air Lines Inc.
UA,United Air Lines Inc.
WN,Southwest Airlines Co." | $HADOOP_HOME/bin/hdfs dfs -put - /data/carrier.csv'

    sudo -u ${HADOOP_USER} bash -c 'source ~/.hadoop_env && echo "tailnum,type,manufacturer,model,engines,seats,speed,engine
N10156,Fixed wing multi engine,EMBRAER,EMB-145XR,2,50,,,Turbo-fan
N102UW,Fixed wing multi engine,AIRBUS INDUSTRIE,A320-214,2,182,,,Turbo-fan" | $HADOOP_HOME/bin/hdfs dfs -put - /data/plane-data.csv'

    sudo -u ${HADOOP_USER} bash -c 'source ~/.hadoop_env && echo "Year,Month,DayofMonth,DayOfWeek,DepTime,CRSDepTime,ArrTime,CRSArrTime,UniqueCarrier,FlightNum,TailNum,ActualElapsedTime,CRSElapsedTime,AirTime,ArrDelay,DepDelay,Origin,Dest,Distance,TaxiIn,TaxiOut,Cancelled,CancellationCode,Diverted,CarrierDelay,WeatherDelay,NASDelay,SecurityDelay,LateAircraftDelay
2023,1,1,7,1232,1225,1341,1340,WN,2891,N464WN,69,75,54,1,7,SMF,ONT,389,6,9,0,,0,0,0,0,0,0
2023,1,1,7,1918,1905,2043,2035,WN,462,N942WN,85,90,74,8,13,SMF,PHX,647,5,6,0,,0,0,0,0,0,0" | $HADOOP_HOME/bin/hdfs dfs -put - /data/flights/flights_2023.csv'
fi

# Kiểm tra dữ liệu đã upload
echo "Kiểm tra dữ liệu trên HDFS..."
sudo -u ${HADOOP_USER} bash -c 'source ~/.hadoop_env && $HADOOP_HOME/bin/hdfs dfs -ls -R /data'

# =====================================================
# Chạy các script HQL để tạo database và bảng
# =====================================================
echo "Tạo database và bảng trong Hive..."

# Chờ HiveServer2 sẵn sàng
echo "Chờ HiveServer2 sẵn sàng..."
for i in {1..30}; do
    if sudo -u ${HADOOP_USER} bash -c 'source ~/.hadoop_env && $HIVE_HOME/bin/beeline -u jdbc:hive2://localhost:10000 -e "SHOW DATABASES;" --silent=true' &>/dev/null; then
        echo "HiveServer2 đã sẵn sàng!"
        break
    fi
    echo "Đang chờ HiveServer2... ($i/30)"
    sleep 5
done

# Chạy script tạo database
if [ -f "${DDL_DIR}/01_create_database.hql" ]; then
    echo "Chạy script tạo database..."
    sudo -u ${HADOOP_USER} bash -c "source ~/.hadoop_env && \$HIVE_HOME/bin/beeline -u jdbc:hive2://localhost:10000 -f ${DDL_DIR}/01_create_database.hql"
else
    echo "Tạo database bằng lệnh trực tiếp..."
    sudo -u ${HADOOP_USER} bash -c 'source ~/.hadoop_env && $HIVE_HOME/bin/beeline -u jdbc:hive2://localhost:10000 -e "CREATE DATABASE IF NOT EXISTS airline_analytics;"'
fi

# Chạy script tạo bảng
if [ -f "${DDL_DIR}/02_create_tables.hql" ]; then
    echo "Chạy script tạo bảng..."
    sudo -u ${HADOOP_USER} bash -c "source ~/.hadoop_env && \$HIVE_HOME/bin/beeline -u jdbc:hive2://localhost:10000 -f ${DDL_DIR}/02_create_tables.hql"
else
    echo "Tạo bảng bằng lệnh trực tiếp..."
    sudo -u ${HADOOP_USER} bash -c 'source ~/.hadoop_env && $HIVE_HOME/bin/beeline -u jdbc:hive2://localhost:10000 -e "
    USE airline_analytics;
    CREATE TABLE IF NOT EXISTS airlines (code STRING, description STRING) 
    ROW FORMAT DELIMITED FIELDS TERMINATED BY \",\" 
    STORED AS TEXTFILE 
    TBLPROPERTIES (\"skip.header.line.count\"=\"1\");
    
    CREATE TABLE IF NOT EXISTS flights_raw (
        year INT, month INT, dayofmonth INT, dayofweek INT,
        deptime STRING, crsdeptime STRING, arrtime STRING, crsarrtime STRING,
        uniquecarrier STRING, flightnum STRING, tailnum STRING,
        actualelapsedtime INT, crselapsedtime INT, airtime INT,
        arrdelay INT, depdelay INT, origin STRING, dest STRING, distance INT,
        taxiin INT, taxiout INT, cancelled INT, cancellationcode STRING, diverted INT,
        carrierdelay INT, weatherdelay INT, nasdelay INT, securitydelay INT, lateaircraftdelay INT
    ) ROW FORMAT DELIMITED FIELDS TERMINATED BY \",\" 
    STORED AS TEXTFILE 
    TBLPROPERTIES (\"skip.header.line.count\"=\"1\");"'
fi

# Chạy script load dữ liệu
if [ -f "${DML_DIR}/03_load_data.hql" ]; then
    echo "Chạy script load dữ liệu..."
    sudo -u ${HADOOP_USER} bash -c "source ~/.hadoop_env && \$HIVE_HOME/bin/beeline -u jdbc:hive2://localhost:10000 -f ${DML_DIR}/03_load_data.hql"
else
    echo "Load dữ liệu bằng lệnh trực tiếp..."
    sudo -u ${HADOOP_USER} bash -c 'source ~/.hadoop_env && $HIVE_HOME/bin/beeline -u jdbc:hive2://localhost:10000 -e "
    USE airline_analytics;
    LOAD DATA INPATH \"/data/airlines.csv\" OVERWRITE INTO TABLE airlines;
    LOAD DATA INPATH \"/data/flights/flights_2023.csv\" OVERWRITE INTO TABLE flights_raw;"'
fi

# =====================================================
# Kiểm tra kết quả
# =====================================================
echo "Kiểm tra kết quả setup..."

# Hiển thị databases
echo "Databases trong Hive:"
sudo -u ${HADOOP_USER} bash -c 'source ~/.hadoop_env && $HIVE_HOME/bin/beeline -u jdbc:hive2://localhost:10000 -e "SHOW DATABASES;" --silent=true'

# Hiển thị tables
echo "Tables trong airline_analytics:"
sudo -u ${HADOOP_USER} bash -c 'source ~/.hadoop_env && $HIVE_HOME/bin/beeline -u jdbc:hive2://localhost:10000 -e "USE airline_analytics; SHOW TABLES;" --silent=true'

# Đếm số records
echo "Số lượng records trong các bảng:"
sudo -u ${HADOOP_USER} bash -c 'source ~/.hadoop_env && $HIVE_HOME/bin/beeline -u jdbc:hive2://localhost:10000 -e "
USE airline_analytics;
SELECT \"airlines\" as table_name, COUNT(*) as record_count FROM airlines
UNION ALL
SELECT \"flights_raw\" as table_name, COUNT(*) as record_count FROM flights_raw;" --silent=true'

# =====================================================
# Tạo script demo
# =====================================================
echo "Tạo script demo..."
sudo tee /usr/local/bin/hive-demo << 'EOF'
#!/bin/bash
echo "=========================================="
echo "Demo Hive với dữ liệu hàng không"
echo "=========================================="

echo "1. Kết nối với Beeline:"
echo "   sudo -u hadoop /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000"
echo ""
echo "2. Các truy vấn mẫu:"
echo "   USE airline_analytics;"
echo "   SHOW TABLES;"
echo "   SELECT * FROM airlines LIMIT 10;"
echo "   SELECT uniquecarrier, COUNT(*) FROM flights_raw GROUP BY uniquecarrier;"
echo ""
echo "3. Web UI:"
echo "   HiveServer2: http://localhost:10002"
echo "   HDFS: http://localhost:9870"
echo "   YARN: http://localhost:8088"
echo ""

# Chạy một truy vấn demo
echo "Chạy truy vấn demo..."
sudo -u hadoop bash -c 'source ~/.hadoop_env && $HIVE_HOME/bin/beeline -u jdbc:hive2://localhost:10000 -e "
USE airline_analytics;
SELECT \"=== Top 5 Airlines by Flight Count ===\" as info;
SELECT uniquecarrier, COUNT(*) as flight_count 
FROM flights_raw 
GROUP BY uniquecarrier 
ORDER BY flight_count DESC 
LIMIT 5;" --silent=true'
EOF

sudo chmod +x /usr/local/bin/hive-demo

echo "=========================================="
echo "Hoàn thành setup dữ liệu!"
echo "=========================================="

echo "Để chạy demo:"
echo "  hive-demo"
echo ""
echo "Để kết nối với Hive:"
echo "  sudo -u hadoop /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000"
echo ""
echo "Dữ liệu đã được load vào database 'airline_analytics'"
