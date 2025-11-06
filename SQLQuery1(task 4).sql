-- Drop the existing table if it exists
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'retail_sales')
    DROP TABLE retail_sales;
GO
-- Create the new retail_sales table
CREATE TABLE retail_sales (
    [InvoiceNo] VARCHAR(20),
    [StockCode] VARCHAR(20),
    [Description] VARCHAR(255),
    [Quantity] INT,
    [InvoiceDate] VARCHAR(50),
    [UnitPrice] DECIMAL(10,2),
    [CustomerID] VARCHAR(20),
    [Country] VARCHAR(100)
);
GO
-- Insert the sample data you provided
INSERT INTO retail_sales VALUES 
('536365', '85123A', 'WHITE HANGING HEART T-LIGHT HOLDER', 6, '12-01-2010 08:26', 2.55, '17850', 'United Kingdom'),
('536365', '71053', 'WHITE METAL LANTERN', 6, '12-01-2010 08:26', 3.39, '17850', 'United Kingdom'),
('536365', '84406B', 'CREAM CUPID HEARTS COAT HANGER', 8, '12-01-2010 08:26', 2.75, '17850', 'United Kingdom'),
('536365', '84029G', 'KNITTED UNION FLAG HOT WATER BOTTLE', 6, '12-01-2010 08:26', 3.39, '17850', 'United Kingdom'),
('536366', '22752', 'SET 7 BABUSHKA NESTING BOXES', 2, '12-01-2010 08:28', 7.65, '17850', 'United Kingdom'),
('536366', '21730', 'GLASS STAR FROSTED T-LIGHT HOLDER', 6, '12-01-2010 08:28', 4.25, '17850', 'United Kingdom'),
('536367', '22633', 'HAND WARMER UNION JACK', 6, '12-01-2010 08:34', 1.85, '13047', 'United Kingdom'),
('536367', '22632', 'HAND WARMER RED POLKA DOT', 6, '12-01-2010 08:34', 1.85, '13047', 'United Kingdom'),
('536368', '84879', 'ASSORTED COLOUR BIRD ORNAMENT', 32, '12-01-2010 08:34', 1.69, '12583', 'France'),
('536368', '22745', 'POPPY''S PLAYHOUSE BEDROOM', 6, '12-01-2010 08:34', 2.10, '12583', 'France'),
('536369', '22748', 'POPPY''S PLAYHOUSE KITCHEN', 6, '12-01-2010 08:35', 2.10, '13705', 'United Kingdom'),
('536369', '22310', 'IVORY KNITTED MUG COSY', 6, '12-01-2010 08:35', 1.65, '13705', 'United Kingdom'),
('536370', '21754', 'HOME BUILDING BLOCK WORD', 3, '12-01-2010 08:35', 5.95, '15100', 'United Kingdom'),
('536370', '21755', 'HOME BUILDING BLOCK NUMBER', 3, '12-01-2010 08:35', 5.95, '15100', 'United Kingdom');
GO
-- Check if data was inserted correctly
SELECT COUNT(*) as 'Total Rows' FROM retail_sales;
SELECT TOP 5 * FROM retail_sales;
-- Add a calculated column for total amount
ALTER TABLE retail_sales ADD [TotalAmount] DECIMAL(10,2);
GO

-- Calculate total amount for each transaction
UPDATE retail_sales 
SET [TotalAmount] = [Quantity] * [UnitPrice];
GO

-- Convert InvoiceDate to proper datetime format
ALTER TABLE retail_sales ADD [InvoiceDateTime] DATETIME;
GO

UPDATE retail_sales 
SET [InvoiceDateTime] = TRY_CONVERT(DATETIME, [InvoiceDate], 101);
GO

-- Add date parts for analysis
ALTER TABLE retail_sales ADD [InvoiceYear] INT;
ALTER TABLE retail_sales ADD [InvoiceMonth] INT;
ALTER TABLE retail_sales ADD [InvoiceMonthName] VARCHAR(20);
GO

UPDATE retail_sales 
SET 
    [InvoiceYear] = YEAR([InvoiceDateTime]),
    [InvoiceMonth] = MONTH([InvoiceDateTime]),
    [InvoiceMonthName] = DATENAME(MONTH, [InvoiceDateTime]);
