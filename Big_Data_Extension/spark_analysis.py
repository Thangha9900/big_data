"""Phan tich dw.fact_sales bang PySpark o che do local tren Windows.

Chay tu thu muc goc project:
    $env:PGPASSWORD = "<mat-khau-postgres>"
    python Big_Data_Extension/spark_analysis.py
"""

import csv
import os
import sys
from pathlib import Path

# Dat truoc khi import pyspark de Spark dung dung Python hien tai tren Windows.
os.environ.setdefault("PYSPARK_PYTHON", sys.executable)
os.environ.setdefault("PYSPARK_DRIVER_PYTHON", sys.executable)
# PowerShell co the dung cp1252; ep UTF-8 de hien thi ten danh muc tieng Viet.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

from pyspark.sql import SparkSession, functions as F


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_DIR = Path(__file__).resolve().parent
OUTPUT_DIR = SCRIPT_DIR / "output"
JARS = sorted(jar for jar in SCRIPT_DIR.glob("postgresql-*.jar") if jar.stat().st_size > 0)

if not JARS:
    raise FileNotFoundError(
        "Khong tim thay PostgreSQL JDBC driver. Dat file postgresql-<version>.jar "
        "(co dung luong > 0) trong Big_Data_Extension/."
    )

JDBC_JAR = JARS[-1]
JDBC_URL = os.getenv("PGJDBC_URL", "jdbc:postgresql://localhost:5432/bigdata_sql")
JDBC_PROPERTIES = {
    "user": os.getenv("PGUSER", "postgres"),
    "password": os.getenv("PGPASSWORD", ""),
    "driver": "org.postgresql.Driver",
    "fetchsize": "10000",
}


def jdbc_read(spark: SparkSession, table_or_query: str):
    """Doc mot bang hoac SELECT boc trong dau ngoac tu PostgreSQL."""
    return spark.read.jdbc(url=JDBC_URL, table=table_or_query, properties=JDBC_PROPERTIES)


def write_csv(filename: str, dataframe) -> Path:
    """Ghi ket qua nho bang Python, tranh phu thuoc winutils.exe khi ghi Spark output."""
    OUTPUT_DIR.mkdir(exist_ok=True)
    target = OUTPUT_DIR / filename
    rows = dataframe.collect()
    with target.open("w", newline="", encoding="utf-8-sig") as file:
        writer = csv.writer(file)
        writer.writerow(dataframe.columns)
        writer.writerows([list(row) for row in rows])
    return target


def main() -> None:
    if not JDBC_PROPERTIES["password"]:
        raise ValueError("Hay dat bien moi truong PGPASSWORD truoc khi chay script.")

    spark = (
        SparkSession.builder.appName("BigDataSQLProject")
        .master("local[2]")
        .config("spark.ui.enabled", "false")
        # Khong dung spark.jars: tren Windows no kich hoat loi HADOOP_HOME/winutils.
        .config("spark.driver.extraClassPath", str(JDBC_JAR))
        .config("spark.executor.extraClassPath", str(JDBC_JAR))
        .getOrCreate()
    )
    spark.sparkContext.setLogLevel("WARN")

    try:
        fact_sales = jdbc_read(spark, "dw.fact_sales")
        dim_date = jdbc_read(spark, "dw.dim_date")
        dim_product = jdbc_read(spark, "dw.dim_product")

        print(f"Spark {spark.version}; JDBC driver: {JDBC_JAR.name}")
        print(f"So dong fact_sales: {fact_sales.count():,}")
        fact_sales.show(10, truncate=False)

        sales = (
            fact_sales.join(dim_date, "date_key")
            .join(dim_product, "product_key")
            .select("order_id", "quantity", "revenue", "year", "month",
                    "product_id", "product_name", "category_name")
        )
        monthly_revenue = (
            sales.groupBy("year", "month")
            .agg(F.sum("revenue").alias("revenue"), F.countDistinct("order_id").alias("order_count"),
                 F.sum("quantity").alias("quantity_sold"))
            .orderBy("year", "month")
        )
        category_revenue = (
            sales.groupBy("category_name")
            .agg(F.sum("revenue").alias("revenue"), F.sum("quantity").alias("quantity_sold"))
            .orderBy(F.desc("revenue"))
        )
        top_products = (
            sales.groupBy("product_id", "product_name", "category_name")
            .agg(F.sum("revenue").alias("revenue"), F.sum("quantity").alias("quantity_sold"))
            .orderBy(F.desc("revenue"), "product_id")
            .limit(10)
        )

        for name, frame in (("Doanh thu theo thang", monthly_revenue),
                            ("Doanh thu theo danh muc", category_revenue),
                            ("Top 10 san pham", top_products)):
            print(f"\n{name}")
            frame.show(20, truncate=False)

        output_files = [
            write_csv("monthly_revenue.csv", monthly_revenue),
            write_csv("category_revenue.csv", category_revenue),
            write_csv("top_products.csv", top_products),
        ]

        postgres_monthly = jdbc_read(
            spark,
            """(
                SELECT d.year, d.month, SUM(f.revenue) AS revenue,
                       COUNT(DISTINCT f.order_id) AS order_count, SUM(f.quantity) AS quantity_sold
                FROM dw.fact_sales f JOIN dw.dim_date d ON d.date_key = f.date_key
                GROUP BY d.year, d.month
            ) AS monthly_sql""",
        ).orderBy("year", "month")

        spark_rows = [tuple(row) for row in monthly_revenue.collect()]
        sql_rows = [tuple(row) for row in postgres_monthly.collect()]
        if spark_rows != sql_rows:
            raise AssertionError("Ket qua Spark khong khop truy van PostgreSQL. Kiem tra schema/du lieu.")

        validation_file = OUTPUT_DIR / "validation_summary.txt"
        validation_file.write_text(
            "PASS: Spark va PostgreSQL khop doanh thu, so don va so luong theo thang.\n"
            f"So nhom thang da doi chieu: {len(spark_rows)}\n", encoding="utf-8"
        )
        print(f"\nPASS: Doi chieu Spark/PostgreSQL thanh cong ({len(spark_rows)} nhom thang).")
        print("Da ghi ket qua:")
        for output_file in output_files + [validation_file]:
            print(f"- {output_file.relative_to(PROJECT_ROOT)}")
    finally:
        spark.stop()


if __name__ == "__main__":
    main()
