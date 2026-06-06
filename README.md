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

### Database Entity-Relationship Map
