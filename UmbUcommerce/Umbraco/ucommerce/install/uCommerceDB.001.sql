BEGIN TRAN
/****** Object:  Table [dbo].[uCommerce_PaymentStatus]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentStatus]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_PaymentStatus](
	[PaymentStatusId] [int] NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
 CONSTRAINT [uCommerce_PK_PaymentStatus] PRIMARY KEY CLUSTERED 
(
	[PaymentStatusId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
INSERT [dbo].[uCommerce_PaymentStatus] ([PaymentStatusId], [Name]) VALUES (1, N'New')
/****** Object:  Table [dbo].[uCommerce_SystemVersion]    Script Date: 09/04/2009 11:22:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_SystemVersion]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_SystemVersion](
	[SystemVersionId] int identity(1,1) not null,
	[SchemaVersion] [int] NOT NULL,
	CONSTRAINT [uCommerce_PK_SystemVersion] PRIMARY KEY CLUSTERED 
	(
		[SystemVersionId] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
INSERT [dbo].[uCommerce_SystemVersion] ([SchemaVersion]) VALUES (0)
/****** Object:  UserDefinedFunction [dbo].[uCommerce_ParseArrayToTable]    Script Date: 09/04/2009 11:22:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ParseArrayToTable]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'
CREATE FUNCTION [dbo].[uCommerce_ParseArrayToTable]
(
	@Array NVARCHAR(MAX), 		-- String to parse (ie: ''1,2,6,4,12'')
	@Separator CHAR(1) = '','',	-- Seperator to use, default to '','' (comma)
	@ReturnAsNumeric BIT = 0	-- If true, returns numeric values in stead of varchars
)
RETURNS @table TABLE
(
	[Id] INT IDENTITY(1, 1),
	stringvalue NVARCHAR(MAX),
	numericvalue INT
)
AS
BEGIN

	DECLARE @Separator_Position int 		-- This is used to locate each separator character
	DECLARE @Array_Value NVARCHAR(MAX) 	-- This holds each array value as it is returned

	-- For my loop to work I need an extra separator at the end.  I always look to the
	-- left of the separator character for each array value
	SET @Array = @Array + @Separator

	WHILE Patindex(''%'' + @Separator + ''%'' , @Array) <> 0 
	BEGIN			
		-- Patindex matches the a pattern against a string
		SELECT @Separator_position =  Patindex(''%'' + @Separator + ''%'' , @Array)
		SELECT @Array_value = Left(@Array, @Separator_Position - 1)

		-- This is where you process the values passed.
		-- Replace this select statement with your processing
		-- @Array_Value holds the value of this element of the array
		-- If the value is not numeric, insert as a string (using '''')
		IF @ReturnAsNumeric = 1
			INSERT @table (numericvalue) VALUES (CONVERT(INT, @Array_Value))
		ELSE
			INSERT @table (stringvalue) VALUES (CONVERT(NVARCHAR(MAX), @Array_Value))

		-- This replaces what we just processed with an empty string
		SELECT @Array = Stuff(@Array, 1, @Separator_Position, '''')

	END

	RETURN

END' 
END
GO
/****** Object:  Table [dbo].[uCommerce_ProductDefinition]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDefinition]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_ProductDefinition](
	[ProductDefinitionId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](512) NOT NULL,
	[Description] [nvarchar](max) NULL,
	[Deleted] [bit] NOT NULL,
 CONSTRAINT [uCommerce_PK_ProductDefinition] PRIMARY KEY CLUSTERED 
(
	[ProductDefinitionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_ProductDefinition] ON
INSERT [dbo].[uCommerce_ProductDefinition] ([ProductDefinitionId], [Name], [Description], [Deleted]) VALUES (19, N'Software', N'', 0)
INSERT [dbo].[uCommerce_ProductDefinition] ([ProductDefinitionId], [Name], [Description], [Deleted]) VALUES (20, N'Support', N'', 0)
SET IDENTITY_INSERT [dbo].[uCommerce_ProductDefinition] OFF
/****** Object:  StoredProcedure [dbo].[uCommerce_GetTotalSales]    Script Date: 09/04/2009 11:22:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_GetTotalSales]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE PROCEDURE [dbo].[uCommerce_GetTotalSales]
(
	@StartDate DATETIME, -- NULLABLE
	@EndDate DATETIME, -- NULLABLE
	@ProductCatalogGroupId INT -- NULLABLE
)
AS
	SET NOCOUNT ON
	SELECT 
		dbo.uCommerce_ProductCatalogGroup.Name,
		SUM(ISNULL(dbo.uCommerce_PurchaseOrder.OrderTotal, 0)) Revenue,
		SUM(ISNULL(dbo.uCommerce_PurchaseOrder.VAT, 0)) [VATTotal],
		SUM(ISNULL(dbo.uCommerce_PurchaseOrder.TaxTotal, 0)) [TaxTotal],
		SUM(ISNULL(dbo.uCommerce_PurchaseOrder.ShippingTotal, 0)) [ShippingTotal],
		ISNULL(dbo.uCommerce_Currency.ISOCode, ''-'') Currency
	FROM
		dbo.uCommerce_PurchaseOrder
		JOIN dbo.uCommerce_Currency ON dbo.uCommerce_Currency.CurrencyId = dbo.uCommerce_PurchaseOrder.CurrencyId
		RIGHT JOIN dbo.uCommerce_ProductCatalogGroup ON dbo.uCommerce_ProductCatalogGroup.ProductCatalogGroupId = dbo.uCommerce_PurchaseOrder.ProductCatalogGroupId
	WHERE
		(
			dbo.uCommerce_PurchaseOrder.CreatedDate BETWEEN @StartDate AND @EndDate
			OR
			(
				@StartDate IS NULL
				AND
				@EndDate IS NULL
			)
			OR
			dbo.uCommerce_PurchaseOrder.CreatedDate IS NULL
		)
		AND
		(
			dbo.uCommerce_ProductCatalogGroup.ProductCatalogGroupId = @ProductCatalogGroupId
			OR
			@ProductCatalogGroupId IS NULL
		)
		AND
		(
			NOT dbo.uCommerce_PurchaseOrder.OrderStatusId IN (1, 4, 7) -- Basket, -- Cancelled Order, -- Cancelled
			OR
			dbo.uCommerce_PurchaseOrder.OrderStatusId IS NULL
		)
	GROUP BY
		dbo.uCommerce_ProductCatalogGroup.Name,
		dbo.uCommerce_Currency.ISOCode
' 
END
GO
/****** Object:  StoredProcedure [dbo].[uCommerce_GetProductTop10]    Script Date: 09/04/2009 11:22:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_GetProductTop10]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE PROCEDURE [dbo].[uCommerce_GetProductTop10]
(
	@ProductCatalogGroupId INT
)
AS
	SET NOCOUNT ON
	
	SELECT TOP 10
		dbo.uCommerce_ProductCatalogGroup.Name,
		dbo.uCommerce_OrderLine.Sku,
		dbo.uCommerce_OrderLine.ProductName,
		SUM(dbo.uCommerce_OrderLine.Quantity) TotalSales,
		SUM(ISNULL(dbo.uCommerce_OrderLine.Total, 0)) TotalRevenue,
		dbo.uCommerce_Currency.ISOCode Currency
	FROM
		dbo.uCommerce_OrderLine
		JOIN dbo.uCommerce_PurchaseOrder ON dbo.uCommerce_PurchaseOrder.OrderId = dbo.uCommerce_OrderLine.OrderId
		JOIN dbo.uCommerce_Currency ON dbo.uCommerce_Currency.CurrencyId = dbo.uCommerce_PurchaseOrder.CurrencyId
		LEFT JOIN dbo.uCommerce_ProductCatalogGroup ON dbo.uCommerce_ProductCatalogGroup.ProductCatalogGroupId = dbo.uCommerce_PurchaseOrder.ProductCatalogGroupId
	WHERE
		dbo.uCommerce_ProductCatalogGroup.ProductCatalogGroupId = @ProductCatalogGroupId
		OR
		@ProductCatalogGroupId IS NULL
	GROUP BY
		dbo.uCommerce_OrderLine.Sku,
		dbo.uCommerce_OrderLine.ProductName,
		dbo.uCommerce_ProductCatalogGroup.Name,
		dbo.uCommerce_Currency.ISOCode
	ORDER BY
		SUM(dbo.uCommerce_OrderLine.Quantity) DESC,
		dbo.uCommerce_ProductCatalogGroup.Name

' 
END
GO
/****** Object:  StoredProcedure [dbo].[uCommerce_GetProductView]    Script Date: 09/04/2009 11:22:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_GetProductView]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
create PROCEDURE [dbo].[uCommerce_GetProductView] 
	@ProductCatalogId INT,
	@CategoryID INT,
	@CultureCode NVARCHAR(50),
	@ProductId INT = NULL,
	@IncludeVariants BIT = 0,
	@IncludeInvisibleProducts BIT = 0
AS
BEGIN
	SET NOCOUNT ON;

	SELECT
            dbo.Product.ProductId, 
			dbo.Product.Sku, 
			dbo.Product.VariantSku, 
			dbo.Product.Name, 
			dbo.Product.DisplayOnSite, 
			dbo.Product.PrimaryImageMediaId, 
            dbo.Currency.ISOCode AS Currency, 
			dbo.PriceGroup.VATRate, 
			dbo.PriceGroupPrice.DiscountPrice AS DiscountPriceAmount, 
			dbo.PriceGroupPrice.Price AS PriceAmount, 
            dbo.ProductDefinition.Name AS ProductDefinitionDisplayName, 
			dbo.ProductDescription.CultureCode, dbo.ProductDescription.DisplayName, 
            dbo.ProductDescription.ShortDescription, 
			dbo.ProductDescription.LongDescription, 
			dbo.InventoryRecord.OnHandQuantity, 
			dbo.InventoryRecord.ReservedQuantity,                     
			dbo.InventoryRecord.Location, 
			dbo.ProductCatalog.Name AS ProductCatalogName, 
			dbo.ProductCatalog.ShowPricesIncludingVAT AS ShowPriceIncludingVAT,
			dbo.Product.ThumbnailImageMediaId
	FROM 
			dbo.Product 
			INNER JOIN dbo.ProductDefinition ON dbo.Product.ProductDefinitionId = dbo.ProductDefinition.ProductDefinitionId 
			INNER JOIN dbo.ProductDescription ON dbo.Product.ProductId = dbo.ProductDescription.ProductId -- Sproget version af beskrivelse, en række per sprog
			-- Catalog info
			LEFT JOIN dbo.CategoryProductRelation ON dbo.CategoryProductRelation.ProductId = dbo.Product.ProductId
			LEFT JOIN dbo.Category ON dbo.Category.CategoryId = dbo.CategoryProductRelation.CategoryId
			LEFT JOIN dbo.ProductCatalog ON dbo.ProductCatalog.ProductCatalogId = dbo.Category.ProductCatalogId
			-- Pricing Info
			LEFT JOIN dbo.PriceGroupPrice ON dbo.PriceGroupPrice.ProductId = dbo.Product.ProductId AND dbo.ProductCatalog.PriceGroupId = dbo.PriceGroupPrice.PriceGroupId
			LEFT JOIN dbo.PriceGroup ON dbo.PriceGroup.PriceGroupId = dbo.PriceGroupPrice.PriceGroupId
			LEFT JOIN dbo.Currency ON dbo.Currency.CurrencyId = dbo.PriceGroup.CurrencyId
			-- Inventory info
			LEFT OUTER JOIN dbo.Inventory ON dbo.ProductCatalog.InventoryId = dbo.Inventory.InventoryId 
			LEFT OUTER JOIN dbo.InventoryRecord ON dbo.Product.ProductId = dbo.InventoryRecord.ProductId AND dbo.Inventory.InventoryId = dbo.InventoryRecord.InventoryId
WHERE		
			(dbo.ProductCatalog.ProductCatalogId = @ProductCatalogId) AND 
			(dbo.ProductDescription.CultureCode = @CultureCode) AND 
			(dbo.CategoryProductRelation.CategoryId = @CategoryId) AND 
			(dbo.Product.ProductId = @ProductId OR @ProductId IS NULL) AND
			(dbo.Product.VariantSKU IS NULL OR @IncludeVariants = 1) 
			AND
			(
				(dbo.Product.DisplayOnSite = 1)
				OR
				(@IncludeInvisibleProducts = 1)
			)
END
' 
END
GO
/****** Object:  StoredProcedure [dbo].[uCommerce_ProductSearchSimple]    Script Date: 09/04/2009 11:22:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductSearchSimple]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE PROCEDURE [dbo].[uCommerce_ProductSearchSimple] 
	@SearchTerm NVARCHAR(MAX),
	@LimitToCatalogIds NVARCHAR(MAX) -- comma separeted string of ints
AS
	SET NOCOUNT ON

	-- Escape special characters
	SELECT @SearchTerm = 
					REPLACE( 
					REPLACE( 
					REPLACE( 
					REPLACE(
					REPLACE(
					REPLACE( @SearchTerm
					,    ''\'', ''\\''  )
					,	 ''--'', ''''   )
					,	 '''''''', ''\'''''')                
					,    ''%'', ''\%''  )
					,    ''_'', ''\_''  )
					,    ''['', ''\[''  )

	SELECT @SearchTerm = ''%'' + @SearchTerm + ''%''

	SELECT DISTINCT
		 Product.*
	FROM
		Product
		JOIN ProductProperty
			ON ProductProperty.ProductId = Product.ProductId
		JOIN ProductDefinitionField
			ON ProductDefinitionField.ProductDefinitionFieldId = ProductProperty.ProductDefinitionFieldId
		LEFT JOIN CategoryProductRelation
			ON CategoryProductRelation.ProductId = Product.ProductId
		LEFT JOIN Category
			ON Category.CategoryId = CategoryProductRelation.CategoryId
		LEFT JOIN ProductCatalog
			ON ProductCatalog.ProductCatalogId = Category.ProductCatalogId
		LEFT JOIN dbo.ParseArrayToTable(@LimitToCatalogIds, '';'', 1) LimitToCatalogIdsTable
			ON LimitToCatalogIdsTable.NumericValue = ProductCatalog.ProductCatalogId OR @LimitToCatalogIds = '''' OR @LimitToCatalogIds IS NULL
	WHERE
		(
			CategoryProductRelation.CategoryId IS NOT NULL
			AND
			(
				Product.Sku LIKE @SearchTerm
				OR
				Product.VariantSku LIKE @SearchTerm
				OR
				Product.Name LIKE @SearchTerm
				OR
				ProductProperty.Value LIKE @SearchTerm
			)
		)	
		OR
		(	-- Include products not in any category, which also matches the search term
			CategoryProductRelation.CategoryId IS NULL
			AND
			(	-- But only if no catalog ids to limit to were provided
				@LimitToCatalogIds IS NULL 
				OR
				@LimitToCatalogIds = ''''
			)
			AND
			(
				Product.Sku LIKE @SearchTerm
				OR
				Product.VariantSku LIKE @SearchTerm
				OR
				Product.Name LIKE @SearchTerm
				OR
				ProductProperty.Value LIKE @SearchTerm
			)
		)				
' 
END
GO
/****** Object:  Table [dbo].[uCommerce_DataType]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DataType]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_DataType](
	[DataTypeId] [int] IDENTITY(1,1) NOT NULL,
	[TypeName] [nvarchar](50) NOT NULL,
	[Nullable] [bit] NOT NULL,
	[ValidationExpression] [nvarchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[BuiltIn] [bit] NOT NULL,
	[DefinitionName] [nvarchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [uCommerce_PK_DataType] PRIMARY KEY CLUSTERED 
(
	[DataTypeId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_DataType] ON
INSERT [dbo].[uCommerce_DataType] ([DataTypeId], [TypeName], [Nullable], [ValidationExpression], [BuiltIn], [DefinitionName]) VALUES (1, N'ShortText', 1, N'', 1, N'Text')
INSERT [dbo].[uCommerce_DataType] ([DataTypeId], [TypeName], [Nullable], [ValidationExpression], [BuiltIn], [DefinitionName]) VALUES (2, N'LongText', 1, N'', 1, N'Text')
INSERT [dbo].[uCommerce_DataType] ([DataTypeId], [TypeName], [Nullable], [ValidationExpression], [BuiltIn], [DefinitionName]) VALUES (3, N'Number', 1, N'', 1, N'Text')
INSERT [dbo].[uCommerce_DataType] ([DataTypeId], [TypeName], [Nullable], [ValidationExpression], [BuiltIn], [DefinitionName]) VALUES (6, N'Boolean', 0, N'', 1, N'Boolean')
INSERT [dbo].[uCommerce_DataType] ([DataTypeId], [TypeName], [Nullable], [ValidationExpression], [BuiltIn], [DefinitionName]) VALUES (8, N'Image', 1, N'', 1, N'Text')
INSERT [dbo].[uCommerce_DataType] ([DataTypeId], [TypeName], [Nullable], [ValidationExpression], [BuiltIn], [DefinitionName]) VALUES (13, N'License', 0, N'', 0, N'Enum')
INSERT [dbo].[uCommerce_DataType] ([DataTypeId], [TypeName], [Nullable], [ValidationExpression], [BuiltIn], [DefinitionName]) VALUES (14, N'SupportCoupons', 0, N'', 0, N'Enum')
SET IDENTITY_INSERT [dbo].[uCommerce_DataType] OFF
/****** Object:  Table [dbo].[uCommerce_Customer]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_Customer]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_Customer](
	[CustomerId] [int] IDENTITY(1,1) NOT NULL,
	[FirstName] [nvarchar](512) NOT NULL,
	[LastName] [nvarchar](512) NOT NULL,
	[EmailAddress] [nvarchar](50) NULL,
	[PhoneNumber] [nvarchar](50) NULL,
	[MobilePhoneNumber] [nvarchar](50) NULL,
	[UmbracoMemberId] [int] NULL,
 CONSTRAINT [uCommerce_PK_Customer] PRIMARY KEY CLUSTERED 
(
	[CustomerId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_Customer] ON
INSERT [dbo].[uCommerce_Customer] ([CustomerId], [FirstName], [LastName], [EmailAddress], [PhoneNumber], [MobilePhoneNumber], [UmbracoMemberId]) VALUES (66, N'Lasse', N'Eskildsen', N'lasse.eskildsen@uCommerce.dk', N'61997779', N'', NULL)
INSERT [dbo].[uCommerce_Customer] ([CustomerId], [FirstName], [LastName], [EmailAddress], [PhoneNumber], [MobilePhoneNumber], [UmbracoMemberId]) VALUES (67, N'Joe', N'Developer', N'', N'', N'', 1125)
INSERT [dbo].[uCommerce_Customer] ([CustomerId], [FirstName], [LastName], [EmailAddress], [PhoneNumber], [MobilePhoneNumber], [UmbracoMemberId]) VALUES (68, N'ælkj', N'ælk', N'leskil99@gmail.com', N'', N'', 1122)
SET IDENTITY_INSERT [dbo].[uCommerce_Customer] OFF
/****** Object:  Table [dbo].[uCommerce_Currency]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_Currency]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_Currency](
	[CurrencyId] [int] IDENTITY(1,1) NOT NULL,
	[ISOCode] [nvarchar](50) NOT NULL,
	[ExchangeRate] [int] NOT NULL,
 CONSTRAINT [uCommerce_PK_Currency] PRIMARY KEY CLUSTERED 
(
	[CurrencyId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_Currency] ON
INSERT [dbo].[uCommerce_Currency] ([CurrencyId], [ISOCode], [ExchangeRate]) VALUES (5, N'EUR', 100)
INSERT [dbo].[uCommerce_Currency] ([CurrencyId], [ISOCode], [ExchangeRate]) VALUES (6, N'GBP', 88)
INSERT [dbo].[uCommerce_Currency] ([CurrencyId], [ISOCode], [ExchangeRate]) VALUES (7, N'USD', 143)
INSERT [dbo].[uCommerce_Currency] ([CurrencyId], [ISOCode], [ExchangeRate]) VALUES (8, N'DKK', 744)
SET IDENTITY_INSERT [dbo].[uCommerce_Currency] OFF
/****** Object:  Table [dbo].[uCommerce_Country]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_Country]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_Country](
	[CountryId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](128) NOT NULL,
	[Culture] [nvarchar](5) NOT NULL,
 CONSTRAINT [uCommerce_PK_Country] PRIMARY KEY CLUSTERED 
(
	[CountryId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_Country] ON
INSERT [dbo].[uCommerce_Country] ([CountryId], [Name], [Culture]) VALUES (6, N'Denmark', N'da-DK')
INSERT [dbo].[uCommerce_Country] ([CountryId], [Name], [Culture]) VALUES (7, N'USA', N'en-US')
INSERT [dbo].[uCommerce_Country] ([CountryId], [Name], [Culture]) VALUES (8, N'United States', N'en-us')
INSERT [dbo].[uCommerce_Country] ([CountryId], [Name], [Culture]) VALUES (9, N'Great Britain', N'en-GB')
INSERT [dbo].[uCommerce_Country] ([CountryId], [Name], [Culture]) VALUES (10, N'United Kingdom', N'en-GB')
INSERT [dbo].[uCommerce_Country] ([CountryId], [Name], [Culture]) VALUES (11, N'Germany', N'de-DE')
INSERT [dbo].[uCommerce_Country] ([CountryId], [Name], [Culture]) VALUES (12, N'Sweden', N'sv-SE')
INSERT [dbo].[uCommerce_Country] ([CountryId], [Name], [Culture]) VALUES (13, N'Norway', N'nb-NO')
SET IDENTITY_INSERT [dbo].[uCommerce_Country] OFF
/****** Object:  Table [dbo].[uCommerce_OrderStatus]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderStatus]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_OrderStatus](
	[OrderStatusId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Sort] [int] NOT NULL,
	[RenderChildren] [bit] NOT NULL,
	[RenderInMenu] [bit] NOT NULL,
	[NextOrderStatusId] [int] NULL,
	[ExternalId] [nvarchar](50) NULL,
	[IncludeInAuditTrail] [bit] NOT NULL,
	[Order] [int] NULL,
	[AllowUpdate] [bit] NOT NULL,
	[AlwaysAvailable] [bit] NOT NULL,
	[Pipeline] [nvarchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [uCommerce_PK_OrderStatus] PRIMARY KEY CLUSTERED 
(
	[OrderStatusId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_OrderStatus] ON
INSERT [dbo].[uCommerce_OrderStatus] ([OrderStatusId], [Name], [Sort], [RenderChildren], [RenderInMenu], [NextOrderStatusId], [ExternalId], [IncludeInAuditTrail], [Order], [AllowUpdate], [AlwaysAvailable], [Pipeline]) VALUES (1, N'Basket', 5, 0, 0, NULL, NULL, 1, NULL, 1, 0, NULL)
INSERT [dbo].[uCommerce_OrderStatus] ([OrderStatusId], [Name], [Sort], [RenderChildren], [RenderInMenu], [NextOrderStatusId], [ExternalId], [IncludeInAuditTrail], [Order], [AllowUpdate], [AlwaysAvailable], [Pipeline]) VALUES (2, N'New order', 2, 1, 1, 3, NULL, 1, NULL, 1, 0, NULL)
INSERT [dbo].[uCommerce_OrderStatus] ([OrderStatusId], [Name], [Sort], [RenderChildren], [RenderInMenu], [NextOrderStatusId], [ExternalId], [IncludeInAuditTrail], [Order], [AllowUpdate], [AlwaysAvailable], [Pipeline]) VALUES (3, N'Completed order', 3, 1, 1, 5, NULL, 1, NULL, 1, 0, NULL)
INSERT [dbo].[uCommerce_OrderStatus] ([OrderStatusId], [Name], [Sort], [RenderChildren], [RenderInMenu], [NextOrderStatusId], [ExternalId], [IncludeInAuditTrail], [Order], [AllowUpdate], [AlwaysAvailable], [Pipeline]) VALUES (5, N'Invoiced', 5, 1, 1, 6, NULL, 1, NULL, 1, 0, NULL)
INSERT [dbo].[uCommerce_OrderStatus] ([OrderStatusId], [Name], [Sort], [RenderChildren], [RenderInMenu], [NextOrderStatusId], [ExternalId], [IncludeInAuditTrail], [Order], [AllowUpdate], [AlwaysAvailable], [Pipeline]) VALUES (6, N'Paid', 6, 1, 1, NULL, NULL, 1, NULL, 0, 0, NULL)
INSERT [dbo].[uCommerce_OrderStatus] ([OrderStatusId], [Name], [Sort], [RenderChildren], [RenderInMenu], [NextOrderStatusId], [ExternalId], [IncludeInAuditTrail], [Order], [AllowUpdate], [AlwaysAvailable], [Pipeline]) VALUES (7, N'Cancelled', 7, 1, 1, NULL, NULL, 1, NULL, 1, 1, NULL)
SET IDENTITY_INSERT [dbo].[uCommerce_OrderStatus] OFF
/****** Object:  Table [dbo].[uCommerce_OrderNumberSerie]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderNumberSerie]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_OrderNumberSerie](
	[OrderNumberId] [int] IDENTITY(1,1) NOT NULL,
	[OrderNumberName] [nvarchar](128) NOT NULL,
	[Prefix] [nvarchar](50) NULL,
	[Postfix] [nvarchar](50) NULL,
	[Increment] [int] NOT NULL,
	[CurrentNumber] [int] NOT NULL,
 CONSTRAINT [uCommerce_PK_OrderNumbers_1] PRIMARY KEY CLUSTERED 
(
	[OrderNumberId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderNumberSerie]') AND name = N'IX_OrderNumbers')
CREATE UNIQUE NONCLUSTERED INDEX [IX_OrderNumbers] ON [dbo].[uCommerce_OrderNumberSerie] 
(
	[OrderNumberName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
GO
SET IDENTITY_INSERT [dbo].[uCommerce_OrderNumberSerie] ON
INSERT [dbo].[uCommerce_OrderNumberSerie] ([OrderNumberId], [OrderNumberName], [Prefix], [Postfix], [Increment], [CurrentNumber]) VALUES (3, N'Default', N'WEB-', N'', 1, 3)
SET IDENTITY_INSERT [dbo].[uCommerce_OrderNumberSerie] OFF
/****** Object:  Table [dbo].[uCommerce_PaymentMethod]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentMethod]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_PaymentMethod](
	[PaymentMethodId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](128) NOT NULL,
	[FeePercent] [decimal](18, 4) NOT NULL,
	[ImageMediaId] [int] NULL,
	[PaymentMethodServiceName] [nvarchar](512) NULL,
	[Enabled] [bit] NOT NULL,
	[Deleted] [bit] NOT NULL,
	[ModifiedOn] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](50) NULL,
 CONSTRAINT [uCommerce_PK_PaymentMethod] PRIMARY KEY CLUSTERED 
(
	[PaymentMethodId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_PaymentMethod] ON
INSERT [dbo].[uCommerce_PaymentMethod] ([PaymentMethodId], [Name], [FeePercent], [ImageMediaId], [PaymentMethodServiceName], [Enabled], [Deleted], [ModifiedOn], [ModifiedBy]) VALUES (6, N'Account', CAST(0.0000 AS Decimal(18, 4)), NULL, NULL, 1, 0, CAST(0x00009C750122D56D AS DateTime), N'uCommerce')
INSERT [dbo].[uCommerce_PaymentMethod] ([PaymentMethodId], [Name], [FeePercent], [ImageMediaId], [PaymentMethodServiceName], [Enabled], [Deleted], [ModifiedOn], [ModifiedBy]) VALUES (7, N'Invoice', CAST(0.0000 AS Decimal(18, 4)), NULL, NULL, 1, 0, CAST(0x00009C7501238875 AS DateTime), N'uCommerce')
SET IDENTITY_INSERT [dbo].[uCommerce_PaymentMethod] OFF
/****** Object:  Table [dbo].[uCommerce_EmailType]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_EmailType]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_EmailType](
	[EmailTypeId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](128) NOT NULL,
	[Description] [ntext] NULL,
	[CreatedOn] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](50) NOT NULL,
	[ModifiedOn] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](50) NOT NULL,
	[Deleted] [bit] NOT NULL,
 CONSTRAINT [uCommerce_PK_EmailType] PRIMARY KEY CLUSTERED 
(
	[EmailTypeId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_EmailType] ON
INSERT [dbo].[uCommerce_EmailType] ([EmailTypeId], [Name], [Description], [CreatedOn], [CreatedBy], [ModifiedOn], [ModifiedBy], [Deleted]) VALUES (4, N'OrderConfirmation', N'E-mail which will be sent to the customer after checkout.', CAST(0x00009C7500DD1FB9 AS DateTime), N'uCommerce', CAST(0x00009C7500DD1FBA AS DateTime), N'uCommerce', 0)
SET IDENTITY_INSERT [dbo].[uCommerce_EmailType] OFF
/****** Object:  Table [dbo].[uCommerce_EmailProfileInformation]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_EmailProfileInformation]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_EmailProfileInformation](
	[EmailProfileInformationId] int identity(1,1) not null,
	[EmailProfileId] [int] NOT NULL,
	[EmailTypeId] [int] NOT NULL,
	[FromName] [nvarchar](512) NOT NULL,
	[FromAddress] [nvarchar](512) NOT NULL,
	[CcAddress] [nvarchar](512) NULL,
	[BccAddress] [nvarchar](512) NULL,
	CONSTRAINT [uCommerce_PK_EmailProfileInformation] PRIMARY KEY CLUSTERED 
	(
		[EmailProfileInformationId] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
INSERT [dbo].[uCommerce_EmailProfileInformation] ([EmailProfileId], [EmailTypeId], [FromName], [FromAddress], [CcAddress], [BccAddress]) VALUES (5, 4, N'uCommerce Demo Shop', N'demo@uCommerce.dk', N'', N'')
/****** Object:  Table [dbo].[uCommerce_EmailProfile]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_EmailProfile]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_EmailProfile](
	[EmailProfileId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](128) NOT NULL,
	[ModifiedOn] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](50) NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](50) NOT NULL,
	[Deleted] [bit] NOT NULL,
 CONSTRAINT [uCommerce_PK_EmailProfile] PRIMARY KEY CLUSTERED 
(
	[EmailProfileId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_EmailProfile] ON
INSERT [dbo].[uCommerce_EmailProfile] ([EmailProfileId], [Name], [ModifiedOn], [ModifiedBy], [CreatedOn], [CreatedBy], [Deleted]) VALUES (5, N'Default', CAST(0x00009C7500DE9ED5 AS DateTime), N'uCommerce', CAST(0x00009C7500DE9ED5 AS DateTime), N'uCommerce', 0)
SET IDENTITY_INSERT [dbo].[uCommerce_EmailProfile] OFF
/****** Object:  Table [dbo].[uCommerce_EmailParameter]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_EmailParameter]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_EmailParameter](
	[EmailParameterId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[GlobalResourceKey] [nvarchar](50) NOT NULL,
	[QueryStringKey] [nvarchar](50) NOT NULL,
 CONSTRAINT [uCommerce_PK_EmailParameter] PRIMARY KEY CLUSTERED 
(
	[EmailParameterId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_EmailParameter] ON
INSERT [dbo].[uCommerce_EmailParameter] ([EmailParameterId], [Name], [GlobalResourceKey], [QueryStringKey]) VALUES (1, N'Order ID', N'OrderIDParameter', N'OrderId')
INSERT [dbo].[uCommerce_EmailParameter] ([EmailParameterId], [Name], [GlobalResourceKey], [QueryStringKey]) VALUES (2, N'Customer ID', N'CustomerIDParameter', N'CustomerId')
SET IDENTITY_INSERT [dbo].[uCommerce_EmailParameter] OFF
/****** Object:  Table [dbo].[uCommerce_AdminPage]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_AdminPage]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_AdminPage](
	[AdminPageId] [int] IDENTITY(1,1) NOT NULL,
	[FullName] [nvarchar](256) NOT NULL,
 CONSTRAINT [uCommerce_PK_AdminPage] PRIMARY KEY CLUSTERED 
(
	[AdminPageId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_AdminPage]') AND name = N'IX_AdminPage')
CREATE UNIQUE NONCLUSTERED INDEX [IX_AdminPage] ON [dbo].[uCommerce_AdminPage] 
(
	[FullName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
GO
SET IDENTITY_INSERT [dbo].[uCommerce_AdminPage] ON
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (22, N'ASP.umbraco_uCommerce_analytics_orderanalytics_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (23, N'ASP.umbraco_uCommerce_analytics_productanalytics_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (16, N'ASP.umbraco_uCommerce_catalog_dialogs_editvariantdescription_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (4, N'ASP.umbraco_uCommerce_catalog_editcategory_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (1, N'ASP.umbraco_uCommerce_catalog_editproduct_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (3, N'ASP.umbraco_uCommerce_catalog_editproductcatalog_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (2, N'ASP.umbraco_uCommerce_catalog_editproductcataloggroup_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (5, N'ASP.umbraco_uCommerce_orders_editorder_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (21, N'ASP.umbraco_uCommerce_orders_search_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (20, N'ASP.umbraco_uCommerce_orders_viewordergroup_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (14, N'ASP.umbraco_uCommerce_settings_catalog_editdatatype_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (15, N'ASP.umbraco_uCommerce_settings_catalog_editdatatypeenum_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (13, N'ASP.umbraco_uCommerce_settings_catalog_editpricegroup_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (6, N'ASP.umbraco_uCommerce_settings_catalog_editproductdefinition_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (7, N'ASP.umbraco_uCommerce_settings_catalog_editproductdefinitionfield_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (10, N'ASP.umbraco_uCommerce_settings_email_editemailprofile_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (12, N'ASP.umbraco_uCommerce_settings_email_editemailprofiletype_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (11, N'ASP.umbraco_uCommerce_settings_email_editemailtype_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (17, N'ASP.umbraco_uCommerce_settings_orders_editcountry_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (18, N'ASP.umbraco_uCommerce_settings_orders_editcurrency_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (19, N'ASP.umbraco_uCommerce_settings_orders_editordernumberserie_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (9, N'ASP.umbraco_uCommerce_settings_orders_editpaymentmethod_aspx')
INSERT [dbo].[uCommerce_AdminPage] ([AdminPageId], [FullName]) VALUES (8, N'ASP.umbraco_uCommerce_settings_orders_editshippingmethod_aspx')
SET IDENTITY_INSERT [dbo].[uCommerce_AdminPage] OFF
/****** Object:  Table [dbo].[uCommerce_Address]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_Address]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_Address](
	[AddressId] [int] IDENTITY(1,1) NOT NULL,
	[Line1] [nvarchar](512) NOT NULL,
	[Line2] [nvarchar](512) NULL,
	[PostalCode] [nvarchar](50) NOT NULL,
	[City] [nvarchar](512) NOT NULL,
	[State] [nvarchar](512) NULL,
	[CountryId] [int] NOT NULL,
	[Attention] [nvarchar](512) NULL,
	[CustomerId] [int] NOT NULL,
	[CompanyName] [nvarchar](512) NULL,
	[AddressName] [nvarchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [uCommerce_PK_Address] PRIMARY KEY CLUSTERED 
(
	[AddressId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_Address] ON
INSERT [dbo].[uCommerce_Address] ([AddressId], [Line1], [Line2], [PostalCode], [City], [State], [CountryId], [Attention], [CustomerId], [CompanyName], [AddressName]) VALUES (46, N'Ny Banegårdsgade 55', N'', N'8000', N'Århus C', N'', 6, N'', 66, N'uCommerce', N'Billing')
INSERT [dbo].[uCommerce_Address] ([AddressId], [Line1], [Line2], [PostalCode], [City], [State], [CountryId], [Attention], [CustomerId], [CompanyName], [AddressName]) VALUES (47, N'Somewhere', N'', N'9000', N'Mytown', N'', 6, N'', 67, N'SomeCompany', N'Billing')
INSERT [dbo].[uCommerce_Address] ([AddressId], [Line1], [Line2], [PostalCode], [City], [State], [CountryId], [Attention], [CustomerId], [CompanyName], [AddressName]) VALUES (48, N'kj', N'ælk', N'jælk', N'ælkj', N'', 6, N'ælkj', 68, N'jæl', N'Billing')
SET IDENTITY_INSERT [dbo].[uCommerce_Address] OFF
/****** Object:  Table [dbo].[uCommerce_DataTypeEnum]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DataTypeEnum]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_DataTypeEnum](
	[DataTypeEnumId] [int] IDENTITY(1,1) NOT NULL,
	[DataTypeId] [int] NOT NULL,
	[Value] [nvarchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [uCommerce_PK_DataTypeEnum] PRIMARY KEY CLUSTERED 
(
	[DataTypeEnumId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_DataTypeEnum] ON
INSERT [dbo].[uCommerce_DataTypeEnum] ([DataTypeEnumId], [DataTypeId], [Value]) VALUES (13, 13, N'Dev')
INSERT [dbo].[uCommerce_DataTypeEnum] ([DataTypeEnumId], [DataTypeId], [Value]) VALUES (14, 13, N'Eval')
INSERT [dbo].[uCommerce_DataTypeEnum] ([DataTypeEnumId], [DataTypeId], [Value]) VALUES (15, 13, N'Live')
INSERT [dbo].[uCommerce_DataTypeEnum] ([DataTypeEnumId], [DataTypeId], [Value]) VALUES (16, 14, N'5')
INSERT [dbo].[uCommerce_DataTypeEnum] ([DataTypeEnumId], [DataTypeId], [Value]) VALUES (17, 14, N'10')
INSERT [dbo].[uCommerce_DataTypeEnum] ([DataTypeEnumId], [DataTypeId], [Value]) VALUES (18, 14, N'15')
SET IDENTITY_INSERT [dbo].[uCommerce_DataTypeEnum] OFF
/****** Object:  Table [dbo].[uCommerce_EmailContent]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_EmailContent]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_EmailContent](
	[EmailContentId] [int] IDENTITY(1,1) NOT NULL,
	[EmailProfileId] [int] NOT NULL,
	[EmailTypeId] [int] NOT NULL,
	[CultureCode] [varchar](5) NOT NULL,
	[Subject] [ntext] NULL,
	[ContentId] [int] NOT NULL,
 CONSTRAINT [uCommerce_PK_EmailContent] PRIMARY KEY CLUSTERED 
(
	[EmailContentId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_EmailContent] ON
INSERT [dbo].[uCommerce_EmailContent] ([EmailContentId], [EmailProfileId], [EmailTypeId], [CultureCode], [Subject], [ContentId]) VALUES (7, 5, 4, N'en-US', N'Order Confirmation', 1130)
INSERT [dbo].[uCommerce_EmailContent] ([EmailContentId], [EmailProfileId], [EmailTypeId], [CultureCode], [Subject], [ContentId]) VALUES (8, 5, 4, N'da-DK', N'Ordrebekræftelse', 1130)
SET IDENTITY_INSERT [dbo].[uCommerce_EmailContent] OFF
/****** Object:  Table [dbo].[uCommerce_ProductCatalogGroup]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroup]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_ProductCatalogGroup](
	[ProductCatalogGroupId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](128) NOT NULL,
	[Description] [ntext] NULL,
	[EmailProfileId] [int] NOT NULL,
	[CurrencyId] [int] NOT NULL,
	[UmbracoDomainId] [int] NULL,
	[OrderNumberId] [int] NULL,
	[Deleted] [bit] NOT NULL,
	[CreateCustomersAsUmbracoMembers] [bit] NOT NULL,
	[UmbracoMemberGroupId] [int] NULL,
	[UmbracoMemberTypeId] [int] NULL,
 CONSTRAINT [uCommerce_PK_CatalogGroup] PRIMARY KEY CLUSTERED 
(
	[ProductCatalogGroupId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_ProductCatalogGroup] ON
INSERT [dbo].[uCommerce_ProductCatalogGroup] ([ProductCatalogGroupId], [Name], [Description], [EmailProfileId], [CurrencyId], [UmbracoDomainId], [OrderNumberId], [Deleted], [CreateCustomersAsUmbracoMembers], [UmbracoMemberGroupId], [UmbracoMemberTypeId]) VALUES (13, N'uCommerce.dk', N'', 5, 5, NULL, 3, 0, 0, 0, 0)
SET IDENTITY_INSERT [dbo].[uCommerce_ProductCatalogGroup] OFF
/****** Object:  Table [dbo].[uCommerce_ProductDefinitionField]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDefinitionField]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_ProductDefinitionField](
	[ProductDefinitionFieldId] [int] IDENTITY(1,1) NOT NULL,
	[DataTypeId] [int] NOT NULL,
	[ProductDefinitionId] [int] NOT NULL,
	[Name] [nvarchar](512) NOT NULL,
	[DisplayOnSite] [bit] NOT NULL,
	[IsVariantProperty] [bit] NOT NULL,
	[Multilingual] [bit] NOT NULL,
	[RenderInEditor] [bit] NOT NULL,
	[Searchable] [bit] NOT NULL,
	[Deleted] [bit] NOT NULL,
 CONSTRAINT [uCommerce_PK_ProductDefinitionField] PRIMARY KEY CLUSTERED 
(
	[ProductDefinitionFieldId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_ProductDefinitionField] ON
INSERT [dbo].[uCommerce_ProductDefinitionField] ([ProductDefinitionFieldId], [DataTypeId], [ProductDefinitionId], [Name], [DisplayOnSite], [IsVariantProperty], [Multilingual], [RenderInEditor], [Searchable], [Deleted]) VALUES (37, 6, 19, N'Downloadable', 1, 1, 0, 1, 0, 0)
INSERT [dbo].[uCommerce_ProductDefinitionField] ([ProductDefinitionFieldId], [DataTypeId], [ProductDefinitionId], [Name], [DisplayOnSite], [IsVariantProperty], [Multilingual], [RenderInEditor], [Searchable], [Deleted]) VALUES (38, 13, 19, N'License', 1, 1, 0, 1, 0, 0)
INSERT [dbo].[uCommerce_ProductDefinitionField] ([ProductDefinitionFieldId], [DataTypeId], [ProductDefinitionId], [Name], [DisplayOnSite], [IsVariantProperty], [Multilingual], [RenderInEditor], [Searchable], [Deleted]) VALUES (39, 14, 20, N'Coupons', 1, 1, 0, 1, 0, 0)
SET IDENTITY_INSERT [dbo].[uCommerce_ProductDefinitionField] OFF
/****** Object:  StoredProcedure [dbo].[uCommerce_GetOrderNumber]    Script Date: 09/04/2009 11:22:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_GetOrderNumber]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE PROCEDURE [dbo].[uCommerce_GetOrderNumber]
	@OrderNumberName NVARCHAR(128)
AS
BEGIN	
	SET NOCOUNT ON;

	DECLARE @OrderNumber NVARCHAR(256);

	BEGIN TRANSACTION
		SELECT @OrderNumber = ISNULL(Prefix,'''') + CONVERT(NVARCHAR(256),(CurrentNumber + Increment)) + ISNULL(Postfix,'''') FROM uCommerce_OrderNumberSerie WHERE OrderNumberName = @OrderNumberName;
		UPDATE uCommerce_OrderNumberSerie
		SET CurrentNumber = CurrentNumber + Increment
		WHERE OrderNumberName = @OrderNumberName
	IF @@ERROR <> 0
	BEGIN	
		ROLLBACK TRANSACTION
	END
	ELSE
	BEGIN
		COMMIT TRANSACTION
	END

	SELECT @OrderNumber;

--SELECT ISNULL(Prefix,'''') + (CurrentNumber + Increment) + ISNULL(Postfix,'''') FROM OrderNumbers WHERE OrderNumberName = ''default'';
    
END
' 
END
GO
/****** Object:  Table [dbo].[uCommerce_EmailTypeParameter]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_EmailTypeParameter]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_EmailTypeParameter](
	[EmailTypeId] [int] NOT NULL,
	[EmailParameterId] [int] NOT NULL,
 CONSTRAINT [uCommerce_PK_EmailTypeParameter] PRIMARY KEY CLUSTERED 
(
	[EmailTypeId] ASC,
	[EmailParameterId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
/****** Object:  Table [dbo].[uCommerce_PaymentMethodDescription]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentMethodDescription]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_PaymentMethodDescription](
	[PaymentMethodDescriptionId] [int] IDENTITY(1,1) NOT NULL,
	[PaymentMethodId] [int] NOT NULL,
	[CultureCode] [nvarchar](5) NOT NULL,
	[DisplayName] [nvarchar](512) NOT NULL,
	[Description] [ntext] NULL,
 CONSTRAINT [uCommerce_PK_PaymentMethodDescription] PRIMARY KEY CLUSTERED 
(
	[PaymentMethodDescriptionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_PaymentMethodDescription] ON
INSERT [dbo].[uCommerce_PaymentMethodDescription] ([PaymentMethodDescriptionId], [PaymentMethodId], [CultureCode], [DisplayName], [Description]) VALUES (1, 6, N'en-US', N'Account', N'')
INSERT [dbo].[uCommerce_PaymentMethodDescription] ([PaymentMethodDescriptionId], [PaymentMethodId], [CultureCode], [DisplayName], [Description]) VALUES (2, 6, N'da-DK', N'Konto', N'')
INSERT [dbo].[uCommerce_PaymentMethodDescription] ([PaymentMethodDescriptionId], [PaymentMethodId], [CultureCode], [DisplayName], [Description]) VALUES (3, 7, N'en-US', N'Invoice', N'')
INSERT [dbo].[uCommerce_PaymentMethodDescription] ([PaymentMethodDescriptionId], [PaymentMethodId], [CultureCode], [DisplayName], [Description]) VALUES (4, 7, N'da-DK', N'Faktura', N'')
SET IDENTITY_INSERT [dbo].[uCommerce_PaymentMethodDescription] OFF
/****** Object:  Table [dbo].[uCommerce_PaymentMethodCountry]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentMethodCountry]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_PaymentMethodCountry](
	[PaymentMethodId] [int] NOT NULL,
	[CountryId] [int] NOT NULL,
 CONSTRAINT [uCommerce_PK_PaymentMethodCountry] PRIMARY KEY CLUSTERED 
(
	[PaymentMethodId] ASC,
	[CountryId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
INSERT [dbo].[uCommerce_PaymentMethodCountry] ([PaymentMethodId], [CountryId]) VALUES (6, 6)
INSERT [dbo].[uCommerce_PaymentMethodCountry] ([PaymentMethodId], [CountryId]) VALUES (6, 7)
INSERT [dbo].[uCommerce_PaymentMethodCountry] ([PaymentMethodId], [CountryId]) VALUES (6, 8)
INSERT [dbo].[uCommerce_PaymentMethodCountry] ([PaymentMethodId], [CountryId]) VALUES (6, 9)
INSERT [dbo].[uCommerce_PaymentMethodCountry] ([PaymentMethodId], [CountryId]) VALUES (6, 10)
INSERT [dbo].[uCommerce_PaymentMethodCountry] ([PaymentMethodId], [CountryId]) VALUES (6, 11)
INSERT [dbo].[uCommerce_PaymentMethodCountry] ([PaymentMethodId], [CountryId]) VALUES (6, 12)
INSERT [dbo].[uCommerce_PaymentMethodCountry] ([PaymentMethodId], [CountryId]) VALUES (6, 13)
INSERT [dbo].[uCommerce_PaymentMethodCountry] ([PaymentMethodId], [CountryId]) VALUES (7, 6)
/****** Object:  Table [dbo].[uCommerce_OrderStatusDescription]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderStatusDescription]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_OrderStatusDescription](
	[OrderStatusId] [int] NOT NULL,
	[DisplayName] [nvarchar](128) NOT NULL,
	[Description] [ntext] NULL,
	[CultureCode] [nvarchar](5) NOT NULL,
 CONSTRAINT [uCommerce_PK_OrderStatusDescription] PRIMARY KEY CLUSTERED 
(
	[OrderStatusId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
/****** Object:  Table [dbo].[uCommerce_PriceGroup]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_PriceGroup]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_PriceGroup](
	[PriceGroupId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](128) NOT NULL,
	[CurrencyId] [int] NOT NULL,
	[VATRate] [decimal](18, 4) NOT NULL,
	[Description] [nvarchar](max) NULL,
	[CreatedOn] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](50) NOT NULL,
	[ModifiedOn] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](50) NOT NULL,
	[Deleted] [bit] NOT NULL,
 CONSTRAINT [uCommerce_PK_PriceGroup] PRIMARY KEY CLUSTERED 
(
	[PriceGroupId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_PriceGroup] ON
INSERT [dbo].[uCommerce_PriceGroup] ([PriceGroupId], [Name], [CurrencyId], [VATRate], [Description], [CreatedOn], [CreatedBy], [ModifiedOn], [ModifiedBy], [Deleted]) VALUES (6, N'EUR 15 pct', 5, CAST(0.1500 AS Decimal(18, 4)), N'Default VAT', CAST(0x00009C7500E3F955 AS DateTime), N'uCommerce', CAST(0x00009C7500E435B2 AS DateTime), N'uCommerce', 0)
SET IDENTITY_INSERT [dbo].[uCommerce_PriceGroup] OFF
/****** Object:  Table [dbo].[uCommerce_Product]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_Product]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_Product](
	[ProductId] [int] IDENTITY(1,1) NOT NULL,
	[ParentProductId] [int] NULL,
	[Sku] [nvarchar](30) NOT NULL,
	[VariantSku] [nvarchar](30) NULL,
	[Name] [nvarchar](512) NOT NULL,
	[DisplayOnSite] [bit] NOT NULL,
	[ThumbnailImageMediaId] [int] NULL,
	[PrimaryImageMediaId] [int] NULL,
	[Weight] [decimal](18, 4) NOT NULL,
	[ProductDefinitionId] [int] NOT NULL,
	[AllowOrdering] [bit] NOT NULL,
	[ModifiedBy] [nvarchar](50) NULL,
	[ModifiedOn] [datetime] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
 CONSTRAINT [uCommerce_PK_Product] PRIMARY KEY CLUSTERED 
(
	[ProductId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_Product]') AND name = N'IX_Product_UniqueSkuAndVariantSku')
CREATE UNIQUE NONCLUSTERED INDEX [IX_Product_UniqueSkuAndVariantSku] ON [dbo].[uCommerce_Product] 
(
	[Sku] ASC,
	[VariantSku] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
GO
SET IDENTITY_INSERT [dbo].[uCommerce_Product] ON
INSERT [dbo].[uCommerce_Product] ([ProductId], [ParentProductId], [Sku], [VariantSku], [Name], [DisplayOnSite], [ThumbnailImageMediaId], [PrimaryImageMediaId], [Weight], [ProductDefinitionId], [AllowOrdering], [ModifiedBy], [ModifiedOn], [CreatedOn]) VALUES (97, NULL, N'100-000-001', NULL, N'uCommerce', 1, 1097, 1097, CAST(0.0000 AS Decimal(18, 4)), 19, 1, N'uCommerce', CAST(0x00009C750104CFC8 AS DateTime), CAST(0x00009C7500F64A2F AS DateTime))
INSERT [dbo].[uCommerce_Product] ([ProductId], [ParentProductId], [Sku], [VariantSku], [Name], [DisplayOnSite], [ThumbnailImageMediaId], [PrimaryImageMediaId], [Weight], [ProductDefinitionId], [AllowOrdering], [ModifiedBy], [ModifiedOn], [CreatedOn]) VALUES (98, 97, N'100-000-001', N'001', N'Developer', 0, NULL, NULL, CAST(0.0000 AS Decimal(18, 4)), 19, 0, N'uCommerce', CAST(0x00009C750104CFE4 AS DateTime), CAST(0x00009C7500F6DA3E AS DateTime))
INSERT [dbo].[uCommerce_Product] ([ProductId], [ParentProductId], [Sku], [VariantSku], [Name], [DisplayOnSite], [ThumbnailImageMediaId], [PrimaryImageMediaId], [Weight], [ProductDefinitionId], [AllowOrdering], [ModifiedBy], [ModifiedOn], [CreatedOn]) VALUES (99, 97, N'100-000-001', N'002', N'Evaluation', 0, NULL, NULL, CAST(0.0000 AS Decimal(18, 4)), 19, 0, N'uCommerce', CAST(0x00009C750104D008 AS DateTime), CAST(0x00009C7500FA7FA8 AS DateTime))
INSERT [dbo].[uCommerce_Product] ([ProductId], [ParentProductId], [Sku], [VariantSku], [Name], [DisplayOnSite], [ThumbnailImageMediaId], [PrimaryImageMediaId], [Weight], [ProductDefinitionId], [AllowOrdering], [ModifiedBy], [ModifiedOn], [CreatedOn]) VALUES (100, 97, N'100-000-001', N'003', N'Go-Live', 0, NULL, NULL, CAST(0.0000 AS Decimal(18, 4)), 19, 0, N'uCommerce', CAST(0x00009C750104D04C AS DateTime), CAST(0x00009C7500FA9032 AS DateTime))
INSERT [dbo].[uCommerce_Product] ([ProductId], [ParentProductId], [Sku], [VariantSku], [Name], [DisplayOnSite], [ThumbnailImageMediaId], [PrimaryImageMediaId], [Weight], [ProductDefinitionId], [AllowOrdering], [ModifiedBy], [ModifiedOn], [CreatedOn]) VALUES (101, NULL, N'200-000-001', NULL, N'Support', 1, 1097, 1097, CAST(0.0000 AS Decimal(18, 4)), 20, 1, N'uCommerce', CAST(0x00009C750106C92F AS DateTime), CAST(0x00009C750106A833 AS DateTime))
INSERT [dbo].[uCommerce_Product] ([ProductId], [ParentProductId], [Sku], [VariantSku], [Name], [DisplayOnSite], [ThumbnailImageMediaId], [PrimaryImageMediaId], [Weight], [ProductDefinitionId], [AllowOrdering], [ModifiedBy], [ModifiedOn], [CreatedOn]) VALUES (102, 101, N'200-000-001', N'001', N'5', 0, NULL, NULL, CAST(0.0000 AS Decimal(18, 4)), 20, 0, N'uCommerce', CAST(0x00009C750106D292 AS DateTime), CAST(0x00009C750106B68E AS DateTime))
INSERT [dbo].[uCommerce_Product] ([ProductId], [ParentProductId], [Sku], [VariantSku], [Name], [DisplayOnSite], [ThumbnailImageMediaId], [PrimaryImageMediaId], [Weight], [ProductDefinitionId], [AllowOrdering], [ModifiedBy], [ModifiedOn], [CreatedOn]) VALUES (103, 101, N'200-000-001', N'002', N'10', 0, NULL, NULL, CAST(0.0000 AS Decimal(18, 4)), 20, 0, N'uCommerce', CAST(0x00009C750106DB2F AS DateTime), CAST(0x00009C750106BFFF AS DateTime))
INSERT [dbo].[uCommerce_Product] ([ProductId], [ParentProductId], [Sku], [VariantSku], [Name], [DisplayOnSite], [ThumbnailImageMediaId], [PrimaryImageMediaId], [Weight], [ProductDefinitionId], [AllowOrdering], [ModifiedBy], [ModifiedOn], [CreatedOn]) VALUES (104, 101, N'200-000-001', N'003', N'15', 0, NULL, NULL, CAST(0.0000 AS Decimal(18, 4)), 20, 0, N'uCommerce', CAST(0x00009C750106E071 AS DateTime), CAST(0x00009C750106C9AB AS DateTime))
SET IDENTITY_INSERT [dbo].[uCommerce_Product] OFF
/****** Object:  Table [dbo].[uCommerce_AdminTab]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_AdminTab]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_AdminTab](
	[AdminTabId] [int] IDENTITY(1,1) NOT NULL,
	[VirtualPath] [nvarchar](512) NOT NULL,
	[AdminPageId] [int] NOT NULL,
	[SortOrder] [int] NOT NULL,
	[MultiLingual] [bit] NOT NULL,
	[ResouceKey] [nvarchar](256) NULL,
	[HasSaveButton] [bit] NOT NULL,
	[HasDeleteButton] [bit] NOT NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [uCommerce_PK_AdminTab] PRIMARY KEY CLUSTERED 
(
	[AdminTabId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_AdminTab] ON
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (1, N'EditProductBaseProperties.ascx', 1, 1, 0, N'Common', 1, 1, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (3, N'EditProductVariants.ascx', 1, 2, 0, N'Variants', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (4, N'EditProductCatalogs.ascx', 1, 5, 0, N'Catalogs', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (6, N'EditProductDescription.ascx', 1, 6, 1, N'Description', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (7, N'EditProductCatalogGroup.ascx', 2, 1, 0, N'Common', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (9, N'EditProductCatalogBaseProperties.ascx', 3, 1, 0, N'Common', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (10, N'EditProductCatalogAccess.ascx', 3, 2, 0, N'Access', 1, 0, 0)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (11, N'EditProductCatalogDescription.ascx', 3, 3, 1, N'Description', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (12, N'EditCategoryBaseProperties.ascx', 4, 1, 0, N'Common', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (13, N'EditCategoryMedia.ascx', 4, 2, 0, N'Media', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (14, N'EditCategoryDescription.ascx', 4, 4, 1, N'Description', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (15, N'EditCategoryProducts.ascx', 4, 3, 0, N'Products', 0, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (16, N'EditProductMedia.ascx', 1, 4, 0, N'Media', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (17, N'EditProductPricing.ascx', 1, 3, 0, N'Pricing', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (18, N'EditOrderOverview.ascx', 5, 1, 0, N'Overview', 0, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (19, N'EditOrderAudit.ascx', 5, 3, 0, N'Audit', 0, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (21, N'EditProductDefinitionBaseProperties.ascx', 6, 1, 0, N'Common', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (22, N'EditProductDefinitionFieldBaseProperties.ascx', 7, 1, 0, N'Common', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (23, N'EditProductDefinitionFieldDescription.ascx', 7, 2, 1, N'Description', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (24, N'EditShippingMethodBaseProperties.ascx', 8, 1, 0, N'Common', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (26, N'EditShippingMethodAvailability.ascx', 8, 2, 0, N'Availability', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (27, N'EditShippingMethodPrices.ascx', 8, 3, 0, N'Pricing', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (28, N'EditShippingMethodDescription.ascx', 8, 4, 1, N'Description', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (29, N'EditPaymentMethodBaseProperties.ascx', 9, 1, 0, N'Common', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (30, N'EditPaymentMethodPricing.ascx', 9, 3, 0, N'Pricing', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (31, N'EditPaymentMethodAvailability.ascx', 9, 2, 0, N'Availability', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (32, N'EditPaymentMethodDescription.ascx', 9, 4, 1, N'Description', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (33, N'EditEmailProfileBaseProperties.ascx', 10, 1, 0, N'Common', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (35, N'EditEmailTypeBaseProperties.ascx', 11, 1, 0, N'Common', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (36, N'EditEmailTypeParameters.ascx', 11, 2, 0, N'Parameters', 1, 0, 0)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (37, N'EditEmailProfileContent.ascx', 12, 2, 1, N'Content', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (38, N'EditEmailProfileTypeInformation.ascx', 12, 1, 0, N'Common', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (39, N'EditPriceGroupBaseProperties.ascx', 13, 1, 0, N'Common', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (40, N'EditDataTypeBaseProperties.ascx', 14, 1, 0, N'Common', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (41, N'EditDataTypeEnumBaseProperties.ascx', 15, 1, 0, N'Common', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (42, N'EditDataTypeEnumDescription.ascx', 15, 2, 1, N'Description', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (43, N'../EditProductDescription.ascx', 16, 1, 1, N'Description', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (44, N'EditCountryBaseProperties.ascx', 17, 1, 0, N'Common', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (45, N'EditCurrencyBaseProperties.ascx', 18, 1, 0, N'Common', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (46, N'EditOrderNumberSerieBaseProperties.ascx', 19, 1, 0, N'Common', 1, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (47, N'ViewOrderGroupOrders.ascx', 20, 1, 0, N'Common', 0, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (48, N'SearchOrders.ascx', 21, 1, 0, N'Common', 0, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (49, N'SalesTotals.ascx', 22, 1, 0, N'SalesTotals', 0, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (50, N'ProductTop10.ascx', 23, 1, 0, N'ProductTop10', 0, 0, 1)
INSERT [dbo].[uCommerce_AdminTab] ([AdminTabId], [VirtualPath], [AdminPageId], [SortOrder], [MultiLingual], [ResouceKey], [HasSaveButton], [HasDeleteButton], [Enabled]) VALUES (51, N'EditOrderShipments.ascx', 5, 2, 0, N'Shipping', 0, 0, 1)
SET IDENTITY_INSERT [dbo].[uCommerce_AdminTab] OFF
/****** Object:  Table [dbo].[uCommerce_ShippingMethod]    Script Date: 09/04/2009 11:22:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethod]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_ShippingMethod](
	[ShippingMethodId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](128) NOT NULL,
	[ImageMediaId] [int] NULL,
	[PaymentMethodId] [int] NULL,
	[ServiceName] [nvarchar](128) NULL,
	[Deleted] [bit] NOT NULL,
 CONSTRAINT [uCommerce_PK_ShippingMethod] PRIMARY KEY CLUSTERED 
(
	[ShippingMethodId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_ShippingMethod] ON
INSERT [dbo].[uCommerce_ShippingMethod] ([ShippingMethodId], [Name], [ImageMediaId], [PaymentMethodId], [ServiceName], [Deleted]) VALUES (8, N'Download', NULL, NULL, N'SinglePriceService', 0)
SET IDENTITY_INSERT [dbo].[uCommerce_ShippingMethod] OFF
/****** Object:  Table [dbo].[uCommerce_PurchaseOrder]    Script Date: 09/04/2009 11:22:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_PurchaseOrder]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_PurchaseOrder](
	[OrderId] [int] IDENTITY(1,1) NOT NULL,
	[OrderNumber] [nvarchar](50) NULL,
	[CustomerId] [int] NULL,
	[OrderStatusId] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[CompletedDate] [datetime] NULL,
	[CurrencyId] [int] NOT NULL,
	[ProductCatalogGroupId] [int] NOT NULL,
	[BillingAddressId] [int] NULL,
	[Note] [ntext] NULL,
	[BasketId] [uniqueidentifier] NOT NULL,
	[VAT] [money] NULL,
	[OrderTotal] [money] NULL,
	[ShippingTotal] [money] NULL,
	[PaymentTotal] [money] NULL,
	[TaxTotal] [money] NULL,
	[SubTotal] [money] NULL,
 CONSTRAINT [uCommerce_PK_Order] PRIMARY KEY CLUSTERED 
(
	[OrderId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_PurchaseOrder]') AND name = N'IX_Order')
CREATE NONCLUSTERED INDEX [IX_Order] ON [dbo].[uCommerce_PurchaseOrder] 
(
	[OrderId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
GO
SET IDENTITY_INSERT [dbo].[uCommerce_PurchaseOrder] ON
INSERT [dbo].[uCommerce_PurchaseOrder] ([OrderId], [OrderNumber], [CustomerId], [OrderStatusId], [CreatedDate], [CompletedDate], [CurrencyId], [ProductCatalogGroupId], [BillingAddressId], [Note], [BasketId], [VAT], [OrderTotal], [ShippingTotal], [PaymentTotal], [TaxTotal], [SubTotal]) VALUES (165, N'WEB-1', 66, 2, CAST(0x00009C750104BD26 AS DateTime), CAST(0x00009C7501093901 AS DateTime), 5, 13, 46, NULL, N'7f5f78a2-bc53-4eec-8314-210185dc8b98', 546.7500, 4191.7500, 0.0000, 0.0000, NULL, 4191.7500)
INSERT [dbo].[uCommerce_PurchaseOrder] ([OrderId], [OrderNumber], [CustomerId], [OrderStatusId], [CreatedDate], [CompletedDate], [CurrencyId], [ProductCatalogGroupId], [BillingAddressId], [Note], [BasketId], [VAT], [OrderTotal], [ShippingTotal], [PaymentTotal], [TaxTotal], [SubTotal]) VALUES (166, NULL, NULL, 1, CAST(0x00009C750104BD26 AS DateTime), NULL, 5, 13, NULL, NULL, N'7f5f78a2-bc53-4eec-8314-210185dc8b98', NULL, NULL, NULL, NULL, NULL, NULL)
INSERT [dbo].[uCommerce_PurchaseOrder] ([OrderId], [OrderNumber], [CustomerId], [OrderStatusId], [CreatedDate], [CompletedDate], [CurrencyId], [ProductCatalogGroupId], [BillingAddressId], [Note], [BasketId], [VAT], [OrderTotal], [ShippingTotal], [PaymentTotal], [TaxTotal], [SubTotal]) VALUES (167, N'WEB-2', 67, 2, CAST(0x00009C75010AAEBE AS DateTime), CAST(0x00009C75010B55C7 AS DateTime), 5, 13, 47, NULL, N'06461b7f-fb70-4c12-a71d-7b4716816821', 0.0000, 0.0000, 0.0000, 0.0000, NULL, 0.0000)
INSERT [dbo].[uCommerce_PurchaseOrder] ([OrderId], [OrderNumber], [CustomerId], [OrderStatusId], [CreatedDate], [CompletedDate], [CurrencyId], [ProductCatalogGroupId], [BillingAddressId], [Note], [BasketId], [VAT], [OrderTotal], [ShippingTotal], [PaymentTotal], [TaxTotal], [SubTotal]) VALUES (168, NULL, NULL, 1, CAST(0x00009C75010AAEBE AS DateTime), NULL, 5, 13, NULL, NULL, N'06461b7f-fb70-4c12-a71d-7b4716816821', NULL, NULL, NULL, NULL, NULL, NULL)
INSERT [dbo].[uCommerce_PurchaseOrder] ([OrderId], [OrderNumber], [CustomerId], [OrderStatusId], [CreatedDate], [CompletedDate], [CurrencyId], [ProductCatalogGroupId], [BillingAddressId], [Note], [BasketId], [VAT], [OrderTotal], [ShippingTotal], [PaymentTotal], [TaxTotal], [SubTotal]) VALUES (169, N'WEB-3', 68, 2, CAST(0x00009C790148ECDC AS DateTime), CAST(0x00009C79014D7591 AS DateTime), 5, 13, 48, NULL, N'e6352adb-083b-4959-95fb-aff4d013ce44', 0.0000, 0.0000, 0.0000, 0.0000, NULL, 0.0000)
INSERT [dbo].[uCommerce_PurchaseOrder] ([OrderId], [OrderNumber], [CustomerId], [OrderStatusId], [CreatedDate], [CompletedDate], [CurrencyId], [ProductCatalogGroupId], [BillingAddressId], [Note], [BasketId], [VAT], [OrderTotal], [ShippingTotal], [PaymentTotal], [TaxTotal], [SubTotal]) VALUES (170, NULL, NULL, 1, CAST(0x00009C790148ECDC AS DateTime), NULL, 5, 13, NULL, NULL, N'e6352adb-083b-4959-95fb-aff4d013ce44', NULL, NULL, NULL, NULL, NULL, NULL)
SET IDENTITY_INSERT [dbo].[uCommerce_PurchaseOrder] OFF
/****** Object:  Table [dbo].[uCommerce_ProductDescription]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDescription]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_ProductDescription](
	[ProductDescriptionId] [int] IDENTITY(1,1) NOT NULL,
	[ProductId] [int] NOT NULL,
	[DisplayName] [nvarchar](512) NOT NULL,
	[ShortDescription] [nvarchar](max) NULL,
	[LongDescription] [nvarchar](max) NULL,
	[CultureCode] [nvarchar](5) NOT NULL,
 CONSTRAINT [uCommerce_PK_ProductDescription] PRIMARY KEY CLUSTERED 
(
	[ProductDescriptionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_ProductDescription] ON
INSERT [dbo].[uCommerce_ProductDescription] ([ProductDescriptionId], [ProductId], [DisplayName], [ShortDescription], [LongDescription], [CultureCode]) VALUES (61, 97, N'uCommerce 1.0 RTM', N'uCommerce is a full featured e-commerce platform with content management features powered by Umbraco. Everything you need to build a killer e-commerce solution for your clients!', N'uCommerce is fully integrated with the content management system Umbraco, which provides not only the frontend renderendering enabling you to create beautifully designed stores, but also the back office capabilities where you configure and cuztomize the store to your liking.

uCommerce_ foundations provide the basis for an e-commerce solution. Each foundation addresses a specific need for providing a full e-commerce solution to your clients. foundations in the box include a Catalog Foundation, a Transactions Foundation, and an Analytics Foundation.

Each of the foundations within uCommerce_ are fully configurable right in Umbraco. No need to switch between a multitude of tools to manage your stores. It''s all available as you would expect in one convenient location.', N'en-US')
INSERT [dbo].[uCommerce_ProductDescription] ([ProductDescriptionId], [ProductId], [DisplayName], [ShortDescription], [LongDescription], [CultureCode]) VALUES (62, 97, N'uCommerce 1.0 RTM', N'uCommerce is a full featured e-commerce platform with content management features powered by Umbraco. Everything you need to build a killer e-commerce solution for your clients!', N'uCommerce is fully integrated with the content management system Umbraco, which provides not only the frontend renderendering enabling you to create beautifully designed stores, but also the back office capabilities where you configure and cuztomize the store to your liking.
', N'da-DK')
INSERT [dbo].[uCommerce_ProductDescription] ([ProductDescriptionId], [ProductId], [DisplayName], [ShortDescription], [LongDescription], [CultureCode]) VALUES (63, 98, N'Developer Edition', N'', N'', N'en-US')
INSERT [dbo].[uCommerce_ProductDescription] ([ProductDescriptionId], [ProductId], [DisplayName], [ShortDescription], [LongDescription], [CultureCode]) VALUES (64, 98, N'Udviklingsversion', N'', N'', N'da-DK')
INSERT [dbo].[uCommerce_ProductDescription] ([ProductDescriptionId], [ProductId], [DisplayName], [ShortDescription], [LongDescription], [CultureCode]) VALUES (65, 99, N'30 Days Evaluation', N'', N'', N'en-US')
INSERT [dbo].[uCommerce_ProductDescription] ([ProductDescriptionId], [ProductId], [DisplayName], [ShortDescription], [LongDescription], [CultureCode]) VALUES (66, 99, N'30 daee evaluering', N'', N'', N'da-DK')
INSERT [dbo].[uCommerce_ProductDescription] ([ProductDescriptionId], [ProductId], [DisplayName], [ShortDescription], [LongDescription], [CultureCode]) VALUES (67, 100, N'Go-Live', N'', N'', N'en-US')
INSERT [dbo].[uCommerce_ProductDescription] ([ProductDescriptionId], [ProductId], [DisplayName], [ShortDescription], [LongDescription], [CultureCode]) VALUES (68, 100, N'Go-Live', N'', N'', N'da-DK')
INSERT [dbo].[uCommerce_ProductDescription] ([ProductDescriptionId], [ProductId], [DisplayName], [ShortDescription], [LongDescription], [CultureCode]) VALUES (69, 101, N'Support', N'', N'', N'en-US')
INSERT [dbo].[uCommerce_ProductDescription] ([ProductDescriptionId], [ProductId], [DisplayName], [ShortDescription], [LongDescription], [CultureCode]) VALUES (70, 101, N'Support', N'', N'', N'da-DK')
INSERT [dbo].[uCommerce_ProductDescription] ([ProductDescriptionId], [ProductId], [DisplayName], [ShortDescription], [LongDescription], [CultureCode]) VALUES (71, 102, N'5 Coupons', N'', N'', N'en-US')
INSERT [dbo].[uCommerce_ProductDescription] ([ProductDescriptionId], [ProductId], [DisplayName], [ShortDescription], [LongDescription], [CultureCode]) VALUES (72, 102, N'5 klip', N'', N'', N'da-DK')
INSERT [dbo].[uCommerce_ProductDescription] ([ProductDescriptionId], [ProductId], [DisplayName], [ShortDescription], [LongDescription], [CultureCode]) VALUES (73, 103, N'10 Coupons', N'', N'', N'en-US')
INSERT [dbo].[uCommerce_ProductDescription] ([ProductDescriptionId], [ProductId], [DisplayName], [ShortDescription], [LongDescription], [CultureCode]) VALUES (74, 103, N'10 klip', N'', N'', N'da-DK')
INSERT [dbo].[uCommerce_ProductDescription] ([ProductDescriptionId], [ProductId], [DisplayName], [ShortDescription], [LongDescription], [CultureCode]) VALUES (75, 104, N'15 Coupons', N'', N'', N'en-US')
INSERT [dbo].[uCommerce_ProductDescription] ([ProductDescriptionId], [ProductId], [DisplayName], [ShortDescription], [LongDescription], [CultureCode]) VALUES (76, 104, N'15 klip', N'', N'', N'da-DK')
SET IDENTITY_INSERT [dbo].[uCommerce_ProductDescription] OFF
/****** Object:  Table [dbo].[uCommerce_ProductDefinitionFieldDescription]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDefinitionFieldDescription]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_ProductDefinitionFieldDescription](
	[ProductDefinitionFieldDescriptionId] [int] IDENTITY(1,1) NOT NULL,
	[CultureCode] [nvarchar](5) NOT NULL,
	[DisplayName] [nvarchar](255) NOT NULL,
	[ProductDefinitionFieldId] [int] NOT NULL,
 CONSTRAINT [uCommerce_PK_ProductDefinitionFieldDescription] PRIMARY KEY CLUSTERED 
(
	[ProductDefinitionFieldDescriptionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_ProductDefinitionFieldDescription] ON
INSERT [dbo].[uCommerce_ProductDefinitionFieldDescription] ([ProductDefinitionFieldDescriptionId], [CultureCode], [DisplayName], [ProductDefinitionFieldId]) VALUES (55, N'en-US', N'Downloadable', 37)
INSERT [dbo].[uCommerce_ProductDefinitionFieldDescription] ([ProductDefinitionFieldDescriptionId], [CultureCode], [DisplayName], [ProductDefinitionFieldId]) VALUES (56, N'da-DK', N'Kan downloades', 37)
INSERT [dbo].[uCommerce_ProductDefinitionFieldDescription] ([ProductDefinitionFieldDescriptionId], [CultureCode], [DisplayName], [ProductDefinitionFieldId]) VALUES (57, N'en-US', N'License', 38)
INSERT [dbo].[uCommerce_ProductDefinitionFieldDescription] ([ProductDefinitionFieldDescriptionId], [CultureCode], [DisplayName], [ProductDefinitionFieldId]) VALUES (58, N'da-DK', N'Licens', 38)
INSERT [dbo].[uCommerce_ProductDefinitionFieldDescription] ([ProductDefinitionFieldDescriptionId], [CultureCode], [DisplayName], [ProductDefinitionFieldId]) VALUES (59, N'en-US', N'No. of coupons', 39)
INSERT [dbo].[uCommerce_ProductDefinitionFieldDescription] ([ProductDefinitionFieldDescriptionId], [CultureCode], [DisplayName], [ProductDefinitionFieldId]) VALUES (60, N'da-DK', N'Antal klip', 39)
SET IDENTITY_INSERT [dbo].[uCommerce_ProductDefinitionFieldDescription] OFF
/****** Object:  Table [dbo].[uCommerce_PaymentMethodFee]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentMethodFee]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_PaymentMethodFee](
	[PaymentMethodFeeId] [int] IDENTITY(1,1) NOT NULL,
	[PaymentMethodId] [int] NOT NULL,
	[CurrencyId] [int] NOT NULL,
	[PriceGroupId] [int] NOT NULL,
	[Fee] [money] NOT NULL,
 CONSTRAINT [uCommerce_PK_PaymentMethodFee] PRIMARY KEY CLUSTERED 
(
	[PaymentMethodFeeId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_PaymentMethodFee] ON
INSERT [dbo].[uCommerce_PaymentMethodFee] ([PaymentMethodFeeId], [PaymentMethodId], [CurrencyId], [PriceGroupId], [Fee]) VALUES (1, 6, 5, 6, 0.0000)
INSERT [dbo].[uCommerce_PaymentMethodFee] ([PaymentMethodFeeId], [PaymentMethodId], [CurrencyId], [PriceGroupId], [Fee]) VALUES (2, 7, 5, 6, 10.0000)
SET IDENTITY_INSERT [dbo].[uCommerce_PaymentMethodFee] OFF
/****** Object:  Table [dbo].[uCommerce_ShippingMethodPrice]    Script Date: 09/04/2009 11:22:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodPrice]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_ShippingMethodPrice](
	[ShippingMethodPriceId] [int] IDENTITY(1,1) NOT NULL,
	[ShippingMethodId] [int] NOT NULL,
	[PriceGroupId] [int] NOT NULL,
	[Price] [money] NOT NULL,
	[CurrencyId] [int] NOT NULL,
 CONSTRAINT [uCommerce_PK_ShippingMethodPrice] PRIMARY KEY CLUSTERED 
(
	[ShippingMethodPriceId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_ShippingMethodPrice] ON
INSERT [dbo].[uCommerce_ShippingMethodPrice] ([ShippingMethodPriceId], [ShippingMethodId], [PriceGroupId], [Price], [CurrencyId]) VALUES (1, 8, 6, 0.0000, 5)
SET IDENTITY_INSERT [dbo].[uCommerce_ShippingMethodPrice] OFF
/****** Object:  Table [dbo].[uCommerce_ShippingMethodPaymentMethods]    Script Date: 09/04/2009 11:22:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodPaymentMethods]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_ShippingMethodPaymentMethods](
	[ShippingMethodId] [int] NOT NULL,
	[PaymentMethodId] [int] NOT NULL,
 CONSTRAINT [uCommerce_PK_ShippingMethodPaymentMethods] PRIMARY KEY CLUSTERED 
(
	[ShippingMethodId] ASC,
	[PaymentMethodId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
INSERT [dbo].[uCommerce_ShippingMethodPaymentMethods] ([ShippingMethodId], [PaymentMethodId]) VALUES (8, 6)
/****** Object:  Table [dbo].[uCommerce_ShippingMethodDescription]    Script Date: 09/04/2009 11:22:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodDescription]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_ShippingMethodDescription](
	[ShippingMethodDescriptionId] [int] IDENTITY(1,1) NOT NULL,
	[ShippingMethodId] [int] NOT NULL,
	[DisplayName] [nvarchar](128) NOT NULL,
	[Description] [nvarchar](512) NULL,
	[DeliveryText] [nvarchar](512) NULL,
	[CultureCode] [nvarchar](5) NOT NULL,
 CONSTRAINT [uCommerce_PK_ShippingMethodDescription] PRIMARY KEY CLUSTERED 
(
	[ShippingMethodDescriptionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_ShippingMethodDescription] ON
INSERT [dbo].[uCommerce_ShippingMethodDescription] ([ShippingMethodDescriptionId], [ShippingMethodId], [DisplayName], [Description], [DeliveryText], [CultureCode]) VALUES (1, 8, N'Download', N'Recieve download link after download.', N'Download', N'en-US')
INSERT [dbo].[uCommerce_ShippingMethodDescription] ([ShippingMethodDescriptionId], [ShippingMethodId], [DisplayName], [Description], [DeliveryText], [CultureCode]) VALUES (2, 8, N'Download', N'Modtag download link efter betaling.', N'Download', N'da-DK')
SET IDENTITY_INSERT [dbo].[uCommerce_ShippingMethodDescription] OFF
/****** Object:  Table [dbo].[uCommerce_ShippingMethodCountry]    Script Date: 09/04/2009 11:22:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodCountry]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_ShippingMethodCountry](
	[ShippingMethodId] [int] NOT NULL,
	[CountryId] [int] NOT NULL,
 CONSTRAINT [uCommerce_PK_ShippingMethodCountry] PRIMARY KEY CLUSTERED 
(
	[ShippingMethodId] ASC,
	[CountryId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
INSERT [dbo].[uCommerce_ShippingMethodCountry] ([ShippingMethodId], [CountryId]) VALUES (8, 6)
INSERT [dbo].[uCommerce_ShippingMethodCountry] ([ShippingMethodId], [CountryId]) VALUES (8, 7)
INSERT [dbo].[uCommerce_ShippingMethodCountry] ([ShippingMethodId], [CountryId]) VALUES (8, 8)
INSERT [dbo].[uCommerce_ShippingMethodCountry] ([ShippingMethodId], [CountryId]) VALUES (8, 9)
INSERT [dbo].[uCommerce_ShippingMethodCountry] ([ShippingMethodId], [CountryId]) VALUES (8, 10)
INSERT [dbo].[uCommerce_ShippingMethodCountry] ([ShippingMethodId], [CountryId]) VALUES (8, 11)
INSERT [dbo].[uCommerce_ShippingMethodCountry] ([ShippingMethodId], [CountryId]) VALUES (8, 12)
INSERT [dbo].[uCommerce_ShippingMethodCountry] ([ShippingMethodId], [CountryId]) VALUES (8, 13)
/****** Object:  Table [dbo].[uCommerce_ProductProperty]    Script Date: 09/04/2009 11:22:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductProperty]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_ProductProperty](
	[ProductPropertyId] [int] IDENTITY(1,1) NOT NULL,
	[Value] [nvarchar](max) NULL,
	[ProductDefinitionFieldId] [int] NOT NULL,
	[ProductId] [int] NOT NULL,
 CONSTRAINT [uCommerce_PK_ProductProperty] PRIMARY KEY CLUSTERED 
(
	[ProductPropertyId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_ProductProperty] ON
INSERT [dbo].[uCommerce_ProductProperty] ([ProductPropertyId], [Value], [ProductDefinitionFieldId], [ProductId]) VALUES (777, N'on', 37, 98)
INSERT [dbo].[uCommerce_ProductProperty] ([ProductPropertyId], [Value], [ProductDefinitionFieldId], [ProductId]) VALUES (778, N'Dev', 38, 98)
INSERT [dbo].[uCommerce_ProductProperty] ([ProductPropertyId], [Value], [ProductDefinitionFieldId], [ProductId]) VALUES (779, N'on', 37, 99)
INSERT [dbo].[uCommerce_ProductProperty] ([ProductPropertyId], [Value], [ProductDefinitionFieldId], [ProductId]) VALUES (780, N'Eval', 38, 99)
INSERT [dbo].[uCommerce_ProductProperty] ([ProductPropertyId], [Value], [ProductDefinitionFieldId], [ProductId]) VALUES (781, N'on', 37, 100)
INSERT [dbo].[uCommerce_ProductProperty] ([ProductPropertyId], [Value], [ProductDefinitionFieldId], [ProductId]) VALUES (782, N'Live', 38, 100)
INSERT [dbo].[uCommerce_ProductProperty] ([ProductPropertyId], [Value], [ProductDefinitionFieldId], [ProductId]) VALUES (783, N'5', 39, 102)
INSERT [dbo].[uCommerce_ProductProperty] ([ProductPropertyId], [Value], [ProductDefinitionFieldId], [ProductId]) VALUES (784, N'10', 39, 103)
INSERT [dbo].[uCommerce_ProductProperty] ([ProductPropertyId], [Value], [ProductDefinitionFieldId], [ProductId]) VALUES (785, N'15', 39, 104)
SET IDENTITY_INSERT [dbo].[uCommerce_ProductProperty] OFF
/****** Object:  Table [dbo].[uCommerce_PriceGroupPrice]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_PriceGroupPrice]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_PriceGroupPrice](
	[PriceGroupPriceId] [int] IDENTITY(1,1) NOT NULL,
	[ProductId] [int] NOT NULL,
	[Price] [money] NULL,
	[DiscountPrice] [money] NULL,
	[PriceGroupId] [int] NOT NULL,
 CONSTRAINT [uCommerce_PK_PriceGroupPrice] PRIMARY KEY CLUSTERED 
(
	[PriceGroupPriceId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_PriceGroupPrice] ON
INSERT [dbo].[uCommerce_PriceGroupPrice] ([PriceGroupPriceId], [ProductId], [Price], [DiscountPrice], [PriceGroupId]) VALUES (84, 97, 3495.0000, NULL, 6)
INSERT [dbo].[uCommerce_PriceGroupPrice] ([PriceGroupPriceId], [ProductId], [Price], [DiscountPrice], [PriceGroupId]) VALUES (85, 98, 0.0000, NULL, 6)
INSERT [dbo].[uCommerce_PriceGroupPrice] ([PriceGroupPriceId], [ProductId], [Price], [DiscountPrice], [PriceGroupId]) VALUES (86, 101, 100.0000, NULL, 6)
INSERT [dbo].[uCommerce_PriceGroupPrice] ([PriceGroupPriceId], [ProductId], [Price], [DiscountPrice], [PriceGroupId]) VALUES (87, 102, 100.0000, NULL, 6)
INSERT [dbo].[uCommerce_PriceGroupPrice] ([PriceGroupPriceId], [ProductId], [Price], [DiscountPrice], [PriceGroupId]) VALUES (88, 103, 150.0000, NULL, 6)
INSERT [dbo].[uCommerce_PriceGroupPrice] ([PriceGroupPriceId], [ProductId], [Price], [DiscountPrice], [PriceGroupId]) VALUES (89, 104, 200.0000, NULL, 6)
SET IDENTITY_INSERT [dbo].[uCommerce_PriceGroupPrice] OFF
/****** Object:  Table [dbo].[uCommerce_ProductCatalogGroupShippingMethodMap]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroupShippingMethodMap]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_ProductCatalogGroupShippingMethodMap](
	[ProductCatalogGroupId] [int] NOT NULL,
	[ShippingMethodId] [int] NOT NULL,
 CONSTRAINT [uCommerce_PK_ProductCatalogGroupShippingMethodMap] PRIMARY KEY CLUSTERED 
(
	[ProductCatalogGroupId] ASC,
	[ShippingMethodId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
INSERT [dbo].[uCommerce_ProductCatalogGroupShippingMethodMap] ([ProductCatalogGroupId], [ShippingMethodId]) VALUES (13, 8)
/****** Object:  Table [dbo].[uCommerce_ProductCatalogGroupPaymentMethodMap]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroupPaymentMethodMap]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_ProductCatalogGroupPaymentMethodMap](
	[ProductCatalogGroupId] [int] NOT NULL,
	[PaymentMethodId] [int] NOT NULL,
 CONSTRAINT [uCommerce_PK_ProductCatalogGroupPaymentMethodMap] PRIMARY KEY CLUSTERED 
(
	[ProductCatalogGroupId] ASC,
	[PaymentMethodId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
INSERT [dbo].[uCommerce_ProductCatalogGroupPaymentMethodMap] ([ProductCatalogGroupId], [PaymentMethodId]) VALUES (13, 6)
INSERT [dbo].[uCommerce_ProductCatalogGroupPaymentMethodMap] ([ProductCatalogGroupId], [PaymentMethodId]) VALUES (13, 7)
/****** Object:  Table [dbo].[uCommerce_ProductCatalog]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalog]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_ProductCatalog](
	[ProductCatalogId] [int] IDENTITY(1,1) NOT NULL,
	[ProductCatalogGroupId] [int] NOT NULL,
	[Name] [nvarchar](60) NOT NULL,
	[PriceGroupId] [int] NOT NULL,
	[ShowPricesIncludingVAT] [bit] NOT NULL,
	[IsVirtual] [bit] NOT NULL,
	[DisplayOnWebSite] [bit] NOT NULL,
	[LimitedAccess] [bit] NOT NULL,
	[Deleted] [bit] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[ModifiedOn] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ModifiedBy] [nvarchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [uCommerce_PK_Catalog] PRIMARY KEY CLUSTERED 
(
	[ProductCatalogId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalog]') AND name = N'IX_ProductCatalog_UniqueName')
CREATE UNIQUE NONCLUSTERED INDEX [IX_ProductCatalog_UniqueName] ON [dbo].[uCommerce_ProductCatalog] 
(
	[Name] ASC,
	[ProductCatalogGroupId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
GO
SET IDENTITY_INSERT [dbo].[uCommerce_ProductCatalog] ON
INSERT [dbo].[uCommerce_ProductCatalog] ([ProductCatalogId], [ProductCatalogGroupId], [Name], [PriceGroupId], [ShowPricesIncludingVAT], [IsVirtual], [DisplayOnWebSite], [LimitedAccess], [Deleted], [CreatedOn], [ModifiedOn], [CreatedBy], [ModifiedBy]) VALUES (23, 13, N'uCommerce', 6, 0, 0, 0, 0, 0, CAST(0x00009C7500F2B69F AS DateTime), CAST(0x00009C7500FCA3F9 AS DateTime), N'uCommerce', N'uCommerce')
SET IDENTITY_INSERT [dbo].[uCommerce_ProductCatalog] OFF
/****** Object:  Table [dbo].[uCommerce_DataTypeEnumDescription]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DataTypeEnumDescription]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_DataTypeEnumDescription](
	[DataTypeEnumDescriptionId] [int] IDENTITY(1,1) NOT NULL,
	[DataTypeEnumId] [int] NOT NULL,
	[CultureCode] [nvarchar](5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DisplayName] [nvarchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [ntext] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [uCommerce_PK_DataTypeEnumDescription] PRIMARY KEY CLUSTERED 
(
	[DataTypeEnumDescriptionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_DataTypeEnumDescription] ON
INSERT [dbo].[uCommerce_DataTypeEnumDescription] ([DataTypeEnumDescriptionId], [DataTypeEnumId], [CultureCode], [DisplayName], [Description]) VALUES (26, 13, N'en-US', N'Developer', N'Developer license')
INSERT [dbo].[uCommerce_DataTypeEnumDescription] ([DataTypeEnumDescriptionId], [DataTypeEnumId], [CultureCode], [DisplayName], [Description]) VALUES (27, 13, N'da-DK', N'Udvikler', N'Udvikler licens')
INSERT [dbo].[uCommerce_DataTypeEnumDescription] ([DataTypeEnumDescriptionId], [DataTypeEnumId], [CultureCode], [DisplayName], [Description]) VALUES (28, 14, N'en-US', N'Evaluation', N'30-day evaluation')
INSERT [dbo].[uCommerce_DataTypeEnumDescription] ([DataTypeEnumDescriptionId], [DataTypeEnumId], [CultureCode], [DisplayName], [Description]) VALUES (29, 14, N'da-DK', N'Evaluering', N'30-dages evaluering')
INSERT [dbo].[uCommerce_DataTypeEnumDescription] ([DataTypeEnumDescriptionId], [DataTypeEnumId], [CultureCode], [DisplayName], [Description]) VALUES (30, 15, N'en-US', N'Go Live', N'License for live sites')
INSERT [dbo].[uCommerce_DataTypeEnumDescription] ([DataTypeEnumDescriptionId], [DataTypeEnumId], [CultureCode], [DisplayName], [Description]) VALUES (31, 15, N'da-DK', N'Go Live', N'Til live websites')
INSERT [dbo].[uCommerce_DataTypeEnumDescription] ([DataTypeEnumDescriptionId], [DataTypeEnumId], [CultureCode], [DisplayName], [Description]) VALUES (32, 16, N'en-US', N'5 coupons', N'')
INSERT [dbo].[uCommerce_DataTypeEnumDescription] ([DataTypeEnumDescriptionId], [DataTypeEnumId], [CultureCode], [DisplayName], [Description]) VALUES (33, 16, N'da-DK', N'5 klip', N'')
INSERT [dbo].[uCommerce_DataTypeEnumDescription] ([DataTypeEnumDescriptionId], [DataTypeEnumId], [CultureCode], [DisplayName], [Description]) VALUES (34, 17, N'en-US', N'10 Coupons', N'')
INSERT [dbo].[uCommerce_DataTypeEnumDescription] ([DataTypeEnumDescriptionId], [DataTypeEnumId], [CultureCode], [DisplayName], [Description]) VALUES (35, 17, N'da-DK', N'10 klip', N'')
INSERT [dbo].[uCommerce_DataTypeEnumDescription] ([DataTypeEnumDescriptionId], [DataTypeEnumId], [CultureCode], [DisplayName], [Description]) VALUES (36, 18, N'en-US', N'15 Coupons', N'')
INSERT [dbo].[uCommerce_DataTypeEnumDescription] ([DataTypeEnumDescriptionId], [DataTypeEnumId], [CultureCode], [DisplayName], [Description]) VALUES (37, 18, N'da-DK', N'15 klip', N'')
SET IDENTITY_INSERT [dbo].[uCommerce_DataTypeEnumDescription] OFF
/****** Object:  Table [dbo].[uCommerce_Payment]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_Payment]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_Payment](
	[PaymentId] [int] IDENTITY(1,1) NOT NULL,
	[TransactionId] [nvarchar](max) NULL,
	[PaymentMethodName] [nvarchar](50) NOT NULL,
	[Created] [datetime] NOT NULL,
	[PaymentMethodId] [int] NOT NULL,
	[Fee] [money] NOT NULL,
	[FeePercentage] [decimal](18, 4) NOT NULL,
	[PaymentStatusId] [int] NOT NULL,
	[Amount] [money] NOT NULL,
	[OrderId] [int] NOT NULL,
 CONSTRAINT [uCommerce_PK_Payment] PRIMARY KEY CLUSTERED 
(
	[PaymentId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_Payment] ON
INSERT [dbo].[uCommerce_Payment] ([PaymentId], [TransactionId], [PaymentMethodName], [Created], [PaymentMethodId], [Fee], [FeePercentage], [PaymentStatusId], [Amount], [OrderId]) VALUES (4, N'true', N'Account', CAST(0x00009C7501092626 AS DateTime), 6, 0.0000, CAST(0.0000 AS Decimal(18, 4)), 1, 0.0000, 165)
INSERT [dbo].[uCommerce_Payment] ([PaymentId], [TransactionId], [PaymentMethodName], [Created], [PaymentMethodId], [Fee], [FeePercentage], [PaymentStatusId], [Amount], [OrderId]) VALUES (5, N'true', N'Account', CAST(0x00009C75010B5077 AS DateTime), 6, 0.0000, CAST(0.0000 AS Decimal(18, 4)), 1, 0.0000, 167)
INSERT [dbo].[uCommerce_Payment] ([PaymentId], [TransactionId], [PaymentMethodName], [Created], [PaymentMethodId], [Fee], [FeePercentage], [PaymentStatusId], [Amount], [OrderId]) VALUES (6, N'true', N'Account', CAST(0x00009C790149E270 AS DateTime), 6, 0.0000, CAST(0.0000 AS Decimal(18, 4)), 1, 0.0000, 169)
SET IDENTITY_INSERT [dbo].[uCommerce_Payment] OFF
/****** Object:  Table [dbo].[uCommerce_OrderLine]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderLine]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_OrderLine](
	[OrderLineId] [int] IDENTITY(1,1) NOT NULL,
	[OrderId] [int] NOT NULL,
	[Sku] [nvarchar](512) NOT NULL,
	[ProductName] [nvarchar](512) NOT NULL,
	[Price] [money] NOT NULL,
	[Quantity] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[Discount] [money] NOT NULL,
	[VAT] [money] NOT NULL,
	[Total] [money] NULL,
	[VATRate] [money] NOT NULL,
 CONSTRAINT [uCommerce_PK_OrderLine] PRIMARY KEY CLUSTERED 
(
	[OrderLineId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_OrderLine] ON
INSERT [dbo].[uCommerce_OrderLine] ([OrderLineId], [OrderId], [Sku], [ProductName], [Price], [Quantity], [CreatedOn], [Discount], [VAT], [Total], [VATRate]) VALUES (173, 165, N'100-000-001-003', N'Go-Live', 3495.0000, 1, CAST(0x00009C750104BDC4 AS DateTime), 0.0000, 524.2500, 4019.2500, 0.1500)
INSERT [dbo].[uCommerce_OrderLine] ([OrderLineId], [OrderId], [Sku], [ProductName], [Price], [Quantity], [CreatedOn], [Discount], [VAT], [Total], [VATRate]) VALUES (174, 165, N'100-000-001-001', N'Developer Edition', 0.0000, 1, CAST(0x00009C750104D6AE AS DateTime), 0.0000, 0.0000, 0.0000, 0.1500)
INSERT [dbo].[uCommerce_OrderLine] ([OrderLineId], [OrderId], [Sku], [ProductName], [Price], [Quantity], [CreatedOn], [Discount], [VAT], [Total], [VATRate]) VALUES (175, 165, N'200-000-001-002', N'10 Coupons', 150.0000, 1, CAST(0x00009C7501074819 AS DateTime), 0.0000, 22.5000, 172.5000, 0.1500)
INSERT [dbo].[uCommerce_OrderLine] ([OrderLineId], [OrderId], [Sku], [ProductName], [Price], [Quantity], [CreatedOn], [Discount], [VAT], [Total], [VATRate]) VALUES (176, 167, N'100-000-001-001', N'Developer Edition', 0.0000, 1, CAST(0x00009C75010AAF65 AS DateTime), 0.0000, 0.0000, 0.0000, 0.1500)
INSERT [dbo].[uCommerce_OrderLine] ([OrderLineId], [OrderId], [Sku], [ProductName], [Price], [Quantity], [CreatedOn], [Discount], [VAT], [Total], [VATRate]) VALUES (177, 169, N'100-000-001-001', N'Developer Edition', 0.0000, 1, CAST(0x00009C790148EDA1 AS DateTime), 0.0000, 0.0000, 0.0000, 0.1500)
SET IDENTITY_INSERT [dbo].[uCommerce_OrderLine] OFF
/****** Object:  Table [dbo].[uCommerce_Category]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_Category]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_Category](
	[CategoryId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](60) NOT NULL,
	[ImageMediaId] [int] NULL,
	[DisplayOnSite] [bit] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[ParentCategoryId] [int] NULL,
	[ProductCatalogId] [int] NOT NULL,
	[ModifiedOn] [datetime] NULL,
	[ModifiedBy] [nvarchar](50) NULL,
	[Deleted] [bit] NOT NULL,
 CONSTRAINT [uCommerce_PK_Category] PRIMARY KEY CLUSTERED 
(
	[CategoryId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_Category]') AND name = N'IX_Category')
CREATE NONCLUSTERED INDEX [IX_Category] ON [dbo].[uCommerce_Category] 
(
	[Name] ASC,
	[ProductCatalogId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
GO
SET IDENTITY_INSERT [dbo].[uCommerce_Category] ON
INSERT [dbo].[uCommerce_Category] ([CategoryId], [Name], [ImageMediaId], [DisplayOnSite], [CreatedOn], [ParentCategoryId], [ProductCatalogId], [ModifiedOn], [ModifiedBy], [Deleted]) VALUES (67, N'Software', NULL, 1, CAST(0x00009C7500F43DDC AS DateTime), NULL, 23, CAST(0x00009C7500F43DDE AS DateTime), N'uCommerce', 0)
INSERT [dbo].[uCommerce_Category] ([CategoryId], [Name], [ImageMediaId], [DisplayOnSite], [CreatedOn], [ParentCategoryId], [ProductCatalogId], [ModifiedOn], [ModifiedBy], [Deleted]) VALUES (68, N'Support', NULL, 1, CAST(0x00009C7500F45C14 AS DateTime), NULL, 23, CAST(0x00009C7500F45C14 AS DateTime), N'uCommerce', 0)
SET IDENTITY_INSERT [dbo].[uCommerce_Category] OFF
/****** Object:  Table [dbo].[uCommerce_ProductCatalogDescription]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogDescription]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_ProductCatalogDescription](
	[ProductCatalogDescriptionId] [int] IDENTITY(1,1) NOT NULL,
	[ProductCatalogId] [int] NOT NULL,
	[CultureCode] [nvarchar](5) NOT NULL,
	[DisplayName] [nvarchar](512) NOT NULL,
 CONSTRAINT [uCommerce_PK_ProductCatalogDescription] PRIMARY KEY CLUSTERED 
(
	[ProductCatalogDescriptionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_ProductCatalogDescription] ON
INSERT [dbo].[uCommerce_ProductCatalogDescription] ([ProductCatalogDescriptionId], [ProductCatalogId], [CultureCode], [DisplayName]) VALUES (42, 23, N'en-US', N'uCommerce')
INSERT [dbo].[uCommerce_ProductCatalogDescription] ([ProductCatalogDescriptionId], [ProductCatalogId], [CultureCode], [DisplayName]) VALUES (43, 23, N'da-DK', N'uCommerce')
SET IDENTITY_INSERT [dbo].[uCommerce_ProductCatalogDescription] OFF
/****** Object:  Table [dbo].[uCommerce_ProductCatalogAccess]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogAccess]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_ProductCatalogAccess](
	[ProductCatalogId] [int] NOT NULL,
	[MemberGroupId] [int] NOT NULL,
 CONSTRAINT [uCommerce_PK_ProductCatalogAccess] PRIMARY KEY CLUSTERED 
(
	[ProductCatalogId] ASC,
	[MemberGroupId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
/****** Object:  Table [dbo].[uCommerce_OrderStatusAudit]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderStatusAudit]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_OrderStatusAudit](
	[OrderStatusAuditId] [int] IDENTITY(1,1) NOT NULL,
	[NewOrderStatusId] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[CreatedBy] [nvarchar](50) NULL,
	[OrderId] [int] NOT NULL,
 CONSTRAINT [uCommerce_PK_OrderStatusAudit] PRIMARY KEY CLUSTERED 
(
	[OrderStatusAuditId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_OrderStatusAudit] ON
INSERT [dbo].[uCommerce_OrderStatusAudit] ([OrderStatusAuditId], [NewOrderStatusId], [CreatedOn], [CreatedBy], [OrderId]) VALUES (72, 2, CAST(0x00009C75010B6E2D AS DateTime), N'uCommerce', 167)
INSERT [dbo].[uCommerce_OrderStatusAudit] ([OrderStatusAuditId], [NewOrderStatusId], [CreatedOn], [CreatedBy], [OrderId]) VALUES (73, 2, CAST(0x00009C79014D75FC AS DateTime), N'uCommerce', 169)
SET IDENTITY_INSERT [dbo].[uCommerce_OrderStatusAudit] OFF
/****** Object:  Table [dbo].[uCommerce_ProductDescriptionProperty]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDescriptionProperty]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_ProductDescriptionProperty](
	[ProductDescriptionPropertyId] [int] IDENTITY(1,1) NOT NULL,
	[ProductDescriptionId] [int] NOT NULL,
	[ProductDefinitionFieldId] [int] NOT NULL,
	[Value] [nvarchar](max) NULL,
 CONSTRAINT [uCommerce_PK_ProductDescriptionProperty] PRIMARY KEY CLUSTERED 
(
	[ProductDescriptionPropertyId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
/****** Object:  Table [dbo].[uCommerce_Shipment]    Script Date: 09/04/2009 11:22:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_Shipment]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_Shipment](
	[ShipmentId] [int] IDENTITY(1,1) NOT NULL,
	[ShipmentName] [nvarchar](128) NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[ShipmentPrice] [money] NOT NULL,
	[ShippingMethodId] [int] NOT NULL,
	[ShipmentAddressId] [int] NULL,
	[DeliveryNote] [ntext] NULL,
	[OrderLineId] [int] NULL,
	[OrderId] [int] NOT NULL,
	[TrackAndTrace] [nvarchar](512) NULL,
 CONSTRAINT [uCommerce_PK_Shipping] PRIMARY KEY CLUSTERED 
(
	[ShipmentId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_Shipment] ON
INSERT [dbo].[uCommerce_Shipment] ([ShipmentId], [ShipmentName], [CreatedOn], [ShipmentPrice], [ShippingMethodId], [ShipmentAddressId], [DeliveryNote], [OrderLineId], [OrderId], [TrackAndTrace]) VALUES (1, N'Download', CAST(0x00009C750107D8D2 AS DateTime), 0.0000, 8, 46, N'Download', NULL, 165, NULL)
INSERT [dbo].[uCommerce_Shipment] ([ShipmentId], [ShipmentName], [CreatedOn], [ShipmentPrice], [ShippingMethodId], [ShipmentAddressId], [DeliveryNote], [OrderLineId], [OrderId], [TrackAndTrace]) VALUES (2, N'Download', CAST(0x00009C75010B4C5B AS DateTime), 0.0000, 8, 46, N'Download', NULL, 167, NULL)
INSERT [dbo].[uCommerce_Shipment] ([ShipmentId], [ShipmentName], [CreatedOn], [ShipmentPrice], [ShippingMethodId], [ShipmentAddressId], [DeliveryNote], [OrderLineId], [OrderId], [TrackAndTrace]) VALUES (3, N'Download', CAST(0x00009C790149DB0C AS DateTime), 0.0000, 8, 46, N'Download', NULL, 169, NULL)
SET IDENTITY_INSERT [dbo].[uCommerce_Shipment] OFF
/****** Object:  Table [dbo].[uCommerce_CategoryProductRelation]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_CategoryProductRelation]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_CategoryProductRelation](
	[CategoryProductRelationId] int identity(1,1) not null,
	[ProductId] [int] NOT NULL,
	[CategoryId] [int] NOT NULL,
	CONSTRAINT [uCommerce_PK_CategoryProductRelation] PRIMARY KEY CLUSTERED 
	(
		[CategoryProductRelationId] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_CategoryProductRelation]') AND name = N'IX_CategoryProductRelation')
CREATE NONCLUSTERED INDEX [IX_CategoryProductRelation] ON [dbo].[uCommerce_CategoryProductRelation] 
(
	[CategoryId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
GO
INSERT [dbo].[uCommerce_CategoryProductRelation] ([ProductId], [CategoryId]) VALUES (97, 67)
INSERT [dbo].[uCommerce_CategoryProductRelation] ([ProductId], [CategoryId]) VALUES (101, 68)
/****** Object:  Table [dbo].[uCommerce_CategoryDescription]    Script Date: 09/04/2009 11:22:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_CategoryDescription]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[uCommerce_CategoryDescription](
	[CategoryDescriptionId] [int] IDENTITY(1,1) NOT NULL,
	[CategoryId] [int] NOT NULL,
	[DisplayName] [nvarchar](512) NOT NULL,
	[Description] [nvarchar](max) NULL,
	[CultureCode] [nvarchar](5) NOT NULL,
	[ContentId] [int] NULL,
	[RenderAsContent] [bit] NOT NULL,
 CONSTRAINT [uCommerce_PK_CategoryDescription] PRIMARY KEY CLUSTERED 
(
	[CategoryDescriptionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[uCommerce_CategoryDescription] ON
INSERT [dbo].[uCommerce_CategoryDescription] ([CategoryDescriptionId], [CategoryId], [DisplayName], [Description], [CultureCode], [ContentId], [RenderAsContent]) VALUES (86, 67, N'Software', N'', N'en-US', NULL, 0)
INSERT [dbo].[uCommerce_CategoryDescription] ([CategoryDescriptionId], [CategoryId], [DisplayName], [Description], [CultureCode], [ContentId], [RenderAsContent]) VALUES (87, 67, N'Software', N'', N'da-DK', NULL, 0)
INSERT [dbo].[uCommerce_CategoryDescription] ([CategoryDescriptionId], [CategoryId], [DisplayName], [Description], [CultureCode], [ContentId], [RenderAsContent]) VALUES (88, 68, N'Support', N'', N'en-US', NULL, 0)
INSERT [dbo].[uCommerce_CategoryDescription] ([CategoryDescriptionId], [CategoryId], [DisplayName], [Description], [CultureCode], [ContentId], [RenderAsContent]) VALUES (89, 68, N'Support', N'', N'da-DK', NULL, 0)
SET IDENTITY_INSERT [dbo].[uCommerce_CategoryDescription] OFF
/****** Object:  Default [uCommerce_DF_AdminTab_MultiLingual]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_AdminTab_MultiLingual]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_AdminTab]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_AdminTab_MultiLingual]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_AdminTab] ADD  CONSTRAINT [uCommerce_DF_AdminTab_MultiLingual]  DEFAULT ((0)) FOR [MultiLingual]
END


End
GO
/****** Object:  Default [uCommerce_DF_AdminTab_HasSaveButton]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_AdminTab_HasSaveButton]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_AdminTab]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_AdminTab_HasSaveButton]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_AdminTab] ADD  CONSTRAINT [uCommerce_DF_AdminTab_HasSaveButton]  DEFAULT ((1)) FOR [HasSaveButton]
END


End
GO
/****** Object:  Default [uCommerce_DF_AdminTab_HasDeleteButton]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_AdminTab_HasDeleteButton]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_AdminTab]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_AdminTab_HasDeleteButton]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_AdminTab] ADD  CONSTRAINT [uCommerce_DF_AdminTab_HasDeleteButton]  DEFAULT ((0)) FOR [HasDeleteButton]
END


End
GO
/****** Object:  Default [uCommerce_DF_Category_DisplayOnSite]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_Category_DisplayOnSite]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Category]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_Category_DisplayOnSite]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_Category] ADD  CONSTRAINT [uCommerce_DF_Category_DisplayOnSite]  DEFAULT ((1)) FOR [DisplayOnSite]
END


End
GO
/****** Object:  Default [uCommerce_DF_Category_CreatedDate]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_Category_CreatedDate]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Category]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_Category_CreatedDate]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_Category] ADD  CONSTRAINT [uCommerce_DF_Category_CreatedDate]  DEFAULT (getdate()) FOR [CreatedOn]
END


End
GO
/****** Object:  Default [uCommerce_DF_Category_Deleted]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_Category_Deleted]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Category]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_Category_Deleted]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_Category] ADD  CONSTRAINT [uCommerce_DF_Category_Deleted]  DEFAULT ((0)) FOR [Deleted]
END


End
GO
/****** Object:  Default [uCommerce_DF_CategoryDescription_RenderAsContent]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_CategoryDescription_RenderAsContent]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_CategoryDescription]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_CategoryDescription_RenderAsContent]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_CategoryDescription] ADD  CONSTRAINT [uCommerce_DF_CategoryDescription_RenderAsContent]  DEFAULT ((0)) FOR [RenderAsContent]
END


End
GO
/****** Object:  Default [uCommerce_DF_DataType_BuiltIn]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_DataType_BuiltIn]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_DataType]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_DataType_BuiltIn]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_DataType] ADD  CONSTRAINT [uCommerce_DF_DataType_BuiltIn]  DEFAULT ((0)) FOR [BuiltIn]
END


End
GO
/****** Object:  Default [uCommerce_DF_EmailProfile_Deleted]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_EmailProfile_Deleted]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_EmailProfile]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_EmailProfile_Deleted]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_EmailProfile] ADD  CONSTRAINT [uCommerce_DF_EmailProfile_Deleted]  DEFAULT ((0)) FOR [Deleted]
END


End
GO
/****** Object:  Default [uCommerce_DF_EmailType_Deleted]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_EmailType_Deleted]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_EmailType]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_EmailType_Deleted]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_EmailType] ADD  CONSTRAINT [uCommerce_DF_EmailType_Deleted]  DEFAULT ((0)) FOR [Deleted]
END


End
GO
/****** Object:  Default [uCommerce_DF_OrderLine_CreatedDate]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_OrderLine_CreatedDate]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderLine]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_OrderLine_CreatedDate]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_OrderLine] ADD  CONSTRAINT [uCommerce_DF_OrderLine_CreatedDate]  DEFAULT (getdate()) FOR [CreatedOn]
END


End
GO
/****** Object:  Default [uCommerce_DF_OrderLine_Rebate]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_OrderLine_Rebate]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderLine]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_OrderLine_Rebate]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_OrderLine] ADD  CONSTRAINT [uCommerce_DF_OrderLine_Rebate]  DEFAULT ((0)) FOR [Discount]
END


End
GO
/****** Object:  Default [uCommerce_DF_OrderLine_Vat]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_OrderLine_Vat]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderLine]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_OrderLine_Vat]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_OrderLine] ADD  CONSTRAINT [uCommerce_DF_OrderLine_Vat]  DEFAULT ((0)) FOR [VAT]
END


End
GO
/****** Object:  Default [uCommerce_DF_OrderStatus_Sort]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_OrderStatus_Sort]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderStatus]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_OrderStatus_Sort]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_OrderStatus] ADD  CONSTRAINT [uCommerce_DF_OrderStatus_Sort]  DEFAULT ((0)) FOR [Sort]
END


End
GO
/****** Object:  Default [uCommerce_DF_OrderStatus_RenderChildren]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_OrderStatus_RenderChildren]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderStatus]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_OrderStatus_RenderChildren]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_OrderStatus] ADD  CONSTRAINT [uCommerce_DF_OrderStatus_RenderChildren]  DEFAULT ((0)) FOR [RenderChildren]
END


End
GO
/****** Object:  Default [uCommerce_DF_OrderStatus_RenderInMenu]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_OrderStatus_RenderInMenu]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderStatus]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_OrderStatus_RenderInMenu]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_OrderStatus] ADD  CONSTRAINT [uCommerce_DF_OrderStatus_RenderInMenu]  DEFAULT ((1)) FOR [RenderInMenu]
END


End
GO
/****** Object:  Default [uCommerce_DF_OrderStatus_IncludeInAuditTrail]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_OrderStatus_IncludeInAuditTrail]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderStatus]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_OrderStatus_IncludeInAuditTrail]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_OrderStatus] ADD  CONSTRAINT [uCommerce_DF_OrderStatus_IncludeInAuditTrail]  DEFAULT ((1)) FOR [IncludeInAuditTrail]
END


End
GO
/****** Object:  Default [uCommerce_DF_OrderStatus_AllowUpdate]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_OrderStatus_AllowUpdate]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderStatus]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_OrderStatus_AllowUpdate]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_OrderStatus] ADD  CONSTRAINT [uCommerce_DF_OrderStatus_AllowUpdate]  DEFAULT ((1)) FOR [AllowUpdate]
END


End
GO
/****** Object:  Default [uCommerce_DF_OrderStatus_AlwaysAvailable]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_OrderStatus_AlwaysAvailable]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderStatus]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_OrderStatus_AlwaysAvailable]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_OrderStatus] ADD  CONSTRAINT [uCommerce_DF_OrderStatus_AlwaysAvailable]  DEFAULT ((0)) FOR [AlwaysAvailable]
END


End
GO
/****** Object:  Default [uCommerce_DF_Payment_Created]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_Payment_Created]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Payment]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_Payment_Created]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_Payment] ADD  CONSTRAINT [uCommerce_DF_Payment_Created]  DEFAULT (getdate()) FOR [Created]
END


End
GO
/****** Object:  Default [uCommerce_DF_Payment_Fee]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_Payment_Fee]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Payment]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_Payment_Fee]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_Payment] ADD  CONSTRAINT [uCommerce_DF_Payment_Fee]  DEFAULT ((0)) FOR [Fee]
END


End
GO
/****** Object:  Default [uCommerce_DF_Payment_FeePercentage]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_Payment_FeePercentage]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Payment]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_Payment_FeePercentage]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_Payment] ADD  CONSTRAINT [uCommerce_DF_Payment_FeePercentage]  DEFAULT ((0)) FOR [FeePercentage]
END


End
GO
/****** Object:  Default [uCommerce_DF_Table_1_FeePercant]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_Table_1_FeePercant]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentMethod]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_Table_1_FeePercant]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_PaymentMethod] ADD  CONSTRAINT [uCommerce_DF_Table_1_FeePercant]  DEFAULT ((0)) FOR [FeePercent]
END


End
GO
/****** Object:  Default [uCommerce_DF_PaymentMethod_Enabled]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_PaymentMethod_Enabled]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentMethod]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_PaymentMethod_Enabled]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_PaymentMethod] ADD  CONSTRAINT [uCommerce_DF_PaymentMethod_Enabled]  DEFAULT ((1)) FOR [Enabled]
END


End
GO
/****** Object:  Default [uCommerce_DF_PaymentMethod_Deleted]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_PaymentMethod_Deleted]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentMethod]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_PaymentMethod_Deleted]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_PaymentMethod] ADD  CONSTRAINT [uCommerce_DF_PaymentMethod_Deleted]  DEFAULT ((0)) FOR [Deleted]
END


End
GO
/****** Object:  Default [uCommerce_DF_PriceGroup_CreatedOn]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_PriceGroup_CreatedOn]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PriceGroup]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_PriceGroup_CreatedOn]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_PriceGroup] ADD  CONSTRAINT [uCommerce_DF_PriceGroup_CreatedOn]  DEFAULT (getdate()) FOR [CreatedOn]
END


End
GO
/****** Object:  Default [uCommerce_DF_PriceGroup_ModifiedOn]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_PriceGroup_ModifiedOn]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PriceGroup]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_PriceGroup_ModifiedOn]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_PriceGroup] ADD  CONSTRAINT [uCommerce_DF_PriceGroup_ModifiedOn]  DEFAULT (getdate()) FOR [ModifiedOn]
END


End
GO
/****** Object:  Default [uCommerce_DF_PriceGroup_Deleted]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_PriceGroup_Deleted]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PriceGroup]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_PriceGroup_Deleted]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_PriceGroup] ADD  CONSTRAINT [uCommerce_DF_PriceGroup_Deleted]  DEFAULT ((0)) FOR [Deleted]
END


End
GO
/****** Object:  Default [uCommerce_DF_Product_DisplayOnSite]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_Product_DisplayOnSite]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Product]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_Product_DisplayOnSite]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_Product] ADD  CONSTRAINT [uCommerce_DF_Product_DisplayOnSite]  DEFAULT ((1)) FOR [DisplayOnSite]
END


End
GO
/****** Object:  Default [uCommerce_DF_Product_Weight]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_Product_Weight]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Product]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_Product_Weight]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_Product] ADD  CONSTRAINT [uCommerce_DF_Product_Weight]  DEFAULT ((0)) FOR [Weight]
END


End
GO
/****** Object:  Default [uCommerce_DF_Product_AllowOrdering]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_Product_AllowOrdering]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Product]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_Product_AllowOrdering]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_Product] ADD  CONSTRAINT [uCommerce_DF_Product_AllowOrdering]  DEFAULT ((1)) FOR [AllowOrdering]
END


End
GO
/****** Object:  Default [uCommerce_DF_Product_LastModified]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_Product_LastModified]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Product]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_Product_LastModified]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_Product] ADD  CONSTRAINT [uCommerce_DF_Product_LastModified]  DEFAULT (getdate()) FOR [ModifiedOn]
END


End
GO
/****** Object:  Default [uCommerce_DF_Product_CreatedDate]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_Product_CreatedDate]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Product]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_Product_CreatedDate]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_Product] ADD  CONSTRAINT [uCommerce_DF_Product_CreatedDate]  DEFAULT (getdate()) FOR [CreatedOn]
END


End
GO
/****** Object:  Default [uCommerce_DF_Catalog_ShowPricesIncludingVAT]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_Catalog_ShowPricesIncludingVAT]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalog]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_Catalog_ShowPricesIncludingVAT]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_ProductCatalog] ADD  CONSTRAINT [uCommerce_DF_Catalog_ShowPricesIncludingVAT]  DEFAULT ((1)) FOR [ShowPricesIncludingVAT]
END


End
GO
/****** Object:  Default [uCommerce_DF_ProductCatalog_IsVirtual]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_ProductCatalog_IsVirtual]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalog]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_ProductCatalog_IsVirtual]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_ProductCatalog] ADD  CONSTRAINT [uCommerce_DF_ProductCatalog_IsVirtual]  DEFAULT ((0)) FOR [IsVirtual]
END


End
GO
/****** Object:  Default [uCommerce_DF_ProductCatalog_DisplayOnWebSite]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_ProductCatalog_DisplayOnWebSite]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalog]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_ProductCatalog_DisplayOnWebSite]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_ProductCatalog] ADD  CONSTRAINT [uCommerce_DF_ProductCatalog_DisplayOnWebSite]  DEFAULT ((0)) FOR [DisplayOnWebSite]
END


End
GO
/****** Object:  Default [uCommerce_DF_ProductCatalog_LimitedAccess]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_ProductCatalog_LimitedAccess]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalog]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_ProductCatalog_LimitedAccess]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_ProductCatalog] ADD  CONSTRAINT [uCommerce_DF_ProductCatalog_LimitedAccess]  DEFAULT ((0)) FOR [LimitedAccess]
END


End
GO
/****** Object:  Default [uCommerce_DF_ProductCatalog_Deleted]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_ProductCatalog_Deleted]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalog]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_ProductCatalog_Deleted]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_ProductCatalog] ADD  CONSTRAINT [uCommerce_DF_ProductCatalog_Deleted]  DEFAULT ((0)) FOR [Deleted]
END


End
GO
/****** Object:  Default [uCommerce_DF_ProductCatalog_CreatedOn]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_ProductCatalog_CreatedOn]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalog]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_ProductCatalog_CreatedOn]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_ProductCatalog] ADD  CONSTRAINT [uCommerce_DF_ProductCatalog_CreatedOn]  DEFAULT (getdate()) FOR [CreatedOn]
END


End
GO
/****** Object:  Default [uCommerce_DF_ProductCatalog_ModifiedOn]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_ProductCatalog_ModifiedOn]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalog]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_ProductCatalog_ModifiedOn]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_ProductCatalog] ADD  CONSTRAINT [uCommerce_DF_ProductCatalog_ModifiedOn]  DEFAULT (getdate()) FOR [ModifiedOn]
END


End
GO
/****** Object:  Default [uCommerce_DF_ProductCatalog_CreatedBy]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_ProductCatalog_CreatedBy]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalog]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_ProductCatalog_CreatedBy]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_ProductCatalog] ADD  CONSTRAINT [uCommerce_DF_ProductCatalog_CreatedBy]  DEFAULT (N'(Unknown)') FOR [CreatedBy]
END


End
GO
/****** Object:  Default [uCommerce_DF_ProductCatalog_ModifiedBy]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_ProductCatalog_ModifiedBy]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalog]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_ProductCatalog_ModifiedBy]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_ProductCatalog] ADD  CONSTRAINT [uCommerce_DF_ProductCatalog_ModifiedBy]  DEFAULT (N'(Unknown)') FOR [ModifiedBy]
END


End
GO
/****** Object:  Default [uCommerce_DF_ProductCatalogGroup_Deleted]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_ProductCatalogGroup_Deleted]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroup]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_ProductCatalogGroup_Deleted]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_ProductCatalogGroup] ADD  CONSTRAINT [uCommerce_DF_ProductCatalogGroup_Deleted]  DEFAULT ((0)) FOR [Deleted]
END


End
GO
/****** Object:  Default [uCommerce_DF_ProductCatalogGroup_CreateCustomersAsMembers]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_ProductCatalogGroup_CreateCustomersAsMembers]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroup]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_ProductCatalogGroup_CreateCustomersAsMembers]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_ProductCatalogGroup] ADD  CONSTRAINT [uCommerce_DF_ProductCatalogGroup_CreateCustomersAsMembers]  DEFAULT ((0)) FOR [CreateCustomersAsUmbracoMembers]
END


End
GO
/****** Object:  Default [uCommerce_DF_ProductDefinition_Deleted]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_ProductDefinition_Deleted]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDefinition]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_ProductDefinition_Deleted]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_ProductDefinition] ADD  CONSTRAINT [uCommerce_DF_ProductDefinition_Deleted]  DEFAULT ((0)) FOR [Deleted]
END


End
GO
/****** Object:  Default [uCommerce_DF_ProductDefinitionField_DisplayOnSite]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_ProductDefinitionField_DisplayOnSite]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDefinitionField]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_ProductDefinitionField_DisplayOnSite]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_ProductDefinitionField] ADD  CONSTRAINT [uCommerce_DF_ProductDefinitionField_DisplayOnSite]  DEFAULT ((0)) FOR [DisplayOnSite]
END


End
GO
/****** Object:  Default [uCommerce_DF_ProductDefinitionField_IsVariantProperty]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_ProductDefinitionField_IsVariantProperty]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDefinitionField]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_ProductDefinitionField_IsVariantProperty]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_ProductDefinitionField] ADD  CONSTRAINT [uCommerce_DF_ProductDefinitionField_IsVariantProperty]  DEFAULT ((0)) FOR [IsVariantProperty]
END


End
GO
/****** Object:  Default [uCommerce_DF_ProductDefinitionField_Searchable]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_ProductDefinitionField_Searchable]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDefinitionField]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_ProductDefinitionField_Searchable]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_ProductDefinitionField] ADD  CONSTRAINT [uCommerce_DF_ProductDefinitionField_Searchable]  DEFAULT ((0)) FOR [Searchable]
END


End
GO
/****** Object:  Default [uCommerce_DF_ProductDefinitionField_Deleted]    Script Date: 09/04/2009 11:22:52 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_ProductDefinitionField_Deleted]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDefinitionField]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_ProductDefinitionField_Deleted]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_ProductDefinitionField] ADD  CONSTRAINT [uCommerce_DF_ProductDefinitionField_Deleted]  DEFAULT ((0)) FOR [Deleted]
END


End
GO
/****** Object:  Default [uCommerce_DF_Order_CreatedDate]    Script Date: 09/04/2009 11:22:53 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_Order_CreatedDate]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PurchaseOrder]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_Order_CreatedDate]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_PurchaseOrder] ADD  CONSTRAINT [uCommerce_DF_Order_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
END


End
GO
/****** Object:  Default [uCommerce_DF_PurchaseOrder_BasketId]    Script Date: 09/04/2009 11:22:53 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_PurchaseOrder_BasketId]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PurchaseOrder]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_PurchaseOrder_BasketId]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_PurchaseOrder] ADD  CONSTRAINT [uCommerce_DF_PurchaseOrder_BasketId]  DEFAULT (newid()) FOR [BasketId]
END


End
GO
/****** Object:  Default [uCommerce_DF_Shipping_Created]    Script Date: 09/04/2009 11:22:53 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_Shipping_Created]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Shipment]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_Shipping_Created]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_Shipment] ADD  CONSTRAINT [uCommerce_DF_Shipping_Created]  DEFAULT (getdate()) FOR [CreatedOn]
END


End
GO
/****** Object:  Default [uCommerce_DF_Shipping_ShippingPrice]    Script Date: 09/04/2009 11:22:53 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_Shipping_ShippingPrice]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Shipment]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_Shipping_ShippingPrice]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_Shipment] ADD  CONSTRAINT [uCommerce_DF_Shipping_ShippingPrice]  DEFAULT ((0)) FOR [ShipmentPrice]
END


End
GO
/****** Object:  Default [uCommerce_DF_ShippingMethod_Deleted]    Script Date: 09/04/2009 11:22:53 ******/
IF Not EXISTS (SELECT * FROM sys.default_constraints WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_DF_ShippingMethod_Deleted]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethod]'))
Begin
IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[uCommerce_DF_ShippingMethod_Deleted]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[uCommerce_ShippingMethod] ADD  CONSTRAINT [uCommerce_DF_ShippingMethod_Deleted]  DEFAULT ((0)) FOR [Deleted]
END


