# Inventory-BI-and-Data-Analytics
A robust relational database blueprint built in SSMS featuring advanced transactional automation and data-driven business intelligence analytics.

# Enterprise Inventory Management & Business Intelligence System

## 📌 Project Overview
This project showcases the design, implementation, and analytical querying of a relational database for a mid-sized retail warehouse system managing **300 unique product lines** and over **500 rolling stock transactions**. 

The goal of this portfolio piece is to demonstrate advanced database architecture using Microsoft SQL Server (T-SQL) via SQL Server Management Studio (SSMS). It highlights complex multi-table relationships, automated transaction triggers, and data-driven business intelligence computations (Window functions, CTEs, and aggregations).


## 🛠️ 1. Database Architecture & Schema
The system relies on a highly normalized 4-table relational structure designed to maintain strict data integrity through the use of Primary Keys, Foreign Keys, `UNIQUE` constraints, and conditional `CHECK` constraints (e.g., preventing stock balances from dropping below zero).

* **Categories Table:** Defines product classifications.
* **Suppliers Table:** Tracks vendor contact and performance data.
* **Products Table:** The core inventory ledger detailing unit pricing, real-time stock quantities, and automated reorder thresholds.
* **StockTransactions Table:** A historical ledger tracking individual `IN` (restock) and `OUT` (sales/shrinkage) item movements.

The complete script to generate this structural blueprint can be found in the **`01_schema.sql`** file in this repository.

---

## ⚙️ 2. Real-Time Automation (Database Triggers)
To ensure the database handles high-volume inventory adjustments without lag or manual intervention, an `AFTER INSERT` database trigger (`trg_UpdateStock`) was implemented on the transaction ledger.

Whenever a sale or restock is logged, the database automatically performs transactional math to update the live product warehouse balance in real time:

$$Current\ Stock = Existing\ Stock \pm Transaction\ Quantity$$

This guarantees that front-end applications or warehouse managers always see accurate stock numbers without needing to manually run manual summation loops.

---

## 📊 3. Advanced Business Computations & Intelligence
The primary value of this database lies in its ability to extract actionable operational and financial metrics. Below are the key data computations executed within SSMS, showcasing advanced SQL fluency.

### A. Multi-Table Master Ledger Sheet
**Business Use:** Generates a unified financial evaluation ledger, calculating absolute asset valuations and flags live reorder requirements dynamically.
* **SQL Elements Used:** 3-Way `INNER JOIN`, Derived Column Math, Conditional `CASE WHEN` logic.

```sql
SELECT 
    p.product_id,
    p.product_name,
    c.category_name,
    s.supplier_name,
    p.price,
    p.stock_quantity,
    (p.price * p.stock_quantity) AS inventory_value,
    CASE 
        WHEN p.stock_quantity = 0 THEN 'OUT OF STOCK'
        WHEN p.stock_quantity <= p.reorder_level THEN 'REORDER IMMEDIATELY'
        ELSE 'HEALTHY STOCK'
    END AS stock_status
FROM Products p
INNER JOIN Categories c ON p.category_id = c.category_id
INNER JOIN Suppliers s ON p.supplier_id = s.supplier_id
ORDER BY inventory_value DESC;