GO
-- DATASET OVERVIEW
SELECT 
    COUNT(*) as Total_Transactions,
    COUNT(DISTINCT [InvoiceNo]) as Total_Invoices,
    COUNT(DISTINCT [CustomerID]) as Unique_Customers,
    COUNT(DISTINCT [StockCode]) as Unique_Products,
    SUM([Quantity]) as Total_Items_Sold,
    SUM([TotalAmount]) as Total_Revenue,
    ROUND(AVG([UnitPrice]), 2) as Avg_Unit_Price
FROM retail_sales;
-- SALES BY COUNTRY
SELECT 
    [Country],
    COUNT(*) as Transaction_Count,
    SUM([TotalAmount]) as Total_Revenue,
    ROUND(SUM([TotalAmount]) * 100.0 / (SELECT SUM([TotalAmount]) FROM retail_sales), 2) as Revenue_Percentage
FROM retail_sales
GROUP BY [Country]
ORDER BY Total_Revenue DESC;
-- TOP 5 PRODUCTS BY REVENUE
SELECT TOP 5
    [StockCode],
    [Description],
    SUM([Quantity]) as Total_Quantity_Sold,
    SUM([TotalAmount]) as Total_Revenue,
    AVG([UnitPrice]) as Avg_Price
FROM retail_sales
GROUP BY [StockCode], [Description]
ORDER BY Total_Revenue DESC;
-- TOP CUSTOMERS
SELECT TOP 5
    [CustomerID],
    [Country],
    COUNT(DISTINCT [InvoiceNo]) as Order_Count,
    SUM([TotalAmount]) as Total_Spent
FROM retail_sales
WHERE [CustomerID] IS NOT NULL
GROUP BY [CustomerID], [Country]
ORDER BY Total_Spent DESC;
-- INVOICE SUMMARY
SELECT 
    [InvoiceNo],
    [CustomerID],
    COUNT(*) as Items_In_Invoice,
    SUM([Quantity]) as Total_Items,
    SUM([TotalAmount]) as Invoice_Total
FROM retail_sales
GROUP BY [InvoiceNo], [CustomerID]
ORDER BY Invoice_Total DESC;
-- PRODUCT PERFORMANCE METRICS
SELECT 
    [StockCode],
    [Description],
    COUNT(*) as Times_Ordered,
    COUNT(DISTINCT [InvoiceNo]) as Unique_Invoices,
    SUM([Quantity]) as Total_Quantity_Sold,
    SUM([TotalAmount]) as Total_Revenue,
    AVG([UnitPrice]) as Avg_Unit_Price,
    AVG([Quantity]) as Avg_Quantity_Per_Order,
    ROUND(SUM([TotalAmount]) / SUM([Quantity]), 2) as Revenue_Per_Item
FROM retail_sales
GROUP BY [StockCode], [Description]
ORDER BY Total_Revenue DESC;
-- HOURLY SALES PATTERN (Extract hour from datetime)
SELECT 
    DATEPART(HOUR, [InvoiceDateTime]) as Hour_of_Day,
    COUNT(*) as Transaction_Count,
    COUNT(DISTINCT [InvoiceNo]) as Unique_Invoices,
    SUM([TotalAmount]) as Hourly_Revenue,
    AVG([TotalAmount]) as Avg_Transaction_Value
FROM retail_sales
WHERE [InvoiceDateTime] IS NOT NULL
GROUP BY DATEPART(HOUR, [InvoiceDateTime])
ORDER BY Hour_of_Day;
-- PRODUCTS FREQUENTLY BOUGHT TOGETHER (Same Invoice)
SELECT 
    a.[StockCode] as Product1,
    a.[Description] as Product1_Desc,
    b.[StockCode] as Product2, 
    b.[Description] as Product2_Desc,
    COUNT(*) as Times_Bought_Together
FROM retail_sales a
INNER JOIN retail_sales b ON a.[InvoiceNo] = b.[InvoiceNo] 
    AND a.[StockCode] < b.[StockCode]  -- Avoid duplicates (A+B and B+A)
WHERE a.[InvoiceNo] IN (
    SELECT [InvoiceNo] 
    FROM retail_sales 
    GROUP BY [InvoiceNo] 
    HAVING COUNT(*) > 1  -- Only invoices with multiple products
)
GROUP BY a.[StockCode], a.[Description], b.[StockCode], b.[Description]
ORDER BY Times_Bought_Together DESC;
-- COUNTRY-SPECIFIC BUYING PATTERNS
SELECT 
    [Country],
    COUNT(DISTINCT [CustomerID]) as Unique_Customers,
    COUNT(DISTINCT [InvoiceNo]) as Total_Invoices,
    SUM([TotalAmount]) as Total_Revenue,
    ROUND(SUM([TotalAmount]) / COUNT(DISTINCT [InvoiceNo]), 2) as Avg_Order_Value_By_Country,
    ROUND(SUM([TotalAmount]) / COUNT(DISTINCT [CustomerID]), 2) as Revenue_Per_Customer,
    ROUND(CAST(COUNT(DISTINCT [InvoiceNo]) as float) / COUNT(DISTINCT [CustomerID]), 2) as Avg_Orders_Per_Customer
