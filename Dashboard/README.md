# Dashboard Power BI

## Du lieu da san sang

Ba CSV trong `Big_Data_Extension/output/` da duoc tao tu Spark va doi chieu `PASS` voi PostgreSQL: `monthly_revenue.csv`, `category_revenue.csv`, `top_products.csv`. Day la nguon du lieu nen dung cho dashboard: nhe, co the refresh bang cach chay lai Spark, va khong lam Power BI phai nap 2.000.011 dong fact.

## Tao dashboard (khoang 10 phut)

1. Mo Power BI Desktop > **Get data** > **Text/CSV**; nap lan luot ca ba file CSV.
2. Chon **Transform Data**. Kiem tra `revenue` la Fixed decimal number/Currency; `order_count`, `quantity_sold`, `year`, `month` la Whole number. Chon **Close & Apply**.
3. Vao **Modeling > New measure**, tao cac measure trong `power_bi_measures.dax`.
4. Tao mot trang co ten **Sales Overview** theo bo cuc ben duoi. Dung `month_start` lam truc thoi gian neu da them bang Power Query; neu import CSV truc tiep, dung hierarchy `year` > `month`.

| Vi tri | Visual | Fields / settings |
| --- | --- | --- |
| Hang 1 | Card: Total Revenue | `[Total Revenue]`, format Currency, 0 decimal |
| Hang 1 | Card: Total Orders | `[Total Orders]`, format Whole number |
| Hang 1 | Card: Total Quantity Sold | `[Total Quantity Sold]` |
| Hang 1 | Card: Average Revenue per Order | `[Average Revenue per Order]`, format Currency |
| Hang 2 trai | Line chart: Revenue by Month | Axis: `monthly_revenue[month_start]`; Values: `[Total Revenue]`; continuous axis |
| Hang 2 phai | Clustered bar: Revenue by Category | Y-axis: `category_revenue[category_name]`; X-axis: `[Category Revenue]`; sort descending |
| Hang 3 trai | Clustered bar: Top 10 Products | Y-axis: `top_products[product_name]`; X-axis: `[Top Product Revenue]`; sort descending |
| Hang 3 phai | Table: Product detail | product_name, category_name, revenue, quantity_sold |

5. Trong **Format**, dat tieu de cac visual theo dung ten tren; chon mot mau nhat quan (vi du xanh dam cho revenue), bat data labels cho hai bar chart. Luu thanh `Dashboard/bigdata_sales_dashboard.pbix`.
6. Chup anh trang dashboard va luu vao `Report/images/dashboard_overview.png` de chen vao bao cao.

## Neu muon dung Power Query

`power_query.m` chua ba query da gan san duong dan tuyet doi cua project va ep dung kieu du lieu. Trong Power Query, chon **New Source > Blank Query > Advanced Editor**, dan tung block, doi ten query dung nhu comment, sau do **Close & Apply**.

## Refresh du lieu

Chay lai `python Big_Data_Extension/spark_analysis.py`, sau do trong Power BI chon **Refresh**. Khong can tai lai du lieu goc hoac chay lai ETL.
