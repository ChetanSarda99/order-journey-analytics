# Data Dictionary

> Updated: 2026-02-15 (v2 SQL views). See `docs/data_info.md` for full reference with source lineage and audit notes.

## wwi.dim_stage (Table)
| Column | Type | Nullable | Description |
|---|---|---|---|
| stage_id | INT IDENTITY | NOT NULL | Surrogate key (PK) |
| stage_name | VARCHAR(100) | NOT NULL | Display name: Order Created, Picked, Invoiced, Delivered |
| stage_sort | INT | NOT NULL | Sort order: 10, 20, 30, 40 |
| stage_group | VARCHAR(50) | NULL | Pre-Ship (stages 1-3) or In-Transit (stage 4) |

## wwi.vw_order_event (View, v2) — DirectQuery
Event log: one row per order per stage milestone.

| Column | Type | Nullable | Description |
|---|---|---|---|
| OrderID | INT | NOT NULL | Order identifier (case ID) |
| EventTS | DATETIME2(0) | NOT NULL | Event timestamp (varies by stage) |
| Stage | VARCHAR(100) | NOT NULL | Stage name from dim_stage |
| StageSort | INT | NOT NULL | Numeric sort order |
| StageGroup | VARCHAR(50) | NULL | Pre-Ship or In-Transit |
| ExpectedDeliveryDate | DATE | NOT NULL | SLA target date |
| CustomerName | NVARCHAR | NULL | Customer name |
| CityName | NVARCHAR | NULL | Delivery city |
| StateProvinceName | NVARCHAR | NULL | State/Province |
| CountryName | NVARCHAR | NULL | Country |
| CustomerCategoryName | NVARCHAR | NULL | Customer's preferred delivery method (v2: was invoice method) |

## wwi.vw_order_rollup (View, v2) — Import (native SQL in M)
One row per order with stage timestamps + pre-calculated metrics.

| Column | Type | Nullable | Description |
|---|---|---|---|
| OrderID | INT | NOT NULL | Order identifier |
| CreatedDate | DATETIME2(0) | NOT NULL | Order Created timestamp |
| PickedDate | DATETIME2(0) | NULL | Picking completed |
| InvoicedDate | DATETIME2(0) | NULL | First invoice date |
| DeliveredDate | DATETIME2(0) | NULL | Confirmed delivery time |
| ExpectedDeliveryDate | DATE | NOT NULL | SLA target date |
| CycleTimeDays | DECIMAL(8,2) | NULL | End-to-end fractional days (v2: was INT) |
| CreatedToPickedDays | DECIMAL(8,2) | NULL | Fractional days Created to Picked (v2: was INT) |
| PickedToInvoicedDays | DECIMAL(8,2) | NULL | Fractional days Picked to Invoiced, floored at 0 (v2: fixed negative) |
| InvoicedToDeliveredDays | DECIMAL(8,2) | NULL | Fractional days Invoiced to Delivered (v2: was INT) |
| IsDelivered | INT | NOT NULL | 1 = delivered, 0 = open |
| IsOnTime | INT | **NULL** | 1 = on time, 0 = late, **NULL = not delivered** (v2: was 0 for open) |
| DaysFromExpected | INT | NULL | Days past expected (neg = early, pos = late) |
| FurthestStage | VARCHAR | NOT NULL | Last stage reached |
| OrderStatus | VARCHAR | NOT NULL | **NEW v2:** Delivered / In Progress / Open |
| CustomerName | NVARCHAR | NULL | Customer name |
| CityName | NVARCHAR | NULL | Delivery city |
| StateProvinceName | NVARCHAR | NULL | State/Province |
| CountryName | NVARCHAR | NULL | Country |
| CustomerCategoryName | NVARCHAR | NULL | Customer's preferred delivery method (v2: was invoice method) |

## dim_calendar (Calculated table, Import)
| Column | Type | Description |
|---|---|---|
| Date | DateTime | Calendar date (PK, Date Table) |
| year | Int64 | Calendar year |
| month_number | Int64 | Month 1-12 |
| month | String | Month name (sorted by month_number) |
| month_year | String | "Jan 2013" (sorted by month_year_sort) |
| month_year_sort | Int64 | YYYYMM for sorting |
| quarter | String | Q1-Q4 |
| quarter_number | Int64 | 1-4 |
| day_of_week | String | Day name (sorted by day_of_week_number) |
| day_of_week_number | Int64 | 1=Sun, 7=Sat |
| week_number | Int64 | ISO week number |
| is_weekend | Int64 | 1 if Sat/Sun |
| fiscal_year | Int64 | July-June fiscal year |
| fiscal_quarter | String | FQ1-FQ4 |

## StageTransition (DAX calculated table, disconnected)
| Column | Type | Description |
|---|---|---|
| Transition | String | "Created to Picked", "Picked to Invoiced", "Invoiced to Delivered" |
| SortOrder | Int64 | 1-3 (hidden) |
