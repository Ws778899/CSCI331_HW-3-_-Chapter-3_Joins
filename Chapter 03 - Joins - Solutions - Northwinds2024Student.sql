---------------------------------------------------------------------
-- T-SQL Fundamentals Fourth Edition
-- Chapter 03 - Joins
-- Solutions (modified for Northwinds2024Student)
--  Original author: Itzik Ben-Gan
--  Adaptation: Updated database context + object/column names to match Northwinds2024Student
---------------------------------------------------------------------

USE Northwinds2024Student;
GO

/* 
NOTE ABOUT ORDER DETAILS TABLE NAME
-----------------------------------
In many Northwind-style databases, the order-details table is named either:
  - dbo.[Order Details]   (with a space), OR
  - dbo.OrderDetails
This script uses dbo.[Order Details]. If your database uses dbo.OrderDetails,
replace dbo.[Order Details] with dbo.OrderDetails below.
*/

---------------------------------------------------------------------
-- 1
-- 1-1
-- Write a query that generates 5 copies out of each employee row
-- Tables involved: Northwinds2024Student database, dbo.Employees
---------------------------------------------------------------------

-- Solution
SELECT
  E.EmployeeID AS empid,
  E.EmployeeFirstName  AS EmployeeFirstName,
  E.EmployeeLastName   AS EmployeeLastName,
  N.n
FROM dbo.Employees AS E
CROSS JOIN (VALUES (1),(2),(3),(4),(5)) AS N(n)
ORDER BY N.n, E.EmployeeID;
GO

---------------------------------------------------------------------
-- 1-2
-- Write a query that returns a row for each employee and day
-- in the range June 12, 2022 through June 16, 2022.
-- Tables involved: Northwinds2024Student database, dbo.Employees
---------------------------------------------------------------------

-- Solution
SELECT
  E.EmployeeID AS empid,
  DATEADD(day, D.n, CONVERT(date, '20220612', 112)) AS dt
FROM dbo.Employees AS E
CROSS JOIN (VALUES (0),(1),(2),(3),(4)) AS D(n)  -- 5 days: 2022-06-12 .. 2022-06-16
ORDER BY E.EmployeeID, dt;
GO

---------------------------------------------------------------------
-- 2
-- Explain what's wrong in the following query and provide a correct alternative
-- (Original issue: references Customers/Orders aliases that don't exist.)
-- Tables involved: Northwinds2024Student database, dbo.Customers, dbo.Orders
---------------------------------------------------------------------

-- Correct solution (using table names without aliases)
SELECT
  Customers.CustomerID  AS custid,
  Customers.CustomerCompanyName AS CustomerCompanyName,
  Orders.OrderID        AS orderid,
  Orders.OrderDate      AS orderdate
FROM dbo.Customers
INNER JOIN dbo.Orders
  ON Customers.CustomerID = Orders.CustomerID;
GO

-- Correct solution (using aliases)
SELECT
  C.CustomerID  AS custid,
  C.CustomerCompanyName AS CustomerCompanyName,
  O.OrderID     AS orderid,
  O.OrderDate   AS orderdate
FROM dbo.Customers AS C
INNER JOIN dbo.Orders AS O
  ON C.CustomerID = O.CustomerID;
GO

---------------------------------------------------------------------
-- 4
-- Return USA customers, and for each return the total number of orders
-- and total quantities in those orders.
-- Tables involved: dbo.Customers, dbo.Orders, dbo.[Order Details]
---------------------------------------------------------------------

-- Solution
-- Solution
SELECT
  C.CustomerID AS custid,
  COUNT(DISTINCT O.OrderID) AS numorders,
  SUM(OD.Quantity) AS totalqty
FROM dbo.Customers AS C
INNER JOIN Sales.[Order] AS O
  ON O.CustomerID = C.CustomerID
INNER JOIN Sales.OrderDetail AS OD
  ON OD.OrderID = O.OrderID
WHERE C.CustomerCountry = N'USA'
GROUP BY C.CustomerID;
GO

---------------------------------------------------------------------
-- 3 / 4 (Customers and their orders)
-- Return customers and their respective orders (outer join)
-- Tables involved: dbo.Customers, dbo.Orders
---------------------------------------------------------------------

-- Solution
SELECT
  C.CustomerID  AS custid,
  C.CustomerCompanyName AS CustomerCompanyName,
  O.OrderID     AS orderid,
  O.OrderDate   AS orderdate
FROM dbo.Customers AS C
LEFT OUTER JOIN dbo.Orders AS O
  ON O.CustomerID = C.CustomerID;
GO

---------------------------------------------------------------------
-- 5
-- Return customers who placed no orders
-- Tables involved: dbo.Customers, dbo.Orders
---------------------------------------------------------------------

-- Solution
SELECT
  C.CustomerID  AS custid,
  C.CustomerCompanyName AS CustomerCompanyName
FROM dbo.Customers AS C
LEFT OUTER JOIN dbo.Orders AS O
  ON O.CustomerID = C.CustomerID
WHERE O.OrderID IS NULL;
GO

---------------------------------------------------------------------
-- 6
-- Return customers with orders placed on Feb 12, 2022 along with their orders
-- Tables involved: dbo.Customers, dbo.Orders
---------------------------------------------------------------------

-- Solution
SELECT
  C.CustomerID  AS custid,
  C.CustomerCompanyName AS CustomerCompanyName,
  O.OrderID     AS orderid,
  O.OrderDate   AS orderdate
FROM dbo.Customers AS C
INNER JOIN dbo.Orders AS O
  ON O.CustomerID = C.CustomerID
WHERE O.OrderDate = CONVERT(date, '20220212', 112);
GO

---------------------------------------------------------------------
-- 7
-- Return all customers, but match them with their respective orders
-- only if they were placed on February 12, 2022
---------------------------------------------------------------------

-- Solution
SELECT
  C.CustomerID  AS custid,
  C.CustomerCompanyName AS CustomerCompanyName,
  O.OrderID     AS orderid,
  O.OrderDate   AS orderdate
FROM dbo.Customers AS C
LEFT OUTER JOIN dbo.Orders AS O
  ON O.CustomerID = C.CustomerID
 AND O.OrderDate  = CONVERT(date, '20220212', 112);
GO

---------------------------------------------------------------------
-- 8
-- Why the following query isn't a correct solution for exercise 7
-- (Because the WHERE clause filters out customers who have orders, but not on 2022-02-12.)
---------------------------------------------------------------------

SELECT
  C.CustomerID  AS custid,
  C.CustomerCompanyName AS CustomerCompanyName,
  O.OrderID     AS orderid,
  O.OrderDate   AS orderdate
FROM dbo.Customers AS C
LEFT OUTER JOIN dbo.Orders AS O
  ON O.CustomerID = C.CustomerID
WHERE O.OrderDate = CONVERT(date, '20220212', 112)
   OR O.OrderID IS NULL;
GO

---------------------------------------------------------------------
-- 9
-- Return all customers, and for each return a Yes/No value
-- depending on whether the customer placed an order on Feb 12, 2022
---------------------------------------------------------------------

-- Solution
SELECT DISTINCT
  C.CustomerID  AS custid,
  C.CustomerCompanyName AS CustomerCompanyName,
  CASE WHEN O.OrderID IS NOT NULL THEN 'Yes' ELSE 'No' END AS HasOrderOn20220212
FROM dbo.Customers AS C
LEFT OUTER JOIN dbo.Orders AS O
  ON O.CustomerID = C.CustomerID
 AND O.OrderDate  = CONVERT(date, '20220212', 112);
GO
