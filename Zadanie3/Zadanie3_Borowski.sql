--											///////////////////////////ZADANIE_3//////////////////////////////////

/*
Podpunkt 1

Indeks zgurpowany tworzony jest dla ka�dej kolumny zawieraj�ce Primary Key i maj�cym typ INTEGER. Jest tylko jeden indeks zgrupowany na jedn� tabele, 
wi�c na przyk�ad tabela Markets posiada indeks zgrupowany na kolumnie MarketID. Indeks ten zawiera wska�nik na blok danych.

*/

/*
Indeks niezgrupowany najlepiej stosowa� do warto�ci kt�re si� powtarzaj� lub s� unikatowe. Nadaje si� te� na kolumny typu VARCHAR. 
Indeksy te znajduj� si� poza tabel� z danymi i wska�nik jest na konkretny rekord.
Indeks�w niezgrupowanych mo�e istnie� kilka w tabeli.
Dlatego mo�emy stworzy� indeks niezgrupowany na orderID w tabeli Orders, oprocz tego �e pole to ma typ VARCHAR oraz nie mamy pewno�ci jaka warto�� b�dzie nast�pna 
(nie mamy pewno�ci �e tak jak w int po 5 jest 6) warto doda�, �e na�o�enie takiego klastra zwi�kszy wydajno�� wyszukiwania zam�wie� po ID.
*/
CREATE NONCLUSTERED INDEX IDX_ORDER_ID ON [Borowski].[Orders] (OrderID);
GO

/*
Podpunkt 2

Indeksy nizegrupowane s� indeksami g�stymi, indeksy te zajmuj� wi�cej miejca na dysku ni� rzadkie, ale s� szybsze.
Indeksy niezgrupowane najlepiej nadadz� si� tam gdzie s� cz�sto dodawane/akutalizowane rekordy, dlatego nadaj� si� np na tabel� OrderProducts

Indeks rzadki to indeks zgrupowany i zawiera wska�nik na blok. Jest wolniejszy od g�stego ale za to zajmuje mniej miejsca

*/

/*
Podpunkt 3

Indeksy kolumnowe s� przydatne gdy chcemy zwi�kszy� szybko�� przeszukiwania du�ych tabel, najlepsze zastosowanie jest wtedy gdy zapytanie jest skierowane 
na du�y zbi�r danych ale r�wnie� nadaje si� do analizy danych.

Podejrzewam �e tabela OrderProducts mo�e by� du�a dlatego indes kolumnowy zosta� utworzony w�a�nie na tej tabeli. Indeks ten pomo�e tak�e w analizie zam�wionych produkt�w.
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