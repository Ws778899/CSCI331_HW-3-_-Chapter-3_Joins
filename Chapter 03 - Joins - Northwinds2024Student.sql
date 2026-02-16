---------------------------------------------------------------------
-- T-SQL Fundamentals (adapted)
-- Chapter 03 - Joins  (Fixed for Northwinds2024Student)
-- Original author: Itzik Ben-Gan
---------------------------------------------------------------------

/*
Notes on the adaptation:
- Database: USE Northwinds2024Student
- Schemas: use dbo.*
- Column mapping (typical Northwind-style):
  Customers:  CustomerId, CustomerCompanyName
  Employees:  EmployeeId, FirstName, LastName
  Orders:     OrderId, CustomerId, EmployeeId, OrderDate
  OrderDetails: OrderId, ProductId, Quantity
- If your Northwinds2024Student uses slightly different names (e.g., [Order Details]),
  adjust the table name accordingly.
*/

---------------------------------------------------------------------
-- CROSS Joins
---------------------------------------------------------------------
USE Northwinds2024Student;
GO

-- SQL-92
SELECT C.CustomerId, E.EmployeeId
FROM dbo.Customers AS C
  CROSS JOIN dbo.Employees AS E;

-- SQL-89
SELECT C.CustomerId, E.EmployeeId
FROM dbo.Customers AS C, dbo.Employees AS E;

-- Self Cross-Join
SELECT
  E1.EmployeeId, E1.EmployeeFirstName, E1.EmployeeLastName,
  E2.EmployeeId, E2.EmployeeFirstName, E2.EmployeeLastName
FROM dbo.Employees AS E1
  CROSS JOIN dbo.Employees AS E2;

---------------------------------------------------------------------
-- All numbers from 1 - 1000 (Digits helper)
---------------------------------------------------------------------

DROP TABLE IF EXISTS dbo.Digits;
GO

CREATE TABLE dbo.Digits(digit INT NOT NULL PRIMARY KEY);
GO

INSERT INTO dbo.Digits(digit)
  VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);
GO

SELECT digit FROM dbo.Digits;

-- All numbers from 1 - 1000
SELECT D3.digit * 100 + D2.digit * 10 + D1.digit + 1 AS n
FROM         dbo.Digits AS D1
  CROSS JOIN dbo.Digits AS D2
  CROSS JOIN dbo.Digits AS D3
ORDER BY n;

---------------------------------------------------------------------
-- INNER Joins
---------------------------------------------------------------------

-- SQL-92
SELECT E.EmployeeId, E.EmployeeFirstName, E.EmployeeLastName, O.OrderId
FROM dbo.Employees AS E
  INNER JOIN dbo.Orders AS O
    ON E.EmployeeId = O.EmployeeId;

-- SQL-89
SELECT E.EmployeeId, E.EmployeeFirstName, E.EmployeeLastName, O.OrderId
FROM dbo.Employees AS E, dbo.Orders AS O
WHERE E.EmployeeId = O.EmployeeId;

-- Inner Join Safety (this would be a Cartesian product; keep commented)
/*
SELECT E.EmployeeId, E.EmployeeFirstName, E.EmployeeLastName, O.OrderId
FROM dbo.Employees AS E
  INNER JOIN dbo.Orders AS O;
*/

-- Demonstration of a Cartesian product (also keep commented unless intended)
/*
SELECT E.EmployeeId, E.EmployeeFirstName, E.EmployeeLastName, O.OrderId
FROM dbo.Employees AS E, dbo.Orders AS O;
*/

---------------------------------------------------------------------
-- More Join Examples
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Composite Joins (OrderDetails + Audit table)
---------------------------------------------------------------------

/*
Northwind order details usually has a composite key (OrderId, ProductId).
We'll create dbo.OrderDetailsAudit with a composite FK to dbo.OrderDetails.
*/

DROP TABLE IF EXISTS dbo.OrderDetailsAudit;
GO

CREATE TABLE dbo.OrderDetailsAudit
(
  lsn        INT NOT NULL IDENTITY(1,1),
  OrderId    INT NOT NULL,
  ProductId  INT NOT NULL,
  dt         DATETIME NOT NULL,
  loginname  sysname NOT NULL,
  columnname sysname NOT NULL,
  oldval     SQL_VARIANT NULL,
  newval     SQL_VARIANT NULL,
  CONSTRAINT PK_OrderDetailsAudit PRIMARY KEY(lsn),
  CONSTRAINT FK_OrderDetailsAudit_OrderDetails
    FOREIGN KEY(OrderId, ProductId)
    REFERENCES Sales.OrderDetail(OrderId, ProductId)
);
GO

SELECT
  OD.OrderId, OD.ProductId, OD.Quantity,
  ODA.dt, ODA.loginname, ODA.oldval, ODA.newval
FROM dbo.OrderDetails AS OD
  INNER JOIN dbo.OrderDetailsAudit AS ODA
    ON OD.OrderId = ODA.OrderId
   AND OD.ProductId = ODA.ProductId
WHERE ODA.columnname = N'Quantity';

---------------------------------------------------------------------
-- Non-Equi Joins
---------------------------------------------------------------------

-- Unique pairs of employees
SELECT
  E1.EmployeeId, E1.EmployeeFirstName, E1.EmployeeLastName,
  E2.EmployeeId, E2.EmployeeFirstName, E2.EmployeeLastName
