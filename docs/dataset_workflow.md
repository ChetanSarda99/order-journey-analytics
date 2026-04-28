# WWI Dataset Workflow (SQL Server)

This is the reproducible “how I got the data” section.

## What you need
- SQL Server (Express is fine)
- SSMS
- WideWorldImporters **OLTP** and **DW** `.bacpac` files

## High-level steps
1. Download WWI `.bacpac` files (OLTP + DW)
2. Import them into SQL Server (creates databases like `WideWorldImporters` and `WideWorldImportersDW`)
3. Create a separate analytics database (recommended): `wwi_analytics`
4. Create your curated schema + objects (`wwi.dim_stage`, `wwi.vw_order_event`, `wwi.vw_order_rollup`)
5. Connect Power BI to `wwi_analytics`

## Why a separate analytics DB?
- Keeps the vendor sample DB untouched
- Lets you version-control your objects
- Makes Power BI connections cleaner (`wwi_analytics.wwi.*`)

## SSMS checklist
- [x] I can see `WideWorldImporters` (OLTP) and `WideWorldImportersDW` (DW)
- [x] I can query `WideWorldImporters.Sales.Orders`
- [x] I can query `WideWorldImporters.Sales.Invoices`
- [x] I created `wwi_analytics` and `wwi` schema
- [x] I created `wwi.dim_stage`
- [x] I created `wwi.vw_order_event`
- [x] I created `wwi.vw_order_rollup` (one row per order, pre-calculated metrics)
