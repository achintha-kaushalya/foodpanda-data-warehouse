

USE master;
GO

IF DB_ID('FoodpandaSourceDB') IS NOT NULL
BEGIN
    ALTER DATABASE FoodpandaSourceDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE FoodpandaSourceDB;
END
GO

CREATE DATABASE FoodpandaSourceDB;
GO

USE FoodpandaSourceDB;
GO



CREATE TABLE RawFoodpandaData (
    customer_id VARCHAR(50),
    gender VARCHAR(20),
    age VARCHAR(20),
    city VARCHAR(100),
    signup_date VARCHAR(50),
    order_id VARCHAR(50),
    order_date VARCHAR(50),
    restaurant_name VARCHAR(200),
    dish_name VARCHAR(200),
    category VARCHAR(100),
    quantity INT,
    price DECIMAL(10,2),
    payment_method VARCHAR(50),
    order_frequency VARCHAR(50),
    last_order_date VARCHAR(50),
    loyalty_points INT,
    churned VARCHAR(10),
    rating INT,
    rating_date VARCHAR(50),
    delivery_status VARCHAR(50)
);
GO

BULK INSERT RawFoodpandaData
FROM 'C:\temp\Foodpanda Analysis Dataset.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK,
    CODEPAGE = '65001'
);
GO


-- Customer
CREATE TABLE Customer (
    CustomerID VARCHAR(50) PRIMARY KEY,
    Gender VARCHAR(20),
    AgeGroup VARCHAR(20),
    City VARCHAR(100),
    SignupDate DATE,
    OrderFrequency VARCHAR(50),
    LastOrderDate DATE,
    LoyaltyPoints INT,
    Churned VARCHAR(10)
);
GO

-- Restaurant (FIXED UNIQUE)
CREATE TABLE Restaurant (
    RestaurantID INT IDENTITY(1,1) PRIMARY KEY,
    RestaurantName VARCHAR(200),
    City VARCHAR(100),
    CONSTRAINT UQ_Restaurant UNIQUE (RestaurantName, City)
);
GO

-- Dish
CREATE TABLE Dish (
    DishID INT IDENTITY(1,1) PRIMARY KEY,
    DishName VARCHAR(200),
    Category VARCHAR(100),
    RestaurantID INT,
    FOREIGN KEY (RestaurantID) REFERENCES Restaurant(RestaurantID)
);
GO

-- OrderHeader
CREATE TABLE OrderHeader (
    OrderID VARCHAR(50) PRIMARY KEY,
    CustomerID VARCHAR(50),
    OrderDate DATE,
    PaymentMethod VARCHAR(50),
    DeliveryStatus VARCHAR(50),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);
GO

-- OrderDetail
CREATE TABLE OrderDetail (
    OrderDetailID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID VARCHAR(50),
    DishID INT,
    Quantity INT,
    Price DECIMAL(10,2),
    FOREIGN KEY (OrderID) REFERENCES OrderHeader(OrderID),
    FOREIGN KEY (DishID) REFERENCES Dish(DishID)
);
GO

-- Rating
CREATE TABLE CustomerRating (
    RatingID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID VARCHAR(50),
    CustomerID VARCHAR(50),
    Rating INT,
    RatingDate DATE,
    FOREIGN KEY (OrderID) REFERENCES OrderHeader(OrderID),
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
);
GO


INSERT INTO Customer
SELECT DISTINCT
    customer_id,
    gender,
    age,
    city,
    TRY_CONVERT(DATE, signup_date),
    order_frequency,
    TRY_CONVERT(DATE, last_order_date),
    loyalty_points,
    churned
FROM RawFoodpandaData;
GO


INSERT INTO Restaurant (RestaurantName, City)
SELECT DISTINCT
    restaurant_name,
    city
FROM RawFoodpandaData;
GO


INSERT INTO Dish (DishName, Category, RestaurantID)
SELECT DISTINCT
    rfd.dish_name,
    rfd.category,
    r.RestaurantID
