CREATE DATABASE PortfolioInventoryDB;
GO
USE PortfolioInventoryDB;
GO

-- 1. Categories Table
CREATE TABLE Categories (
    category_id INT PRIMARY KEY IDENTITY(1,1),
    category_name VARCHAR(100) NOT NULL UNIQUE
);

-- 2. Suppliers Table
CREATE TABLE Suppliers (
    supplier_id INT PRIMARY KEY IDENTITY(1,1),
    supplier_name VARCHAR(100) NOT NULL,
    contact_name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100)
);

-- 3. Products Table
CREATE TABLE Products (
    product_id INT PRIMARY KEY IDENTITY(1,1),
    product_name VARCHAR(150) NOT NULL,
    category_id INT FOREIGN KEY REFERENCES Categories(category_id),
    supplier_id INT FOREIGN KEY REFERENCES Suppliers(supplier_id),
    sku VARCHAR(50) UNIQUE NOT NULL,
    price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
    stock_quantity INT DEFAULT 0 CHECK (stock_quantity >= 0),
    reorder_level INT DEFAULT 15
);

-- 4. Stock Transactions Ledger Table
CREATE TABLE StockTransactions (
    transaction_id INT PRIMARY KEY IDENTITY(1,1),
    product_id INT FOREIGN KEY REFERENCES Products(product_id),
    transaction_type VARCHAR(10) CHECK (transaction_type IN ('IN', 'OUT')),
    quantity INT NOT NULL CHECK (quantity > 0),
    transaction_date DATETIME DEFAULT GETDATE(),
    notes VARCHAR(255)
);

-- Insert Base Categories
INSERT INTO Categories (category_name) VALUES 
('Electronics'), ('Office Supplies'), ('Furniture'), ('Apparel'), ('Breakroom & Janitorial');

-- Insert Base Suppliers
INSERT INTO Suppliers (supplier_name, contact_name, phone, email) VALUES 
('TechDistro Corp', 'Alice Smith', '555-0192', 'orders@techdistro.com'),
('Global Office Ltd', 'Bob Jones', '555-0143', 'sales@globaloffice.com'),
('Comfort Logistics', 'Charlie Brown', '555-0188', 'charlie@comfortlog.com'),
('Janitorial Express', 'Dana White', '555-0122', 'supply@janitorialex.com');

-- Loop to generate 300 unique products
DECLARE @Counter INT = 1;
DECLARE @RandomCategory INT;
DECLARE @RandomSupplier INT;
DECLARE @RandomPrice DECIMAL(10,2);
DECLARE @RandomStock INT;

WHILE @Counter <= 300
BEGIN
    -- Randomize values using ABS(CHECKSUM(NEWID()))
    SET @RandomCategory = (ABS(CHECKSUM(NEWID())) % 5) + 1; -- 1 to 5
    SET @RandomSupplier = (ABS(CHECKSUM(NEWID())) % 4) + 1; -- 1 to 4
    SET @RandomPrice = CAST((ABS(CHECKSUM(NEWID())) % 480) + 19.99 AS DECIMAL(10,2)); -- Prices between $19.99 and $499.99
    SET @RandomStock = (ABS(CHECKSUM(NEWID())) % 250); -- Stock between 0 and 249

    INSERT INTO Products (product_name, category_id, supplier_id, sku, price, stock_quantity, reorder_level)
    VALUES (
        'Product Model ' + CAST(@Counter AS VARCHAR(10)),
        @RandomCategory,
        @RandomSupplier,
        'SKU-' + UPPER(SUBSTRING(CAST(NEWID() AS VARCHAR(50)), 1, 8)),
        @RandomPrice,
        @RandomStock,
        20 -- Reorder triggers when stock is 20 or below
    );

    SET @Counter = @Counter + 1;
END;

CREATE TRIGGER trg_UpdateStock
ON StockTransactions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET p.stock_quantity = p.stock_quantity + 
        CASE 
            WHEN i.transaction_type = 'IN' THEN i.quantity
            WHEN i.transaction_type = 'OUT' THEN -i.quantity
        END
    FROM Products p
    INNER JOIN inserted i ON p.product_id = i.product_id;
END;

DECLARE @TxCounter INT = 1;
DECLARE @RandomProduct INT;
DECLARE @RandomType VARCHAR(10);
DECLARE @RandomQty INT;

WHILE @TxCounter <= 500
BEGIN
    SET @RandomProduct = (ABS(CHECKSUM(NEWID())) % 300) + 1; -- Picks a product from 1 to 300
    SET @RandomQty = (ABS(CHECKSUM(NEWID())) % 15) + 1; -- Quantity between 1 and 15
    
    -- 70% chance it's a sale (OUT), 30% chance it's a restock (IN)
    IF (ABS(CHECKSUM(NEWID())) % 10) < 7
        SET @RandomType = 'OUT';
    ELSE
        SET @RandomType = 'IN';

    -- Avoid entering a transaction that forces stock below 0 (handled by table constraint)
    IF @RandomType = 'OUT' AND (SELECT stock_quantity FROM Products WHERE product_id = @RandomProduct) < @RandomQty
    BEGIN
        SET @RandomType = 'IN'; -- Flip to a restock if it would break the constraint
    END

    INSERT INTO StockTransactions (product_id, transaction_type, quantity, transaction_date, notes)
    VALUES (
        @RandomProduct,
        @RandomType,
        @RandomQty,
        DATEADD(day, -(ABS(CHECKSUM(NEWID())) % 90), GETDATE()), -- Random date within the last 90 days
        CASE WHEN @RandomType = 'OUT' THEN 'Customer Order Fulfillment' ELSE 'Vendor Restock Batch' END
    );

    SET @TxCounter = @TxCounter + 1;
