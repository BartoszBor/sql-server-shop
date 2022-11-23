/*W swoim projekcie wykorzysta³em XML, a technologia Xquery pozwoli³a mi na przeprowaddzenie operacji na XMLu  */
/*Tworzenie, sprawdzenie oraz u¿ycie danej bazy danych*/
USE master
DROP DATABASE IF EXISTS OrderDB;

CREATE DATABASE	OrderDB

GO
USE OrderDB

GO
/*Tworzenie i sprawdzenie czy istnienie Schema*/
DROP SCHEMA IF EXISTS Borowski

GO
CREATE SCHEMA Borowski

GO
/*Tworzenie Tabel*/
/*Checki s¹ w Orders oraz OrderProducts*/
CREATE TABLE OrderDB.Borowski.Markets (
    MarketID int identity(1,1),
    Market varchar(30) NOT NULL UNIQUE,
    PRIMARY KEY (MarketID)
);

CREATE TABLE OrderDB.Borowski.Countries (
    CountryID int NOT NULL identity(1,1),
    Country varchar(30) NOT NULL UNIQUE,
	MarketID int NOT NULL,
    PRIMARY KEY (CountryID),
	FOREIGN KEY (MarketID) REFERENCES OrderDB.Borowski.Markets(MarketID)
);

CREATE TABLE OrderDB.Borowski.Cities (
    CityID int NOT NULL identity(1,1),
    City varchar(50) NOT NULL UNIQUE,
    PRIMARY KEY (CityID)
);
CREATE TABLE OrderDB.Borowski.PostalCodes (
    PostalCodeID int NOT NULL identity(1,1),
    PostalCode varchar(8) NOT NULL UNIQUE,
    PRIMARY KEY (PostalCodeID)
);
CREATE TABLE OrderDB.Borowski.States (
    StateID int NOT NULL identity(1,1),
    State varchar(30) NOT NULL UNIQUE,
    PRIMARY KEY (StateID)
);
CREATE TABLE OrderDB.Borowski.Locations (
    LocationID int NOT NULL identity(1,1),
	CityID int NOT NULL,
	CountryID int NOT NULL,
	StateID int NOT NULL,
	PostalCodeID int NULL,
    PRIMARY KEY (LocationID),
	FOREIGN KEY (CityID) REFERENCES OrderDB.Borowski.Cities(CityID),
	FOREIGN KEY (CountryID) REFERENCES OrderDB.Borowski.Countries(CountryID),
	FOREIGN KEY (StateID) REFERENCES OrderDB.Borowski.States(StateID),
	FOREIGN KEY (PostalCodeID) REFERENCES OrderDB.Borowski.PostalCodes(PostalCodeID)
);
CREATE TABLE OrderDB.Borowski.Segments (
    SegmentID int NOT NULL identity(1,1),
    Segment varchar(30) NOT NULL UNIQUE,
    PRIMARY KEY (SegmentID)
);
CREATE TABLE OrderDB.Borowski.Customers (
    CustomerID varchar(50) NOT NULL,
    Name varchar(50) NOT NULL,
	SegmentID int NOT NULL,
    PRIMARY KEY (CustomerID),
	FOREIGN KEY (SegmentID) REFERENCES OrderDB.Borowski.Segments(SegmentID)
);
CREATE TABLE OrderDB.Borowski.ProductCategories (
    ProductCategoryID int NOT NULL identity(1,1),
    Category varchar(50) NOT NULL UNIQUE,
    PRIMARY KEY (ProductCategoryID)
);
CREATE TABLE OrderDB.Borowski.ProductSubcategories (
    ProductSubcatID int NOT NULL identity(1,1),
    Sybcategory varchar(50) NOT NULL,
	ProductCategoryID int NOT NULL,
    PRIMARY KEY (ProductSubcatID),
	FOREIGN KEY (ProductCategoryID) REFERENCES OrderDB.Borowski.ProductCategories(ProductCategoryID)
);
CREATE TABLE OrderDB.Borowski.Products (
    ProductID varchar(50) NOT NULL,
    Name varchar(100) NOT NULL,
	ProductSubcatID int NOT NULL,
    PRIMARY KEY (ProductID),
	FOREIGN KEY (ProductSubcatID) REFERENCES OrderDB.Borowski.ProductSubcategories(ProductSubcatID)
);
CREATE TABLE OrderDB.Borowski.ShipmentsMode (
    ShipmentModeID int NOT NULL identity(1,1),
    ShipmentMode varchar(32) NOT NULL UNIQUE,
    PRIMARY KEY (ShipmentModeID)
);