FROM RawFoodpandaData rfd
JOIN Restaurant r
    ON rfd.restaurant_name = r.RestaurantName
   AND rfd.city = r.City;
GO


INSERT INTO OrderHeader
SELECT DISTINCT
    order_id,
    customer_id,
    TRY_CONVERT(DATE, order_date),
    payment_method,
    delivery_status
FROM RawFoodpandaData;
GO



INSERT INTO OrderDetail (OrderID, DishID, Quantity, Price)
SELECT
    rfd.order_id,
    d.DishID,
    rfd.quantity,
    rfd.price
FROM RawFoodpandaData rfd
JOIN Restaurant r
    ON rfd.restaurant_name = r.RestaurantName
   AND rfd.city = r.City
JOIN Dish d
    ON rfd.dish_name = d.DishName
   AND rfd.category = d.Category
   AND d.RestaurantID = r.RestaurantID;
GO


INSERT INTO CustomerRating
SELECT DISTINCT
    order_id,
    customer_id,
    rating,
    TRY_CONVERT(DATE, rating_date)
FROM RawFoodpandaData;
GO


SELECT 'Customer', COUNT(*) FROM Customer
UNION ALL
SELECT 'Restaurant', COUNT(*) FROM Restaurant
UNION ALL
SELECT 'Dish', COUNT(*) FROM Dish
UNION ALL
SELECT 'OrderHeader', COUNT(*) FROM OrderHeader
UNION ALL
SELECT 'OrderDetail', COUNT(*) FROM OrderDetail
UNION ALL
SELECT 'CustomerRating', COUNT(*) FROM CustomerRating;
GO


USE master;
GO

IF DB_ID('Foodpanda_DW') IS NOT NULL
BEGIN
    ALTER DATABASE Foodpanda_DW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Foodpanda_DW;
END
GO

CREATE DATABASE Foodpanda_DW;
GO

USE Foodpanda_DW;
GO


USE Foodpanda_DW;
GO

CREATE TABLE DimDate (
    DateKey INT PRIMARY KEY,
    FullDate DATE NOT NULL,
    DayNumber INT NOT NULL,
    MonthNumber INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    QuarterNumber INT NOT NULL,
    YearNumber INT NOT NULL,
    DayName VARCHAR(20) NOT NULL,
    WeekNumber INT NOT NULL
);
GO


DECLARE @StartDate DATE = '2024-01-01';
DECLARE @EndDate DATE = '2025-12-31';

WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO DimDate (
        DateKey,
        FullDate,
        DayNumber,
        MonthNumber,
        MonthName,
        QuarterNumber,
        YearNumber,
        DayName,
        WeekNumber
    )
    VALUES (
        CONVERT(INT, CONVERT(VARCHAR(8), @StartDate, 112)),
        @StartDate,
        DAY(@StartDate),
        MONTH(@StartDate),
        DATENAME(MONTH, @StartDate),
        DATEPART(QUARTER, @StartDate),
        YEAR(@StartDate),
        DATENAME(WEEKDAY, @StartDate),
        DATEPART(WEEK, @StartDate)
    );

    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END
GO


SELECT TOP 10 * FROM DimDate;
SELECT COUNT(*) AS DimDateCount FROM DimDate;
GO


CREATE TABLE DimCustomer (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID VARCHAR(50) NOT NULL,
    Gender VARCHAR(20),
    AgeGroup VARCHAR(20),
    City VARCHAR(100),
    SignupDate DATE,
    OrderFrequency VARCHAR(50),
    LastOrderDate DATE,
    LoyaltyPoints INT,
    Churned VARCHAR(10),
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NULL,
    IsCurrent BIT NOT NULL
);
GO


CREATE TABLE DimRestaurant (
    RestaurantKey INT IDENTITY(1,1) PRIMARY KEY,
    RestaurantID INT NOT NULL,
    RestaurantName VARCHAR(200),
    City VARCHAR(100)
);
GO


CREATE TABLE DimDish (
    DishKey INT IDENTITY(1,1) PRIMARY KEY,
    DishID INT NOT NULL,
    DishName VARCHAR(200),
    Category VARCHAR(100)
);
GO


