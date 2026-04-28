# Data Info — Complete Reference

> All SQL objects, Power BI tables, columns, types, descriptions, source lineage, DAX measures, and relationships in one place.
> Updated: 2026-02-15 (v2 SQL views)

---

## SQL Server Objects

**Server:** `DESKTOP-TNE86KL\SQLEXPRESS`
**Database:** `wwi_analytics`
**Schema:** `wwi`
**Source DB:** `WideWorldImporters` (cross-database queries)

---

### 1. `wwi` Schema

```sql
-- sql/00_setup/00_create_schema.sql
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'wwi')
    EXEC('CREATE SCHEMA wwi');
```

---

### 2. `wwi.dim_stage` (Table)

Stage dimension for the 4-stage order lifecycle. Loaded once, never changes.

**File:** `sql/00_setup/01_dim_stage.sql`

| Column | SQL Type | Nullable | Description |
|---|---|---|---|
| `stage_id` | `INT IDENTITY(1,1)` | NOT NULL | Surrogate key (PK) |
| `stage_name` | `VARCHAR(100)` | NOT NULL | Display name: Order Created, Picked, Invoiced, Delivered |
| `stage_sort` | `INT` | NOT NULL | Sort order: 10, 20, 30, 40 |
| `stage_group` | `VARCHAR(50)` | NULL | Grouping: Pre-Ship (stages 1-3), In-Transit (stage 4) |

**Seed data:**

| stage_id | stage_name | stage_sort | stage_group |
|---|---|---|---|
| 1 | Order Created | 10 | Pre-Ship |
| 2 | Picked | 20 | Pre-Ship |
| 3 | Invoiced | 30 | Pre-Ship |
| 4 | Delivered | 40 | In-Transit |

---

### 3. `wwi.vw_order_event` (View) — v2

Event log: one row per order per stage milestone. Used for timeline/journey visuals and event-level analysis.

**File:** `sql/01_views/01_vw_order_event.sql`
**Row count:** ~279,000 (4 stages x ~70K orders, minus NULLs)
**Power BI mode:** DirectQuery

