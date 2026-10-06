"""Generate reproducible CSV input only; it does not modify PostgreSQL.

Example: python generate_sales_data.py --customers 100000 --products 10000 --orders 1000000
The historical project dataset is already loaded, so do not run this unintentionally.
"""

import argparse
import csv
import random
from datetime import datetime, timedelta
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--customers", type=int, default=100_000)
    parser.add_argument("--products", type=int, default=10_000)
    parser.add_argument("--orders", type=int, default=1_000_000)
    parser.add_argument("--seed", type=int, default=2024)
    parser.add_argument("--output", type=Path, default=Path("generated_sample"))
    args = parser.parse_args()
    random.seed(args.seed)
    args.output.mkdir(parents=True, exist_ok=True)
    categories = ["Laptop", "Dien thoai", "Dong ho", "Phu kien", "Thoi trang"]

    with (args.output / "customers.csv").open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f); writer.writerow(["customer_id", "name", "email", "city"])
        for i in range(1, args.customers + 1):
            writer.writerow([i, f"Customer {i}", f"customer{i}@example.com", f"City {i % 20 + 1}"])
    with (args.output / "products.csv").open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f); writer.writerow(["product_id", "category_id", "product_name", "price", "stock"])
        for i in range(1, args.products + 1):
            writer.writerow([i, (i - 1) % len(categories) + 1, f"Product {i}", random.randint(100_000, 30_000_000), random.randint(10, 1000)])
    start = datetime(2024, 1, 1)
    with (args.output / "orders.csv").open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f); writer.writerow(["order_id", "customer_id", "order_date", "status", "total_amount"])
        for i in range(1, args.orders + 1):
            writer.writerow([i, random.randint(1, args.customers), start + timedelta(days=random.randint(0, 729)), "Completed", 0])


if __name__ == "__main__":
    main()