CREATE TABLE DimPaymentDelivery (
    PaymentDeliveryKey INT IDENTITY(1,1) PRIMARY KEY,
    PaymentMethod VARCHAR(50),
    DeliveryStatus VARCHAR(50)
);
GO


CREATE TABLE FactOrders (
    FactOrderKey INT IDENTITY(1,1) PRIMARY KEY,
    OrderID VARCHAR(50) NOT NULL,
    CustomerKey INT NOT NULL,
    RestaurantKey INT NOT NULL,
    DishKey INT NOT NULL,
    PaymentDeliveryKey INT NOT NULL,
    OrderDateKey INT NOT NULL,
    RatingDateKey INT NULL,
    Quantity INT,
    UnitPrice DECIMAL(10,2),
    SalesAmount DECIMAL(12,2),
    Rating INT,
    LoyaltyPoints INT,
    accm_txn_create_time DATETIME NULL,
    accm_txn_complete_time DATETIME NULL,
    txn_process_time_hours DECIMAL(10,2) NULL,
    CONSTRAINT FK_FactOrders_DimCustomer
        FOREIGN KEY (CustomerKey) REFERENCES DimCustomer(CustomerKey),
    CONSTRAINT FK_FactOrders_DimRestaurant
        FOREIGN KEY (RestaurantKey) REFERENCES DimRestaurant(RestaurantKey),
    CONSTRAINT FK_FactOrders_DimDish
        FOREIGN KEY (DishKey) REFERENCES DimDish(DishKey),
    CONSTRAINT FK_FactOrders_DimPaymentDelivery
        FOREIGN KEY (PaymentDeliveryKey) REFERENCES DimPaymentDelivery(PaymentDeliveryKey),
    CONSTRAINT FK_FactOrders_OrderDate
        FOREIGN KEY (OrderDateKey) REFERENCES DimDate(DateKey),
    CONSTRAINT FK_FactOrders_RatingDate
        FOREIGN KEY (RatingDateKey) REFERENCES DimDate(DateKey)
);
GO

INSERT INTO DimCustomer (
    CustomerID,
    Gender,
    AgeGroup,
    City,
    SignupDate,
    OrderFrequency,
    LastOrderDate,
    LoyaltyPoints,
    Churned,
    StartDate,
    EndDate,
    IsCurrent
)
SELECT
    c.CustomerID,
    c.Gender,
    c.AgeGroup,
    c.City,
    c.SignupDate,
    c.OrderFrequency,
    c.LastOrderDate,
    c.LoyaltyPoints,
    c.Churned,
    GETDATE(),
    NULL,
    1
FROM FoodpandaSourceDB.dbo.Customer c;
GO

SELECT TOP 20 * FROM DimCustomer;
SELECT COUNT(*) AS DimCustomerCount FROM DimCustomer;
GO


INSERT INTO DimRestaurant (
    RestaurantID,
    RestaurantName,
    City
)
SELECT
    RestaurantID,
    RestaurantName,
    City
FROM FoodpandaSourceDB.dbo.Restaurant;
GO


SELECT TOP 20 * FROM DimRestaurant;
SELECT COUNT(*) AS DimRestaurantCount FROM DimRestaurant;
GO

INSERT INTO DimDish (
    DishID,
    DishName,
    Category
)
SELECT
    DishID,
    DishName,
    Category
FROM FoodpandaSourceDB.dbo.Dish;
GO


SELECT TOP 20 * FROM DimDish;
SELECT COUNT(*) AS DimDishCount FROM DimDish;
GO

INSERT INTO DimPaymentDelivery (
    PaymentMethod,
    DeliveryStatus
)
SELECT DISTINCT
    PaymentMethod,
    DeliveryStatus
FROM FoodpandaSourceDB.dbo.OrderHeader;
GO

SELECT TOP 20 * FROM DimPaymentDelivery;
SELECT COUNT(*) AS DimPaymentDeliveryCount FROM DimPaymentDelivery;
GO


