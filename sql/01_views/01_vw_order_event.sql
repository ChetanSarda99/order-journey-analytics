/*
    wwi.vw_order_event  (v3 — 2026-02-15)
    Event log: one row per order per stage milestone.

    CHANGES:
    v2: Customer delivery method (still only Delivery Van for all customers).
    v3: Replaced DeliveryMethodName with CustomerCategoryName (5 categories
        with real variety: Novelty Shop, Supermarket, Computer Store, etc.)
        Added BuyingGroupName (Tailspin Toys, Wingtip Toys, or NULL).
    v3.1: Added DeliveryMethodName as alias of CustomerCategoryName for
        backward compatibility with PBI Desktop's cached DirectQuery schema.
*/

IF OBJECT_ID('wwi.vw_order_event', 'V') IS NOT NULL
    DROP VIEW wwi.vw_order_event;
GO

CREATE VIEW [wwi].[vw_order_event]
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
        MIN(i.InvoiceDate)            AS InvoiceDate,
        MIN(i.ConfirmedDeliveryTime)  AS ConfirmedDeliveryTime
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
-- Stage 1: Order Created (every order has this)
SELECT
    b.OrderID,
    CAST(b.OrderDate AS DATETIME2(0)) AS EventTS,
    s.stage_name AS Stage,
    s.stage_sort AS StageSort,
    s.stage_group AS StageGroup,
    b.ExpectedDeliveryDate,
    c.CustomerName,
    c.CityName,
    c.StateProvinceName,
    c.CountryName,
    cc.CustomerCategoryName,
    cc.CustomerCategoryName AS DeliveryMethodName,
    bg.BuyingGroupName
FROM base b
JOIN wwi.dim_stage s ON s.stage_name = 'Order Created'
LEFT JOIN cust c ON c.CustomerID = b.CustomerID
LEFT JOIN cc ON cc.CustomerCategoryID = c.CustomerCategoryID
LEFT JOIN bg ON bg.BuyingGroupID = c.BuyingGroupID

UNION ALL

-- Stage 2: Picked (only orders with PickingCompletedWhen)
SELECT
    b.OrderID,
    CAST(b.PickingCompletedWhen AS DATETIME2(0)) AS EventTS,
    s.stage_name,
    s.stage_sort,
    s.stage_group,
    b.ExpectedDeliveryDate,
    c.CustomerName,
    c.CityName,
    c.StateProvinceName,
    c.CountryName,
    cc.CustomerCategoryName,
    cc.CustomerCategoryName AS DeliveryMethodName,
    bg.BuyingGroupName
FROM base b
JOIN wwi.dim_stage s ON s.stage_name = 'Picked'
LEFT JOIN cust c ON c.CustomerID = b.CustomerID
LEFT JOIN cc ON cc.CustomerCategoryID = c.CustomerCategoryID
LEFT JOIN bg ON bg.BuyingGroupID = c.BuyingGroupID
WHERE b.PickingCompletedWhen IS NOT NULL

UNION ALL

-- Stage 3: Invoiced (only orders with invoices)
SELECT
    b.OrderID,
    CAST(inv.InvoiceDate AS DATETIME2(0)) AS EventTS,
    s.stage_name,
    s.stage_sort,
    s.stage_group,
    b.ExpectedDeliveryDate,
    c.CustomerName,
    c.CityName,
    c.StateProvinceName,
    c.CountryName,
    cc.CustomerCategoryName,
    cc.CustomerCategoryName AS DeliveryMethodName,
    bg.BuyingGroupName
FROM base b
JOIN invoice inv ON inv.OrderID = b.OrderID
JOIN wwi.dim_stage s ON s.stage_name = 'Invoiced'
LEFT JOIN cust c ON c.CustomerID = b.CustomerID
LEFT JOIN cc ON cc.CustomerCategoryID = c.CustomerCategoryID
LEFT JOIN bg ON bg.BuyingGroupID = c.BuyingGroupID
WHERE inv.InvoiceDate IS NOT NULL

UNION ALL

-- Stage 4: Delivered (only orders with confirmed delivery)
SELECT
    b.OrderID,
    CAST(inv.ConfirmedDeliveryTime AS DATETIME2(0)) AS EventTS,
    s.stage_name,
    s.stage_sort,
    s.stage_group,
    b.ExpectedDeliveryDate,
    c.CustomerName,
    c.CityName,
    c.StateProvinceName,
    c.CountryName,
    cc.CustomerCategoryName,
    cc.CustomerCategoryName AS DeliveryMethodName,
    bg.BuyingGroupName
FROM base b
JOIN invoice inv ON inv.OrderID = b.OrderID
JOIN wwi.dim_stage s ON s.stage_name = 'Delivered'
LEFT JOIN cust c ON c.CustomerID = b.CustomerID
LEFT JOIN cc ON cc.CustomerCategoryID = c.CustomerCategoryID
LEFT JOIN bg ON bg.BuyingGroupID = c.BuyingGroupID
WHERE inv.ConfirmedDeliveryTime IS NOT NULL;
GO
