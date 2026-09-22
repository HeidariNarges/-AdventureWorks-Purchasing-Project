-- رتبه‌بندی Vendorها بر اساس میانگین زمان تحویل (کندترین در بالا)
WITH VendorPerformance AS (
    SELECT 
        v.BusinessEntityID AS VendorID,
        v.Name AS VendorName,
        COUNT(h.PurchaseOrderID) AS OrderCount,
        AVG(DATEDIFF(DAY, h.OrderDate, h.ShipDate)) AS AvgDaysToShip,
        SUM(h.TotalDue) AS TotalSpend
    FROM Purchasing.PurchaseOrderHeader h
    JOIN Purchasing.Vendor v ON h.VendorID = v.BusinessEntityID
    GROUP BY v.BusinessEntityID, v.Name
)
SELECT 
    VendorID,
    VendorName,
    OrderCount,
    AvgDaysToShip,
    TotalSpend,
    RANK() OVER (ORDER BY AvgDaysToShip DESC) AS SlowestRank,
    RANK() OVER (ORDER BY TotalSpend DESC) AS SpendRank
FROM VendorPerformance
ORDER BY SlowestRank;

-- روند تغییر زمان تحویل هر Vendor در سفارش‌های متوالی
WITH VendorOrders AS (
    SELECT 
        h.VendorID,
        v.Name AS VendorName,
        h.PurchaseOrderID,
        h.OrderDate,
        DATEDIFF(DAY, h.OrderDate, h.ShipDate) AS DaysToShip,
        ROW_NUMBER() OVER (PARTITION BY h.VendorID ORDER BY h.OrderDate) AS OrderSequence
    FROM Purchasing.PurchaseOrderHeader h
    JOIN Purchasing.Vendor v ON h.VendorID = v.BusinessEntityID
)
SELECT 
    VendorID,
    VendorName,
    PurchaseOrderID,
    OrderDate,
    OrderSequence,
    DaysToShip,
    LAG(DaysToShip) OVER (PARTITION BY VendorID ORDER BY OrderDate) AS PreviousDaysToShip,
    DaysToShip - LAG(DaysToShip) OVER (PARTITION BY VendorID ORDER BY OrderDate) AS ChangeFromPrevious,
    LEAD(DaysToShip) OVER (PARTITION BY VendorID ORDER BY OrderDate) AS NextDaysToShip
FROM VendorOrders
WHERE VendorID IN (1636, 1576, 1684)  -- یکی از Vendorهای کند (1636) + دو تا از Vendorهای پرتراکنش برای مقایسه
ORDER BY VendorID, OrderSequence;

-- روند ماهانه تعداد و ارزش سفارشات خرید
SELECT 
    YEAR(OrderDate) AS OrderYear,
    MONTH(OrderDate) AS OrderMonth,
    COUNT(*) AS OrderCount,
    SUM(TotalDue) AS TotalSpend,
    AVG(TotalDue) AS AvgOrderValue
FROM Purchasing.PurchaseOrderHeader
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY OrderYear, OrderMonth;

-- گروه‌بندی Vendorها بر اساس تعداد سفارش، برای اثبات رسمی رابطه
WITH VendorStats AS (
    SELECT 
        v.BusinessEntityID AS VendorID,
        v.Name AS VendorName,
        COUNT(h.PurchaseOrderID) AS OrderCount,
        AVG(DATEDIFF(DAY, h.OrderDate, h.ShipDate)) AS AvgDaysToShip
    FROM Purchasing.PurchaseOrderHeader h
    JOIN Purchasing.Vendor v ON h.VendorID = v.BusinessEntityID
    GROUP BY v.BusinessEntityID, v.Name
)
SELECT 
    CASE 
        WHEN OrderCount <= 5 THEN '۱. کم‌تراکنش (۱ تا ۵ سفارش)'
        WHEN OrderCount BETWEEN 6 AND 30 THEN '۲. متوسط (۶ تا ۳۰ سفارش)'
        ELSE '۳. پرتراکنش (بیش از ۳۰ سفارش)'
    END AS VendorTier,
    COUNT(*) AS VendorCount,
    AVG(AvgDaysToShip) AS AvgDaysToShipInGroup,
    MIN(AvgDaysToShip) AS MinDays,
    MAX(AvgDaysToShip) AS MaxDays