**Source tables:**
- `WideWorldImporters.Sales.Orders` — OrderDate, PickingCompletedWhen
- `WideWorldImporters.Sales.Invoices` — InvoiceDate, ConfirmedDeliveryTime (grouped by OrderID)
- `WideWorldImporters.Sales.Customers` — CustomerName, DeliveryMethodID (customer's default)
- `WideWorldImporters.Application.Cities` — CityName
- `WideWorldImporters.Application.StateProvinces` — StateProvinceName
- `WideWorldImporters.Application.Countries` — CountryName
- `WideWorldImporters.Application.DeliveryMethods` — CustomerCategoryName
- `wwi.dim_stage` — stage_name, stage_sort, stage_group

| Column | SQL Type | Nullable | Description | Source |
|---|---|---|---|---|
| `OrderID` | `INT` | NOT NULL | Order identifier (case ID) | `Sales.Orders.OrderID` |
| `EventTS` | `DATETIME2(0)` | NOT NULL | Event timestamp for this stage | Varies by stage (see below) |
| `Stage` | `VARCHAR(100)` | NOT NULL | Stage name (from dim_stage) | `wwi.dim_stage.stage_name` |
| `StageSort` | `INT` | NOT NULL | Numeric sort order | `wwi.dim_stage.stage_sort` |
| `StageGroup` | `VARCHAR(50)` | NULL | Pre-Ship or In-Transit | `wwi.dim_stage.stage_group` |
| `ExpectedDeliveryDate` | `DATE` | NOT NULL | SLA target delivery date | `Sales.Orders.ExpectedDeliveryDate` |
| `CustomerName` | `NVARCHAR` | NULL | Customer name | `Sales.Customers.CustomerName` |
| `CityName` | `NVARCHAR` | NULL | Delivery city | `Application.Cities.CityName` |
| `StateProvinceName` | `NVARCHAR` | NULL | Delivery state/province | `Application.StateProvinces` |
| `CountryName` | `NVARCHAR` | NULL | Delivery country | `Application.Countries` |
| `CustomerCategoryName` | `NVARCHAR` | NULL | Customer's preferred delivery method | `Customers.DeliveryMethodID` -> `DeliveryMethods` |

**EventTS source by stage:**

| Stage | EventTS source | Filter |
|---|---|---|
| Order Created | `Orders.OrderDate` | All orders (always present) |
| Picked | `Orders.PickingCompletedWhen` | WHERE PickingCompletedWhen IS NOT NULL |
| Invoiced | `MIN(Invoices.InvoiceDate)` | WHERE InvoiceDate IS NOT NULL |
| Delivered | `MIN(Invoices.ConfirmedDeliveryTime)` | WHERE ConfirmedDeliveryTime IS NOT NULL |

**v2 change:** CustomerCategoryName now uses customer's default method (`Sales.Customers.DeliveryMethodID`) instead of invoice-level method. All WWI invoices use DeliveryMethodID=3 (Delivery Van), so invoice-level method is useless for analysis. Customer preference provides variety: Post, Courier, Delivery Van, Customer Collect, etc.

---

### 4. `wwi.vw_order_rollup` (View) — v2

One row per order with stage timestamps + pre-calculated metrics. Used for KPIs, aggregations, and slicer-driven analysis.

**File:** `sql/02_metrics/01_order_rollup.sql`
**Row count:** ~73,595 (one per order)
**Power BI mode:** Import (native SQL query in M expression)

**Source tables:** Same as vw_order_event (Orders, Invoices, Customers, Cities, StateProvinces, Countries, DeliveryMethods)

| Column | SQL Type | Nullable | Description | Source / Calculation |
|---|---|---|---|---|
| `OrderID` | `INT` | NOT NULL | Order identifier | `Sales.Orders.OrderID` |
| `CreatedDate` | `DATETIME2(0)` | NOT NULL | Order Created timestamp | `CAST(Orders.OrderDate AS DATETIME2(0))` |
| `PickedDate` | `DATETIME2(0)` | NULL | Picking completed | `CAST(Orders.PickingCompletedWhen AS DATETIME2(0))` |
| `InvoicedDate` | `DATETIME2(0)` | NULL | First invoice date | `CAST(MIN(Invoices.InvoiceDate) AS DATETIME2(0))` |
| `DeliveredDate` | `DATETIME2(0)` | NULL | Confirmed delivery time | `CAST(MIN(Invoices.ConfirmedDeliveryTime) AS DATETIME2(0))` |
| `ExpectedDeliveryDate` | `DATE` | NOT NULL | SLA target date | `Orders.ExpectedDeliveryDate` |
| `CycleTimeDays` | `DECIMAL(8,2)` | NULL | End-to-end days (Created to Delivered) | `DATEDIFF(HOUR, OrderDate, ConfirmedDeliveryTime) / 24.0` |
| `CreatedToPickedDays` | `DECIMAL(8,2)` | NULL | Days from Created to Picked | `DATEDIFF(HOUR, OrderDate, PickingCompletedWhen) / 24.0` |
| `PickedToInvoicedDays` | `DECIMAL(8,2)` | NULL | Days from Picked to Invoiced (floored at 0) | `IIF(hours < 0, 0, hours / 24.0)` |
| `InvoicedToDeliveredDays` | `DECIMAL(8,2)` | NULL | Days from Invoiced to Delivered | `DATEDIFF(HOUR, InvoiceDate, ConfirmedDeliveryTime) / 24.0` |
| `IsDelivered` | `INT` | NOT NULL | 1 = delivered, 0 = open | `ConfirmedDeliveryTime IS NOT NULL` |
| `IsOnTime` | `INT` | NULL | 1 = on time, 0 = late, NULL = not delivered | `DeliveredDate <= ExpectedDate` |
| `DaysFromExpected` | `INT` | NULL | Days past expected (negative = early, positive = late) | `DATEDIFF(DAY, ExpectedDate, DeliveredDate)` |
| `FurthestStage` | `VARCHAR` | NOT NULL | Last stage reached | Delivered > Invoiced > Picked > Order Created |
| `OrderStatus` | `VARCHAR` | NOT NULL | Simplified status grouping | Delivered / In Progress / Open |
| `CustomerName` | `NVARCHAR` | NULL | Customer name | `Sales.Customers` |
| `CityName` | `NVARCHAR` | NULL | Delivery city | `Application.Cities` |
| `StateProvinceName` | `NVARCHAR` | NULL | Delivery state/province | `Application.StateProvinces` |
| `CountryName` | `NVARCHAR` | NULL | Delivery country | `Application.Countries` |
| `CustomerCategoryName` | `NVARCHAR` | NULL | Customer's preferred delivery method | `Customers.DeliveryMethodID` -> `DeliveryMethods` |

**v2 changes:**
- `CycleTimeDays` and stage durations now `DECIMAL(8,2)` (was INT). Uses `DATEDIFF(HOUR)/24.0` for fractional days.
- `PickedToInvoicedDays` floored at 0 to fix negative durations (InvoiceDate is DATE-only midnight, PickingCompletedWhen is DATETIME noon).
- `IsOnTime` is now NULL for undelivered orders (was 0, which incorrectly counted open orders as "late").
- `CustomerCategoryName` uses customer's default method (variety) instead of invoice method (always Delivery Van).
- Added `OrderStatus` column: Delivered / In Progress / Open.

---

## Power BI Semantic Model

### Tables

| Table | Mode | Source | Rows (approx) | Purpose |
|---|---|---|---|---|
| `wwi vw_order_event` | DirectQuery | `wwi.vw_order_event` | ~279K | Event log for journey timelines |
| `wwi vw_order_rollup` | Import | Native SQL query (M) | ~73K | KPIs, aggregations, slicer analysis |
| `wwi dim_stage` | Import | `wwi.dim_stage` | 4 | Stage dimension |
| `dim_calendar` | Calculated (Import) | DAX date table | ~3,650 | Date dimension with fiscal columns |
| `StageTransition` | Calculated (DAX) | DAX table expression | 3 | Disconnected lookup for stage duration charts |

### Relationships

| From | To | Cardinality | Cross-filter | Active |
|---|---|---|---|---|
| `wwi vw_order_event[Stage]` | `wwi dim_stage[stage_name]` | Many:1 | Single | Yes |
| `wwi vw_order_event[EventTS]` | `dim_calendar[Date]` | Many:1 | Single | Yes |
| `wwi vw_order_rollup[CreatedDate]` | `dim_calendar[Date]` | Many:1 | Single | Yes |

**Note:** `StageTransition` has no relationships (disconnected table used in SWITCH measures).

### dim_calendar Columns

| Column | Type | Description |
|---|---|---|
| `Date` | DateTime | Calendar date (PK) |
| `year` | Int64 | Calendar year (e.g. 2013) |
| `month_number` | Int64 | Month number 1-12 |
| `month` | String | Month name (January, February...) |
| `month_year` | String | "Jan 2013" format |
| `month_year_sort` | Int64 | YYYYMM for sorting |
| `quarter` | String | "Q1", "Q2", "Q3", "Q4" |
| `quarter_number` | Int64 | 1-4 |
| `day_of_week` | String | Day name (Monday, Tuesday...) |
| `day_of_week_number` | Int64 | 1=Sunday, 7=Saturday |
| `week_number` | Int64 | ISO week number |
| `is_weekend` | Int64 | 1 if Sat/Sun |
| `fiscal_year` | Int64 | July-June fiscal year |
| `fiscal_quarter` | String | "FQ1"-"FQ4" |

### StageTransition Columns

| Column | Type | Description |
|---|---|---|
| `Transition` | String | Label: "Created to Picked", "Picked to Invoiced", "Invoiced to Delivered" |
| `SortOrder` | Int64 | 1, 2, 3 (hidden) |

---

## DAX Measures (33 total)

All measures defined on `wwi vw_order_rollup` unless noted. Organized by display folder.

### Core Counts

| Measure | DAX Logic | Format |
|---|---|---|
| `Total Orders` | `DISTINCTCOUNT(rollup[OrderID])` | #,0 |
| `Delivered Orders` | `CALCULATE([Total Orders], rollup[IsDelivered] = 1)` | #,0 |
| `Open Orders` | `[Total Orders] - [Delivered Orders]` | #,0 |
| `Delivered %` | `DIVIDE([Delivered Orders], [Total Orders])` | 0.0% |

### SLA

| Measure | DAX Logic | Format |
|---|---|---|
| `On-Time Orders` | `CALCULATE([Delivered Orders], rollup[IsOnTime] = 1)` | #,0 |
| `Late Orders` | `[Delivered Orders] - [On-Time Orders]` | #,0 |
| `On-Time %` | `DIVIDE([On-Time Orders], [Delivered Orders])` | 0.0% |
| `SLA Breach %` | `1 - [On-Time %]` | 0.0% |
| `Cumulative Late %` | Running total of late / total late (Pareto) | 0.0% |
| `Scatter Color` | `"#E07A5F"` if breach > 20%, else `"#2E8B8B"` | text |

### Cycle Time

| Measure | DAX Logic | Format |
|---|---|---|
| `Median Cycle Days` | `MEDIAN(rollup[CycleTimeDays])` | 0.0 |
| `P90 Cycle Days` | `PERCENTILE.INC(rollup[CycleTimeDays], 0.90)` | 0.0 |
| `Avg Cycle Days` | `AVERAGE(rollup[CycleTimeDays])` | 0.0 |

### Stage Duration

| Measure | DAX Logic | Format |
|---|---|---|
| `Median Created-to-Picked` | `MEDIAN(rollup[CreatedToPickedDays])` | 0.0 |
| `Median Picked-to-Invoiced` | `MEDIAN(rollup[PickedToInvoicedDays])` | 0.0 |
| `Median Invoiced-to-Delivered` | `MEDIAN(rollup[InvoicedToDeliveredDays])` | 0.0 |
| `P90 Created-to-Picked` | `PERCENTILE.INC(rollup[CreatedToPickedDays], 0.90)` | 0.0 |
| `P90 Picked-to-Invoiced` | `PERCENTILE.INC(rollup[PickedToInvoicedDays], 0.90)` | 0.0 |
| `P90 Invoiced-to-Delivered` | `PERCENTILE.INC(rollup[InvoicedToDeliveredDays], 0.90)` | 0.0 |
| `Median Stage Duration` | `SWITCH` on StageTransition[Transition] -> above medians | 0.0 |
| `P90 Stage Duration` | `SWITCH` on StageTransition[Transition] -> above P90s | 0.0 |

### Period Comparison

| Measure | DAX Logic | Format |
|---|---|---|
| `Total Orders PM` | `CALCULATE([Total Orders], DATEADD(dim_calendar[Date], -1, MONTH))` | #,0 |
| `On-Time % PM` | `CALCULATE([On-Time %], DATEADD(dim_calendar[Date], -1, MONTH))` | 0.0% |
| `Median Cycle PM` | `CALCULATE([Median Cycle Days], DATEADD(dim_calendar[Date], -1, MONTH))` | 0.0 |
| `Orders MoM %` | `DIVIDE([Total Orders] - [Total Orders PM], [Total Orders PM])` | +0.0% |
| `On-Time MoM pp` | `[On-Time %] - [On-Time % PM]` (percentage points) | +0.0 pp |
| `Cycle Time MoM` | `[Median Cycle Days] - [Median Cycle PM]` | +0.0 |
| `Orders MoM Label` | Arrow + formatted MoM % delta | text |
| `OnTime MoM Label` | Arrow + formatted MoM pp delta | text |

### Journey (on `wwi vw_order_event`)

| Measure | DAX Logic | Format |
|---|---|---|
| `Event Count` | `COUNTROWS('wwi vw_order_event')` | #,0 |
| `Selected Order Stage` | `SELECTEDVALUE` of FurthestStage | text |
| `Selected Order Method` | `SELECTEDVALUE` of CustomerCategoryName | text |
| `Selected Order OnTime` | "Yes"/"No" based on IsOnTime | text |

---

## WWI Source Table Reference

These are the upstream tables from `WideWorldImporters` database used by our views.

### Sales.Orders

| Column Used | Type | Description |
|---|---|---|
| `OrderID` | `INT` | Primary key |
| `CustomerID` | `INT` | FK to Sales.Customers |
| `OrderDate` | `DATE` | When the order was placed |
| `ExpectedDeliveryDate` | `DATE` | SLA target delivery date |
| `PickingCompletedWhen` | `DATETIME2(7)` | When warehouse picking was done (nullable) |

### Sales.Invoices

| Column Used | Type | Description |
|---|---|---|
| `InvoiceID` | `INT` | Primary key |
| `OrderID` | `INT` | FK to Sales.Orders (nullable for non-order invoices) |
| `InvoiceDate` | `DATE` | Invoice creation date (DATE only, no time component) |
| `ConfirmedDeliveryTime` | `DATETIME2(7)` | Actual delivery confirmation (nullable) |
| `DeliveryMethodID` | `INT` | FK to DeliveryMethods (always 3 = Delivery Van in WWI) |

### Sales.Customers

| Column Used | Type | Description |
|---|---|---|
| `CustomerID` | `INT` | Primary key |
| `CustomerName` | `NVARCHAR(100)` | Customer display name |
| `DeliveryMethodID` | `INT` | Customer's preferred delivery method (provides variety) |
| `DeliveryCityID` | `INT` | FK to Application.Cities |

### Application.DeliveryMethods

| DeliveryMethodID | CustomerCategoryName | Notes |
|---|---|---|
| 1 | Post | Used by some customers |
| 2 | Courier | Used by some customers |
| 3 | Delivery Van | Default for invoices + some customers |
| 4-10 | Various | Air Freight, Refrigerated, Customer Collect, etc. |

### Application.Cities / StateProvinces / Countries

Standard geographic hierarchy joined through CityID -> StateProvinceID -> CountryID.

---

## Data Quality Notes (from audit, 2026-02-15)

| Finding | Detail | Resolution |
|---|---|---|
| Single invoice delivery method | All 70,510 invoices use DeliveryMethodID=3 (Delivery Van) | v2: Use customer's default method instead |
| Negative Picked-to-Invoiced | InvoiceDate (DATE, midnight) < PickingCompletedWhen (DATETIME, noon) = negative hours | v2: IIF to floor at 0 |
| Stage durations = 0 | DATEDIFF(DAY) rounded same-day events to 0 | v2: DATEDIFF(HOUR)/24.0 for fractional days |
| 93.6% cycle time = 1 day | Genuine data pattern (WWI orders processed quickly) | No fix needed, data is correct |
| 3,085 orders at "Order Created" | Genuine open/incomplete orders (no picking or invoice) | OrderStatus = "Open" |
| 3,085 NULL delivery methods | Orders without customers or with NULL DeliveryMethodID | LEFT JOIN, acceptable NULLs |
| IsOnTime = 0 for open orders | Unfair to count undelivered as "late" | v2: IsOnTime = NULL for undelivered |

---

## File Index

| File | Purpose |
|---|---|
| `sql/00_setup/00_create_schema.sql` | Create `wwi` schema |
| `sql/00_setup/01_dim_stage.sql` | Create + seed `wwi.dim_stage` table |
| `sql/01_views/01_vw_order_event.sql` | Event log view (v2) |
| `sql/02_metrics/01_order_rollup.sql` | Order rollup view (v2) |
| `sql/03_audit/01_data_audit.sql` | 10 data quality audit queries |
| `docs/data_dictionary.md` | Column-level reference (brief) |
| `docs/metric_definitions.md` | DAX measure definitions |
| `docs/business_rules.md` | Stage mapping + data handling rules |
| `docs/data_info.md` | This file (comprehensive reference) |
| `docs/page_visual_specs.md` | PBIR visual layout specifications |
| `docs/report_storyboard.md` | Report page narrative design |
