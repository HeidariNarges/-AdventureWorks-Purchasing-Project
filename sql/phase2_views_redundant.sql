-- ========== View 1: Dim_Vendor ==========
IF OBJECT_ID('Purchasing.vw_Dim_Vendor', 'V') IS NOT NULL
    DROP VIEW Purchasing.vw_Dim_Vendor;
GO
CREATE VIEW Purchasing.vw_Dim_Vendor AS
SELECT 
    v.BusinessEntityID   AS VendorID,
    v.Name                AS VendorName,
    v.CreditRating,
    v.ActiveFlag,
    v.PreferredVendorStatus
FROM Purchasing.Vendor v;
GO

-- ========== View 2: Dim_Employee ==========
IF OBJECT_ID('Purchasing.vw_Dim_Employee', 'V') IS NOT NULL
    DROP VIEW Purchasing.vw_Dim_Employee;
GO
CREATE VIEW Purchasing.vw_Dim_Employee AS
SELECT 
    e.BusinessEntityID   AS EmployeeID,
    p.FirstName + ' ' + p.LastName AS EmployeeName,
    e.JobTitle,
    e.HireDate
FROM HumanResources.Employee e
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID;
GO

-- ========== View 3: Dim_Product ==========
IF OBJECT_ID('Purchasing.vw_Dim_Product', 'V') IS NOT NULL
    DROP VIEW Purchasing.vw_Dim_Product;
GO
CREATE VIEW Purchasing.vw_Dim_Product AS
SELECT 
    p.ProductID,
    p.Name             AS ProductName,
    p.ProductNumber,
    p.Color,
    p.StandardCost,
    p.ListPrice,
    psc.Name           AS SubcategoryName,
    pc.Name            AS CategoryName
FROM Production.Product p
LEFT JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID;
GO

-- ========== View 4: Dim_Date ==========
IF OBJECT_ID('Purchasing.vw_Dim_Date', 'V') IS NOT NULL
    DROP VIEW Purchasing.vw_Dim_Date;
GO
CREATE VIEW Purchasing.vw_Dim_Date AS
WITH Numbers AS (
    SELECT TOP (2000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
),
DateRange AS (
    SELECT DATEADD(DAY, n, CAST('2011-01-01' AS DATE)) AS FullDate
    FROM Numbers
    WHERE DATEADD(DAY, n, CAST('2011-01-01' AS DATE)) <= '2015-12-31'
)
SELECT 
    CONVERT(INT, FORMAT(FullDate, 'yyyyMMdd')) AS DateKey,
    FullDate,
    YEAR(FullDate)                              AS [Year],
    MONTH(FullDate)                             AS [Month],
    DATENAME(MONTH, FullDate)                   AS MonthName,
    DATEPART(QUARTER, FullDate)                 AS [Quarter],
    DAY(FullDate)                               AS [Day],
    DATENAME(WEEKDAY, FullDate)                 AS WeekdayName
FROM DateRange;
GO

-- ========== View 5: Fact_PurchaseOrderDetail ==========
IF OBJECT_ID('Purchasing.vw_Fact_PurchaseOrderDetail', 'V') IS NOT NULL
    DROP VIEW Purchasing.vw_Fact_PurchaseOrderDetail;
GO
CREATE VIEW Purchasing.vw_Fact_PurchaseOrderDetail AS
SELECT 
    d.PurchaseOrderDetailID,
    h.PurchaseOrderID,
    CONVERT(INT, FORMAT(h.OrderDate, 'yyyyMMdd')) AS OrderDateKey,
    CONVERT(INT, FORMAT(h.ShipDate, 'yyyyMMdd'))  AS ShipDateKey,
    CONVERT(INT, FORMAT(d.DueDate, 'yyyyMMdd'))   AS DueDateKey,
    h.VendorID,
    h.EmployeeID,
    d.ProductID,
    d.OrderQty,
    d.UnitPrice,
    d.LineTotal,
    d.ReceivedQty,
    d.RejectedQty,
    d.StockedQty,
    h.Freight,
    h.SubTotal,
    h.TotalDue,
    DATEDIFF(DAY, h.OrderDate, h.ShipDate)        AS DaysToShip,
    CASE WHEN h.ShipDate > d.DueDate THEN 1 ELSE 0 END AS IsLate,
    h.Status
FROM Purchasing.PurchaseOrderDetail d
JOIN Purchasing.PurchaseOrderHeader h ON d.PurchaseOrderID = h.PurchaseOrderID;
GO

SELECT 'Dim_Vendor' AS ViewName, COUNT(*) AS RecordCount FROM Purchasing.vw_Dim_Vendor
UNION ALL
SELECT 'Dim_Employee', COUNT(*) FROM Purchasing.vw_Dim_Employee
UNION ALL
SELECT 'Dim_Product', COUNT(*) FROM Purchasing.vw_Dim_Product
UNION ALL
SELECT 'Dim_Date', COUNT(*) FROM Purchasing.vw_Dim_Date
UNION ALL
SELECT 'Fact_PurchaseOrderDetail', COUNT(*) FROM Purchasing.vw_Fact_PurchaseOrderDetail;