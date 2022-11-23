CREATE TABLE Markets (
    MarketID int NOT NULL identity(1,1),
    Market varchar(30) NOT NULL UNIQUE,
    PRIMARY KEY (MarketID)
);

CREATE TABLE Countries (
    CountryID int NOT NULL identity(1,1),
    Country varchar(30) NOT NULL UNIQUE,
	MarketID int NOT NULL,
    PRIMARY KEY (CountryID),
	FOREIGN KEY (MarketID) REFERENCES Markets(MarketID)
);

CREATE TABLE Cities (
    CityID int NOT NULL identity(1,1),
    City varchar(50) NOT NULL UNIQUE,
    PRIMARY KEY (CityID)
);
CREATE TABLE PostalCodes (
    PostalCodeID int NOT NULL identity(1,1),
    PostalCode varchar(8) NOT NULL UNIQUE,
    PRIMARY KEY (PostalCodeID)
);
CREATE TABLE States (
    StateID int NOT NULL identity(1,1),
    State varchar(30) NOT NULL UNIQUE,
    PRIMARY KEY (StateID)
);
CREATE TABLE Locations (
    LocationID int NOT NULL identity(1,1),
	CityID int NOT NULL,
	CountryID int NOT NULL,
	StateID int NOT NULL,
	PostalCodeID int NULL,
    PRIMARY KEY (LocationID),
	FOREIGN KEY (CityID) REFERENCES Cities(CityID),
	FOREIGN KEY (CountryID) REFERENCES Countries(CountryID),
	FOREIGN KEY (StateID) REFERENCES States(StateID),
	FOREIGN KEY (PostalCodeID) REFERENCES PostalCodes(PostalCodeID)
);
CREATE TABLE Segments (
    SegmentID int NOT NULL identity(1,1),
    Segment varchar(30) NOT NULL UNIQUE,
    PRIMARY KEY (SegmentID)
);
CREATE TABLE Customers (
    CustomerID varchar(50) NOT NULL,
    Name varchar(50) NOT NULL,
	SegmentID int NOT NULL,
    PRIMARY KEY (CustomerID),
	FOREIGN KEY (SegmentID) REFERENCES Segments(SegmentID)
);
CREATE TABLE ProductCategories (
    ProductCategoryID int NOT NULL identity(1,1),
    Category varchar(50) NOT NULL UNIQUE,
    PRIMARY KEY (ProductCategoryID)
);
CREATE TABLE ProductSubcategories (
    ProductSubcatID int NOT NULL identity(1,1),
    Sybcategory varchar(50) NOT NULL,
	ProductCategoryID int NOT NULL,
    PRIMARY KEY (ProductSubcatID),
	FOREIGN KEY (ProductCategoryID) REFERENCES ProductCategories(ProductCategoryID)
);
CREATE TABLE Products (
    ProductID varchar(50) NOT NULL,
    Name varchar(100) NOT NULL,
	ProductSubcatID int NOT NULL,
    PRIMARY KEY (ProductID),
	FOREIGN KEY (ProductSubcatID) REFERENCES ProductSubcategories(ProductSubcatID)
);
CREATE TABLE ShipmentsMode (
    ShipmentModeID int NOT NULL identity(1,1),
    ShipmentMode varchar(32) NOT NULL UNIQUE,
    PRIMARY KEY (ShipmentModeID)
);

