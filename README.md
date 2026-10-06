# Big Data SQL Project

Project: toi uu va phan tich du lieu ban hang quy mo lon bang PostgreSQL, ETL, Data Warehouse, PySpark va Power BI.

## Run order

1. `Database/create_tables.sql` creates the operational schema.
2. `Data_Generation/generate_sales_data.py` creates reproducible input CSV when a new dataset is required.
3. `ETL/load_sales_to_warehouse.sql` and `Data_Warehouse/create_star_schema.sql` document the warehouse pipeline.
4. `Optimization/` and `SQL_Queries/` hold analysis and benchmark SQL.
5. Run `Big_Data_Extension/spark_analysis.py`; then refresh `Dashboard/bigdata_sales_dashboard.pbix`.

The current database and dashboard are already populated. Do not rerun schema or historical ETL scripts against the existing database without a backup.
