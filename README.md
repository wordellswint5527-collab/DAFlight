# Pipeline Dữ liệu End-to-End với Azure và dbt

## Tóm tắt Dự án
Dự án này là một hướng dẫn toàn diện về cách thiết kế và triển khai một pipeline dữ liệu hiện đại, tự động trên nền tảng đám mây Microsoft Azure. Bằng cách kết hợp các dịch vụ hàng đầu của Azure như Synapse Analytics, Data Factory, và Power BI với công cụ chuyển đổi dữ liệu mã nguồn mở dbt, chúng ta sẽ xây dựng một quy trình ELT (Extract, Load, Transform) mạnh mẽ.

## Kiến trúc Hệ thống

```
[CSV Files] → [Azure Blob Storage] → [Azure Data Factory] → [Azure Synapse Analytics]
                                                                        ↓
[Power BI] ← [dbt Models] ← [Azure Synapse Analytics (Transformed Data)]
                                                                        ↓
                                                            [Azure Monitor & Logic Apps]
```

## Ngăn xếp Công nghệ (Tech Stack)

- **Nền tảng**: Microsoft Azure
- **Lưu trữ Dữ liệu thô**: Azure Blob Storage
- **Kho dữ liệu & Phân tích**: Azure Synapse Analytics
- **Điều phối Pipeline**: Azure Data Factory (ADF)
- **Chuyển đổi Dữ liệu**: dbt (Data Build Tool)
- **Trực quan hóa Dữ liệu**: Microsoft Power BI
- **Giám sát & Cảnh báo**: Azure Monitor & Azure Logic Apps
- **Ngôn ngữ**: SQL, Python

## Cấu trúc Dự án

```
├── README.md
├── requirements.txt
├── .gitignore
├── dbt_project/
│   ├── dbt_project.yml
│   ├── profiles.yml
│   ├── models/
│   │   ├── staging/
│   │   ├── intermediate/
│   │   └── marts/
│   ├── macros/
│   ├── tests/
│   └── seeds/
├── azure_infrastructure/
│   ├── arm_templates/
│   ├── bicep_templates/
│   └── terraform/
├── azure_data_factory/
│   ├── pipelines/
│   ├── datasets/
│   ├── linked_services/
│   └── triggers/
├── monitoring/
│   ├── azure_monitor/
│   └── logic_apps/
├── scripts/
│   ├── deployment/
│   ├── data_generation/
│   └── utilities/
├── sample_data/
└── docs/
    ├── architecture.md
    ├── deployment_guide.md
    └── user_guide.md
```

## Luồng hoạt động của Pipeline

1. **Nạp Dữ liệu (Data Ingestion)**
   - Dữ liệu nguồn (CSV files) được tải lên Azure Blob Storage
   - Blob Storage hoạt động như "landing zone" cho dữ liệu thô

2. **Điều phối và Tải vào Kho dữ liệu (Orchestration and Loading)**
   - Azure Data Factory pipeline chạy theo lịch trình hoặc trigger
   - Sao chép dữ liệu từ Blob Storage vào Azure Synapse Analytics

3. **Chuyển đổi và Mô hình hóa Dữ liệu (Data Transformation)**
   - ADF kích hoạt dbt models
   - dbt thực hiện transformation, cleaning, và modeling dữ liệu

4. **Trực quan hóa và Khai thác Thông tin (Visualization)**
   - Power BI kết nối với Synapse Analytics
   - Tạo dashboards và reports tương tác

5. **Giám sát và Cảnh báo (Monitoring & Alerting)**
   - Azure Monitor theo dõi pipeline
   - Logic Apps gửi thông báo khi có lỗi

## Yêu cầu Hệ thống

- Azure Subscription với quyền tạo resources
- dbt Core hoặc dbt Cloud
- Python 3.8+
- Azure CLI
- Power BI Desktop/Service

## Hướng dẫn Triển khai Nhanh

### Bước 1: Chuẩn bị
```bash
# Clone repository
git clone <repository-url>
cd azure-dbt-pipeline

# Tạo virtual environment
python -m venv venv
source venv/bin/activate  # Linux/macOS
# hoặc venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt

# Đăng nhập Azure
az login
az account set --subscription "your-subscription-id"
```

### Bước 2: Triển khai Infrastructure
```bash
# Chỉnh sửa cấu hình trong script
nano scripts/deployment/deploy_infrastructure.sh

# Chạy deployment
chmod +x scripts/deployment/deploy_infrastructure.sh
./scripts/deployment/deploy_infrastructure.sh
```