INSERT INTO FactOrders (
    OrderID,
    CustomerKey,
    RestaurantKey,
    DishKey,
    PaymentDeliveryKey,
    OrderDateKey,
    RatingDateKey,
    Quantity,
    UnitPrice,
    SalesAmount,
    Rating,
    LoyaltyPoints,
    accm_txn_create_time,
    accm_txn_complete_time,
    txn_process_time_hours
)
SELECT
    oh.OrderID,
    dc.CustomerKey,
    dr.RestaurantKey,
    dd.DishKey,
    dpd.PaymentDeliveryKey,
    CONVERT(INT, CONVERT(VARCHAR(8), oh.OrderDate, 112)) AS OrderDateKey,
    CASE
        WHEN cr.RatingDate IS NOT NULL
        THEN CONVERT(INT, CONVERT(VARCHAR(8), cr.RatingDate, 112))
        ELSE NULL
    END AS RatingDateKey,
    od.Quantity,
    od.Price AS UnitPrice,
    od.Quantity * od.Price AS SalesAmount,
    cr.Rating,
    dc.LoyaltyPoints,
    GETDATE() AS accm_txn_create_time,
    NULL AS accm_txn_complete_time,
    NULL AS txn_process_time_hours
FROM FoodpandaSourceDB.dbo.OrderHeader oh
INNER JOIN FoodpandaSourceDB.dbo.OrderDetail od
    ON oh.OrderID = od.OrderID
INNER JOIN FoodpandaSourceDB.dbo.Customer c
    ON oh.CustomerID = c.CustomerID
INNER JOIN DimCustomer dc
    ON c.CustomerID = dc.CustomerID
   AND dc.IsCurrent = 1
INNER JOIN FoodpandaSourceDB.dbo.Dish d
    ON od.DishID = d.DishID
INNER JOIN FoodpandaSourceDB.dbo.Restaurant r
    ON d.RestaurantID = r.RestaurantID
INNER JOIN DimRestaurant dr
    ON r.RestaurantID = dr.RestaurantID
INNER JOIN DimDish dd
    ON d.DishID = dd.DishID
INNER JOIN DimPaymentDelivery dpd
    ON oh.PaymentMethod = dpd.PaymentMethod
   AND oh.DeliveryStatus = dpd.DeliveryStatus
LEFT JOIN FoodpandaSourceDB.dbo.CustomerRating cr
    ON oh.OrderID = cr.OrderID;
GO


SELECT 
    MIN(OrderDate) AS MinOrderDate,
    MAX(OrderDate) AS MaxOrderDate
FROM FoodpandaSourceDB.dbo.OrderHeader;
GO

SELECT 
    MIN(RatingDate) AS MinRatingDate,
    MAX(RatingDate) AS MaxRatingDate
FROM FoodpandaSourceDB.dbo.CustomerRating;
GO

SELECT DISTINCT
    oh.OrderDate,
    CONVERT(INT, CONVERT(VARCHAR(8), oh.OrderDate, 112)) AS MissingOrderDateKey
FROM FoodpandaSourceDB.dbo.OrderHeader oh
LEFT JOIN Foodpanda_DW.dbo.DimDate d
    ON CONVERT(INT, CONVERT(VARCHAR(8), oh.OrderDate, 112)) = d.DateKey
WHERE d.DateKey IS NULL
  AND oh.OrderDate IS NOT NULL
ORDER BY oh.OrderDate;
GO

SELECT DISTINCT
    cr.RatingDate,
    CONVERT(INT, CONVERT(VARCHAR(8), cr.RatingDate, 112)) AS MissingRatingDateKey
FROM FoodpandaSourceDB.dbo.CustomerRating cr
LEFT JOIN Foodpanda_DW.dbo.DimDate d
    ON CONVERT(INT, CONVERT(VARCHAR(8), cr.RatingDate, 112)) = d.DateKey
WHERE d.DateKey IS NULL
  AND cr.RatingDate IS NOT NULL
ORDER BY cr.RatingDate;
GO


USE Foodpanda_DW;
GO

DELETE FROM FactOrders;
GO

