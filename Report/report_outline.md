# Bao cao: Toi uu va phan tich du lieu ban hang quy mo lon bang SQL va Big Data

## 1. Gioi thieu

- Bai toan, muc tieu va pham vi: PostgreSQL, ETL, Data Warehouse, PySpark local va Power BI.
- Quy mo: 100.000 khach hang, 10.000 san pham, 1.000.000 don hang va hon 2.000.000 dong chi tiet.

## 2. Kien truc

`PostgreSQL operational tables -> staging/ETL -> dw star schema -> PySpark JDBC -> CSV tong hop -> Power BI dashboard`.

Chen so do kien truc va mo ta vai tro cua tung thanh phan.

## 3. Thiet ke du lieu

- Mo hinh quan he goc: customers, products, categories, orders, order_items.
- Star schema `dw`: dim_date, dim_customer, dim_product, dim_status va fact_sales.
- Grain cua `fact_sales`: mot dong chi tiet don hang.

## 4. Xu ly va ETL

- Staging, kiem tra du lieu loi, nap thang 1 va thang 2/2024.
- Doi chieu nguon va dich: chenh lech 0 dong.

## 5. SQL nang cao va toi uu

- JOIN, CTE, window functions (`RANK`, `LAG`, `SUM OVER`).
- Trinh bay `EXPLAIN ANALYZE` truoc/sau index. Ghi ro truy van nao khong nhanh hon va ly do.

## 6. Spark va kiem chung

- Spark local doc `dw.fact_sales` qua JDBC PostgreSQL.
- Chen anh `df.show(10)` va `PASS` doi chieu Spark/PostgreSQL; dinh kem CSV ket qua.

## 7. Dashboard

- KPI doanh thu/don hang, xu huong thang, doanh thu danh muc, top san pham.
- Rut ra nhan dinh tu so lieu thuc te sau khi tao dashboard.

## 8. Ket luan va han che

- Spark local khong phai cluster phan tan; JDBC co the la nut that chai o quy mo lon hon.
- Huong phat trien: partition JDBC, Parquet/data lake, orchestration va Spark cluster.
