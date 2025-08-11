# Dự án Xử lý Dữ liệu Lớn với Hive và Hadoop

## Tổng quan
Dự án này hướng dẫn xây dựng một hệ thống xử lý dữ liệu lớn hoàn chỉnh sử dụng Apache Hadoop và Apache Hive để phân tích dữ liệu hàng không của Hoa Kỳ. Đây là một dự án thực hành toàn diện về Big Data Engineering, từ cài đặt hệ thống đến tối ưu hóa hiệu năng.

## Kiến trúc Hệ thống
```
┌─────────────────┐    ┌─────────────────┐
│   Hive Client   │    │    Beeline      │
│   (HQL Query)   │    │   (CLI Tool)    │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          └──────────┬───────────┘
                     │
          ┌─────────────────────┐
          │   Hive Server 2     │
          └─────────┬───────────┘
                    │
          ┌─────────────────────┐
          │      Driver         │
          └─────────┬───────────┘
                    │
    ┌───────────────┼───────────────┐
    │               │               │
┌───▼────┐    ┌────▼────┐    ┌────▼────┐
│Compiler│    │Optimizer│    │Executor │
└────────┘    └─────────┘    └─────────┘
                    │
          ┌─────────────────────┐
          │     Metastore       │
          │   (Table Schema)    │
          └─────────────────────┘
                    │
          ┌─────────────────────┐
          │   Hadoop Cluster    │
          │                     │
          │  ┌─────────────┐    │
          │  │    HDFS     │    │
          │  │ (Storage)   │    │
          │  └─────────────┘    │
          │                     │
          │  ┌─────────────┐    │
          │  │    YARN     │    │
          │  │(Resource Mgr)│   │
          │  └─────────────┘    │
          │                     │
          │  ┌─────────────┐    │
          │  │  MapReduce  │    │
          │  │(Processing) │    │
          │  └─────────────┘    │
          └─────────────────────┘
```

## Cấu trúc Dự án
```
hadoop-hive-project/
├── data/                           # Dữ liệu
│   ├── airlines.csv                # Thông tin hãng hàng không
│   ├── carrier.csv                 # Thông tin nhà vận chuyển
│   ├── plane-data.csv              # Thông tin máy bay
│   └── flights/                    # Dữ liệu chuyến bay
│       └── flights_2023.csv
├── infra/                          # Cấu hình hạ tầng (không còn setup wrappers)
│   ├── hadoop/                     # Cấu hình Hadoop
│   │   ├── core-site.xml
│   │   ├── hdfs-site.xml
│   │   ├── mapred-site.xml
│   │   └── yarn-site.xml
│   ├── hive/                       # Cấu hình Hive
│   │   ├── hive-site.xml
│   │   └── metastore-setup.sql
├── sql/
│   └── hive/
│       ├── ddl/                    # Khởi tạo schema, bảng, views
│       │   ├── 01_create_database.hql
│       │   ├── 02_create_tables.hql
│       │   ├── 04_create_optimized_tables.hql
│       │   └── 06_create_views.hql
│       ├── dml/                    # Load/transform dữ liệu
│       │   └── 03_load_data.hql
│       └── analysis/               # Truy vấn phân tích
│           ├── performance_comparison.hql
│           ├── optimization_examples.hql
│           └── 05_analysis_queries.hql
├── scripts/                        # Thư mục setup chuẩn (được Makefile dùng)
│   ├── setup/
│   ├── hql/        [đã gỡ nếu để trống]
│   └── analysis/   [đã gỡ nếu để trống]
├── bin/                            # Tiện ích CLI nội bộ repo
│   ├── run-hql
│   ├── hadoop-hive-status
│   └── hive-demo
├── docs/                           # Tài liệu
│   ├── installation.md
│   ├── configuration.md
│   └── usage_guide.md
└── README.md                       # File này

Ghi chú cấu trúc:
- Thư mục setup chuẩn: scripts/setup (Makefile sử dụng)
- Thư mục infra/setup: đã gỡ bỏ wrappers (không còn tồn tại)
- Dữ liệu đầu vào: đặt trực tiếp trong data/ và data/flights/ (không còn data/raw/)
```

## Công nghệ sử dụng
- **Apache Hadoop 3.3.4**: Nền tảng xử lý dữ liệu lớn
- **Apache Hive 3.1.3**: Data warehouse trên Hadoop
- **HQL**: Ngôn ngữ truy vấn của Hive (tương tự SQL)
- **MySQL 8.0**: Database cho Hive Metastore
- **Azure VM**: Môi trường triển khai cloud
- **HDFS**: Hệ thống file phân tán
- **YARN**: Quản lý tài nguyên cluster
- **MapReduce**: Framework xử lý song song
- **ORC/Parquet**: Định dạng file tối ưu
- **Beeline**: Client kết nối HiveServer2