DELETE FROM DimDate;
GO

DECLARE @StartDate DATE = '2020-01-01';
DECLARE @EndDate DATE = '2030-12-31';

WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO DimDate (
        DateKey,
        FullDate,
        DayNumber,
        MonthNumber,
        MonthName,
        QuarterNumber,
        YearNumber,
        DayName,
        WeekNumber
    )
    VALUES (
        CONVERT(INT, CONVERT(VARCHAR(8), @StartDate, 112)),
        @StartDate,
        DAY(@StartDate),
        MONTH(@StartDate),
        DATENAME(MONTH, @StartDate),
        DATEPART(QUARTER, @StartDate),
        YEAR(@StartDate),
        DATENAME(WEEKDAY, @StartDate),
        DATEPART(WEEK, @StartDate)
    );

    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END
GO


SELECT MIN(FullDate) AS MinDate, MAX(FullDate) AS MaxDate
FROM DimDate;
GO


INSERT INTO FactOrders (
    OrderID,
    CustomerKey,
    RestaurantKey,
    DishKey,
    PaymentDeliveryKey,
    OrderDateKey,
    RatingDateKey,
    Quantity,
    UnitPrice,
    SalesAmount,
    Rating,
    LoyaltyPoints,
    accm_txn_create_time,
    accm_txn_complete_time,
    txn_process_time_hours
)
SELECT
    oh.OrderID,
    dc.CustomerKey,
    dr.RestaurantKey,
    dd.DishKey,
    dpd.PaymentDeliveryKey,
    odt.DateKey AS OrderDateKey,
    rdt.DateKey AS RatingDateKey,
    od.Quantity,
    od.Price AS UnitPrice,
    od.Quantity * od.Price AS SalesAmount,
    cr.Rating,
    dc.LoyaltyPoints,
    GETDATE() AS accm_txn_create_time,
    NULL AS accm_txn_complete_time,
    NULL AS txn_process_time_hours
FROM FoodpandaSourceDB.dbo.OrderHeader oh
INNER JOIN FoodpandaSourceDB.dbo.OrderDetail od
    ON oh.OrderID = od.OrderID
INNER JOIN FoodpandaSourceDB.dbo.Customer c
    ON oh.CustomerID = c.CustomerID
INNER JOIN DimCustomer dc
    ON c.CustomerID = dc.CustomerID
   AND dc.IsCurrent = 1
INNER JOIN FoodpandaSourceDB.dbo.Dish d
    ON od.DishID = d.DishID
INNER JOIN FoodpandaSourceDB.dbo.Restaurant r
    ON d.RestaurantID = r.RestaurantID
INNER JOIN DimRestaurant dr
    ON r.RestaurantID = dr.RestaurantID
INNER JOIN DimDish dd
    ON d.DishID = dd.DishID
INNER JOIN DimPaymentDelivery dpd
    ON oh.PaymentMethod = dpd.PaymentMethod
   AND oh.DeliveryStatus = dpd.DeliveryStatus
INNER JOIN DimDate odt
    ON oh.OrderDate = odt.FullDate
LEFT JOIN FoodpandaSourceDB.dbo.CustomerRating cr
    ON oh.OrderID = cr.OrderID
LEFT JOIN DimDate rdt
    ON cr.RatingDate = rdt.FullDate;
GO


SELECT COUNT(*) AS FactOrdersCount
FROM FactOrders;
GO

SELECT TOP 20 *
FROM FactOrders;
GO


SELECT 'DimDate' AS TableName, COUNT(*) AS RowCounts FROM DimDate
UNION ALL
SELECT 'DimCustomer', COUNT(*) FROM DimCustomer
UNION ALL
SELECT 'DimRestaurant', COUNT(*) FROM DimRestaurant
UNION ALL
SELECT 'DimDish', COUNT(*) FROM DimDish
UNION ALL
SELECT 'DimPaymentDelivery', COUNT(*) FROM DimPaymentDelivery
UNION ALL
SELECT 'FactOrders', COUNT(*) FROM FactOrders;
GO