CREATE TABLE OrderDB.Borowski.Orders (
    OrderID varchar(50) Primary key NOT NULL,
	CustomerID varchar(50) NOT NULL,
	LocationID int NOT NULL,
	ShipmentModeID int NOT NULL,
	OrderDate date NOT NULL,
	ShipDate date NOT NULL,
	CONSTRAINT ck_ShipDate CHECK (ShipDate >= OrderDate),
	FOREIGN KEY (CustomerID) REFERENCES OrderDB.Borowski.Customers(CustomerID),
	FOREIGN KEY (LocationID) REFERENCES OrderDB.Borowski.Locations(LocationID),
	FOREIGN KEY (ShipmentModeID) REFERENCES OrderDB.Borowski.ShipmentsMode(ShipmentModeID)
);
CREATE TABLE OrderDB.Borowski.OrderProducts (
    OrderProductID int NOT NULL identity(1,1),
	OrderID varchar(50) NOT NULL,
	ProductID varchar(50) NOT NULL,
	Sales smallmoney NOT NULL,
	Quantity int NOT NULL CHECK (Quantity > 0),
	Discount float NOT NULL CHECK (Discount >= 0),
	Shipping_cost smallmoney NOT NULL,
	Profit smallmoney NOT NULL,
    PRIMARY KEY (OrderProductID),
	FOREIGN KEY (OrderID) REFERENCES OrderDB.Borowski.Orders(OrderID),
	FOREIGN KEY (ProductID) REFERENCES OrderDB.Borowski.Products(ProductID)
);
GO

/*Ustawienie ktore nie bêdzie zwraca³a wierszy gdy dana zmienna jest NULL (szczególnie przydatne dla zmiennych po WHERE)*/
SET ANSI_NULLS ON
GO
/*Ustawienie które nie pozwala zapisywania w tabeli podwójnie danych (wykorzystane szczególnie dla OrderID)*/
SET XACT_ABORT ON
GO
/*Sprawdzenie czy istnieje Procedura i usuniêcie jeœli tak*/
IF EXISTS(SELECT 1 FROM OrderDB.sys.procedures WHERE Name = 'dodaj_zamowienie')
	DROP PROCEDURE Borowski.dodaj_zamowienie
GO

/* Procedura pozwalaj¹ca dodaæ zamówienia*/
create procedure Borowski.dodaj_zamowienie
	@Products as XML,
	@Market VARCHAR(30),
	@country VARCHAR(30),
	@City VARCHAR(50),
	@State VARCHAR(30),
	@PostalCode VARCHAR(8),
	@CustomerID VARCHAR(50),
	@CustomerName VARCHAR(50),
	@ShipMode VARCHAR(32),
	@OrderID VARCHAR(50),
	@OrderDate DATE,
	@ShipDate DATE
as

BEGIN TRANSACTION
/*Wpisywanie zmiennych do tabel*/
	DECLARE @fk_markets INT
	DECLARE @fk_country INT

	SELECT @fk_markets = MarketID FROM Markets m WHERE m.Market = @Market
	IF @fk_markets IS NULL
	BEGIN
		INSERT INTO Markets(Market) VALUES (@Market)
		SELECT @fk_markets = SCOPE_IDENTITY()
	END

	SELECT @fk_country = CountryID FROM Countries c WHERE c.Country = @Country
	IF @fk_country IS NULL
	BEGIN
		INSERT INTO Countries (Country, MarketID) VALUES (@Country, @fk_markets)
		SELECT @fk_country = SCOPE_IDENTITY()
	END

	DECLARE @fk_city INT = NULL

	SELECT @fk_city = c.CityID FROM Cities c WHERE c.City = @City
	IF @fk_city IS NULL
	BEGIN
		INSERT INTO Cities(City) VALUES (@City)
		SELECT @fk_city = SCOPE_IDENTITY()
	END

	DECLARE @fk_state INT = NULL

	SELECT @fk_state = s.StateID FROM States s WHERE s.State = @State
	IF @fk_state IS NULL
	BEGIN
		INSERT INTO States(State) VALUES (@State)
		SELECT @fk_state = SCOPE_IDENTITY()
	END

	DECLARE @fk_postalcode INT = NULL

	SELECT @fk_postalcode = pc.PostalCodeID FROM PostalCodes pc WHERE pc.PostalCode = @PostalCode
	IF @fk_postalcode IS NULL
	BEGIN
		INSERT INTO PostalCodes(PostalCode) VALUES (@PostalCode)
		SELECT @fk_postalcode = SCOPE_IDENTITY()
	END

	DECLARE @fk_location INT

	SELECT 1 FROM Locations l WHERE l.CountryID = @fk_country AND l.CityID = @fk_city AND l.StateID = @fk_state and l.PostalCodeID = @fk_postalcode
	IF @fk_location IS NULL
	BEGIN
		INSERT INTO Locations(CountryID, CityID, StateID, PostalCodeID) VALUES (@fk_country, @fk_city, @fk_state, @fk_postalcode)
		SELECT @fk_location = SCOPE_IDENTITY()
	END



	DECLARE @fk_shipMode INT = NULL

	SELECT @fk_shipMode = ShipmentModeID FROM ShipmentsMode sm WHERE sm.ShipmentMode = @ShipMode
	IF @fk_shipMode IS NULL
	BEGIN
		INSERT INTO ShipmentsMode(ShipmentMode) VALUES (@ShipMode)
		SELECT @fk_shipMode = SCOPE_IDENTITY()
	END