End
GO
/****** Object:  ForeignKey [uCommerce_FK_Address_Country]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Address_Country]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Address]'))
ALTER TABLE [dbo].[uCommerce_Address]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_Address_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[uCommerce_Country] ([CountryId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Address_Country]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Address]'))
ALTER TABLE [dbo].[uCommerce_Address] CHECK CONSTRAINT [uCommerce_FK_Address_Country]
GO
/****** Object:  ForeignKey [uCommerce_FK_Address_Customer]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Address_Customer]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Address]'))
ALTER TABLE [dbo].[uCommerce_Address]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_Address_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[uCommerce_Customer] ([CustomerId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Address_Customer]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Address]'))
ALTER TABLE [dbo].[uCommerce_Address] CHECK CONSTRAINT [uCommerce_FK_Address_Customer]
GO
/****** Object:  ForeignKey [uCommerce_FK_AdminTab_AdminPage]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_AdminTab_AdminPage]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_AdminTab]'))
ALTER TABLE [dbo].[uCommerce_AdminTab]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_AdminTab_AdminPage] FOREIGN KEY([AdminPageId])
REFERENCES [dbo].[uCommerce_AdminPage] ([AdminPageId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_AdminTab_AdminPage]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_AdminTab]'))
ALTER TABLE [dbo].[uCommerce_AdminTab] CHECK CONSTRAINT [uCommerce_FK_AdminTab_AdminPage]
GO
/****** Object:  ForeignKey [uCommerce_FK_Category_ProductCatalog]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Category_ProductCatalog]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Category]'))
ALTER TABLE [dbo].[uCommerce_Category]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_Category_ProductCatalog] FOREIGN KEY([ProductCatalogId])
REFERENCES [dbo].[uCommerce_ProductCatalog] ([ProductCatalogId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Category_ProductCatalog]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Category]'))
ALTER TABLE [dbo].[uCommerce_Category] CHECK CONSTRAINT [uCommerce_FK_Category_ProductCatalog]
GO
/****** Object:  ForeignKey [uCommerce_FK_CategoryDescription_Category]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_CategoryDescription_Category]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_CategoryDescription]'))
ALTER TABLE [dbo].[uCommerce_CategoryDescription]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_CategoryDescription_Category] FOREIGN KEY([CategoryId])
REFERENCES [dbo].[uCommerce_Category] ([CategoryId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_CategoryDescription_Category]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_CategoryDescription]'))
ALTER TABLE [dbo].[uCommerce_CategoryDescription] CHECK CONSTRAINT [uCommerce_FK_CategoryDescription_Category]
GO
/****** Object:  ForeignKey [uCommerce_FK_CategoryProductRelation_Category]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_CategoryProductRelation_Category]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_CategoryProductRelation]'))
ALTER TABLE [dbo].[uCommerce_CategoryProductRelation]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_CategoryProductRelation_Category] FOREIGN KEY([CategoryId])
REFERENCES [dbo].[uCommerce_Category] ([CategoryId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_CategoryProductRelation_Category]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_CategoryProductRelation]'))
ALTER TABLE [dbo].[uCommerce_CategoryProductRelation] CHECK CONSTRAINT [uCommerce_FK_CategoryProductRelation_Category]
GO
/****** Object:  ForeignKey [uCommerce_FK_CategoryProductRelation_Product]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_CategoryProductRelation_Product]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_CategoryProductRelation]'))
ALTER TABLE [dbo].[uCommerce_CategoryProductRelation]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_CategoryProductRelation_Product] FOREIGN KEY([ProductId])
REFERENCES [dbo].[uCommerce_Product] ([ProductId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_CategoryProductRelation_Product]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_CategoryProductRelation]'))
ALTER TABLE [dbo].[uCommerce_CategoryProductRelation] CHECK CONSTRAINT [uCommerce_FK_CategoryProductRelation_Product]
GO
/****** Object:  ForeignKey [uCommerce_FK_DataTypeEnum_DataType]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_DataTypeEnum_DataType]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_DataTypeEnum]'))
ALTER TABLE [dbo].[uCommerce_DataTypeEnum]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_DataTypeEnum_DataType] FOREIGN KEY([DataTypeId])
REFERENCES [dbo].[uCommerce_DataType] ([DataTypeId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_DataTypeEnum_DataType]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_DataTypeEnum]'))
ALTER TABLE [dbo].[uCommerce_DataTypeEnum] CHECK CONSTRAINT [uCommerce_FK_DataTypeEnum_DataType]
GO
/****** Object:  ForeignKey [uCommerce_FK_DataTypeEnumDescription_DataTypeEnum]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_DataTypeEnumDescription_DataTypeEnum]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_DataTypeEnumDescription]'))
ALTER TABLE [dbo].[uCommerce_DataTypeEnumDescription]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_DataTypeEnumDescription_DataTypeEnum] FOREIGN KEY([DataTypeEnumId])
REFERENCES [dbo].[uCommerce_DataTypeEnum] ([DataTypeEnumId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_DataTypeEnumDescription_DataTypeEnum]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_DataTypeEnumDescription]'))
ALTER TABLE [dbo].[uCommerce_DataTypeEnumDescription] CHECK CONSTRAINT [uCommerce_FK_DataTypeEnumDescription_DataTypeEnum]
GO
/****** Object:  ForeignKey [uCommerce_FK_EmailContent_EmailProfile]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_EmailContent_EmailProfile]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_EmailContent]'))
ALTER TABLE [dbo].[uCommerce_EmailContent]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_EmailContent_EmailProfile] FOREIGN KEY([EmailProfileId])
REFERENCES [dbo].[uCommerce_EmailProfile] ([EmailProfileId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_EmailContent_EmailProfile]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_EmailContent]'))
ALTER TABLE [dbo].[uCommerce_EmailContent] CHECK CONSTRAINT [uCommerce_FK_EmailContent_EmailProfile]
GO
/****** Object:  ForeignKey [uCommerce_FK_EmailContent_EmailType]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_EmailContent_EmailType]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_EmailContent]'))
ALTER TABLE [dbo].[uCommerce_EmailContent]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_EmailContent_EmailType] FOREIGN KEY([EmailTypeId])
REFERENCES [dbo].[uCommerce_EmailType] ([EmailTypeId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_EmailContent_EmailType]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_EmailContent]'))
ALTER TABLE [dbo].[uCommerce_EmailContent] CHECK CONSTRAINT [uCommerce_FK_EmailContent_EmailType]
GO
/****** Object:  ForeignKey [uCommerce_FK_EmailTypeParameter_EmailParameter]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_EmailTypeParameter_EmailParameter]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_EmailTypeParameter]'))
ALTER TABLE [dbo].[uCommerce_EmailTypeParameter]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_EmailTypeParameter_EmailParameter] FOREIGN KEY([EmailParameterId])
REFERENCES [dbo].[uCommerce_EmailParameter] ([EmailParameterId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_EmailTypeParameter_EmailParameter]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_EmailTypeParameter]'))
ALTER TABLE [dbo].[uCommerce_EmailTypeParameter] CHECK CONSTRAINT [uCommerce_FK_EmailTypeParameter_EmailParameter]
GO
/****** Object:  ForeignKey [uCommerce_FK_EmailTypeParameter_EmailType]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_EmailTypeParameter_EmailType]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_EmailTypeParameter]'))
ALTER TABLE [dbo].[uCommerce_EmailTypeParameter]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_EmailTypeParameter_EmailType] FOREIGN KEY([EmailTypeId])
REFERENCES [dbo].[uCommerce_EmailType] ([EmailTypeId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_EmailTypeParameter_EmailType]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_EmailTypeParameter]'))
ALTER TABLE [dbo].[uCommerce_EmailTypeParameter] CHECK CONSTRAINT [uCommerce_FK_EmailTypeParameter_EmailType]
GO
/****** Object:  ForeignKey [uCommerce_FK_OrderLine_Order]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_OrderLine_Order]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderLine]'))
ALTER TABLE [dbo].[uCommerce_OrderLine]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_OrderLine_Order] FOREIGN KEY([OrderId])
REFERENCES [dbo].[uCommerce_PurchaseOrder] ([OrderId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_OrderLine_Order]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderLine]'))
ALTER TABLE [dbo].[uCommerce_OrderLine] CHECK CONSTRAINT [uCommerce_FK_OrderLine_Order]
GO
/****** Object:  ForeignKey [uCommerce_FK_OrderStatus_OrderStatus]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_OrderStatus_OrderStatus]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderStatus]'))
ALTER TABLE [dbo].[uCommerce_OrderStatus]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_OrderStatus_OrderStatus] FOREIGN KEY([OrderStatusId])
REFERENCES [dbo].[uCommerce_OrderStatus] ([OrderStatusId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_OrderStatus_OrderStatus]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderStatus]'))
ALTER TABLE [dbo].[uCommerce_OrderStatus] CHECK CONSTRAINT [uCommerce_FK_OrderStatus_OrderStatus]
GO
/****** Object:  ForeignKey [uCommerce_FK_OrderStatus_OrderStatus1]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_OrderStatus_OrderStatus1]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderStatus]'))
ALTER TABLE [dbo].[uCommerce_OrderStatus]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_OrderStatus_OrderStatus1] FOREIGN KEY([NextOrderStatusId])
REFERENCES [dbo].[uCommerce_OrderStatus] ([OrderStatusId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_OrderStatus_OrderStatus1]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderStatus]'))
ALTER TABLE [dbo].[uCommerce_OrderStatus] CHECK CONSTRAINT [uCommerce_FK_OrderStatus_OrderStatus1]
GO
/****** Object:  ForeignKey [uCommerce_FK_OrderStatusAudit_OrderStatus]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_OrderStatusAudit_OrderStatus]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderStatusAudit]'))
ALTER TABLE [dbo].[uCommerce_OrderStatusAudit]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_OrderStatusAudit_OrderStatus] FOREIGN KEY([NewOrderStatusId])
REFERENCES [dbo].[uCommerce_OrderStatus] ([OrderStatusId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_OrderStatusAudit_OrderStatus]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderStatusAudit]'))
ALTER TABLE [dbo].[uCommerce_OrderStatusAudit] CHECK CONSTRAINT [uCommerce_FK_OrderStatusAudit_OrderStatus]
GO
/****** Object:  ForeignKey [uCommerce_FK_OrderStatusAudit_PurchaseOrder]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_OrderStatusAudit_PurchaseOrder]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderStatusAudit]'))
ALTER TABLE [dbo].[uCommerce_OrderStatusAudit]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_OrderStatusAudit_PurchaseOrder] FOREIGN KEY([OrderId])
REFERENCES [dbo].[uCommerce_PurchaseOrder] ([OrderId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_OrderStatusAudit_PurchaseOrder]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderStatusAudit]'))
ALTER TABLE [dbo].[uCommerce_OrderStatusAudit] CHECK CONSTRAINT [uCommerce_FK_OrderStatusAudit_PurchaseOrder]
GO
/****** Object:  ForeignKey [uCommerce_FK_OrderStatusDescription_OrderStatus]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_OrderStatusDescription_OrderStatus]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderStatusDescription]'))
ALTER TABLE [dbo].[uCommerce_OrderStatusDescription]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_OrderStatusDescription_OrderStatus] FOREIGN KEY([OrderStatusId])
REFERENCES [dbo].[uCommerce_OrderStatus] ([OrderStatusId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_OrderStatusDescription_OrderStatus]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_OrderStatusDescription]'))
ALTER TABLE [dbo].[uCommerce_OrderStatusDescription] CHECK CONSTRAINT [uCommerce_FK_OrderStatusDescription_OrderStatus]
GO
/****** Object:  ForeignKey [uCommerce_FK_Payment_Order]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Payment_Order]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Payment]'))
ALTER TABLE [dbo].[uCommerce_Payment]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_Payment_Order] FOREIGN KEY([OrderId])
REFERENCES [dbo].[uCommerce_PurchaseOrder] ([OrderId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Payment_Order]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Payment]'))
ALTER TABLE [dbo].[uCommerce_Payment] CHECK CONSTRAINT [uCommerce_FK_Payment_Order]
GO
/****** Object:  ForeignKey [uCommerce_FK_Payment_PaymentMethod]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Payment_PaymentMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Payment]'))
ALTER TABLE [dbo].[uCommerce_Payment]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_Payment_PaymentMethod] FOREIGN KEY([PaymentMethodId])
REFERENCES [dbo].[uCommerce_PaymentMethod] ([PaymentMethodId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Payment_PaymentMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Payment]'))
ALTER TABLE [dbo].[uCommerce_Payment] CHECK CONSTRAINT [uCommerce_FK_Payment_PaymentMethod]
GO
/****** Object:  ForeignKey [uCommerce_FK_Payment_PaymentStatus]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Payment_PaymentStatus]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Payment]'))
ALTER TABLE [dbo].[uCommerce_Payment]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_Payment_PaymentStatus] FOREIGN KEY([PaymentStatusId])
REFERENCES [dbo].[uCommerce_PaymentStatus] ([PaymentStatusId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Payment_PaymentStatus]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Payment]'))
ALTER TABLE [dbo].[uCommerce_Payment] CHECK CONSTRAINT [uCommerce_FK_Payment_PaymentStatus]
GO
/****** Object:  ForeignKey [uCommerce_FK_PaymentMethodCountry_Country]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_PaymentMethodCountry_Country]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentMethodCountry]'))
ALTER TABLE [dbo].[uCommerce_PaymentMethodCountry]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_PaymentMethodCountry_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[uCommerce_Country] ([CountryId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_PaymentMethodCountry_Country]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentMethodCountry]'))
ALTER TABLE [dbo].[uCommerce_PaymentMethodCountry] CHECK CONSTRAINT [uCommerce_FK_PaymentMethodCountry_Country]
GO
/****** Object:  ForeignKey [uCommerce_FK_PaymentMethodCountry_PaymentMethod]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_PaymentMethodCountry_PaymentMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentMethodCountry]'))
ALTER TABLE [dbo].[uCommerce_PaymentMethodCountry]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_PaymentMethodCountry_PaymentMethod] FOREIGN KEY([PaymentMethodId])
REFERENCES [dbo].[uCommerce_PaymentMethod] ([PaymentMethodId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_PaymentMethodCountry_PaymentMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentMethodCountry]'))
ALTER TABLE [dbo].[uCommerce_PaymentMethodCountry] CHECK CONSTRAINT [uCommerce_FK_PaymentMethodCountry_PaymentMethod]
GO
/****** Object:  ForeignKey [uCommerce_FK_PaymentMethodDescription_PaymentMethod]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_PaymentMethodDescription_PaymentMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentMethodDescription]'))
ALTER TABLE [dbo].[uCommerce_PaymentMethodDescription]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_PaymentMethodDescription_PaymentMethod] FOREIGN KEY([PaymentMethodId])
REFERENCES [dbo].[uCommerce_PaymentMethod] ([PaymentMethodId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_PaymentMethodDescription_PaymentMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentMethodDescription]'))
ALTER TABLE [dbo].[uCommerce_PaymentMethodDescription] CHECK CONSTRAINT [uCommerce_FK_PaymentMethodDescription_PaymentMethod]
GO
/****** Object:  ForeignKey [uCommerce_FK_PaymentMethodFee_Currency]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_PaymentMethodFee_Currency]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentMethodFee]'))
ALTER TABLE [dbo].[uCommerce_PaymentMethodFee]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_PaymentMethodFee_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[uCommerce_Currency] ([CurrencyId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_PaymentMethodFee_Currency]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentMethodFee]'))
ALTER TABLE [dbo].[uCommerce_PaymentMethodFee] CHECK CONSTRAINT [uCommerce_FK_PaymentMethodFee_Currency]
GO
/****** Object:  ForeignKey [uCommerce_FK_PaymentMethodFee_PaymentMethod]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_PaymentMethodFee_PaymentMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentMethodFee]'))
ALTER TABLE [dbo].[uCommerce_PaymentMethodFee]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_PaymentMethodFee_PaymentMethod] FOREIGN KEY([PaymentMethodId])
REFERENCES [dbo].[uCommerce_PaymentMethod] ([PaymentMethodId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_PaymentMethodFee_PaymentMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentMethodFee]'))
ALTER TABLE [dbo].[uCommerce_PaymentMethodFee] CHECK CONSTRAINT [uCommerce_FK_PaymentMethodFee_PaymentMethod]
GO
/****** Object:  ForeignKey [uCommerce_FK_PaymentMethodFee_PriceGroup]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_PaymentMethodFee_PriceGroup]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentMethodFee]'))
ALTER TABLE [dbo].[uCommerce_PaymentMethodFee]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_PaymentMethodFee_PriceGroup] FOREIGN KEY([PriceGroupId])
REFERENCES [dbo].[uCommerce_PriceGroup] ([PriceGroupId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_PaymentMethodFee_PriceGroup]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PaymentMethodFee]'))
ALTER TABLE [dbo].[uCommerce_PaymentMethodFee] CHECK CONSTRAINT [uCommerce_FK_PaymentMethodFee_PriceGroup]
GO
/****** Object:  ForeignKey [uCommerce_FK_PriceGroup_Currency]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_PriceGroup_Currency]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PriceGroup]'))
ALTER TABLE [dbo].[uCommerce_PriceGroup]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_PriceGroup_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[uCommerce_Currency] ([CurrencyId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_PriceGroup_Currency]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PriceGroup]'))
ALTER TABLE [dbo].[uCommerce_PriceGroup] CHECK CONSTRAINT [uCommerce_FK_PriceGroup_Currency]
GO
/****** Object:  ForeignKey [uCommerce_FK_PriceGroupPrice_PriceGroup]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_PriceGroupPrice_PriceGroup]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PriceGroupPrice]'))
ALTER TABLE [dbo].[uCommerce_PriceGroupPrice]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_PriceGroupPrice_PriceGroup] FOREIGN KEY([PriceGroupId])
REFERENCES [dbo].[uCommerce_PriceGroup] ([PriceGroupId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_PriceGroupPrice_PriceGroup]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PriceGroupPrice]'))
ALTER TABLE [dbo].[uCommerce_PriceGroupPrice] CHECK CONSTRAINT [uCommerce_FK_PriceGroupPrice_PriceGroup]
GO
/****** Object:  ForeignKey [uCommerce_FK_PriceGroupPrice_Product]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_PriceGroupPrice_Product]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PriceGroupPrice]'))
ALTER TABLE [dbo].[uCommerce_PriceGroupPrice]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_PriceGroupPrice_Product] FOREIGN KEY([ProductId])
REFERENCES [dbo].[uCommerce_Product] ([ProductId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_PriceGroupPrice_Product]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PriceGroupPrice]'))
ALTER TABLE [dbo].[uCommerce_PriceGroupPrice] CHECK CONSTRAINT [uCommerce_FK_PriceGroupPrice_Product]
GO
/****** Object:  ForeignKey [uCommerce_FK_Product_ProductDefinition]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Product_ProductDefinition]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Product]'))
ALTER TABLE [dbo].[uCommerce_Product]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_Product_ProductDefinition] FOREIGN KEY([ProductDefinitionId])
REFERENCES [dbo].[uCommerce_ProductDefinition] ([ProductDefinitionId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Product_ProductDefinition]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Product]'))
ALTER TABLE [dbo].[uCommerce_Product] CHECK CONSTRAINT [uCommerce_FK_Product_ProductDefinition]
GO
/****** Object:  ForeignKey [uCommerce_FK_Catalog_CatalogGroup]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Catalog_CatalogGroup]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalog]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalog]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_Catalog_CatalogGroup] FOREIGN KEY([ProductCatalogGroupId])
REFERENCES [dbo].[uCommerce_ProductCatalogGroup] ([ProductCatalogGroupId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Catalog_CatalogGroup]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalog]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalog] CHECK CONSTRAINT [uCommerce_FK_Catalog_CatalogGroup]
GO
/****** Object:  ForeignKey [uCommerce_FK_Catalog_PriceGroup]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Catalog_PriceGroup]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalog]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalog]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_Catalog_PriceGroup] FOREIGN KEY([PriceGroupId])
REFERENCES [dbo].[uCommerce_PriceGroup] ([PriceGroupId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Catalog_PriceGroup]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalog]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalog] CHECK CONSTRAINT [uCommerce_FK_Catalog_PriceGroup]
GO
/****** Object:  ForeignKey [uCommerce_FK_ProductCatalogAccess_ProductCatalog]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogAccess_ProductCatalog]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogAccess]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogAccess]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ProductCatalogAccess_ProductCatalog] FOREIGN KEY([ProductCatalogId])
REFERENCES [dbo].[uCommerce_ProductCatalog] ([ProductCatalogId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogAccess_ProductCatalog]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogAccess]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogAccess] CHECK CONSTRAINT [uCommerce_FK_ProductCatalogAccess_ProductCatalog]
GO
/****** Object:  ForeignKey [uCommerce_FK_ProductCatalogDescription_ProductCatalog]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogDescription_ProductCatalog]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogDescription]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogDescription]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ProductCatalogDescription_ProductCatalog] FOREIGN KEY([ProductCatalogId])
REFERENCES [dbo].[uCommerce_ProductCatalog] ([ProductCatalogId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogDescription_ProductCatalog]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogDescription]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogDescription] CHECK CONSTRAINT [uCommerce_FK_ProductCatalogDescription_ProductCatalog]
GO
/****** Object:  ForeignKey [uCommerce_FK_ProductCatalogGroup_Currency]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogGroup_Currency]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroup]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogGroup]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ProductCatalogGroup_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[uCommerce_Currency] ([CurrencyId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogGroup_Currency]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroup]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogGroup] CHECK CONSTRAINT [uCommerce_FK_ProductCatalogGroup_Currency]
GO
/****** Object:  ForeignKey [uCommerce_FK_ProductCatalogGroup_EmailProfile]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogGroup_EmailProfile]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroup]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogGroup]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ProductCatalogGroup_EmailProfile] FOREIGN KEY([EmailProfileId])
REFERENCES [dbo].[uCommerce_EmailProfile] ([EmailProfileId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogGroup_EmailProfile]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroup]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogGroup] CHECK CONSTRAINT [uCommerce_FK_ProductCatalogGroup_EmailProfile]
GO
/****** Object:  ForeignKey [uCommerce_FK_ProductCatalogGroup_OrderNumbers]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogGroup_OrderNumbers]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroup]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogGroup]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ProductCatalogGroup_OrderNumbers] FOREIGN KEY([OrderNumberId])
REFERENCES [dbo].[uCommerce_OrderNumberSerie] ([OrderNumberId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogGroup_OrderNumbers]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroup]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogGroup] CHECK CONSTRAINT [uCommerce_FK_ProductCatalogGroup_OrderNumbers]
GO
/****** Object:  ForeignKey [uCommerce_FK_ProductCatalogGroup_ProductCatalogGroup]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogGroup_ProductCatalogGroup]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroup]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogGroup]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ProductCatalogGroup_ProductCatalogGroup] FOREIGN KEY([ProductCatalogGroupId])
REFERENCES [dbo].[uCommerce_ProductCatalogGroup] ([ProductCatalogGroupId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogGroup_ProductCatalogGroup]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroup]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogGroup] CHECK CONSTRAINT [uCommerce_FK_ProductCatalogGroup_ProductCatalogGroup]
GO
/****** Object:  ForeignKey [uCommerce_FK_ProductCatalogGroupPaymentMethodMap_PaymentMethod]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogGroupPaymentMethodMap_PaymentMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroupPaymentMethodMap]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogGroupPaymentMethodMap]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ProductCatalogGroupPaymentMethodMap_PaymentMethod] FOREIGN KEY([PaymentMethodId])
REFERENCES [dbo].[uCommerce_PaymentMethod] ([PaymentMethodId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogGroupPaymentMethodMap_PaymentMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroupPaymentMethodMap]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogGroupPaymentMethodMap] CHECK CONSTRAINT [uCommerce_FK_ProductCatalogGroupPaymentMethodMap_PaymentMethod]
GO
/****** Object:  ForeignKey [uCommerce_FK_ProductCatalogGroupPaymentMethodMap_ProductCatalogGroup]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogGroupPaymentMethodMap_ProductCatalogGroup]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroupPaymentMethodMap]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogGroupPaymentMethodMap]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ProductCatalogGroupPaymentMethodMap_ProductCatalogGroup] FOREIGN KEY([ProductCatalogGroupId])
REFERENCES [dbo].[uCommerce_ProductCatalogGroup] ([ProductCatalogGroupId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogGroupPaymentMethodMap_ProductCatalogGroup]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroupPaymentMethodMap]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogGroupPaymentMethodMap] CHECK CONSTRAINT [uCommerce_FK_ProductCatalogGroupPaymentMethodMap_ProductCatalogGroup]
GO
/****** Object:  ForeignKey [uCommerce_FK_ProductCatalogGroupShippingMethodMap_ProductCatalogGroup]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogGroupShippingMethodMap_ProductCatalogGroup]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroupShippingMethodMap]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogGroupShippingMethodMap]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ProductCatalogGroupShippingMethodMap_ProductCatalogGroup] FOREIGN KEY([ProductCatalogGroupId])
REFERENCES [dbo].[uCommerce_ProductCatalogGroup] ([ProductCatalogGroupId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogGroupShippingMethodMap_ProductCatalogGroup]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroupShippingMethodMap]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogGroupShippingMethodMap] CHECK CONSTRAINT [uCommerce_FK_ProductCatalogGroupShippingMethodMap_ProductCatalogGroup]
GO
/****** Object:  ForeignKey [uCommerce_FK_ProductCatalogGroupShippingMethodMap_ShippingMethod]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogGroupShippingMethodMap_ShippingMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroupShippingMethodMap]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogGroupShippingMethodMap]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ProductCatalogGroupShippingMethodMap_ShippingMethod] FOREIGN KEY([ShippingMethodId])
REFERENCES [dbo].[uCommerce_ShippingMethod] ([ShippingMethodId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductCatalogGroupShippingMethodMap_ShippingMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductCatalogGroupShippingMethodMap]'))
ALTER TABLE [dbo].[uCommerce_ProductCatalogGroupShippingMethodMap] CHECK CONSTRAINT [uCommerce_FK_ProductCatalogGroupShippingMethodMap_ShippingMethod]
GO
/****** Object:  ForeignKey [uCommerce_FK_ProductDefinition_ProductDefinition]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductDefinition_ProductDefinition]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDefinition]'))
ALTER TABLE [dbo].[uCommerce_ProductDefinition]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ProductDefinition_ProductDefinition] FOREIGN KEY([ProductDefinitionId])
REFERENCES [dbo].[uCommerce_ProductDefinition] ([ProductDefinitionId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductDefinition_ProductDefinition]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDefinition]'))
ALTER TABLE [dbo].[uCommerce_ProductDefinition] CHECK CONSTRAINT [uCommerce_FK_ProductDefinition_ProductDefinition]
GO
/****** Object:  ForeignKey [uCommerce_FK_ProductDefinitionField_DataType]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductDefinitionField_DataType]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDefinitionField]'))
ALTER TABLE [dbo].[uCommerce_ProductDefinitionField]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ProductDefinitionField_DataType] FOREIGN KEY([DataTypeId])
REFERENCES [dbo].[uCommerce_DataType] ([DataTypeId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductDefinitionField_DataType]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDefinitionField]'))
ALTER TABLE [dbo].[uCommerce_ProductDefinitionField] CHECK CONSTRAINT [uCommerce_FK_ProductDefinitionField_DataType]
GO
/****** Object:  ForeignKey [uCommerce_FK_ProductDefinitionField_ProductDefinition]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductDefinitionField_ProductDefinition]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDefinitionField]'))
ALTER TABLE [dbo].[uCommerce_ProductDefinitionField]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ProductDefinitionField_ProductDefinition] FOREIGN KEY([ProductDefinitionId])
REFERENCES [dbo].[uCommerce_ProductDefinition] ([ProductDefinitionId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductDefinitionField_ProductDefinition]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDefinitionField]'))
ALTER TABLE [dbo].[uCommerce_ProductDefinitionField] CHECK CONSTRAINT [uCommerce_FK_ProductDefinitionField_ProductDefinition]
GO
/****** Object:  ForeignKey [uCommerce_FK_ProductDefinitionFieldDescription_ProductDefinitionField]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductDefinitionFieldDescription_ProductDefinitionField]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDefinitionFieldDescription]'))
ALTER TABLE [dbo].[uCommerce_ProductDefinitionFieldDescription]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ProductDefinitionFieldDescription_ProductDefinitionField] FOREIGN KEY([ProductDefinitionFieldId])
REFERENCES [dbo].[uCommerce_ProductDefinitionField] ([ProductDefinitionFieldId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductDefinitionFieldDescription_ProductDefinitionField]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDefinitionFieldDescription]'))
ALTER TABLE [dbo].[uCommerce_ProductDefinitionFieldDescription] CHECK CONSTRAINT [uCommerce_FK_ProductDefinitionFieldDescription_ProductDefinitionField]
GO
/****** Object:  ForeignKey [uCommerce_FK_ProductDescription_Product]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductDescription_Product]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDescription]'))
ALTER TABLE [dbo].[uCommerce_ProductDescription]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ProductDescription_Product] FOREIGN KEY([ProductId])
REFERENCES [dbo].[uCommerce_Product] ([ProductId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductDescription_Product]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDescription]'))
ALTER TABLE [dbo].[uCommerce_ProductDescription] CHECK CONSTRAINT [uCommerce_FK_ProductDescription_Product]
GO
/****** Object:  ForeignKey [uCommerce_FK_ProductDescriptionProperty_ProductDefinitionField]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductDescriptionProperty_ProductDefinitionField]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDescriptionProperty]'))
ALTER TABLE [dbo].[uCommerce_ProductDescriptionProperty]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ProductDescriptionProperty_ProductDefinitionField] FOREIGN KEY([ProductDefinitionFieldId])
REFERENCES [dbo].[uCommerce_ProductDefinitionField] ([ProductDefinitionFieldId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductDescriptionProperty_ProductDefinitionField]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDescriptionProperty]'))
ALTER TABLE [dbo].[uCommerce_ProductDescriptionProperty] CHECK CONSTRAINT [uCommerce_FK_ProductDescriptionProperty_ProductDefinitionField]
GO
/****** Object:  ForeignKey [uCommerce_FK_ProductDescriptionProperty_ProductDescription]    Script Date: 09/04/2009 11:22:52 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductDescriptionProperty_ProductDescription]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDescriptionProperty]'))
ALTER TABLE [dbo].[uCommerce_ProductDescriptionProperty]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ProductDescriptionProperty_ProductDescription] FOREIGN KEY([ProductDescriptionId])
REFERENCES [dbo].[uCommerce_ProductDescription] ([ProductDescriptionId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductDescriptionProperty_ProductDescription]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductDescriptionProperty]'))
ALTER TABLE [dbo].[uCommerce_ProductDescriptionProperty] CHECK CONSTRAINT [uCommerce_FK_ProductDescriptionProperty_ProductDescription]
GO
/****** Object:  ForeignKey [uCommerce_FK_ProductProperty_Product]    Script Date: 09/04/2009 11:22:53 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductProperty_Product]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductProperty]'))
ALTER TABLE [dbo].[uCommerce_ProductProperty]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ProductProperty_Product] FOREIGN KEY([ProductId])
REFERENCES [dbo].[uCommerce_Product] ([ProductId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductProperty_Product]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductProperty]'))
ALTER TABLE [dbo].[uCommerce_ProductProperty] CHECK CONSTRAINT [uCommerce_FK_ProductProperty_Product]
GO
/****** Object:  ForeignKey [uCommerce_FK_ProductProperty_ProductDefinitionField]    Script Date: 09/04/2009 11:22:53 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductProperty_ProductDefinitionField]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductProperty]'))
ALTER TABLE [dbo].[uCommerce_ProductProperty]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ProductProperty_ProductDefinitionField] FOREIGN KEY([ProductDefinitionFieldId])
REFERENCES [dbo].[uCommerce_ProductDefinitionField] ([ProductDefinitionFieldId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ProductProperty_ProductDefinitionField]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ProductProperty]'))
ALTER TABLE [dbo].[uCommerce_ProductProperty] CHECK CONSTRAINT [uCommerce_FK_ProductProperty_ProductDefinitionField]
GO
/****** Object:  ForeignKey [uCommerce_FK_Order_Address]    Script Date: 09/04/2009 11:22:53 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Order_Address]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PurchaseOrder]'))
ALTER TABLE [dbo].[uCommerce_PurchaseOrder]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_Order_Address] FOREIGN KEY([BillingAddressId])
REFERENCES [dbo].[uCommerce_Address] ([AddressId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Order_Address]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PurchaseOrder]'))
ALTER TABLE [dbo].[uCommerce_PurchaseOrder] CHECK CONSTRAINT [uCommerce_FK_Order_Address]
GO
/****** Object:  ForeignKey [uCommerce_FK_Order_Currency]    Script Date: 09/04/2009 11:22:53 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Order_Currency]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PurchaseOrder]'))
ALTER TABLE [dbo].[uCommerce_PurchaseOrder]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_Order_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[uCommerce_Currency] ([CurrencyId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Order_Currency]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PurchaseOrder]'))
ALTER TABLE [dbo].[uCommerce_PurchaseOrder] CHECK CONSTRAINT [uCommerce_FK_Order_Currency]
GO
/****** Object:  ForeignKey [uCommerce_FK_Order_Customer]    Script Date: 09/04/2009 11:22:53 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Order_Customer]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PurchaseOrder]'))
ALTER TABLE [dbo].[uCommerce_PurchaseOrder]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_Order_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[uCommerce_Customer] ([CustomerId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Order_Customer]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PurchaseOrder]'))
ALTER TABLE [dbo].[uCommerce_PurchaseOrder] CHECK CONSTRAINT [uCommerce_FK_Order_Customer]
GO
/****** Object:  ForeignKey [uCommerce_FK_Order_OrderStatus1]    Script Date: 09/04/2009 11:22:53 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Order_OrderStatus1]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PurchaseOrder]'))
ALTER TABLE [dbo].[uCommerce_PurchaseOrder]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_Order_OrderStatus1] FOREIGN KEY([OrderStatusId])
REFERENCES [dbo].[uCommerce_OrderStatus] ([OrderStatusId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Order_OrderStatus1]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PurchaseOrder]'))
ALTER TABLE [dbo].[uCommerce_PurchaseOrder] CHECK CONSTRAINT [uCommerce_FK_Order_OrderStatus1]
GO
/****** Object:  ForeignKey [uCommerce_FK_Order_ProductCatalogGroup]    Script Date: 09/04/2009 11:22:53 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Order_ProductCatalogGroup]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PurchaseOrder]'))
ALTER TABLE [dbo].[uCommerce_PurchaseOrder]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_Order_ProductCatalogGroup] FOREIGN KEY([ProductCatalogGroupId])
REFERENCES [dbo].[uCommerce_ProductCatalogGroup] ([ProductCatalogGroupId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Order_ProductCatalogGroup]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_PurchaseOrder]'))
ALTER TABLE [dbo].[uCommerce_PurchaseOrder] CHECK CONSTRAINT [uCommerce_FK_Order_ProductCatalogGroup]
GO
/****** Object:  ForeignKey [uCommerce_FK_Shipment_Address]    Script Date: 09/04/2009 11:22:53 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Shipment_Address]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Shipment]'))
ALTER TABLE [dbo].[uCommerce_Shipment]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_Shipment_Address] FOREIGN KEY([ShipmentAddressId])
REFERENCES [dbo].[uCommerce_Address] ([AddressId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Shipment_Address]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Shipment]'))
ALTER TABLE [dbo].[uCommerce_Shipment] CHECK CONSTRAINT [uCommerce_FK_Shipment_Address]
GO
/****** Object:  ForeignKey [uCommerce_FK_Shipment_OrderLine]    Script Date: 09/04/2009 11:22:53 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Shipment_OrderLine]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Shipment]'))
ALTER TABLE [dbo].[uCommerce_Shipment]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_Shipment_OrderLine] FOREIGN KEY([OrderLineId])
REFERENCES [dbo].[uCommerce_OrderLine] ([OrderLineId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Shipment_OrderLine]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Shipment]'))
ALTER TABLE [dbo].[uCommerce_Shipment] CHECK CONSTRAINT [uCommerce_FK_Shipment_OrderLine]
GO
/****** Object:  ForeignKey [uCommerce_FK_Shipment_PurchaseOrder]    Script Date: 09/04/2009 11:22:53 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Shipment_PurchaseOrder]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Shipment]'))
ALTER TABLE [dbo].[uCommerce_Shipment]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_Shipment_PurchaseOrder] FOREIGN KEY([OrderId])
REFERENCES [dbo].[uCommerce_PurchaseOrder] ([OrderId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_Shipment_PurchaseOrder]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_Shipment]'))
ALTER TABLE [dbo].[uCommerce_Shipment] CHECK CONSTRAINT [uCommerce_FK_Shipment_PurchaseOrder]
GO
/****** Object:  ForeignKey [uCommerce_FK_ShippingMethod_PaymentMethod]    Script Date: 09/04/2009 11:22:53 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ShippingMethod_PaymentMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethod]'))
ALTER TABLE [dbo].[uCommerce_ShippingMethod]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ShippingMethod_PaymentMethod] FOREIGN KEY([PaymentMethodId])
REFERENCES [dbo].[uCommerce_PaymentMethod] ([PaymentMethodId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ShippingMethod_PaymentMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethod]'))
ALTER TABLE [dbo].[uCommerce_ShippingMethod] CHECK CONSTRAINT [uCommerce_FK_ShippingMethod_PaymentMethod]
GO
/****** Object:  ForeignKey [uCommerce_FK_ShippingMethodCountry_Country]    Script Date: 09/04/2009 11:22:53 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ShippingMethodCountry_Country]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodCountry]'))
ALTER TABLE [dbo].[uCommerce_ShippingMethodCountry]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ShippingMethodCountry_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[uCommerce_Country] ([CountryId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ShippingMethodCountry_Country]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodCountry]'))
ALTER TABLE [dbo].[uCommerce_ShippingMethodCountry] CHECK CONSTRAINT [uCommerce_FK_ShippingMethodCountry_Country]
GO
/****** Object:  ForeignKey [uCommerce_FK_ShippingMethodCountry_ShippingMethod]    Script Date: 09/04/2009 11:22:53 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ShippingMethodCountry_ShippingMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodCountry]'))
ALTER TABLE [dbo].[uCommerce_ShippingMethodCountry]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ShippingMethodCountry_ShippingMethod] FOREIGN KEY([ShippingMethodId])
REFERENCES [dbo].[uCommerce_ShippingMethod] ([ShippingMethodId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ShippingMethodCountry_ShippingMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodCountry]'))
ALTER TABLE [dbo].[uCommerce_ShippingMethodCountry] CHECK CONSTRAINT [uCommerce_FK_ShippingMethodCountry_ShippingMethod]
GO
/****** Object:  ForeignKey [uCommerce_FK_ShippingMethodDescription_ShippingMethod]    Script Date: 09/04/2009 11:22:53 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ShippingMethodDescription_ShippingMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodDescription]'))
ALTER TABLE [dbo].[uCommerce_ShippingMethodDescription]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ShippingMethodDescription_ShippingMethod] FOREIGN KEY([ShippingMethodId])
REFERENCES [dbo].[uCommerce_ShippingMethod] ([ShippingMethodId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ShippingMethodDescription_ShippingMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodDescription]'))
ALTER TABLE [dbo].[uCommerce_ShippingMethodDescription] CHECK CONSTRAINT [uCommerce_FK_ShippingMethodDescription_ShippingMethod]
GO
/****** Object:  ForeignKey [uCommerce_FK_ShippingMethodPaymentMethods_PaymentMethod]    Script Date: 09/04/2009 11:22:53 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ShippingMethodPaymentMethods_PaymentMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodPaymentMethods]'))
ALTER TABLE [dbo].[uCommerce_ShippingMethodPaymentMethods]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ShippingMethodPaymentMethods_PaymentMethod] FOREIGN KEY([PaymentMethodId])
REFERENCES [dbo].[uCommerce_PaymentMethod] ([PaymentMethodId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ShippingMethodPaymentMethods_PaymentMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodPaymentMethods]'))
ALTER TABLE [dbo].[uCommerce_ShippingMethodPaymentMethods] CHECK CONSTRAINT [uCommerce_FK_ShippingMethodPaymentMethods_PaymentMethod]
GO
/****** Object:  ForeignKey [uCommerce_FK_ShippingMethodPaymentMethods_ShippingMethod]    Script Date: 09/04/2009 11:22:53 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ShippingMethodPaymentMethods_ShippingMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodPaymentMethods]'))
ALTER TABLE [dbo].[uCommerce_ShippingMethodPaymentMethods]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ShippingMethodPaymentMethods_ShippingMethod] FOREIGN KEY([ShippingMethodId])
REFERENCES [dbo].[uCommerce_ShippingMethod] ([ShippingMethodId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ShippingMethodPaymentMethods_ShippingMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodPaymentMethods]'))
ALTER TABLE [dbo].[uCommerce_ShippingMethodPaymentMethods] CHECK CONSTRAINT [uCommerce_FK_ShippingMethodPaymentMethods_ShippingMethod]
GO
/****** Object:  ForeignKey [uCommerce_FK_ShippingMethodPrice_Currency]    Script Date: 09/04/2009 11:22:53 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ShippingMethodPrice_Currency]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodPrice]'))
ALTER TABLE [dbo].[uCommerce_ShippingMethodPrice]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ShippingMethodPrice_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[uCommerce_Currency] ([CurrencyId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ShippingMethodPrice_Currency]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodPrice]'))
ALTER TABLE [dbo].[uCommerce_ShippingMethodPrice] CHECK CONSTRAINT [uCommerce_FK_ShippingMethodPrice_Currency]
GO
/****** Object:  ForeignKey [uCommerce_FK_ShippingMethodPrice_PriceGroup]    Script Date: 09/04/2009 11:22:53 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ShippingMethodPrice_PriceGroup]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodPrice]'))
ALTER TABLE [dbo].[uCommerce_ShippingMethodPrice]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ShippingMethodPrice_PriceGroup] FOREIGN KEY([PriceGroupId])
REFERENCES [dbo].[uCommerce_PriceGroup] ([PriceGroupId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ShippingMethodPrice_PriceGroup]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodPrice]'))
ALTER TABLE [dbo].[uCommerce_ShippingMethodPrice] CHECK CONSTRAINT [uCommerce_FK_ShippingMethodPrice_PriceGroup]
GO
/****** Object:  ForeignKey [uCommerce_FK_ShippingMethodPrice_ShippingMethod]    Script Date: 09/04/2009 11:22:53 ******/
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ShippingMethodPrice_ShippingMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodPrice]'))
ALTER TABLE [dbo].[uCommerce_ShippingMethodPrice]  WITH CHECK ADD  CONSTRAINT [uCommerce_FK_ShippingMethodPrice_ShippingMethod] FOREIGN KEY([ShippingMethodId])
REFERENCES [dbo].[uCommerce_ShippingMethod] ([ShippingMethodId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[uCommerce_FK_ShippingMethodPrice_ShippingMethod]') AND parent_object_id = OBJECT_ID(N'[dbo].[uCommerce_ShippingMethodPrice]'))
ALTER TABLE [dbo].[uCommerce_ShippingMethodPrice] CHECK CONSTRAINT [uCommerce_FK_ShippingMethodPrice_ShippingMethod]
GO

COMMIT