CREATE TABLE Orders (
    OrderID varchar(50) NOT NULL,
	CustomerID varchar(50) NOT NULL,
	LocationID int NOT NULL,
	ShipmentID int NOT NULL,
	ShipmentModeID int NOT NULL,
	OrderDate date NOT NULL,
	ShipDate date NOT NULL,
    PRIMARY KEY (OrderID),
	FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
	FOREIGN KEY (LocationID) REFERENCES Locations(LocationID),
	FOREIGN KEY (ShipmentModeID) REFERENCES ShipmentsMode(ShipmentModeID)
);
CREATE TABLE OrderProducts (
    OrderProductID int NOT NULL identity(1,1),
	OrderID varchar(50) NOT NULL,
	ProductID varchar(50) NOT NULL,
	Sales smallmoney NOT NULL,
	Quantity int NOT NULL CHECK (Quantity > 0),
	Discount float NOT NULL CHECK (Discount >= 0),
	Shipping_cost smallmoney NOT NULL,
	Profit smallmoney NOT NULL,
    PRIMARY KEY (OrderProductID),
	FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
	FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

/* stworzenie procedury dodania zamowienia*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(SELECT 1 FROM OrderDB.sys.procedures p WHERE Name = 'dodaj_zamowienie')
DROP PROCEDURE dbo.dodaj_zamowienie
GO
	
create procedure dbo.dodaj_zamowienie

@Market VARCHAR(30),
@country varchar(30),
@City varchar(50),
@State varchar(30),
@PostalCode varchar(8),
@Category varchar(50),
@SubCategory varchar(50),
@ProductId varchar (50),
@ProductName varchar(100),
@Segment varchar(30),
@CustomerID varchar(50),
@CustomerName varchar(50),
@ShipMode varchar(32),
@OrderID varchar(50),
@OrderDate date,
@ShipDate date,

@id	varchar(50),
@name	varchar(MAX),
@segment_id	int,
@product_id	varchar(50),
@order_id	varchar(50),
@sales		numeric(18 ,2),
@quantity	int,
@discount	numeric(18 ,3),
@profit		numeric(18 ,2),
@shipping_cost		numeric(18 ,3),
@ship_date	date,
@location_id	int,
@ship_modes_id	int,
@customer_id	varchar(50),
@order_date	date,
@id_int	int,
@sub_category_id	int,
@country_id	int	,
@state_id	int,
@city_id		int,
@postal_code_id	int,
@market_id int,
@category_id int
as

begin transaction

declare @fk_markets INT
declare @fk_country INT

SELECT @fk_markets = MarketID FROM Markets m WHERE m.Market = @Market
IF @fk_markets IS NULL
BEGIN
	INSERT INTO Markets(Market) VALUES (@Market)
	SELECT @fk_markets = SCOPE_IDENTITY()
END

SELECT @fk_country = CountryID FROM Countries c WHERE c.Country = @Country
IF @fk_country IS NULL
BEGIN
	INSERT INTO Countries (Country) VALUES (@Country)
	SELECT @fk_country = SCOPE_IDENTITY()
END

declare @fk_city INT = NULL
SELECT @fk_city = c.CityID FROM Cities c WHERE c.City = @City
IF @fk_city IS NULL
BEGIN
	INSERT INTO Cities(City) VALUES (@City)
	SELECT @fk_city = SCOPE_IDENTITY()
END

declare @fk_state INT = NULL
SELECT @fk_state = s.StateID FROM States s WHERE s.State = @State
IF @fk_state IS NULL
BEGIN
	INSERT INTO States(State) VALUES (@State)
	SELECT @fk_state = SCOPE_IDENTITY()
END

declare @fk_postalcode INT = NULL
SELECT @fk_postalcode = pc.PostalCodeID FROM PostalCodes pc WHERE pc.PostalCode = @PostalCode
IF @fk_postalcode IS NULL
BEGIN
	INSERT INTO PostalCodes(PostalCode) VALUES (@PostalCode)
	SELECT @fk_postalcode = SCOPE_IDENTITY()
END

declare @fk_location INT

SELECT 1 FROM Locations l WHERE l.CountryID = @fk_country AND l.CityID = @fk_city AND l.StateID = @fk_state and l.PostalCodeID = @fk_postalcode
IF @fk_location IS NULL
BEGIN
	INSERT INTO Locations(CountryID, CityID, StateID, PostalCodeID) VALUES (@fk_country, @fk_city, @fk_state, @fk_postalcode)
	SELECT @fk_location = SCOPE_IDENTITY()
END

declare @fk_productCategories INT = NULL
	
SELECT @fk_productCategories = ProductCategoryID FROM ProductCategories pc WHERE pc.Category = @Category

IF @fk_productCategories IS NULL
BEGIN
	INSERT INTO ProductCategories(Category) VALUES (@Category);
	SELECT @fk_productCategories = SCOPE_IDENTITY();
END
	
declare @fk_productSubCategories INT = NULL

SELECT @fk_productSubCategories = ProductSubcatID FROM ProductSubCategories psc WHERE psc.Sybcategory = @SubCategory

IF @fk_productSubCategories IS NULL
BEGIN
	INSERT INTO ProductSubCategories(Sybcategory, ProductCategoryID) VALUES (@SubCategory, @fk_productCategories)
	SELECT @fk_productSubCategories = SCOPE_IDENTITY();
END

declare @fk_product varchar(50)

SELECT @fk_product = ProductID FROM Products p WHERE p.ProductID = @ProductId
IF @fk_product IS NULL
BEGIN
	INSERT INTO Products(ProductId, Name, ProductSubcatID) VALUES (@ProductId, @ProductName, @fk_productSubCategories)
	SELECT @fk_product = SCOPE_IDENTITY()
END

declare @fk_segment INT = NULL
SELECT @fk_segment = SegmentID FROM Segments s WHERE s.Segment = @Segment
IF @fk_segment IS NULL
BEGIN
	INSERT INTO Segments(Segment) VALUES (@Segment)
	SELECT @fk_segment = SCOPE_IDENTITY()
END

declare @fk_customer CHAR(12) 
SELECT @fk_customer = c.CustomerID FROM Customers c WHERE c.CustomerID = @CustomerID

IF @fk_customer IS NULL
BEGIN
	INSERT INTO Customers(CustomerID, Name, SegmentID) VALUES (@CustomerId, @CustomerName, @fk_segment)
	select @fk_customer = SCOPE_IDENTITY()
END

declare @fk_shipMode INT = NULL
SELECT @fk_shipMode = ShipmentModeID FROM ShipmentsMode sm WHERE sm.ShipmentMode = @ShipMode
IF @fk_shipMode IS NULL
BEGIN
	INSERT INTO ShipmentsMode(ShipmentMode) VALUES (@ShipMode)
	SELECT @fk_shipMode = SCOPE_IDENTITY()
END

declare @fk_order varchar(50) = NULL
SELECT @fk_order = o.OrderId FROM Orders o WHERE o.OrderID = @OrderID
	
IF @fk_order IS NULL
BEGIN
	INSERT INTO Orders(
		OrderID, 
		OrderDate,
		ShipDate,
		CustomerID,
		fk_shipMode,
		LocationID
	) VALUES (
		@OrderID,
		@OrderDate,
		@ShipDate,
		@fk_customer,
		@fk_shipMode,
		@fk_location
	)
END

INSERT INTO OrderProducts(
	OrderID,
	ProductID,
	Sales,
	Quantity,
	Discount,
	Profit,
	Shipping_cost
) VALUES (
	@OrderID,
	@ProductId,
	@Sales,
	@Quantity,
	@Discount,
	@Profit,
	@shipping_cost
)
IF @@ERROR = 0  
BEGIN
COMMIT
END
ELSE
BEGIN
ROLLBACK
END

GO

CREATE PROCEDURE [Borowski].[Zamowienia_w_miesiacu]
AS
BEGIN
	    DECLARE @Month INTEGER = MONTH(getdate());
		DECLARE @Year INTEGER = YEAR(getdate());

		SELECT o.OrderID, o.OrderDate, p.Name AS ProductName, op.Sales, op.Quantity
		FROM [Borowski].[Orders] o
		JOIN [Borowski].[OrderProducts] op ON o.OrderID = op.OrderID
		JOIN [Borowski].[Products] p ON op.ProductID = p.ProductID
		WHERE MONTH(o.OrderDate) = @Month AND YEAR(o.OrderDate) = @Year

		RETURN
	END
EXECUTE [Borowski].[Zamowienia_w_miesiacu]
GO