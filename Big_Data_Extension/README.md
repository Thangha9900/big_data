# Spark va PostgreSQL

## Trang thai

Da kiem tra thanh cong Spark local doc `dw.fact_sales` qua PostgreSQL JDBC tren may nay. Khong can cai Hadoop cluster hay tai `winutils.exe` tu nguon khong xac dinh.

`winutils.exe` la canh bao khi Spark khoi dong tren Windows. No tro thanh loi khi cau hinh `spark.jars` lam Spark sao chep JAR. Script su dung `spark.driver.extraClassPath` va `spark.executor.extraClassPath` cho JAR cu bo, phu hop voi `local[2]`, nen tranh duoc loi nay.

## Chay phan tich

Tu thu muc goc project, dat mat khau o bien moi truong (khong ghi mat khau vao source code):

```powershell
$env:PGPASSWORD = "<mat-khau-postgres>"
python Big_Data_Extension/spark_analysis.py
```

Neu host/database/user khac mac dinh, dat them `PGJDBC_URL` va `PGUSER`. Script doc fact/dimension, tinh doanh thu theo thang, danh muc va top 10 san pham, doi chieu voi PostgreSQL, sau do ghi CSV vao `Big_Data_Extension/output/`.

Dong `PASS: Doi chieu Spark/PostgreSQL thanh cong` la dieu kien hoan thanh phan ket noi va doi chieu.


$env:PGPASSWORD = "<mat-khau-postgres>"
python Big_Data_Extension/spark_analysis.py