### Bước 3: Cấu hình dbt
```bash
# Copy và chỉnh sửa profiles
mkdir -p ~/.dbt
cp dbt_project/profiles.yml.example ~/.dbt/profiles.yml
nano ~/.dbt/profiles.yml

# Test connection
cd dbt_project
dbt deps
dbt debug
```

### Bước 4: Triển khai Pipelines
```bash
# Deploy Data Factory pipelines
./scripts/deployment/deploy_adf_pipeline.sh
```

### Bước 5: Test với Sample Data
```bash
# Generate sample data
python scripts/data_generation/generate_sample_data.py

# Upload to Azure Blob Storage
az storage blob upload-batch \
  --account-name yourstorageaccount \
  --destination raw-data \
  --source sample_data \
  --pattern "*.csv"

# Trigger pipeline manually
az datafactory pipeline create-run \
  --resource-group rg-data-pipeline \
  --factory-name your-data-factory \
  --pipeline-name Main_ELT_Pipeline
```

## Monitoring và Utilities

### Kiểm tra Data Quality
```bash
# Chạy comprehensive data quality checks
python scripts/utilities/check_data_quality.py \
  --connection-string "your-synapse-connection-string" \
  --output-file data_quality_report.txt
```

### Monitor Pipeline Status
```bash
# Xem status report
python scripts/utilities/monitor_pipeline.py \
  --subscription-id "your-subscription-id" \
  --resource-group "rg-data-pipeline" \
  --factory-name "your-data-factory" \
  --command report

# Monitor real-time
python scripts/utilities/monitor_pipeline.py \
  --subscription-id "your-subscription-id" \
  --resource-group "rg-data-pipeline" \
  --factory-name "your-data-factory" \
  --command monitor

# Check pipeline health
python scripts/utilities/monitor_pipeline.py \
  --subscription-id "your-subscription-id" \
  --resource-group "rg-data-pipeline" \
  --factory-name "your-data-factory" \
  --command health
```

### dbt Commands
```bash
cd dbt_project

# Chạy tất cả models
dbt run

# Chạy tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve

# Chạy specific models
dbt run --models staging
dbt run --models marts
```

### Quản lý Triggers
```bash
# Start daily trigger
az datafactory trigger start \
  --resource-group rg-data-pipeline \
  --factory-name your-data-factory \
  --trigger-name DailyTrigger

# Stop trigger
az datafactory trigger stop \
  --resource-group rg-data-pipeline \
  --factory-name your-data-factory \
  --trigger-name DailyTrigger

# List all triggers
az datafactory trigger list \
  --resource-group rg-data-pipeline \
  --factory-name your-data-factory \
  --query "[].{Name:name, State:properties.runtimeState}"
```

## Troubleshooting

### Common Issues

1. **dbt Connection Failed**
   ```bash
   # Check ODBC driver
   odbcinst -j
   
   # Test SQL connection
   sqlcmd -S your-synapse-workspace.sql.azuresynapse.net -d DataWarehouse
   ```

2. **Pipeline Failed**
   ```bash
   # Check pipeline logs
   az datafactory pipeline-run query-by-factory \
     --resource-group rg-data-pipeline \
     --factory-name your-data-factory
   ```

3. **Data Quality Issues**
   ```bash
   # Run data quality checks
   python scripts/utilities/check_data_quality.py \
     --connection-string "your-connection-string"
   ```

## Performance Tips

- **Synapse SQL Pool**: Scale DWU based on workload
- **dbt Models**: Use incremental materialization for large tables
- **Monitoring**: Set up alerts for pipeline failures
- **Cost Optimization**: Auto-pause SQL Pool when not in use

## Tài liệu

- [Kiến trúc Hệ thống](docs/architecture.md)
- [Hướng dẫn Triển khai Chi tiết](docs/deployment_guide.md)
- [Hướng dẫn Sử dụng](docs/user_guide.md)

## Đóng góp

Vui lòng đọc [CONTRIBUTING.md](CONTRIBUTING.md) để biết chi tiết về quy trình đóng góp.

## Support

- **Issues**: [GitHub Issues](https://github.com/your-org/azure-dbt-pipeline/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/azure-dbt-pipeline/discussions)
- **Email**: data-team@company.com

## Giấy phép

Dự án này được cấp phép theo [MIT License](LICENSE).
