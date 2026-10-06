// Power Query M: tao 3 Blank Query, doi ten va dan dung tung block.
// Sau khi mo file, chon Data type: revenue = Fixed decimal number;
// order_count, quantity_sold, year, month = Whole number.

// Query: monthly_revenue
let
    Source = Csv.Document(
        File.Contents("C:\\Users\\admin\\Desktop\\BigData_SQL_Project\\Big_Data_Extension\\output\\monthly_revenue.csv"),
        [Delimiter = ",", Columns = 5, Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    PromoteHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    ChangeTypes = Table.TransformColumnTypes(PromoteHeaders, {
        {"year", Int64.Type}, {"month", Int64.Type}, {"revenue", Currency.Type},
        {"order_count", Int64.Type}, {"quantity_sold", Int64.Type}
    }),
    AddMonthStart = Table.AddColumn(ChangeTypes, "month_start", each #date([year], [month], 1), type date)
in
    AddMonthStart

// Query: category_revenue
let
    Source = Csv.Document(
        File.Contents("C:\\Users\\admin\\Desktop\\BigData_SQL_Project\\Big_Data_Extension\\output\\category_revenue.csv"),
        [Delimiter = ",", Columns = 3, Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    PromoteHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    ChangeTypes = Table.TransformColumnTypes(PromoteHeaders, {
        {"category_name", type text}, {"revenue", Currency.Type}, {"quantity_sold", Int64.Type}
    })
in
    ChangeTypes

// Query: top_products
let
    Source = Csv.Document(
        File.Contents("C:\\Users\\admin\\Desktop\\BigData_SQL_Project\\Big_Data_Extension\\output\\top_products.csv"),
        [Delimiter = ",", Columns = 5, Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    PromoteHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    ChangeTypes = Table.TransformColumnTypes(PromoteHeaders, {
        {"product_id", Int64.Type}, {"product_name", type text}, {"category_name", type text},
        {"revenue", Currency.Type}, {"quantity_sold", Int64.Type}
    })
in
    ChangeTypes
