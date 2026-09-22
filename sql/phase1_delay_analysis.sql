SELECT 
    h.PurchaseOrderID,
    h.OrderDate,
    h.ShipDate,
    MIN(d.DueDate) AS EarliestDueDate,
    DATEDIFF(DAY, h.OrderDate, h.ShipDate) AS DaysToShip,
    DATEDIFF(DAY, MIN(d.DueDate), h.ShipDate) AS DelayDays,
    h.SubTotal,
    h.Freight,
    h.TotalDue,
    ROUND(h.Freight / NULLIF(h.TotalDue, 0) * 100, 2) AS FreightPercentOfTotal
FROM Purchasing.PurchaseOrderHeader h
JOIN Purchasing.PurchaseOrderDetail d ON h.PurchaseOrderID = d.PurchaseOrderID
GROUP BY h.PurchaseOrderID, h.OrderDate, h.ShipDate, h.SubTotal, h.Freight, h.TotalDue
ORDER BY h.OrderDate DESC;

WITH OrderDueDates AS (
    SELECT 
        h.PurchaseOrderID,
        h.OrderDate,
        h.ShipDate,
        h.Freight,
        h.TotalDue,
        MIN(d.DueDate) AS DueDate
    FROM Purchasing.PurchaseOrderHeader h
    JOIN Purchasing.PurchaseOrderDetail d ON h.PurchaseOrderID = d.PurchaseOrderID
    GROUP BY h.PurchaseOrderID, h.OrderDate, h.ShipDate, h.Freight, h.TotalDue
)
SELECT 
    AVG(DATEDIFF(DAY, OrderDate, ShipDate)) AS AvgDaysToShip,
    AVG(CASE WHEN ShipDate > DueDate THEN DATEDIFF(DAY, DueDate, ShipDate) END) AS AvgDelayWhenLate,
    SUM(CASE WHEN ShipDate > DueDate THEN 1 ELSE 0 END) AS LateOrdersCount,
    COUNT(*) AS TotalOrders,
    ROUND(SUM(CASE WHEN ShipDate > DueDate THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 2) AS LatePercentage,
    AVG(Freight / NULLIF(TotalDue, 0)) * 100 AS AvgFreightPercent
FROM OrderDueDates;