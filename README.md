# 🍕 Food Delivery Data Warehouse & BI System

> **Module:** IT3021 — Data Warehousing and Business Intelligence  
> **University:** SLIIT — BSc (Hons) in IT, Specializing in Data Science  
> **Year:** 3, Semester 1, 2025

---

## 📌 Project Overview

Designed and implemented a complete **Data Warehouse and Business Intelligence solution** for a Foodpanda-style food delivery platform. The project simulates a real enterprise BI pipeline — from raw operational data all the way to an analytics-ready data warehouse connected to Power BI.

---

## 🏗️ Architecture

```
Source Systems → Staging Area → ETL (SSIS) → Data Warehouse → Power BI / SSAS
```

| Layer | Component | Description |
|-------|-----------|-------------|
| Source | FoodpandaSourceDB (SQL Server) | Normalized OLTP database with 6 tables |
| Source | CustomerProfileExtra.csv | External flat file with additional customer data |
| Staging | Foodpanda_Staging | Temporary area for data cleaning and preparation |
| ETL | SSIS (3 Packages) | Extract, Transform, Load pipelines |
| Warehouse | Foodpanda_DW | Star schema dimensional model |
| BI Layer | Power BI / SSAS | Dashboards and analytical reporting |

---

## ⭐ Dimensional Model (Star Schema)

**Fact Table:**
- `FactOrders` — Order-level data: quantity, price, sales amount, rating, transaction time

**Dimension Tables:**
| Table | Description |
|-------|-------------|
| DimCustomer | Customer demographics with SCD Type 2 for history tracking |
| DimRestaurant | Restaurant name and location |
| DimDish | Dish name, category, price |
| DimPaymentDelivery | Payment method and delivery status combinations |
| DimDate | Full date hierarchy: day → week → month → quarter → year |

---

## ⚙️ ETL Development (SSIS)

### Package 1: Foodpanda_Load_Staging.dtsx
Extracts raw data from both source systems into staging tables.
- Truncates staging tables (clean slate each run)
- Loads 6 OLTP tables from SQL Server
- Loads CustomerProfileExtra.csv via Flat File Connection Manager

### Package 2: Foodpanda_Load_DW.dtsx
Transforms and loads data into the dimensional model.
- **SCD Type 2** on DimCustomer — tracks city, loyalty points, and churn status changes over time
- Lookup transformations for surrogate key generation
- Derived Column transformation calculates `SalesAmount = Quantity × UnitPrice`
- Loads dimensions first, then FactOrders (referential integrity)

### Package 3: UpdateFactOrders.dtsx
Updates the accumulating fact table with completion data.
- Reads completion timestamps from external CSV
- Updates `accm_txn_complete_time` in FactOrders
- Calculates `txn_process_time_hours` using DATEDIFF

---

## 🔑 Key Concepts Demonstrated

- ✅ Star Schema dimensional modeling
- ✅ Slowly Changing Dimension Type 2 (SCD2)
- ✅ Multi-source ETL (SQL Server + CSV)
- ✅ Surrogate key generation with Lookup transformations
- ✅ Accumulating snapshot fact table
- ✅ Derived business metrics (SalesAmount, processing time)
- ✅ Data staging and transformation best practices

---

## 🛠️ Tech Stack

`SQL Server 2019` `SSIS (SQL Server Integration Services)` `SQL Server Management Studio`  
`Visual Studio 2022` `Power BI Desktop` `MySQL` `CSV (Flat File Integration)`

---

## 📂 Repository Contents

| File | Description |
|------|-------------|
| `Assignment_Report.pdf` | Full project documentation with diagrams |
| `screenshots/` | SSIS package screenshots and data flow diagrams |
| `ER_Diagram.png` | Entity-Relationship diagram of source database |
| `Star_Schema.png` | Dimensional model diagram |

---

## 📧 Contact

**Achintha Kaushalya** — achirathnayaka12903@gmail.com