/*Stworzenie tymczasowej tabeli która bêdzie potrzebna ponizej w orderproducts*/
	DECLARE @numberOfProducts INT = 0
	DECLARE @fk_product varchar(50)
	DECLARE @ProdName VARCHAR(100)
	DECLARE @Category VARCHAR(50)
	DECLARE @SubCat VARCHAR(50)
	DECLARE @Segment VARCHAR(30)
	DECLARE @fk_productCategories INT 
	DECLARE @fk_productSubCategories INT 
	DECLARE @fk_customer CHAR(12) 
	DECLARE @fk_segment INT 

	SELECT @numberOfProducts = count(Col.value('id[1]', 'varchar(50)'))
	FROM @Products.nodes('/root/product') AS T(Col)

	DECLARE @tempOrders TABLE (id INT IDENTITY(1, 1) PRIMARY KEY, OrderId VARCHAR(24))

	WHILE (SELECT count(*) FROM @tempOrders) != @numberOfProducts
	BEGIN
		INSERT @tempOrders VALUES (@OrderID)
	END

/*Poni¿sza czêœæ pozwala na wprowadzenie nowego wiersza z nowym (nie bêd¹cym w bazie) produktem */
	DECLARE @set INT = 0
	DECLARE @tempProducts TABLE (id INT IDENTITY(1, 1) PRIMARY KEY, OrderId VARCHAR(24), prodname varchar(100), cat VARCHAR(50), subcat VARCHAR(50), segment VARCHAR(30))
	
	INSERT INTO @tempProducts (OrderId, prodname, cat, subcat, segment) SELECT Col.value('id[1]', 'varchar(50)') AS fk_product,
	Col.value('prodname[1]', 'varchar(100)') AS ProdName,
	Col.value('cat[1]', 'varchar(50)') AS Category,
	Col.value('subcat[1]', 'varchar(50)') AS SubCategory,
	Col.value('segment[1]', 'varchar(30)') AS Segment
	FROM @Products.nodes('/root/product') AS T(Col) 

	DECLARE @temp TABLE (id INT IDENTITY(1, 1) PRIMARY KEY, temp VARCHAR(24), tempname VARCHAR (100), tempcat varchar(50), tempsubcat varchar(50), tempsegment varchar(30))
	
		WHILE @set != @numberOfProducts
		BEGIN

		INSERT INTO @temp SELECT OrderId,prodname, cat, subcat, segment FROM @tempProducts WHERE OrderId NOT IN (SELECT ProductID FROM Products) OR CAT NOT IN (SELECT Category FROM ProductCategories)
		SELECT @fk_product = temp, @ProdName = tempname, @Category = tempcat, @SubCat = tempsubcat, @Segment = tempsegment FROM @temp

		SELECT @fk_productCategories = ProductCategoryID FROM ProductCategories pc WHERE pc.Category = @Category
		IF @Category NOT IN (SELECT Category FROM ProductCategories)
		BEGIN
			INSERT INTO ProductCategories(Category) VALUES (@Category);
			SELECT @fk_productCategories = SCOPE_IDENTITY();		
		END

		SELECT @fk_productSubCategories = ProductSubcatID FROM ProductSubCategories psc WHERE psc.Sybcategory = @SubCat
		IF @SubCat not in  (SELECT Sybcategory FROM ProductSubcategories)
		BEGIN
			INSERT INTO ProductSubCategories(Sybcategory, ProductCategoryID) VALUES (@SubCat, @fk_productCategories)
			SELECT @fk_productSubCategories = SCOPE_IDENTITY();		
		END

		SELECT @fk_segment = SegmentID FROM Segments s WHERE s.Segment = @Segment
		IF @Segment not in (SELECT Segment FROM Segments)
		BEGIN
			INSERT INTO Segments(Segment) VALUES (@Segment)
			SELECT @fk_segment = SCOPE_IDENTITY()
		END

		IF (EXISTS (SELECT 1 FROM @temp))
		BEGIN
			IF @fk_product not in (SELECT ProductID FROM Products)
			BEGIN
				INSERT INTO Products(ProductID, Name, ProductSubcatID) VALUES ( @fk_product, @ProdName, @fk_productSubCategories);
			END
		END
		SET @set = @set + 1
	END 

	SELECT @fk_customer = c.CustomerID FROM Customers c WHERE c.CustomerID = @CustomerID
	IF @fk_customer IS NULL
	BEGIN
		INSERT INTO Customers(CustomerID, Name, SegmentID) VALUES (@CustomerId, @CustomerName, @fk_segment)
		SET @fk_customer = @CustomerId
	END

	INSERT INTO Orders(
		OrderID, 
		OrderDate,
		ShipDate,
		CustomerID,
		ShipmentModeID,
		LocationID
	) VALUES (
		@OrderID,
		@OrderDate,
		@ShipDate,
		@fk_customer,
		@fk_shipMode,
		@fk_location
	)

	INSERT INTO OrderProducts (
		OrderID,
		ProductID,
		Sales,
		Quantity,
		Discount,
		Profit,
		Shipping_cost)
	SELECT tmpOrders.OrderId,
		tmpProducts.fk_product,
		tmpProducts.Sales,
		tmpProducts.Quantity,
		tmpProducts.Discount,
		tmpProducts.Profit,
		tmpProducts.ShippingCost
		FROM (SELECT 
	  ROW_NUMBER() OVER(ORDER BY Col.value('id[1]', 'varchar(50)')) AS num_row,
	  Col.value('id[1]', 'varchar(50)') AS fk_product,
	  Col.value('sales[1]', 'varchar(50)') AS Sales,
	  Col.value('quantity[1]', 'varchar(50)') AS Quantity,
	  Col.value('discount[1]', 'varchar(50)') AS Discount,
	  Col.value('profit[1]', 'varchar(50)') AS Profit,
	  Col.value('shippingCost[1]', 'varchar(50)') AS ShippingCost
	FROM @Products.nodes('/root/product') AS T(Col)) AS tmpProducts
		LEFT JOIN (SELECT * FROM @tempOrders) AS tmpOrders ON tmpOrders.id = tmpProducts.num_row	

