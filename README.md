# Phân tích dữ liệu bán hàng quy mô lớn

Dự án minh họa quy trình phân tích dữ liệu bán hàng với PostgreSQL, SQL, kho dữ liệu dạng star schema, PySpark chạy local và Power BI. Quy mô dữ liệu mục tiêu gồm 100.000 khách hàng, 10.000 sản phẩm, 1.000.000 đơn hàng và hơn 2.000.000 dòng chi tiết đơn hàng.

## Kiến trúc

```text
PostgreSQL (dữ liệu vận hành)
    -> staging và ETL
    -> PostgreSQL Data Warehouse (dw star schema)
    -> PySpark đọc qua JDBC, tổng hợp và đối chiếu với PostgreSQL
    -> CSV tổng hợp
    -> Power BI
```

`dw.fact_sales` có grain là một dòng trên mỗi sản phẩm trong đơn hàng. Spark tạo các kết quả doanh thu theo tháng, theo danh mục và top 10 sản phẩm; các CSV này được Power BI sử dụng thay vì nạp toàn bộ bảng fact.

## Cấu trúc dự án

| Thư mục / tệp | Nội dung |
| --- | --- |
| `Database/create_tables.sql` | Tạo các bảng dữ liệu vận hành |
| `Data_Generation/generate_sales_data.py` | Tạo CSV dữ liệu mẫu có thể tái lập |
| `Data_Warehouse/create_star_schema.sql` | Tạo schema `dw`, dimension và fact |
| `ETL/load_sales_to_warehouse.sql` | Nạp dữ liệu từ bảng vận hành vào staging và kho dữ liệu |
| `SQL_Queries/` | Truy vấn phân tích bán hàng và truy vấn đối chiếu Spark |
| `Optimization/` | Các index và ghi chú benchmark `EXPLAIN ANALYZE` |
| `Big_Data_Extension/spark_analysis.py` | Phân tích `dw.fact_sales` bằng PySpark qua PostgreSQL JDBC |
| `Big_Data_Extension/output/` | CSV tổng hợp và kết quả đối chiếu dùng cho dashboard |
| `Dashboard/` | Báo cáo Power BI, measures DAX và hướng dẫn Power Query |
| `Report/` | Dàn ý báo cáo dự án |

## Yêu cầu

- PostgreSQL với cơ sở dữ liệu `bigdata_sql` đã được nạp dữ liệu dự án.
- Python, PySpark và Java được cài đặt để chạy Spark local.
- PostgreSQL JDBC driver dạng JAR trong `Big_Data_Extension/` (các bản driver có sẵn trong thư mục này).
- Power BI Desktop nếu muốn mở hoặc cập nhật dashboard.

## Chạy phân tích Spark

Từ thư mục gốc dự án, đặt mật khẩu PostgreSQL trong biến môi trường rồi chạy:

```powershell
$env:PGPASSWORD = "<mat-khau-postgres>"
python Big_Data_Extension/spark_analysis.py
```

Mặc định script kết nối tới `jdbc:postgresql://localhost:5432/bigdata_sql` bằng user `postgres`. Có thể cấu hình `PGJDBC_URL` và `PGUSER` nếu kết nối của bạn khác. Mật khẩu chỉ nên được đặt qua biến môi trường, không ghi vào mã nguồn.

Khi chạy thành công, script in thông báo đối chiếu Spark/PostgreSQL `PASS` và ghi các tệp sau vào `Big_Data_Extension/output/`:

- `monthly_revenue.csv`
- `category_revenue.csv`
- `top_products.csv`
- `validation_summary.txt`

## Mở hoặc cập nhật dashboard

Mở `Dashboard/bigdata_sales_dashboard.pbix` bằng Power BI Desktop. Dashboard dùng ba CSV tổng hợp trong `Big_Data_Extension/output/`; sau khi chạy lại Spark, chọn **Refresh** trong Power BI để cập nhật dữ liệu. Xem `Dashboard/README.md` để biết cách tạo các visual, measures và thiết lập Power Query.

## Lưu ý khi tạo hoặc nạp lại dữ liệu

Dữ liệu lịch sử và dashboard của dự án đã có sẵn. Các script SQL thiết lập schema và ETL là tài liệu/quy trình cho cơ sở dữ liệu mới hoặc một đợt nạp đã được kiểm soát, không phải các bước cần chạy lại mỗi lần phân tích:

- `Database/create_tables.sql` chỉ chạy trên cơ sở dữ liệu trống.
- `Data_Warehouse/create_star_schema.sql` chỉ chạy khi khởi tạo kho dữ liệu mới.
- Trước khi chạy `ETL/load_sales_to_warehouse.sql`, kiểm tra khoảng ngày và cách nạp theo batch trong script; sao lưu dữ liệu trước khi thay đổi kho dữ liệu hiện có.
- `Data_Generation/generate_sales_data.py` chỉ tạo CSV đầu vào, không nạp dữ liệu vào PostgreSQL. Chỉ chạy khi thực sự cần tạo một bộ dữ liệu mới.

## SQL và tối ưu

Chạy các truy vấn trong `SQL_Queries/` trên cơ sở dữ liệu dự án để xem các phân tích nâng cao như xếp hạng danh mục, doanh thu theo tháng và doanh thu lũy kế. Đánh giá các index trong `Optimization/indexes.sql` bằng `EXPLAIN (ANALYZE, BUFFERS)` trước và sau khi tạo index; ghi kết quả thực đo vào `Optimization/benchmark_results.md`, không giả định rằng mọi truy vấn đều nhanh hơn khi có index.

# Chạy chương trình 
$env:PGPASSWORD = "123456"
python Big_Data_Extension/spark_analysis.py