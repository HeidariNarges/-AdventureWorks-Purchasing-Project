IF OBJECT_ID('Purchasing.usp_VendorPerformanceReport', 'P') IS NOT NULL
    DROP PROCEDURE Purchasing.usp_VendorPerformanceReport;
GO

CREATE PROCEDURE Purchasing.usp_VendorPerformanceReport
    @StartDate DATE,
    @EndDate   DATE,
    @VendorID  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @StartDate IS NULL OR @EndDate IS NULL
        BEGIN
            THROW 50001, N'تاریخ شروع و پایان نمی‌توانند خالی باشند.', 1;
        END

        IF @StartDate > @EndDate
        BEGIN
            THROW 50002, N'تاریخ شروع نمی‌تواند بعد از تاریخ پایان باشد.', 1;
        END

        IF @VendorID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Purchasing.Vendor WHERE BusinessEntityID = @VendorID)
        BEGIN
            THROW 50003, N'تامین کننده ای با این VendorID پیدا نشد.', 1;
        END

        SELECT 
            v.BusinessEntityID AS VendorID,
            v.Name AS VendorName,
            COUNT(DISTINCT h.PurchaseOrderID) AS OrderCount,
            SUM(h.TotalDue) AS TotalSpend,
            AVG(DATEDIFF(DAY, h.OrderDate, h.ShipDate)) AS AvgDaysToShip,
            SUM(CASE WHEN h.ShipDate > d.DueDate THEN 1 ELSE 0 END) AS LateDeliveries,
            ROUND(SUM(CASE WHEN h.ShipDate > d.DueDate THEN 1.0 ELSE 0 END) / NULLIF(COUNT(DISTINCT h.PurchaseOrderID), 0) * 100, 2) AS LateDeliveryPercent,
            ROUND(AVG(h.Freight / NULLIF(h.TotalDue, 0)) * 100, 2) AS AvgFreightPercent
        FROM Purchasing.PurchaseOrderHeader h
        JOIN Purchasing.PurchaseOrderDetail d ON h.PurchaseOrderID = d.PurchaseOrderID
        JOIN Purchasing.Vendor v ON h.VendorID = v.BusinessEntityID
        WHERE h.OrderDate BETWEEN @StartDate AND @EndDate
          AND (@VendorID IS NULL OR h.VendorID = @VendorID)
        GROUP BY v.BusinessEntityID, v.Name
        ORDER BY TotalSpend DESC;

    END TRY
    BEGIN CATCH
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage,
            ERROR_LINE() AS ErrorLine,
            ERROR_SEVERITY() AS ErrorSeverity;
    END CATCH
END
GO

EXEC Purchasing.usp_VendorPerformanceReport 
    @StartDate = '2014-01-01', 
    @EndDate = '2014-12-31';

	EXEC Purchasing.usp_VendorPerformanceReport 
    @StartDate = '2011-01-01', 
    @EndDate = '2014-12-31', 
    @VendorID = 1636;

	EXEC Purchasing.usp_VendorPerformanceReport 
    @StartDate = '2015-01-01', 
    @EndDate = '2014-01-01';