END;

-- 1. CRITICAL LOW STOCK WARNING
-- Finds items that dropped below reorder thresholds, sorted by most urgent.
SELECT TOP 10
    p.product_name,
    c.category_name,
    p.stock_quantity,
    p.reorder_level,
    s.supplier_name
FROM Products p
JOIN Categories c ON p.category_id = c.category_id
JOIN Suppliers s ON p.supplier_id = s.supplier_id
WHERE p.stock_quantity <= p.reorder_level
ORDER BY p.stock_quantity ASC;

-- 2. HIGH-VALUE INVENTORY MANAGEMENT
-- Shows the executive team where capital is tied up.
SELECT 
    c.category_name,
    COUNT(p.product_id) AS total_product_lines,
    SUM(p.stock_quantity) AS physical_items_in_warehouse,
    FORMAT(SUM(p.stock_quantity * p.price), 'C') AS total_asset_value
FROM Products p
JOIN Categories c ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY SUM(p.stock_quantity * p.price) DESC;

-- 3. MOVING PRODUCT REPORT (TRANSACTION VOLUME)
-- Ranks which products have the highest transaction volume over the last 90 days.
SELECT TOP 10
    p.product_name,
    COUNT(t.transaction_id) AS total_transaction_events,
    SUM(CASE WHEN t.transaction_type = 'OUT' THEN t.quantity ELSE 0 END) AS total_units_sold
FROM StockTransactions t
JOIN Products p ON t.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_units_sold DESC;

-- Calculating Average Price and Total Items across the whole database
SELECT 
    COUNT(*) AS total_products,
    AVG(price) AS average_product_price,
    SUM(stock_quantity) AS total_items_on_hand
FROM Products;

SELECT 
    p.product_id,
    p.product_name,
    c.category_name,
    s.supplier_name,
    p.price,
    p.stock_quantity,
    -- Basic Math Computation
    (p.price * p.stock_quantity) AS inventory_value,
    -- Conditional Computation (CASE statement)
    CASE 
        WHEN p.stock_quantity = 0 THEN 'OUT OF STOCK'
        WHEN p.stock_quantity <= p.reorder_level THEN 'REORDER IMMEDIATELY'
        ELSE 'HEALTHY STOCK'
    END AS stock_status
FROM Products p
INNER JOIN Categories c ON p.category_id = c.category_id
INNER JOIN Suppliers s ON p.supplier_id = s.supplier_id
ORDER BY inventory_value DESC;

SELECT 
    s.supplier_name,
    COUNT(p.product_id) AS total_products_supplied,
    FORMAT(AVG(p.price), 'C') AS average_item_cost,
    SUM(p.stock_quantity) AS total_items_in_warehouse,
    FORMAT(SUM(p.price * p.stock_quantity), 'C') AS total_supplier_value
FROM Suppliers s
LEFT JOIN Products p ON s.supplier_id = p.supplier_id
GROUP BY s.supplier_name
HAVING COUNT(p.product_id) > 5 -- Advanced Filtering
ORDER BY total_items_in_warehouse DESC;

SELECT 
    product_name,
    sku,
    price,
    (SELECT AVG(price) FROM Products) AS global_average_price,
    (price - (SELECT AVG(price) FROM Products)) AS amount_above_average
FROM Products
WHERE price > (SELECT AVG(price) FROM Products)
ORDER BY price DESC;

WITH RankedProducts AS (
    SELECT 
        c.category_name,
        p.product_name,
        p.price,
        p.stock_quantity,
        DENSE_RANK() OVER (PARTITION BY c.category_id ORDER BY p.price DESC) AS price_rank
    FROM Products p
    JOIN Categories c ON p.category_id = c.category_id
)
SELECT 
    category_name,
    product_name,
    price,
    stock_quantity,
    price_rank
FROM RankedProducts
WHERE price_rank <= 3; -- Filters for only the top 3 per category

SELECT 
    DATENAME(month, transaction_date) AS movement_month,
    transaction_type,
    COUNT(transaction_id) AS total_transaction_events,
    SUM(quantity) AS total_units_moved
FROM StockTransactions
GROUP BY MONTH(transaction_date), DATENAME(month, transaction_date), transaction_type
ORDER BY MONTH(transaction_date) DESC, transaction_type;

SELECT TOP 15
    p.product_name,
    p.stock_quantity AS current_stock,
    SUM(CASE WHEN t.transaction_type = 'OUT' THEN t.quantity ELSE 0 END) AS total_units_sold,
    -- Compute a ratio: (Units Sold / (Current Stock + 1 to prevent dividing by zero))
    CAST(SUM(CASE WHEN t.transaction_type = 'OUT' THEN t.quantity ELSE 0 END) AS DECIMAL(10,2)) / 
    NULLIF(p.stock_quantity, 0) AS sales_to_stock_ratio
FROM Products p
LEFT JOIN StockTransactions t ON p.product_id = t.product_id
GROUP BY p.product_id, p.product_name, p.stock_quantity
ORDER BY sales_to_stock_ratio DESC;