FROM VendorStats
GROUP BY 
    CASE 
        WHEN OrderCount <= 5 THEN '۱. کم‌تراکنش (۱ تا ۵ سفارش)'
        WHEN OrderCount BETWEEN 6 AND 30 THEN '۲. متوسط (۶ تا ۳۰ سفارش)'
        ELSE '۳. پرتراکنش (بیش از ۳۰ سفارش)'
    END
ORDER BY VendorTier;

-- بررسی سیستماتیک ناهنجاری DueDate < OrderDate
SELECT 
    h.PurchaseOrderID,
    h.OrderDate,
    d.DueDate,
    DATEDIFF(DAY, h.OrderDate, d.DueDate) AS DaysBetweenOrderAndDue,
    h.VendorID,
    v.Name AS VendorName,
    d.ProductID,
    d.OrderQty
FROM Purchasing.PurchaseOrderHeader h
JOIN Purchasing.PurchaseOrderDetail d ON h.PurchaseOrderID = d.PurchaseOrderID
JOIN Purchasing.Vendor v ON h.VendorID = v.BusinessEntityID
WHERE d.DueDate < h.OrderDate
ORDER BY DaysBetweenOrderAndDue ASC;

-- سهم هر کارمند خرید از تعداد و ارزش کل سفارشات
SELECT 
    h.EmployeeID,
    p.FirstName + ' ' + p.LastName AS EmployeeName,
    COUNT(h.PurchaseOrderID) AS OrderCount,
    SUM(h.TotalDue) AS TotalValue,
    ROUND(COUNT(h.PurchaseOrderID) * 100.0 / SUM(COUNT(h.PurchaseOrderID)) OVER (), 2) AS PercentOfOrders,
    ROUND(SUM(h.TotalDue) * 100.0 / SUM(SUM(h.TotalDue)) OVER (), 2) AS PercentOfValue,
    AVG(DATEDIFF(DAY, h.OrderDate, h.ShipDate)) AS AvgDaysToShip
FROM Purchasing.PurchaseOrderHeader h
JOIN Person.Person p ON h.EmployeeID = p.BusinessEntityID
GROUP BY h.EmployeeID, p.FirstName, p.LastName
ORDER BY OrderCount DESC;

WITH VendorRFM AS (
    SELECT 
        v.BusinessEntityID AS VendorID,
        v.Name AS VendorName,
        DATEDIFF(DAY, MAX(h.OrderDate), (SELECT MAX(OrderDate) FROM Purchasing.PurchaseOrderHeader)) AS Recency,
        COUNT(h.PurchaseOrderID) AS Frequency,
        SUM(h.TotalDue) AS Monetary
    FROM Purchasing.PurchaseOrderHeader h
    JOIN Purchasing.Vendor v ON h.VendorID = v.BusinessEntityID
    GROUP BY v.BusinessEntityID, v.Name
),
RFM_Scored AS (
    SELECT 
        VendorID,
        VendorName,
        Recency,
        Frequency,
        Monetary,
        NTILE(4) OVER (ORDER BY Recency DESC) AS R_Score,
        NTILE(4) OVER (ORDER BY Frequency ASC) AS F_Score,
        NTILE(4) OVER (ORDER BY Monetary ASC) AS M_Score
    FROM VendorRFM
)
SELECT 
    VendorID,
    VendorName,
    Recency,
    Frequency,
    Monetary,
    R_Score,
    F_Score,
    M_Score,
    (R_Score + F_Score + M_Score) AS RFM_Total,
    CASE 
        WHEN F_Score >= 3 AND M_Score >= 3 THEN 'Vendor کلیدی (Strategic)'
        WHEN F_Score <= 2 AND M_Score <= 2 THEN 'Vendor کم‌اهمیت (At Risk)'
        ELSE 'Vendor متوسط (Standard)'
    END AS VendorSegment
FROM RFM_Scored
ORDER BY RFM_Total DESC;