# Metric definitions

## Core timestamps
- Order Created: Orders.OrderDate
- Picked: Orders.PickingCompletedWhen
- Invoiced: Invoices.InvoiceDate
- Delivered: Invoices.ConfirmedDeliveryTime

## DAX Measures (33 total, on wwi vw_order_rollup unless noted)

### Core Counts
| Measure | Logic | Format |
|---|---|---|
| Total Orders | DISTINCTCOUNT of OrderID | #,0 |
| Delivered Orders | Total Orders where IsDelivered = 1 | #,0 |
| Open Orders | Total Orders - Delivered Orders | #,0 |
| Delivered % | Delivered / Total (DIVIDE) | 0.0% |

### SLA
| Measure | Logic | Format |
|---|---|---|
| On-Time Orders | Delivered Orders where IsOnTime = 1 | #,0 |
| Late Orders | Delivered - On-Time | #,0 |
| On-Time % | On-Time / Delivered (DIVIDE) | 0.0% |
| SLA Breach % | 1 - On-Time % | 0.0% |
| Cumulative Late % | Running total of late orders / total late (Pareto) | 0.0% |
| Scatter Color | "#E07A5F" if breach > 20%, else "#2E8B8B" | text |

### Cycle Time
| Measure | Logic | Format |
|---|---|---|
| Median Cycle Days | MEDIAN of CycleTimeDays | 0.0 |
| P90 Cycle Days | PERCENTILE.INC at 0.90 | 0.0 |
| Avg Cycle Days | AVERAGE of CycleTimeDays | 0.0 |

### Stage Duration
| Measure | Logic | Format |
|---|---|---|
| Median Created-to-Picked | MEDIAN of CreatedToPickedDays | 0.0 |
| Median Picked-to-Invoiced | MEDIAN of PickedToInvoicedDays | 0.0 |
| Median Invoiced-to-Delivered | MEDIAN of InvoicedToDeliveredDays | 0.0 |
| P90 Created-to-Picked | PERCENTILE.INC at 0.90 | 0.0 |
| P90 Picked-to-Invoiced | PERCENTILE.INC at 0.90 | 0.0 |
| P90 Invoiced-to-Delivered | PERCENTILE.INC at 0.90 | 0.0 |
| Median Stage Duration | SWITCH on StageTransition[Transition] → above medians | 0.0 |
| P90 Stage Duration | SWITCH on StageTransition[Transition] → above P90s | 0.0 |

### Period Comparison
| Measure | Logic | Format |
|---|---|---|
| Total Orders PM | DATEADD -1 month (hidden) | #,0 |
| On-Time % PM | DATEADD -1 month (hidden) | 0.0% |
| Median Cycle PM | DATEADD -1 month (hidden) | 0.0 |
| Orders MoM % | (Current - Prior) / Prior | +0.0% |
| On-Time MoM pp | Current - Prior (percentage points) | +0.0 pp |
| Cycle Time MoM | Current - Prior (days) | +0.0 |
| Orders MoM Label | Arrow + formatted MoM % delta for KPI card | text |
| OnTime MoM Label | Arrow + formatted MoM pp delta for KPI card | text |

### Journey (on wwi vw_order_event)
| Measure | Logic | Format |
|---|---|---|
| Event Count | COUNTROWS of event log | #,0 |
| Selected Order Stage | SELECTEDVALUE of FurthestStage (single-order context) | text |
| Selected Order Method | SELECTEDVALUE of CustomerCategoryName (single-order context) | text |
| Selected Order OnTime | "Yes"/"No" based on IsOnTime (single-order context) | text |

## Business Rules (v2)
- On-time: DeliveredDate <= ExpectedDeliveryDate (IsOnTime = 1)
- Late: DeliveredDate > ExpectedDeliveryDate (IsOnTime = 0)
- Not delivered: IsOnTime = NULL (excluded from On-Time % denominator)
- SLA breach: 1 - On-Time % (among delivered orders only)
- Cycle time: DATEDIFF(HOUR, OrderDate, ConfirmedDeliveryTime) / 24.0 (fractional days)
- Stage durations: DATEDIFF(HOUR) / 24.0 between adjacent timestamps (Picked→Invoiced floored at 0)
- Open order: ConfirmedDeliveryTime IS NULL
- Delivery method: Customer's preferred method (not invoice-level, which is always Delivery Van)