FROM dbo.Employees AS E1
  INNER JOIN dbo.Employees AS E2
    ON E1.EmployeeId < E2.EmployeeId;

---------------------------------------------------------------------
-- Multi-Join Queries
---------------------------------------------------------------------

SELECT
  C.CustomerId, C.CustomerCompanyName, O.OrderId,
  OD.ProductId, OD.Quantity
FROM dbo.Customers AS C
  INNER JOIN dbo.Orders AS O
    ON C.CustomerId = O.CustomerId
  INNER JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId;

---------------------------------------------------------------------
-- Outer joins, described
---------------------------------------------------------------------

-- Customers and their orders, including customers with no orders
SELECT C.CustomerId, C.CustomerCompanyName, O.OrderId
FROM dbo.Customers AS C
  LEFT OUTER JOIN dbo.Orders AS O
    ON C.CustomerId = O.CustomerId;

-- Customers with no orders
SELECT C.CustomerId, C.CustomerCompanyName
FROM dbo.Customers AS C
  LEFT OUTER JOIN dbo.Orders AS O
    ON C.CustomerId = O.CustomerId
WHERE O.OrderId IS NULL;

---------------------------------------------------------------------
-- Including Missing Values (generate dates + outer join)
---------------------------------------------------------------------

/*
TSQLV6 uses dbo.Nums; Northwinds2024Student often doesn't.
We'll generate numbers on the fly using dbo.Digits (must exist from above).
Date range: 2020-01-01 to 2022-12-31
*/

WITH Nums AS
(
  SELECT TOP (DATEDIFF(day, '20200101', '20221231') + 1)
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
  FROM dbo.Digits AS D1
  CROSS JOIN dbo.Digits AS D2
  CROSS JOIN dbo.Digits AS D3
  CROSS JOIN dbo.Digits AS D4
)
SELECT DATEADD(day, n-1, CAST('20200101' AS date)) AS orderdate
FROM Nums
ORDER BY orderdate;

WITH Nums AS
(
  SELECT TOP (DATEDIFF(day, '20200101', '20221231') + 1)
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
  FROM dbo.Digits AS D1
  CROSS JOIN dbo.Digits AS D2
  CROSS JOIN dbo.Digits AS D3
  CROSS JOIN dbo.Digits AS D4
)
SELECT
  DATEADD(day, Nums.n - 1, CAST('20200101' AS date)) AS orderdate,
  O.OrderId, O.CustomerId, O.EmployeeId
FROM Nums
  LEFT OUTER JOIN dbo.Orders AS O
    ON DATEADD(day, Nums.n - 1, CAST('20200101' AS date)) = CAST(O.OrderDate AS date)
ORDER BY orderdate;

---------------------------------------------------------------------
-- Filtering Attributes from Non-Preserved Side of Outer Join
---------------------------------------------------------------------

/*
If you put the filter in WHERE, it turns the LEFT JOIN effectively into an INNER JOIN.
Keep it here intentionally to match the chapter example.
*/

SELECT C.CustomerId, C.CustomerCompanyName, O.OrderId, O.OrderDate
FROM dbo.Customers AS C
  LEFT OUTER JOIN dbo.Orders AS O
    ON C.CustomerId = O.CustomerId
WHERE O.OrderDate >= '20220101';

---------------------------------------------------------------------
-- Using Outer Joins in a Multi-Join Query
---------------------------------------------------------------------

-- This returns only customers that have orders that have order details
SELECT C.CustomerId, O.OrderId, OD.ProductId, OD.Quantity
FROM dbo.Customers AS C
  LEFT OUTER JOIN dbo.Orders AS O
    ON C.CustomerId = O.CustomerId
  INNER JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId;

-- Option 1: use outer join all along
SELECT C.CustomerId, O.OrderId, OD.ProductId, OD.Quantity
FROM dbo.Customers AS C
  LEFT OUTER JOIN dbo.Orders AS O
    ON C.CustomerId = O.CustomerId
  LEFT OUTER JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId;

-- Option 2: change join order (RIGHT JOIN)
SELECT C.CustomerId, O.OrderId, OD.ProductId, OD.Quantity
FROM dbo.Orders AS O
  INNER JOIN dbo.OrderDetails AS OD
    ON O.OrderId = OD.OrderId
  RIGHT OUTER JOIN dbo.Customers AS C
    ON O.CustomerId = C.CustomerId;

-- Option 3: use parentheses
SELECT C.CustomerId, O.OrderId, OD.ProductId, OD.Quantity
FROM dbo.Customers AS C
  LEFT OUTER JOIN
      (dbo.Orders AS O
         INNER JOIN dbo.OrderDetails AS OD
           ON O.OrderId = OD.OrderId)
    ON C.CustomerId = O.CustomerId;

---------------------------------------------------------------------
-- Using the COUNT Aggregate with Outer Joins
---------------------------------------------------------------------

SELECT C.CustomerId, COUNT(*) AS numorders
FROM dbo.Customers AS C
  LEFT OUTER JOIN dbo.Orders AS O
    ON C.CustomerId = O.CustomerId
GROUP BY C.CustomerId;

SELECT C.CustomerId, COUNT(O.OrderId) AS numorders
FROM dbo.Customers AS C
  LEFT OUTER JOIN dbo.Orders AS O
    ON C.CustomerId = O.CustomerId
GROUP BY C.CustomerId;
