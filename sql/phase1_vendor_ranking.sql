-- شناسایی سفارشاتی که واقعاً با تأخیر تحویل شدن (ShipDate > DueDate)
SELECT 
    h.PurchaseOrderID,
    h.OrderDate,
    h.ShipDate,
    MIN(d.DueDate) AS DueDate,
    DATEDIFF(DAY, MIN(d.DueDate), h.ShipDate) AS DelayDays,
    h.VendorID,
    v.Name AS VendorName,
    h.EmployeeID,
    h.TotalDue
FROM Purchasing.PurchaseOrderHeader h
JOIN Purchasing.PurchaseOrderDetail d ON h.PurchaseOrderID = d.PurchaseOrderID
JOIN Purchasing.Vendor v ON h.VendorID = v.BusinessEntityID
GROUP BY h.PurchaseOrderID, h.OrderDate, h.ShipDate, h.VendorID, v.Name, h.EmployeeID, h.TotalDue
HAVING DATEDIFF(DAY, MIN(d.DueDate), h.ShipDate) > 0
ORDER BY DelayDays DESC;


-- رتبه‌بندی Vendorها بر اساس تعداد و ارزش سفارشات
SELECT 
    v.BusinessEntityID AS VendorID,
    v.Name AS VendorName,
    COUNT(h.PurchaseOrderID) AS OrderCount,
    SUM(h.TotalDue) AS TotalPurchaseValue,
    ROUND(SUM(h.TotalDue) * 100.0 / SUM(SUM(h.TotalDue)) OVER (), 2) AS PercentOfTotalSpend,
    AVG(DATEDIFF(DAY, h.OrderDate, h.ShipDate)) AS AvgDaysToShip
FROM Purchasing.PurchaseOrderHeader h
JOIN Purchasing.Vendor v ON h.VendorID = v.BusinessEntityID
GROUP BY v.BusinessEntityID, v.Name
ORDER BY TotalPurchaseValue DESC;