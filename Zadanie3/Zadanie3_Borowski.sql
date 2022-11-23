--											///////////////////////////ZADANIE_3//////////////////////////////////

/*
Podpunkt 1

Indeks zgurpowany tworzony jest dla ka¿dej kolumny zawieraj¹ce Primary Key i maj¹cym typ INTEGER. Jest tylko jeden indeks zgrupowany na jedn¹ tabele, 
wiêc na przyk³ad tabela Markets posiada indeks zgrupowany na kolumnie MarketID. Indeks ten zawiera wskaŸnik na blok danych.

*/

/*
Indeks niezgrupowany najlepiej stosowaæ do wartoœci które siê powtarzaj¹ lub s¹ unikatowe. Nadaje siê te¿ na kolumny typu VARCHAR. 
Indeksy te znajduj¹ siê poza tabel¹ z danymi i wskaŸnik jest na konkretny rekord.
Indeksów niezgrupowanych mo¿e istnieæ kilka w tabeli.
Dlatego mo¿emy stworzyæ indeks niezgrupowany na orderID w tabeli Orders, oprocz tego ¿e pole to ma typ VARCHAR oraz nie mamy pewnoœci jaka wartoœæ bêdzie nastêpna 
(nie mamy pewnoœci ¿e tak jak w int po 5 jest 6) warto dodaæ, ¿e na³o¿enie takiego klastra zwiêkszy wydajnoœæ wyszukiwania zamówieñ po ID.
*/
CREATE NONCLUSTERED INDEX IDX_ORDER_ID ON [Borowski].[Orders] (OrderID);
GO

/*
Podpunkt 2

Indeksy nizegrupowane s¹ indeksami gêstymi, indeksy te zajmuj¹ wiêcej miejca na dysku ni¿ rzadkie, ale s¹ szybsze.
Indeksy niezgrupowane najlepiej nadadz¹ siê tam gdzie s¹ czêsto dodawane/akutalizowane rekordy, dlatego nadajê siê np na tabelê OrderProducts

Indeks rzadki to indeks zgrupowany i zawiera wskaŸnik na blok. Jest wolniejszy od gêstego ale za to zajmuje mniej miejsca

*/

/*
Podpunkt 3

Indeksy kolumnowe s¹ przydatne gdy chcemy zwiêkszyæ szybkoœæ przeszukiwania du¿ych tabel, najlepsze zastosowanie jest wtedy gdy zapytanie jest skierowane 
na du¿y zbiór danych ale równie¿ nadaje siê do analizy danych.

Podejrzewam ¿e tabela OrderProducts mo¿e byæ du¿a dlatego indes kolumnowy zosta³ utworzony w³aœnie na tej tabeli. Indeks ten pomo¿e tak¿e w analizie zamówionych produktów.
*/

CREATE NONCLUSTERED COLUMNSTORE INDEX CSIX_OrderProducts
    ON [Borowski].[OrderProducts] (OrderID, ProductID, Sales, Quantity, Discount, Shipping_cost, profit ); 
GO

/*Podpunkt4*/

CREATE FUNCTION [Borowski].[Dostan_Zamowienia] (@subcategory VARCHAR(50), @country VARCHAR(30))
RETURNS TABLE
AS
RETURN(
	SELECT o.OrderID, o.OrderDate, o.ShipDate, p.Name AS ProductName, op.Sales, op.Quantity, op.Profit
	FROM [Borowski].[Orders] o
	JOIN [Borowski].[OrderProducts] op ON o.OrderID = op.OrderID
	JOIN [Borowski].[Products] p ON op.ProductID = p.ProductID
	JOIN [Borowski].[ProductSubcategories] ps ON p.ProductSubcatID = ps.ProductSubcatID
	JOIN [Borowski].[Locations] l ON o.LocationID = l.LocationID
	JOIN [Borowski].[Countries] c on l.CountryID = c.CountryID
	WHERE ps.Sybcategory = @subcategory AND c.Country = @country
)
GO
select * from [Borowski].[Dostan_Zamowienia]('Bookcases', 'United States');
GO

/*Podpunkt5*/



CREATE FUNCTION [Borowski].[Dostan_2_najnowsze_zamowienia] ()
RETURNS TABLE
AS
RETURN(
	SELECT TOP 2 o.OrderID, o.OrderDate, p.Name AS ProductName, op.Sales, c.Name AS CustomerName
	FROM [Borowski].[Orders] o
	JOIN [Borowski].[OrderProducts] op ON o.OrderID = op.OrderID
	JOIN [Borowski].[Products] p ON op.ProductID = p.ProductID
	JOIN [Borowski].[ProductSubcategories] ps ON p.ProductSubcatID = ps.ProductSubcatID
	JOIN [Borowski].[Customers] c ON o.CustomerID = c.CustomerID
	JOIN [Borowski].[Segments] s ON c.SegmentID = s.SegmentID
	WHERE S.Segment = 'Consumer'
	ORDER BY OrderDate DESC
)
GO
SELECT * FROM [Borowski].[Dostan_2_najnowsze_zamowienia]();
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
		WHERE MONTH(o.OrderDate) = @Month ABD YEAR(o.OrderDate) = @Year

		RETURN
	END
EXECUTE [Borowski].[Zamowienia_w_miesiacu]
GO