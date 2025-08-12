# Hướng dẫn Cấu hình Hadoop và Hive

## Tổng quan
Tài liệu này mô tả chi tiết các file cấu hình và tham số quan trọng của Hadoop và Hive trong dự án.

## Lưu ý về vị trí file cấu hình

- Từ cấu trúc mới (Option B), các file cấu hình đặt tại:
  - infra/hadoop/*.xml (Hadoop)
  - infra/hive/hive-site.xml, infra/hive/metastore-setup.sql (Hive)
- Các script cài đặt đã ưu tiên đọc từ infra/* và chỉ fallback về config/* (nếu còn). Khuyến nghị sử dụng infra/*.
- Ghi chú: Thư mục setup chuẩn là scripts/setup (được Makefile sử dụng). Thư mục infra/setup chỉ là lớp tương thích cũ và đã được loại bỏ; nếu tài liệu cũ trỏ tới infra/setup, hãy dùng scripts/setup.

## Cấu hình Hadoop

### 1. core-site.xml
File cấu hình cốt lõi của Hadoop, định nghĩa filesystem mặc định và các thuộc tính chung.

```xml
<configuration>
    <!-- Filesystem mặc định -->
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
        <description>Địa chỉ của HDFS NameNode</description>
    </property>
    
    <!-- Thư mục tạm -->
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/opt/hadoop/tmp</value>
        <description>Thư mục tạm cho Hadoop</description>
    </property>
    
    <!-- Proxy user cho Hive -->
    <property>
        <name>hadoop.proxyuser.hive.hosts</name>
        <value>*</value>
    </property>
    
    <property>
        <name>hadoop.proxyuser.hive.groups</name>
        <value>*</value>
    </property>
</configuration>
```

**Các tham số quan trọng:**
- `fs.defaultFS`: Địa chỉ NameNode, định nghĩa filesystem mặc định
- `hadoop.tmp.dir`: Thư mục lưu trữ file tạm thời
- `hadoop.proxyuser.*`: Cấu hình proxy user cho các service khác

### 2. hdfs-site.xml
Cấu hình cho HDFS (Hadoop Distributed File System).

```xml
<configuration>
    <!-- Replication factor -->
    <property>
        <name>dfs.replication</name>
        <value>1</value>
        <description>Số bản sao của mỗi block (1 cho single node)</description>
    </property>
    
    <!-- NameNode directory -->
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/opt/hadoop/hdfs/namenode</value>
        <description>Thư mục lưu trữ metadata của NameNode</description>
    </property>
    
    <!-- DataNode directory -->
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/opt/hadoop/hdfs/datanode</value>
        <description>Thư mục lưu trữ dữ liệu của DataNode</description>
    </property>
    
    <!-- Block size -->
    <property>
        <name>dfs.blocksize</name>
        <value>134217728</value>
        <description>Kích thước block mặc định (128MB)</description>
    </property>
</configuration>
```

**Các tham số quan trọng:**
- `dfs.replication`: Số bản sao của mỗi block (1 cho single node, 3 cho cluster)
- `dfs.namenode.name.dir`: Thư mục lưu metadata của NameNode
- `dfs.datanode.data.dir`: Thư mục lưu dữ liệu thực tế
- `dfs.blocksize`: Kích thước block (128MB mặc định)

### 3. mapred-site.xml
Cấu hình cho MapReduce framework.

```xml
<configuration>
    <!-- MapReduce framework -->
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
        <description>Sử dụng YARN làm resource manager</description>
    </property>
    
    <!-- Memory cho Map tasks -->
    <property>
        <name>mapreduce.map.memory.mb</name>
        <value>1024</value>
        <description>Bộ nhớ cho mỗi Map task (MB)</description>
    </property>
    
    <!-- Memory cho Reduce tasks -->
    <property>
        <name>mapreduce.reduce.memory.mb</name>
        <value>1024</value>
        <description>Bộ nhớ cho mỗi Reduce task (MB)</description>
    </property>
</configuration>
```

**Các tham số quan trọng:**
- `mapreduce.framework.name`: Framework sử dụng (yarn)
- `mapreduce.map.memory.mb`: Bộ nhớ cho Map tasks
- `mapreduce.reduce.memory.mb`: Bộ nhớ cho Reduce tasks

### 4. yarn-site.xml
Cấu hình cho YARN (Yet Another Resource Negotiator).

```xml
<configuration>
    <!-- ResourceManager -->
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>localhost</value>
        <description>Hostname của ResourceManager</description>
    </property>
    
    <!-- NodeManager services -->
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
        <description>Auxiliary services cho NodeManager</description>
    </property>
    
    <!-- Memory configuration -->
    <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>4096</value>
        <description>Tổng bộ nhớ khả dụng cho containers</description>
    </property>
    
    <property>
        <name>yarn.scheduler.maximum-allocation-mb</name>
        <value>4096</value>
        <description>Bộ nhớ tối đa cho một container</description>
    </property>
</configuration>
```

**Các tham số quan trọng:**
- `yarn.nodemanager.resource.memory-mb`: Tổng memory cho containers
- `yarn.scheduler.maximum-allocation-mb`: Memory tối đa cho 1 container
- `yarn.nodemanager.aux-services`: Auxiliary services (mapreduce_shuffle)

## Cấu hình Hive

### 1. hive-site.xml
File cấu hình chính của Hive.

```xml
<configuration>
    <!-- Metastore Database -->
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://localhost:3306/hive_metastore?createDatabaseIfNotExist=true&amp;useSSL=false</value>
        <description>JDBC connection URL cho Hive Metastore</description>
    </property>
    
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>com.mysql.cj.jdbc.Driver</value>
        <description>JDBC driver class cho MySQL</description>
    </property>
    
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>hive</value>
        <description>Username cho database connection</description>
    </property>
    
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>hive123</value>
        <description>Password cho database connection</description>
    </property>
    
    <!-- HiveServer2 Configuration -->
    <property>
        <name>hive.server2.thrift.bind.host</name>
        <value>0.0.0.0</value>
        <description>Bind host cho HiveServer2</description>
    </property>
    
    <property>
        <name>hive.server2.thrift.port</name>
        <value>10000</value>
        <description>Port cho HiveServer2</description>
    </property>
    
    <!-- Metastore Service -->
    <property>
        <name>hive.metastore.uris</name>
        <value>thrift://localhost:9083</value>
        <description>URI của Hive Metastore service</description>
    </property>
    
    <!-- Warehouse Directory -->
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>/user/hive/warehouse</value>
        <description>Thư mục warehouse trên HDFS</description>
    </property>
</configuration>
```

**Các tham số quan trọng:**
- `javax.jdo.option.ConnectionURL`: URL kết nối database Metastore
- `hive.server2.thrift.port`: Port của HiveServer2 (10000)
- `hive.metastore.uris`: URI của Metastore service
- `hive.metastore.warehouse.dir`: Thư mục warehouse trên HDFS

### 2. Cấu hình Tối ưu hóa

#### Dynamic Partitioning
```xml
<property>
    <name>hive.exec.dynamic.partition</name>
    <value>true</value>
    <description>Bật dynamic partitioning</description>
</property>

<property>
    <name>hive.exec.dynamic.partition.mode</name>
    <value>nonstrict</value>
    <description>Mode cho dynamic partitioning</description>
</property>

<property>
    <name>hive.exec.max.dynamic.partitions</name>
    <value>1000</value>
    <description>Số partition tối đa</description>
</property>
```

#### Compression
```xml
<property>
    <name>hive.exec.compress.output</name>
    <value>true</value>
    <description>Nén output của Hive queries</description>
</property>

<property>
    <name>hive.exec.compress.intermediate</name>
    <value>true</value>
    <description>Nén intermediate data</description>
</property>
```

#### Vectorization
```xml
<property>
    <name>hive.vectorized.execution.enabled</name>
    <value>true</value>
    <description>Bật vectorized execution</description>
</property>

<property>
    <name>hive.vectorized.execution.reduce.enabled</name>
    <value>true</value>
    <description>Bật vectorized execution cho reduce tasks</description>
</property>
```

## Biến Môi trường

### Hadoop Environment
```bash
# File: ~/.hadoop_env
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export YARN_HOME=$HADOOP_HOME
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
```

### Hive Environment
```bash
# Thêm vào ~/.hadoop_env
export HIVE_HOME=/opt/hive
export PATH=$PATH:$HIVE_HOME/bin
export CLASSPATH=$CLASSPATH:$HADOOP_HOME/lib/*:$HIVE_HOME/lib/*
```

## Tuning Parameters

### Memory Tuning

#### Cho hệ thống 8GB RAM:
```xml
<!-- YARN -->
<property>
    <name>yarn.nodemanager.resource.memory-mb</name>
    <value>6144</value>
</property>

<!-- MapReduce -->
<property>
    <name>mapreduce.map.memory.mb</name>
    <value>1024</value>
</property>

<property>
    <name>mapreduce.reduce.memory.mb</name>
    <value>2048</value>
</property>
```

#### Cho hệ thống 16GB RAM:
```xml
<!-- YARN -->
<property>
    <name>yarn.nodemanager.resource.memory-mb</name>
    <value>12288</value>
</property>

<!-- MapReduce -->
<property>
    <name>mapreduce.map.memory.mb</name>
    <value>2048</value>
</property>

<property>
    <name>mapreduce.reduce.memory.mb</name>
    <value>4096</value>
</property>
```

### Performance Tuning

#### Hive Performance
```xml
<!-- Cost-based Optimization -->
<property>
    <name>hive.cbo.enable</name>
    <value>true</value>
</property>

<!-- Statistics -->
<property>
    <name>hive.stats.autogather</name>
    <value>true</value>
</property>

<!-- Map-side Join -->
<property>
    <name>hive.auto.convert.join</name>
    <value>true</value>
</property>

<property>
    <name>hive.mapjoin.smalltable.filesize</name>
    <value>25000000</value>
</property>
```

## Security Configuration

### Basic Security
```xml
<!-- Hadoop -->
<property>
    <name>hadoop.security.authentication</name>
    <value>simple</value>
</property>

<property>
    <name>hadoop.security.authorization</name>
    <value>false</value>
</property>

<!-- Hive -->
<property>
    <name>hive.server2.authentication</name>
    <value>NONE</value>
</property>
```

### Kerberos Security (Production)
```xml
<!-- Hadoop -->
<property>
    <name>hadoop.security.authentication</name>
    <value>kerberos</value>
</property>

<property>
    <name>hadoop.security.authorization</name>
    <value>true</value>
</property>

<!-- Hive -->
<property>
    <name>hive.server2.authentication</name>
    <value>KERBEROS</value>
</property>

<property>
    <name>hive.server2.authentication.kerberos.principal</name>
    <value>hive/_HOST@REALM.COM</value>
</property>
```

## Monitoring và Logging

### Log Configuration
```xml
<!-- Hive Logging -->
<property>
    <name>hive.server2.logging.operation.enabled</name>
    <value>true</value>
</property>

<property>
    <name>hive.server2.logging.operation.log.location</name>
    <value>/opt/hive/logs/operation</value>
</property>
```

### JVM Tuning
```bash
# File: hadoop-env.sh
export HADOOP_HEAPSIZE=2048
export HADOOP_NAMENODE_OPTS="-Xmx2048m"
export HADOOP_DATANODE_OPTS="-Xmx1024m"

# File: hive-env.sh
export HADOOP_HEAPSIZE=2048
```

## Troubleshooting Configuration

### Common Issues

#### 1. OutOfMemory Errors
```xml
<!-- Tăng memory allocation -->
<property>
    <name>yarn.scheduler.maximum-allocation-mb</name>
    <value>8192</value>
</property>

<property>
    <name>mapreduce.map.memory.mb</name>
    <value>2048</value>
</property>
```

#### 2. Slow Queries
```xml
<!-- Bật compression -->
<property>
    <name>hive.exec.compress.output</name>
    <value>true</value>
</property>

<!-- Bật vectorization -->
<property>
    <name>hive.vectorized.execution.enabled</name>
    <value>true</value>
</property>
```

#### 3. Connection Issues
```xml
<!-- Tăng timeout -->
<property>
    <name>hive.server2.idle.session.timeout</name>
    <value>7200000</value>
</property>

<property>
    <name>hive.server2.idle.operation.timeout</name>
    <value>300000</value>
</property>
```

## Best Practices

### 1. Resource Allocation
- Để lại 20-25% RAM cho OS
- Cấu hình YARN memory = 75% total RAM
- Map task memory = 1-2GB
- Reduce task memory = 2-4GB

### 2. Storage Configuration
- Sử dụng SSD cho NameNode metadata
- Phân tán DataNode directories trên nhiều disk
- Thiết lập replication factor phù hợp (1 cho dev, 3 cho prod)

### 3. Performance Optimization
- Bật compression cho intermediate và output data
- Sử dụng ORC/Parquet format
- Thiết lập partitioning và bucketing hợp lý
- Bật vectorization và CBO

### 4. Monitoring
- Thiết lập log rotation
- Monitor memory và disk usage
- Theo dõi query performance
- Thiết lập alerting cho critical metrics