## Tính năng Chính

### 🚀 Cài đặt Tự động
- Script cài đặt một lệnh cho toàn bộ hệ thống
- Tự động cấu hình Hadoop, Hive, và MySQL
- Thiết lập dữ liệu mẫu và database

### 📊 Phân tích Dữ liệu Hàng không
- Dữ liệu thực tế về các chuyến bay tại Hoa Kỳ
- Phân tích xu hướng, độ trễ, hiệu suất hãng hàng không
- Các truy vấn phức tạp với joins, aggregations, window functions

### ⚡ Tối ưu hóa Hiệu năng
- **Partitioning**: Phân vùng dữ liệu theo thời gian
- **Bucketing**: Phân cụm dữ liệu cho joins hiệu quả
- **Compression**: Nén dữ liệu với Snappy, GZIP
- **Vectorization**: Xử lý vector hóa cho analytical queries
- **File Formats**: ORC, Parquet với indexing

### 🔧 Monitoring và Troubleshooting
- Scripts kiểm tra trạng thái hệ thống
- Log analysis và performance monitoring
- Execution plan analysis với EXPLAIN
- Best practices và troubleshooting guide

## Mục tiêu Học tập
Sau khi hoàn thành dự án này, bạn sẽ có thể:

1. **Hiểu kiến trúc Big Data**: Nắm vững cách Hadoop và Hive hoạt động
2. **Cài đặt và cấu hình**: Tự tay setup hệ thống từ đầu
3. **Quản lý dữ liệu**: Thiết lập Hive Metastore, tạo và quản lý bảng
4. **Sử dụng HQL**: Viết các truy vấn phức tạp với HQL
5. **Tối ưu hóa hiệu năng**: Áp dụng partitioning, bucketing, compression
6. **Phân tích dữ liệu**: Thực hiện joins, views, window functions
7. **Monitoring**: Theo dõi và tối ưu hiệu năng hệ thống
8. **Troubleshooting**: Xử lý các vấn đề thường gặp

## Cài đặt Nhanh

### Yêu cầu Hệ thống
- **OS**: Ubuntu 18.04+ hoặc Debian 10+
- **RAM**: 8GB (khuyến nghị 16GB)
- **CPU**: 4 cores
- **Disk**: 50GB trống
- **Network**: Kết nối internet ổn định

### Cài đặt Một lệnh
```bash
# Clone dự án
git clone <repository-url>
cd hadoop-hive-project

# Chạy script cài đặt tự động
sudo chmod +x scripts/setup/master_setup.sh
sudo ./scripts/setup/master_setup.sh
```

### Sử dụng Makefile (tùy chọn)
```bash
# Cài đặt nhanh
make install

# Kiểm tra trạng thái
make status

# Upload dữ liệu & tạo bảng
make load-data

# Chạy file HQL bất kỳ
make run-hql file=sql/hive/ddl/01_create_database.hql
```

### Kiểm tra Cài đặt
```bash
# Kiểm tra trạng thái hệ thống
hadoop-hive-status

# Chạy demo (nếu đã cài đặt tiện ích này)
hive-demo

# Kết nối với Hive
sudo -u hadoop /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000
```

## Sử dụng Nhanh

### Web UIs
- **HDFS NameNode**: http://localhost:9870
- **YARN ResourceManager**: http://localhost:8088
- **HiveServer2**: http://localhost:10002
- **MapReduce JobHistory**: http://localhost:19888

### Lệnh Cơ bản
```bash
# Quản lý services
start-hadoop          # Khởi động Hadoop
start-hive            # Khởi động Hive
stop-hive             # Dừng Hive
stop-hadoop           # Dừng Hadoop

# Kiểm tra trạng thái
hadoop-hive-status    # Trạng thái tổng thể
hive-demo            # Chạy demo với dữ liệu mẫu
test-hive            # Test kết nối Hive
```

### Truy vấn Mẫu
```sql
-- Kết nối với Hive
sudo -u hadoop /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000

-- Sử dụng database
USE airline_analytics;

-- Xem các bảng
SHOW TABLES;

-- Phân tích cơ bản
SELECT uniquecarrier, COUNT(*) as flight_count
FROM flights_raw
GROUP BY uniquecarrier
ORDER BY flight_count DESC;

-- Phân tích với join
SELECT f.uniquecarrier, a.description, COUNT(*) as flights
FROM flights_raw f
JOIN airlines a ON f.uniquecarrier = a.code
GROUP BY f.uniquecarrier, a.description
ORDER BY flights DESC;
```

