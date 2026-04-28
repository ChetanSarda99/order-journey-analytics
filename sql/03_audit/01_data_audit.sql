/*
    Data Audit — Run in SSMS against wwi_analytics
    Checks WWI source data quality + view correctness
*/

USE wwi_analytics;
GO

PRINT '=== 1. DELIVERY METHODS IN WWI SOURCE ==='
-- How many distinct delivery methods exist in invoices?
SELECT dm.DeliveryMethodID, dm.DeliveryMethodName, COUNT(*) AS InvoiceCount
FROM WideWorldImporters.Sales.Invoices i
JOIN WideWorldImporters.Application.DeliveryMethods dm
    ON dm.DeliveryMethodID = i.DeliveryMethodID
GROUP BY dm.DeliveryMethodID, dm.DeliveryMethodName
ORDER BY InvoiceCount DESC;

PRINT '=== 2. ALL DELIVERY METHODS IN LOOKUP TABLE ==='
SELECT * FROM WideWorldImporters.Application.DeliveryMethods;

PRINT '=== 3. CUSTOMER DEFAULT DELIVERY METHODS ==='
-- Do customers have different delivery methods?
SELECT dm.DeliveryMethodName, COUNT(*) AS CustomerCount
FROM WideWorldImporters.Sales.Customers c
JOIN WideWorldImporters.Application.DeliveryMethods dm
    ON dm.DeliveryMethodID = c.DeliveryMethodID
GROUP BY dm.DeliveryMethodName
ORDER BY CustomerCount DESC;

PRINT '=== 4. ORDER STAGE DISTRIBUTION ==='
SELECT
    CASE
        WHEN inv.ConfirmedDeliveryTime IS NOT NULL THEN 'Delivered'
        WHEN inv.InvoiceDate IS NOT NULL THEN 'Invoiced'
        WHEN o.PickingCompletedWhen IS NOT NULL THEN 'Picked'
        ELSE 'Order Created'
    END AS FurthestStage,
    COUNT(*) AS OrderCount
FROM WideWorldImporters.Sales.Orders o
LEFT JOIN (
    SELECT OrderID, MIN(InvoiceDate) AS InvoiceDate,
           MIN(ConfirmedDeliveryTime) AS ConfirmedDeliveryTime
    FROM WideWorldImporters.Sales.Invoices
    WHERE OrderID IS NOT NULL
    GROUP BY OrderID
) inv ON inv.OrderID = o.OrderID
GROUP BY
    CASE
        WHEN inv.ConfirmedDeliveryTime IS NOT NULL THEN 'Delivered'
        WHEN inv.InvoiceDate IS NOT NULL THEN 'Invoiced'
        WHEN o.PickingCompletedWhen IS NOT NULL THEN 'Picked'
        ELSE 'Order Created'
    END
ORDER BY OrderCount DESC;

PRINT '=== 5. CYCLE TIME DISTRIBUTION (DAYS) ==='
SELECT
    CASE
        WHEN days IS NULL THEN 'Not Delivered'
        WHEN days = 0 THEN '0 (same day)'
        WHEN days = 1 THEN '1'
        WHEN days BETWEEN 2 AND 3 THEN '2-3'
        WHEN days BETWEEN 4 AND 7 THEN '4-7'
        WHEN days BETWEEN 8 AND 14 THEN '8-14'
        WHEN days BETWEEN 15 AND 30 THEN '15-30'
        ELSE '30+'
    END AS CycleBucket,
    COUNT(*) AS OrderCount
FROM (
    SELECT DATEDIFF(DAY, o.OrderDate, inv.ConfirmedDeliveryTime) AS days
    FROM WideWorldImporters.Sales.Orders o
    LEFT JOIN (
        SELECT OrderID, MIN(ConfirmedDeliveryTime) AS ConfirmedDeliveryTime
        FROM WideWorldImporters.Sales.Invoices
        WHERE OrderID IS NOT NULL
        GROUP BY OrderID
    ) inv ON inv.OrderID = o.OrderID
) x
GROUP BY
    CASE
        WHEN days IS NULL THEN 'Not Delivered'
        WHEN days = 0 THEN '0 (same day)'
        WHEN days = 1 THEN '1'
        WHEN days BETWEEN 2 AND 3 THEN '2-3'
        WHEN days BETWEEN 4 AND 7 THEN '4-7'
        WHEN days BETWEEN 8 AND 14 THEN '8-14'
        WHEN days BETWEEN 15 AND 30 THEN '15-30'
        ELSE '30+'
    END
ORDER BY MIN(ISNULL(days, 9999));

PRINT '=== 6. STAGE-TO-STAGE DURATION (HOURS, not days) ==='
SELECT
    'Created to Picked' AS Transition,
    COUNT(*) AS OrderCount,
    AVG(DATEDIFF(HOUR, o.OrderDate, o.PickingCompletedWhen)) AS AvgHours,
    MIN(DATEDIFF(HOUR, o.OrderDate, o.PickingCompletedWhen)) AS MinHours,
    MAX(DATEDIFF(HOUR, o.OrderDate, o.PickingCompletedWhen)) AS MaxHours