FROM retail_sales
GROUP BY [Country]
ORDER BY Total_Revenue DESC;
-- Drop existing views if they exist
IF EXISTS (SELECT * FROM sys.views WHERE name = 'Customer_Summary')
    DROP VIEW Customer_Summary;
GO

IF EXISTS (SELECT * FROM sys.views WHERE name = 'Product_Performance')
    DROP VIEW Product_Performance;
GO
-- Create Customer Summary View
CREATE VIEW Customer_Summary AS
SELECT 
    [CustomerID],
    [Country],
    COUNT(DISTINCT [InvoiceNo]) as Total_Orders,
    SUM([TotalAmount]) as Lifetime_Value,
    SUM([Quantity]) as Total_Items_Purchased,
    MIN([InvoiceDateTime]) as First_Order_Date,
    MAX([InvoiceDateTime]) as Last_Order_Date,
    DATEDIFF(DAY, MIN([InvoiceDateTime]), MAX([InvoiceDateTime])) as Customer_Lifetime_Days
FROM retail_sales
WHERE [CustomerID] IS NOT NULL
GROUP BY [CustomerID], [Country];
GO
-- Create Product Performance View
CREATE VIEW Product_Performance AS
SELECT 
    [StockCode],
    [Description],
    COUNT(*) as Times_Ordered,
    SUM([Quantity]) as Total_Quantity_Sold,
    SUM([TotalAmount]) as Total_Revenue,
    AVG([UnitPrice]) as Avg_Unit_Price,
    COUNT(DISTINCT [InvoiceNo]) as Unique_Invoices
FROM retail_sales
GROUP BY [StockCode], [Description];
GO
-- EXECUTIVE DASHBOARD METRICS
SELECT 
    'Total Revenue' as Metric, 
    CAST(SUM([TotalAmount]) as VARCHAR(20)) as Value
FROM retail_sales
UNION ALL
SELECT 
    'Total Customers', 
    CAST(COUNT(DISTINCT [CustomerID]) as VARCHAR(20))
FROM retail_sales
WHERE [CustomerID] IS NOT NULL
UNION ALL
SELECT 
    'Total Products', 
    CAST(COUNT(DISTINCT [StockCode]) as VARCHAR(20))
FROM retail_sales
UNION ALL
SELECT 
    'Avg Order Value', 
    CAST(ROUND(AVG([TotalAmount]), 2) as VARCHAR(20))
FROM retail_sales
UNION ALL
SELECT 
    'Top Country', 
    (SELECT TOP 1 [Country] FROM retail_sales 
     GROUP BY [Country] ORDER BY SUM([TotalAmount]) DESC)
FROM retail_sales;
-- TOP PERFORMERS IN ONE VIEW
SELECT 'Top Customer' as Category, 
       [CustomerID] as Name, 
       CAST([Lifetime_Value] as VARCHAR(50)) as Value
FROM Customer_Summary 
WHERE [Lifetime_Value] = (SELECT MAX([Lifetime_Value]) FROM Customer_Summary)
UNION ALL
SELECT 'Top Product', 
       [Description], 
       CAST([Total_Revenue] as VARCHAR(50))
FROM Product_Performance 
WHERE [Total_Revenue] = (SELECT MAX([Total_Revenue]) FROM Product_Performance)
UNION ALL
SELECT 'Most Popular Product', 
       [Description], 
       CAST([Times_Ordered] as VARCHAR(50))
FROM Product_Performance 
WHERE [Times_Ordered] = (SELECT MAX([Times_Ordered]) FROM Product_Performance);
SELECT TOP 3 
    [CustomerID],
    [Country],
    [Lifetime_Value],
    [Total_Orders]
FROM Customer_Summary 
ORDER BY [Lifetime_Value] DESC;
SELECT TOP 5
    [StockCode],
    [Description],
    [Total_Revenue],
    [Times_Ordered],
    [Avg_Unit_Price]
FROM Product_Performance
ORDER BY [Total_Revenue] DESC;