USE master;
GO

IF DB_ID('Foodpanda_Staging') IS NOT NULL
BEGIN
    ALTER DATABASE Foodpanda_Staging SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Foodpanda_Staging;
END
GO

CREATE DATABASE Foodpanda_Staging;
GO

USE Foodpanda_Staging;
GO


USE Foodpanda_Staging;
GO

CREATE TABLE StgCustomer (
    CustomerID VARCHAR(50),
    Gender VARCHAR(20),
    AgeGroup VARCHAR(20),
    City VARCHAR(100),
    SignupDate DATE,
    OrderFrequency VARCHAR(50),
    LastOrderDate DATE,
    LoyaltyPoints INT,
    Churned VARCHAR(10)
);
GO

CREATE TABLE StgRestaurant (
    RestaurantID INT,
    RestaurantName VARCHAR(200),
    City VARCHAR(100)
);
GO

CREATE TABLE StgDish (
    DishID INT,
    DishName VARCHAR(200),
    Category VARCHAR(100),
    RestaurantID INT
);
GO

CREATE TABLE StgOrderHeader (
    OrderID VARCHAR(50),
    CustomerID VARCHAR(50),
    OrderDate DATE,
    PaymentMethod VARCHAR(50),
    DeliveryStatus VARCHAR(50)
);
GO

CREATE TABLE StgOrderDetail (
    OrderDetailID INT,
    OrderID VARCHAR(50),
    DishID INT,
    Quantity INT,
    Price DECIMAL(10,2)
);
GO

CREATE TABLE StgCustomerRating (
    RatingID INT,
    OrderID VARCHAR(50),
    CustomerID VARCHAR(50),
    Rating INT,
    RatingDate DATE
);
GO

CREATE TABLE StgCustomerProfileExtra (
    CustomerID VARCHAR(50),
    City VARCHAR(100),
    Gender VARCHAR(20),
    AgeGroup VARCHAR(20),
    ChurnedStatus VARCHAR(10),
    LoyaltyPoints INT
);
GO



USE Foodpanda_Staging;
GO

SELECT 'StgCustomer' AS TableName, COUNT(*) AS RowCounts FROM StgCustomer
UNION ALL
SELECT 'StgRestaurant', COUNT(*) FROM StgRestaurant
UNION ALL
SELECT 'StgDish', COUNT(*) FROM StgDish
UNION ALL
SELECT 'StgOrderHeader', COUNT(*) FROM StgOrderHeader
UNION ALL
SELECT 'StgOrderDetail', COUNT(*) FROM StgOrderDetail
UNION ALL
SELECT 'StgCustomerRating', COUNT(*) FROM StgCustomerRating
UNION ALL
SELECT 'StgCustomerProfileExtra', COUNT(*) FROM StgCustomerProfileExtra;
GO


USE Foodpanda_DW;
GO

SELECT 'DimCustomer' AS TableName, COUNT(*) AS RowCounts FROM DimCustomer
UNION ALL
SELECT 'DimRestaurant', COUNT(*) FROM DimRestaurant
UNION ALL
SELECT 'DimDish', COUNT(*) FROM DimDish
UNION ALL
SELECT 'DimPaymentDelivery', COUNT(*) FROM DimPaymentDelivery
UNION ALL
SELECT 'FactOrders', COUNT(*) FROM FactOrders;
GO


USE Foodpanda_DW;
GO

USE Foodpanda_DW;
GO

SELECT TOP 5000
    OrderID,
    accm_txn_create_time,
    accm_txn_complete_time,
    txn_process_time_hours
FROM FactOrders;
GO


USE Foodpanda_Staging;
GO

CREATE TABLE StgFactOrdersCompletion (
    OrderID VARCHAR(50),
    accm_txn_complete_time DATETIME
);
GO


SELECT TOP 20
    OrderID,
    accm_txn_create_time,
    accm_txn_complete_time,
    txn_process_time_hours
FROM Foodpanda_DW.dbo.FactOrders
WHERE accm_txn_complete_time IS NOT NULL;
