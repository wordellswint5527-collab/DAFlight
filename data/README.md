# Sample Data

Thư mục này chứa dữ liệu mẫu để test pipeline dữ liệu.

## Cấu trúc Dữ liệu

### customer_data.csv
Dữ liệu khách hàng với các trường:
- `customer_id`: ID khách hàng (CUST_000001)
- `first_name`: Tên
- `last_name`: Họ
- `email`: Email
- `phone`: Số điện thoại
- `address`: Địa chỉ
- `city`: Thành phố
- `state`: Bang/Tỉnh
- `country`: Quốc gia
- `postal_code`: Mã bưu điện
- `registration_date`: Ngày đăng ký
- `customer_segment`: Phân khúc khách hàng (premium, standard, basic)
- `created_at`: Timestamp tạo record

### product_data.csv
Dữ liệu sản phẩm với các trường:
- `product_id`: ID sản phẩm (PROD_000001)
- `product_name`: Tên sản phẩm
- `category`: Danh mục
- `subcategory`: Danh mục con
- `brand`: Thương hiệu
- `supplier_id`: ID nhà cung cấp
- `cost_price`: Giá vốn
- `retail_price`: Giá bán lẻ
- `weight`: Trọng lượng
- `dimensions`: Kích thước
- `launch_date`: Ngày ra mắt
- `status`: Trạng thái (active, discontinued)
- `created_at`: Timestamp tạo record

### sales_data.csv
Dữ liệu giao dịch bán hàng với các trường:
- `transaction_id`: ID giao dịch (TXN_00000001)
- `customer_id`: ID khách hàng
- `product_id`: ID sản phẩm
- `transaction_date`: Ngày giao dịch
- `quantity`: Số lượng
- `unit_price`: Đơn giá
- `total_amount`: Tổng tiền
- `sales_channel`: Kênh bán hàng (online, store, mobile, phone)
- `region`: Khu vực (north, south, east, west, central)
- `created_at`: Timestamp tạo record

## Tạo Dữ liệu Mẫu

Để tạo dữ liệu mẫu mới:

```bash
cd scripts/data_generation
python generate_sample_data.py --customers 1000 --products 500 --transactions 10000 --output ../../sample_data
```

## Upload lên Azure

```bash
# Upload tất cả file CSV lên Blob Storage
az storage blob upload-batch \
  --account-name yourstorageaccount \
  --destination raw-data \
  --source sample_data \
  --pattern "*.csv"
```
