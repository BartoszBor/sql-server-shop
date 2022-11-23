-- Zadanie 4.1
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

-- Zadanie 4.2
CREATE OR ALTER VIEW [Borowski].[V_wszyscyklienci]
WITH schemabinding
AS
SELECT c.CustomerID, c.Name AS CustomerName, s.Segment, COUNT_BIG(*) AS Count
FROM [Borowski].[Orders] o
INNER JOIN [Borowski].[Customers] c ON o.CustomerID = c.CustomerID
INNER JOIN [Borowski].[Segments] s ON c.SegmentID = s.SegmentID
GROUP BY c.CustomerID, c.Name, s.Segment
GO

CREATE UNIQUE CLUSTERED INDEX IX_v_wszyscykliencue
ON [Borowski].[V_wszyscyklienci] (CustomerID)
GO

SELECT * FROM Borowski.V_wszyscyklienci

--Zadanie 4.3
--B�d� kompresowa� tabele OrderProducts ze wzgl�du na to, �e ona w przysz�o�ci b�dzie jedn� z tabel o najwi�kszej liczbie rekord�w

--Dwa poni�sze zapytania pozwol� mi wyznaczy� jaki typ kompresji jest lepszy (Page czy Row)
EXEC sp_estimate_data_compression_savings 
    @schema_name = 'Borowski', 
    @object_name = 'OrderProducts', 
    @index_id = NULL, 
    @partition_number = NULL, 
    @data_compression = 'ROW'

EXEC sp_estimate_data_compression_savings 
    @schema_name = 'Borowski', 
    @object_name = 'OrderProducts', 
    @index_id = NULL, 
    @partition_number = NULL, 
    @data_compression = 'PAGE'

--Po wykonaniu tych zapyta�, zwr�cona warto�� jest taka sama mo�liwe, �e za ma�o jest danych aby zobaczy� r�nice

--Wykonam dla przyk�adu kompresje PAGE

ALTER TABLE [Borowski].[OrderProducts]
REBUILD WITH (DATA_COMPRESSION=PAGE)

--sprawdzam kompresje, wyglada na dobr� ze wzgledu na to, �e warto�� kolumn "size_with_current_compression_setting" oraz "size_with_requested_compression_setting" jest taka sama
EXEC sp_estimate_data_compression_savings 
    @schema_name = 'Borowski', 
    @object_name = 'OrderProducts', 
    @index_id = NULL, 
    @partition_number = NULL, 
    @data_compression = 'PAGE'
GO

--Zadanie 4.4

/*
W tym zadaniu skorzystam z partycjonowania horyzontalnego. Ten rodzaj partycjonowania jest przydatny gdy mamy na przyk�ad du�� ilo�� zakres�w dat.
Wi�c takie partycjonowanie zwi�kszy wydajno�� zapyta� np. w raportach kt�re polegaj� na datach.
*/

SET SHOWPLAN_XML OFF;
GO

-- Na pocz�tku nale�y stworzy� funkcj� partycjonuj�c� daty dla poszczeg�lnych w bazie

CREATE PARTITION FUNCTION fn_partycja (date) 
AS RANGE LEFT 
FOR VALUES(
	 '20181231'
	 ,'20191231'
	 ,'20201231'
	 ,'20211231'
	 ,'20221231'
	 );
GO

CREATE PARTITION SCHEME sch_partycja
    AS PARTITION fn_partycja
    ALL TO ([PRIMARY])
GO

-- Usuwanie Constrain�w oraz PK bez tego nie b�d� m�g� modyfikowa� PK index
ALTER TABLE [Borowski].[Orders] DROP CONSTRAINT [FK__Orders__Customer__4BAC3F29];
ALTER TABLE [Borowski].[Orders] DROP CONSTRAINT [FK__Orders__Location__4CA06362];
ALTER TABLE [Borowski].[Orders] DROP CONSTRAINT [FK__Orders__Shipment__4D94879B];
ALTER TABLE [Borowski].[OrderProducts] DROP CONSTRAINT [FK__OrderProd__Order__52593CB8] ;

GO

DECLARE @ordersPK VARCHAR(100)

SELECT @ordersPK = x.name FROM sys.indexes x
    JOIN sys.objects o ON o.object_id = x.object_id
WHERE o.name LIKE 'Orders'

EXEC('ALTER TABLE [Borowski].[Orders] DROP CONSTRAINT ' + @ordersPK);


-- Poni�ej twor�� PK index do posortowania zam�wie�
ALTER TABLE [Borowski].[Orders] ADD CONSTRAINT PK_Orders PRIMARY KEY NONCLUSTERED  (OrderID)
   WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, 
         ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
         
GO
-- tworz� indeks zgrupowany na OrderDate 
CREATE CLUSTERED INDEX IX_OrderDate ON [Borowski].[Orders] (OrderDate)
  WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, 
        ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
  ON sch_partycja(OrderDate)

-- Poni�ej nadaje constrainy jakie wcze�niej usun��em
ALTER table [Borowski].[Orders] add constraint FK__Orders__Shipment foreign key ([ShipmentModeID]) references [Borowski].[ShipmentsMode]([ShipmentModeID]);
ALTER table [Borowski].[Orders] add constraint FK__Orders__Customer foreign key ([CustomerID]) references [Borowski].[Customers]([CustomerID]);
ALTER table [Borowski].[Orders] add constraint FK__Orders__Location foreign key ([LocationID]) references [Borowski].[Locations]([LocationID]);
ALTER table [Borowski].[OrderProducts] add constraint FK__OrderProd__Order foreign key ([OrderID]) references [Borowski].[Orders]([OrderID]);

--poni�szym zapytaniem sprawdzam partycje (zwraca partycje tabeli Orders)
select * from sys.partitions
where OBJECT_ID=OBJECT_ID('[Borowski].[Orders]')

GO