## Tài liệu Chi tiết

### 📖 Hướng dẫn Cài đặt
Xem [docs/installation.md](docs/installation.md) để biết chi tiết về:
- Yêu cầu hệ thống
- Cài đặt từng bước
- Cấu hình Azure VM
- Xử lý sự cố

### ⚙️ Hướng dẫn Cấu hình
Xem [docs/configuration.md](docs/configuration.md) để hiểu về:
- File cấu hình Hadoop và Hive
- Tham số tối ưu hóa
- Security configuration
- Performance tuning

### 🎯 Hướng dẫn Sử dụng
Xem [docs/usage_guide.md](docs/usage_guide.md) để học cách:
- Làm việc với HDFS
- Quản lý database và tables
- Viết truy vấn HQL
- Tối ưu hóa performance

## Ví dụ Phân tích

### Phân tích Hiệu suất Hãng hàng không
```sql
SELECT 
    f.uniquecarrier,
    a.description as airline_name,
    COUNT(*) as total_flights,
    AVG(f.depdelay) as avg_departure_delay,
    AVG(f.arrdelay) as avg_arrival_delay,
    COUNT(CASE WHEN f.cancelled = 1 THEN 1 END) as cancelled_flights,
    ROUND(COUNT(CASE WHEN f.cancelled = 1 THEN 1 END) * 100.0 / COUNT(*), 2) as cancellation_rate
FROM flights_raw f
LEFT JOIN airlines a ON f.uniquecarrier = a.code
GROUP BY f.uniquecarrier, a.description
ORDER BY total_flights DESC;
```

### Top Tuyến bay Bận rộn
```sql
SELECT 
    origin,
    dest,
    COUNT(*) as flight_count,
    AVG(distance) as avg_distance,
    AVG(airtime) as avg_airtime
FROM flights_raw
WHERE cancelled = 0
GROUP BY origin, dest
ORDER BY flight_count DESC
LIMIT 10;
```

## Performance Benchmarks

### So sánh Hiệu năng
| Table Type | Query Time | Storage Size | Compression Ratio |
|------------|------------|--------------|-------------------|
| Raw (Text) | 45s | 2.1GB | 1:1 |
| Partitioned (ORC) | 12s | 890MB | 2.4:1 |
| Bucketed (ORC) | 8s | 890MB | 2.4:1 |
| Optimized (Part+Buck) | 5s | 890MB | 2.4:1 |

### Kỹ thuật Tối ưu hóa
- **Partitioning**: Giảm 70% thời gian scan cho time-based queries
- **Bucketing**: Tăng 60% hiệu suất joins
- **ORC Format**: Giảm 58% storage, tăng 3x tốc độ đọc
- **Compression**: Giảm 140% I/O overhead
- **Vectorization**: Tăng 2-5x hiệu suất analytical queries

## Troubleshooting

### Lỗi thường gặp
```bash
# Java not found
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# MySQL connection failed
sudo systemctl restart mysql

# HDFS NameNode not starting
sudo -u hadoop /opt/hadoop/bin/hdfs namenode -format -force

# HiveServer2 connection timeout
sudo systemctl restart hive
```

### Log Files
```bash
# Hadoop logs
/opt/hadoop/logs/

# Hive logs
/opt/hive/logs/

# System logs
journalctl -u hadoop
journalctl -u hive
```

## Đóng góp

### Cách đóng góp
1. Fork repository
2. Tạo feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

### Báo lỗi
- Mở issue trên GitHub
- Mô tả chi tiết lỗi
- Cung cấp log files
- Môi trường hệ thống

## License
Dự án này được phát hành dưới MIT License. Xem file LICENSE để biết chi tiết.

## Tác giả
Dự án được xây dựng để học tập về Big Data Engineering với Hadoop và Hive.

## Tài nguyên Tham khảo
- [Apache Hadoop Documentation](https://hadoop.apache.org/docs/)
- [Apache Hive Documentation](https://hive.apache.org/docs/)
- [HQL Language Manual](https://cwiki.apache.org/confluence/display/Hive/LanguageManual)
- [Hadoop Performance Tuning](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/ClusterSetup.html)

---

**🎯 Mục tiêu**: Trở thành chuyên gia Big Data Engineering với Hadoop và Hive!

**📧 Liên hệ**: Nếu có câu hỏi, hãy tạo issue trên GitHub repository.