/*Rollback jeœli jest jakiœ b³¹d*/
	IF @@ERROR <> 0  
	BEGIN
		ROLLBACK TRANSACTION
	END
	IF @@ERROR = 0
	BEGIN
		COMMIT TRANSACTION
	END
GO

DECLARE @Products as XML
SET @Products = N'<root>
	<product><id>FUR-BO-3174</id><sales>540</sales><quantity>32</quantity><discount>0</discount><profit>380</profit><shippingCost>30</shippingCost><prodname>Atlantic Metals Mobile 2-Shelf Bookcases, Custom Colors</prodname><cat>Furniture</cat><subcat>Bookcases</subcat><segment>Consumer</segment></product>
	<product><id>FUR-BO-6121</id><sales>540</sales><quantity>510</quantity><discount>0</discount><profit>380</profit><shippingCost>30</shippingCost><prodname>Metals Mobile 3-Shelf Bookcases, Custom Colors</prodname><cat>Furniture</cat><subcat>Bookcases</subcat><segment>Consumer</segment></product>
	</root>'
EXEC Borowski.dodaj_zamowienie @PRODUCTS, 'USCA', 'United States', 'Oklahoma City', 'Oklahoma', '73-120', 'Ap-100151402', 'Aaron Bergman', 'First Class', 'CA-2014-AB10015140-213', '2014-11-11', '2014-11-13'
GO

/*
select * from [Borowski].[OrderProducts]
select * from [Borowski].[Orders]
select * from [Borowski].[Products]
SELECT * FROM [Borowski].[ProductCategories]
select * from [Borowski].[Customers]
*/
