# Business Rules (v2, updated 2026-02-15)

## Stage Mapping
1) Order Created  -> `Orders.OrderDate` (always present)
2) Picked         -> `Orders.PickingCompletedWhen` (nullable)
3) Invoiced       -> `MIN(Invoices.InvoiceDate)` (nullable)
4) Delivered      -> `MIN(Invoices.ConfirmedDeliveryTime)` (nullable)

## Core Rules
- One row per OrderID per stage (at most) in event log
- NULL milestone = stage omitted (no fake dates)
- Stage ordering enforced by `wwi.dim_stage.stage_sort` (10, 20, 30, 40)
- **Delivery method:** Customer's preferred method (`Sales.Customers.DeliveryMethodID`), NOT invoice-level method (which is always "Delivery Van" in WWI)
- Multiple invoices per order: use `MIN()` timestamps

## SLA Rules
- **On-time:** `DeliveredDate <= ExpectedDeliveryDate` (date comparison)
- **Late:** `DeliveredDate > ExpectedDeliveryDate`
- **Unknown:** `DeliveredDate IS NULL` (order not yet delivered) -> `IsOnTime = NULL`
- **SLA Breach %:** `1 - On-Time %` (only among delivered orders)

## Duration Calculations
- **Cycle time:** `DATEDIFF(HOUR, OrderDate, ConfirmedDeliveryTime) / 24.0` (fractional days)
- **Stage durations:** Same HOUR/24.0 pattern for each stage transition
- **Picked-to-Invoiced:** Floored at 0 (InvoiceDate is DATE-only midnight, PickingCompletedWhen is DATETIME with time, so raw difference can be negative)

## Order Status
- **Delivered:** ConfirmedDeliveryTime IS NOT NULL
- **In Progress:** Has PickingCompletedWhen OR InvoiceDate, but not delivered
- **Open:** Only has OrderDate (nothing else completed)

## Known Data Characteristics
- 93.6% of delivered orders have cycle time = 1 day (genuine WWI pattern)
- ~3,085 orders stuck at "Order Created" (genuine open/incomplete orders)
- All WWI invoices use DeliveryMethodID=3 (Delivery Van) — this is why we use customer method instead
- InvoiceDate has no time component (midnight), while PickingCompletedWhen has time (typically noon)
