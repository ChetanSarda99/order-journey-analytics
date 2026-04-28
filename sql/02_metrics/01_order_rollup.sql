/*
    wwi.vw_order_rollup  (v3 — 2026-02-15)
    One row per order with stage timestamps + pre-calculated metrics.

    CHANGES:
    v2: Fractional days, Picked-to-Invoiced floored at 0, IsOnTime NULL, OrderStatus.
    v3: Replaced DeliveryMethodName with CustomerCategoryName + BuyingGroupName.
        ALL WWI customers AND invoices use DeliveryMethodID=3 (Delivery Van),
        making that column useless for analysis. CustomerCategory provides real
        variety: Novelty Shop (459), Supermarket (58), Computer Store (51),
        Gift Store (48), Corporate (47).
    v3.1: Added DeliveryMethodName as alias of CustomerCategoryName for
        backward compatibility with PBI Desktop's cached DirectQuery schema.
*/

IF OBJECT_ID('wwi.vw_order_rollup', 'V') IS NOT NULL
    DROP VIEW wwi.vw_order_rollup;
GO

CREATE VIEW [wwi].[vw_order_rollup]
AS
WITH base AS (
    SELECT
        o.OrderID,
        o.CustomerID,
        o.OrderDate,
        o.ExpectedDeliveryDate,
        o.PickingCompletedWhen
    FROM WideWorldImporters.Sales.Orders o
)
, invoice AS (
    SELECT
        i.OrderID,
        MIN(i.InvoiceDate)             AS InvoiceDate,
        MIN(i.ConfirmedDeliveryTime)   AS ConfirmedDeliveryTime
    FROM WideWorldImporters.Sales.Invoices i
    WHERE i.OrderID IS NOT NULL
    GROUP BY i.OrderID
)
, cust AS (
    SELECT
        c.CustomerID,
        c.CustomerName,
        c.CustomerCategoryID,
        c.BuyingGroupID,
        ct.CityName,
        sp.StateProvinceName,
        co.CountryName
    FROM WideWorldImporters.Sales.Customers c
    LEFT JOIN WideWorldImporters.Application.Cities ct
        ON ct.CityID = c.DeliveryCityID
    LEFT JOIN WideWorldImporters.Application.StateProvinces sp
        ON sp.StateProvinceID = ct.StateProvinceID
    LEFT JOIN WideWorldImporters.Application.Countries co
        ON co.CountryID = sp.CountryID
)
, cc AS (
    SELECT CustomerCategoryID, CustomerCategoryName
    FROM WideWorldImporters.Sales.CustomerCategories
)
, bg AS (
    SELECT BuyingGroupID, BuyingGroupName
    FROM WideWorldImporters.Sales.BuyingGroups
)
SELECT
    b.OrderID,

    -- Stage timestamps
    CAST(b.OrderDate              AS DATETIME2(0)) AS CreatedDate,
    CAST(b.PickingCompletedWhen   AS DATETIME2(0)) AS PickedDate,
    CAST(inv.InvoiceDate          AS DATETIME2(0)) AS InvoicedDate,
    CAST(inv.ConfirmedDeliveryTime AS DATETIME2(0)) AS DeliveredDate,

    -- SLA target
    b.ExpectedDeliveryDate,

    -- End-to-end cycle time: fractional days (hours / 24)
    CAST(DATEDIFF(HOUR, b.OrderDate, inv.ConfirmedDeliveryTime) / 24.0 AS DECIMAL(8,2))
        AS CycleTimeDays,

    -- Stage-to-stage durations: fractional days (hours / 24), floor at 0
    CAST(
        CASE WHEN b.PickingCompletedWhen IS NOT NULL
             THEN DATEDIFF(HOUR, b.OrderDate, b.PickingCompletedWhen) / 24.0
             ELSE NULL END
        AS DECIMAL(8,2))
        AS CreatedToPickedDays,

    -- Picked to Invoiced: use 0 when InvoiceDate <= PickingCompletedWhen
    -- (WWI stores InvoiceDate as DATE which appears before the DATETIME of picking)
    CAST(
        CASE WHEN b.PickingCompletedWhen IS NOT NULL AND inv.InvoiceDate IS NOT NULL
             THEN IIF(
                DATEDIFF(HOUR, b.PickingCompletedWhen, inv.InvoiceDate) < 0,
                0,
                DATEDIFF(HOUR, b.PickingCompletedWhen, inv.InvoiceDate) / 24.0
             )
             ELSE NULL END
        AS DECIMAL(8,2))
        AS PickedToInvoicedDays,

    CAST(
        CASE WHEN inv.InvoiceDate IS NOT NULL AND inv.ConfirmedDeliveryTime IS NOT NULL
             THEN DATEDIFF(HOUR, inv.InvoiceDate, inv.ConfirmedDeliveryTime) / 24.0
             ELSE NULL END
        AS DECIMAL(8,2))
        AS InvoicedToDeliveredDays,

    -- Flags
    CASE WHEN inv.ConfirmedDeliveryTime IS NOT NULL THEN 1 ELSE 0 END AS IsDelivered,
    CASE
        WHEN inv.ConfirmedDeliveryTime IS NOT NULL
         AND CAST(inv.ConfirmedDeliveryTime AS DATE) <= b.ExpectedDeliveryDate
        THEN 1
        WHEN inv.ConfirmedDeliveryTime IS NULL THEN NULL  -- unknown, not "late"
        ELSE 0
    END AS IsOnTime,

    -- How many days past expected (negative = early, positive = late, NULL = not delivered)
    DATEDIFF(DAY, b.ExpectedDeliveryDate, inv.ConfirmedDeliveryTime) AS DaysFromExpected,

    -- Furthest stage reached
    CASE
        WHEN inv.ConfirmedDeliveryTime IS NOT NULL THEN 'Delivered'
        WHEN inv.InvoiceDate          IS NOT NULL THEN 'Invoiced'
        WHEN b.PickingCompletedWhen   IS NOT NULL THEN 'Picked'
        ELSE 'Order Created'
    END AS FurthestStage,

    -- Order status (simpler grouping)
    CASE
        WHEN inv.ConfirmedDeliveryTime IS NOT NULL THEN 'Delivered'
        WHEN inv.InvoiceDate IS NOT NULL OR b.PickingCompletedWhen IS NOT NULL THEN 'In Progress'
        ELSE 'Open'
    END AS OrderStatus,

    -- Dimension columns
    c.CustomerName,
    c.CityName,
    c.StateProvinceName,
    c.CountryName,

    -- Customer category (v3): gives real variety for analysis
    -- Replaces DeliveryMethodName which was always "Delivery Van" for all WWI customers
    cc.CustomerCategoryName,
    cc.CustomerCategoryName AS DeliveryMethodName,

    -- Buying group (v3): Tailspin Toys, Wingtip Toys, or NULL
    bg.BuyingGroupName

FROM base b
LEFT JOIN invoice inv ON inv.OrderID = b.OrderID
LEFT JOIN cust c      ON c.CustomerID = b.CustomerID
LEFT JOIN cc          ON cc.CustomerCategoryID = c.CustomerCategoryID
LEFT JOIN bg          ON bg.BuyingGroupID = c.BuyingGroupID;
GO