FROM WideWorldImporters.Sales.Orders o
WHERE o.PickingCompletedWhen IS NOT NULL
UNION ALL
SELECT
    'Picked to Invoiced',
    COUNT(*),
    AVG(DATEDIFF(HOUR, o.PickingCompletedWhen, inv.InvoiceDate)),
    MIN(DATEDIFF(HOUR, o.PickingCompletedWhen, inv.InvoiceDate)),
    MAX(DATEDIFF(HOUR, o.PickingCompletedWhen, inv.InvoiceDate))
FROM WideWorldImporters.Sales.Orders o
JOIN (
    SELECT OrderID, MIN(InvoiceDate) AS InvoiceDate
    FROM WideWorldImporters.Sales.Invoices WHERE OrderID IS NOT NULL
    GROUP BY OrderID
) inv ON inv.OrderID = o.OrderID
WHERE o.PickingCompletedWhen IS NOT NULL
UNION ALL
SELECT
    'Invoiced to Delivered',
    COUNT(*),
    AVG(DATEDIFF(HOUR, inv.InvoiceDate, inv.ConfirmedDeliveryTime)),
    MIN(DATEDIFF(HOUR, inv.InvoiceDate, inv.ConfirmedDeliveryTime)),
    MAX(DATEDIFF(HOUR, inv.InvoiceDate, inv.ConfirmedDeliveryTime))
FROM (
    SELECT OrderID,
           MIN(InvoiceDate) AS InvoiceDate,
           MIN(ConfirmedDeliveryTime) AS ConfirmedDeliveryTime
    FROM WideWorldImporters.Sales.Invoices WHERE OrderID IS NOT NULL
    GROUP BY OrderID
) inv
WHERE inv.ConfirmedDeliveryTime IS NOT NULL;

PRINT '=== 7. SAMPLE ROWS WITH TIMESTAMPS ==='
SELECT TOP 20
    o.OrderID,
    o.OrderDate,
    o.ExpectedDeliveryDate,
    o.PickingCompletedWhen,
    inv.InvoiceDate,
    inv.ConfirmedDeliveryTime,
    DATEDIFF(HOUR, o.OrderDate, o.PickingCompletedWhen) AS CreatedToPickedHrs,
    DATEDIFF(HOUR, o.PickingCompletedWhen, inv.InvoiceDate) AS PickedToInvoicedHrs,
    DATEDIFF(HOUR, inv.InvoiceDate, inv.ConfirmedDeliveryTime) AS InvoicedToDeliveredHrs,
    DATEDIFF(DAY, o.OrderDate, inv.ConfirmedDeliveryTime) AS CycleTimeDays
FROM WideWorldImporters.Sales.Orders o
LEFT JOIN (
    SELECT OrderID, MIN(InvoiceDate) AS InvoiceDate,
           MIN(ConfirmedDeliveryTime) AS ConfirmedDeliveryTime
    FROM WideWorldImporters.Sales.Invoices WHERE OrderID IS NOT NULL
    GROUP BY OrderID
) inv ON inv.OrderID = o.OrderID
WHERE inv.ConfirmedDeliveryTime IS NOT NULL
ORDER BY o.OrderID;

PRINT '=== 8. NULL CHECK — ROLLUP VIEW ==='
SELECT
    COUNT(*) AS TotalOrders,
    SUM(CASE WHEN DeliveryMethodName IS NULL THEN 1 ELSE 0 END) AS NullDeliveryMethod,
    SUM(CASE WHEN CycleTimeDays IS NULL THEN 1 ELSE 0 END) AS NullCycleTime,
    SUM(CASE WHEN CustomerName IS NULL THEN 1 ELSE 0 END) AS NullCustomer,
    SUM(CASE WHEN StateProvinceName IS NULL THEN 1 ELSE 0 END) AS NullState,
    SUM(CASE WHEN CreatedToPickedDays IS NULL THEN 1 ELSE 0 END) AS NullCreatedToPicked,
    SUM(CASE WHEN PickedToInvoicedDays IS NULL THEN 1 ELSE 0 END) AS NullPickedToInvoiced,
    SUM(CASE WHEN InvoicedToDeliveredDays IS NULL THEN 1 ELSE 0 END) AS NullInvoicedToDelivered
FROM wwi.vw_order_rollup;

PRINT '=== 9. VIEW ROW COUNTS ==='
SELECT 'vw_order_event' AS ViewName, COUNT(*) AS [RowCount] FROM wwi.vw_order_event
UNION ALL
SELECT 'vw_order_rollup', COUNT(*) FROM wwi.vw_order_rollup;

PRINT '=== 10. ORDERS WITH LONG CYCLE TIMES (>30 days) ==='
SELECT TOP 10
    OrderID, CreatedDate, DeliveredDate, CycleTimeDays,
    CustomerName, StateProvinceName, DeliveryMethodName
FROM wwi.vw_order_rollup
WHERE CycleTimeDays > 30
ORDER BY CycleTimeDays DESC;
