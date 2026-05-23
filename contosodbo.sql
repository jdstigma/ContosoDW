-- DROP SCHEMA dbo;
-- CREATE SCHEMA dbo; -- Removed: dbo is a built-in schema and cannot be dropped or recreated

-- ContosoRetailDW.dbo.DimAccount definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.DimAccount;

CREATE TABLE ContosoRetailDW.dbo.DimAccount (
	AccountKey int IDENTITY(1,1) NOT NULL,
	ParentAccountKey int NULL,
	AccountLabel nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	AccountName nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	AccountDescription nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	AccountType nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	Operator nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CustomMembers nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ValueType nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CustomMemberOptions nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT PK_DimAccount_AccountKey PRIMARY KEY (AccountKey)
);


-- ContosoRetailDW.dbo.DimChannel definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.DimChannel;

CREATE TABLE ContosoRetailDW.dbo.DimChannel (
	ChannelKey int IDENTITY(1,1) NOT NULL,
	ChannelLabel nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ChannelName nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ChannelDescription nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT PK_DimChannel_ChannelKey PRIMARY KEY (ChannelKey)
);


-- ContosoRetailDW.dbo.DimCurrency definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.DimCurrency;

CREATE TABLE ContosoRetailDW.dbo.DimCurrency (
	CurrencyKey int IDENTITY(1,1) NOT NULL,
	CurrencyLabel nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CurrencyName nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CurrencyDescription nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT AK_DimCurrency_CurrencyLabel UNIQUE (CurrencyLabel),
	CONSTRAINT PK_DimCurrency_CurrencyKey PRIMARY KEY (CurrencyKey)
);


-- ContosoRetailDW.dbo.DimDate definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.DimDate;

CREATE TABLE ContosoRetailDW.dbo.DimDate (
	Datekey datetime NOT NULL,
	FullDateLabel nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	DateDescription nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CalendarYear int NOT NULL,
	CalendarYearLabel nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CalendarHalfYear int NOT NULL,
	CalendarHalfYearLabel nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CalendarQuarter int NOT NULL,
	CalendarQuarterLabel nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CalendarMonth int NOT NULL,
	CalendarMonthLabel nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CalendarWeek int NOT NULL,
	CalendarWeekLabel nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CalendarDayOfWeek int NOT NULL,
	CalendarDayOfWeekLabel nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	FiscalYear int NOT NULL,
	FiscalYearLabel nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	FiscalHalfYear int NOT NULL,
	FiscalHalfYearLabel nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	FiscalQuarter int NOT NULL,
	FiscalQuarterLabel nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	FiscalMonth int NOT NULL,
	FiscalMonthLabel nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	IsWorkDay nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	IsHoliday int NOT NULL,
	HolidayName nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	EuropeSeason nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	NorthAmericaSeason nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	AsiaSeason nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CONSTRAINT PK_DimDate_DateKey PRIMARY KEY (Datekey)
);


-- ContosoRetailDW.dbo.DimEntity definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.DimEntity;

CREATE TABLE ContosoRetailDW.dbo.DimEntity (
	EntityKey int IDENTITY(1,1) NOT NULL,
	EntityLabel nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ParentEntityKey int NULL,
	ParentEntityLabel nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	EntityName nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	EntityDescription nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	EntityType nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	StartDate datetime NULL,
	EndDate datetime NULL,
	Status nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT N'Current' NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT PK_DimEntity_EntityKey PRIMARY KEY (EntityKey)
);


-- ContosoRetailDW.dbo.DimGeography definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.DimGeography;

CREATE TABLE ContosoRetailDW.dbo.DimGeography (
	GeographyKey int IDENTITY(1,1) NOT NULL,
	GeographyType nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ContinentName nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CityName nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	StateProvinceName nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	RegionCountryName nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	Geometry geometry NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT PK_DimGeography_GeographyKey PRIMARY KEY (GeographyKey)
);


-- ContosoRetailDW.dbo.DimOutage definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.DimOutage;

CREATE TABLE ContosoRetailDW.dbo.DimOutage (
	OutageKey int IDENTITY(1,1) NOT NULL,
	OutageLabel nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	OutageName nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	OutageDescription nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	OutageType nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	OutageTypeDescription nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	OutageSubType nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	OutageSubTypeDescription nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT PK_DimOutage_OutageKey PRIMARY KEY (OutageKey)
);


-- ContosoRetailDW.dbo.DimProductCategory definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.DimProductCategory;

CREATE TABLE ContosoRetailDW.dbo.DimProductCategory (
	ProductCategoryKey int IDENTITY(1,1) NOT NULL,
	ProductCategoryLabel nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ProductCategoryName nvarchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ProductCategoryDescription nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT AK_DimProductCategory_ProductCategoryLabel UNIQUE (ProductCategoryLabel),
	CONSTRAINT PK_DimProductCategory_ProductCategoryKey PRIMARY KEY (ProductCategoryKey)
);


-- ContosoRetailDW.dbo.DimPromotion definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.DimPromotion;

CREATE TABLE ContosoRetailDW.dbo.DimPromotion (
	PromotionKey int IDENTITY(1,1) NOT NULL,
	PromotionLabel nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	PromotionName nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	PromotionDescription nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	DiscountPercent float NULL,
	PromotionType nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	PromotionCategory nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	StartDate datetime NOT NULL,
	EndDate datetime NULL,
	MinQuantity int NULL,
	MaxQuantity int NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT AK_DimPromotion_PromotionLabel UNIQUE (PromotionLabel),
	CONSTRAINT PK_DimPromotion_PromotionKey PRIMARY KEY (PromotionKey)
);


-- ContosoRetailDW.dbo.DimScenario definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.DimScenario;

CREATE TABLE ContosoRetailDW.dbo.DimScenario (
	ScenarioKey int IDENTITY(1,1) NOT NULL,
	ScenarioLabel nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ScenarioName nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ScenarioDescription nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT PK_DimScenario PRIMARY KEY (ScenarioKey)
);


-- ContosoRetailDW.dbo.sysdiagrams definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.sysdiagrams;

CREATE TABLE ContosoRetailDW.dbo.sysdiagrams (
	name sysname COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	principal_id int NOT NULL,
	diagram_id int IDENTITY(1,1) NOT NULL,
	version int NULL,
	definition varbinary(MAX) NULL,
	CONSTRAINT PK__sysdiagr__C2B05B6173BA3083 PRIMARY KEY (diagram_id),
	CONSTRAINT UK_principal_name UNIQUE (principal_id,name)
);


-- ContosoRetailDW.dbo.DimCustomer definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.DimCustomer;

CREATE TABLE ContosoRetailDW.dbo.DimCustomer (
	CustomerKey int IDENTITY(1,1) NOT NULL,
	GeographyKey int NOT NULL,
	CustomerLabel nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	Title nvarchar(8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	FirstName nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	MiddleName nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	LastName nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	NameStyle bit NULL,
	BirthDate date NULL,
	MaritalStatus nchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	Suffix nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	Gender nvarchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	EmailAddress nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	YearlyIncome money NULL,
	TotalChildren tinyint NULL,
	NumberChildrenAtHome tinyint NULL,
	Education nvarchar(40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	Occupation nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	HouseOwnerFlag nchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	NumberCarsOwned tinyint NULL,
	AddressLine1 nvarchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	AddressLine2 nvarchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	Phone nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	DateFirstPurchase date NULL,
	CustomerType nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CompanyName nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT IX_DimCustomer_CustomerLabel UNIQUE (CustomerLabel),
	CONSTRAINT PK_DimCustomer_CustomerKey PRIMARY KEY (CustomerKey),
	CONSTRAINT FK_DimCustomer_DimGeography FOREIGN KEY (GeographyKey) REFERENCES ContosoRetailDW.dbo.DimGeography(GeographyKey)
);


-- ContosoRetailDW.dbo.DimEmployee definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.DimEmployee;

CREATE TABLE ContosoRetailDW.dbo.DimEmployee (
	EmployeeKey int IDENTITY(1,1) NOT NULL,
	ParentEmployeeKey int NULL,
	FirstName nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	LastName nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	MiddleName nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	Title nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	HireDate date NULL,
	BirthDate date NULL,
	EmailAddress nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	Phone nvarchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	MaritalStatus nchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	EmergencyContactName nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	EmergencyContactPhone nvarchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	SalariedFlag bit NULL,
	Gender nchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	PayFrequency tinyint NULL,
	BaseRate money NULL,
	VacationHours smallint NULL,
	CurrentFlag bit NOT NULL,
	SalesPersonFlag bit NOT NULL,
	DepartmentName nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	StartDate date NULL,
	EndDate date NULL,
	Status nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT PK_DimEmployee_EmployeeKey PRIMARY KEY (EmployeeKey),
	CONSTRAINT FK_DimEmployee_DimEmployee FOREIGN KEY (ParentEmployeeKey) REFERENCES ContosoRetailDW.dbo.DimEmployee(EmployeeKey)
);


-- ContosoRetailDW.dbo.DimProductSubcategory definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.DimProductSubcategory;

CREATE TABLE ContosoRetailDW.dbo.DimProductSubcategory (
	ProductSubcategoryKey int IDENTITY(1,1) NOT NULL,
	ProductSubcategoryLabel nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ProductSubcategoryName nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ProductSubcategoryDescription nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ProductCategoryKey int NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT AK_DimProductSubcategory_ProductSubcategoryLabel UNIQUE (ProductSubcategoryLabel),
	CONSTRAINT PK_DimProductSubcategory_ProductSubcategoryKey PRIMARY KEY (ProductSubcategoryKey),
	CONSTRAINT FK_DimProductSubcategory_DimProductCategory FOREIGN KEY (ProductCategoryKey) REFERENCES ContosoRetailDW.dbo.DimProductCategory(ProductCategoryKey)
);


-- ContosoRetailDW.dbo.DimSalesTerritory definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.DimSalesTerritory;

CREATE TABLE ContosoRetailDW.dbo.DimSalesTerritory (
	SalesTerritoryKey int IDENTITY(1,1) NOT NULL,
	GeographyKey int NOT NULL,
	SalesTerritoryLabel nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	SalesTerritoryName nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	SalesTerritoryRegion nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	SalesTerritoryCountry nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	SalesTerritoryGroup nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	SalesTerritoryLevel nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	SalesTerritoryManager int NULL,
	StartDate datetime NULL,
	EndDate datetime NULL,
	Status nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT AK_DimSalesTerritory_SalesTerritoryLabel UNIQUE (SalesTerritoryLabel),
	CONSTRAINT PK_DimSalesTerritory_SalesTerritoryKey PRIMARY KEY (SalesTerritoryKey),
	CONSTRAINT FK_DimSalesTerritory_DimGeography FOREIGN KEY (GeographyKey) REFERENCES ContosoRetailDW.dbo.DimGeography(GeographyKey)
);


-- ContosoRetailDW.dbo.DimStore definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.DimStore;

CREATE TABLE ContosoRetailDW.dbo.DimStore (
	StoreKey int IDENTITY(1,1) NOT NULL,
	GeographyKey int NOT NULL,
	StoreManager int NULL,
	StoreType nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	StoreName nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	StoreDescription nvarchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	Status nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	OpenDate datetime NOT NULL,
	CloseDate datetime NULL,
	EntityKey int NULL,
	ZipCode nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ZipCodeExtension nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	StorePhone nvarchar(15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	StoreFax nvarchar(14) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	AddressLine1 nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	AddressLine2 nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CloseReason nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	EmployeeCount int NULL,
	SellingAreaSize float NULL,
	LastRemodelDate datetime NULL,
	GeoLocation geography NULL,
	Geometry geometry NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT PK_DimStore_StoreKey PRIMARY KEY (StoreKey),
	CONSTRAINT FK_DimStore_DimGeography FOREIGN KEY (GeographyKey) REFERENCES ContosoRetailDW.dbo.DimGeography(GeographyKey)
);


-- ContosoRetailDW.dbo.FactExchangeRate definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.FactExchangeRate;

CREATE TABLE ContosoRetailDW.dbo.FactExchangeRate (
	ExchangeRateKey int IDENTITY(1,1) NOT NULL,
	CurrencyKey int NOT NULL,
	DateKey datetime NOT NULL,
	AverageRate float NOT NULL,
	EndOfDayRate float NOT NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT PK_FactExchangeRate_ExchangeRateKey PRIMARY KEY (ExchangeRateKey),
	CONSTRAINT FK_FactExchangeRate_DimCurrency FOREIGN KEY (CurrencyKey) REFERENCES ContosoRetailDW.dbo.DimCurrency(CurrencyKey),
	CONSTRAINT FK_FactExchangeRate_DimDate FOREIGN KEY (DateKey) REFERENCES ContosoRetailDW.dbo.DimDate(Datekey)
);


-- ContosoRetailDW.dbo.FactStrategyPlan definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.FactStrategyPlan;

CREATE TABLE ContosoRetailDW.dbo.FactStrategyPlan (
	StrategyPlanKey int IDENTITY(1,1) NOT NULL,
	Datekey datetime NOT NULL,
	EntityKey int NOT NULL,
	ScenarioKey int NOT NULL,
	AccountKey int NOT NULL,
	CurrencyKey int NOT NULL,
	ProductCategoryKey int NULL,
	Amount money NOT NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT PK_FactStrategyPlan_StrategyPlanKey PRIMARY KEY (StrategyPlanKey),
	CONSTRAINT FK_FactStrategyPlan_DimAccount FOREIGN KEY (AccountKey) REFERENCES ContosoRetailDW.dbo.DimAccount(AccountKey),
	CONSTRAINT FK_FactStrategyPlan_DimCurrency FOREIGN KEY (CurrencyKey) REFERENCES ContosoRetailDW.dbo.DimCurrency(CurrencyKey),
	CONSTRAINT FK_FactStrategyPlan_DimDate FOREIGN KEY (Datekey) REFERENCES ContosoRetailDW.dbo.DimDate(Datekey),
	CONSTRAINT FK_FactStrategyPlan_DimEntity FOREIGN KEY (EntityKey) REFERENCES ContosoRetailDW.dbo.DimEntity(EntityKey),
	CONSTRAINT FK_FactStrategyPlan_DimProductCategory FOREIGN KEY (ProductCategoryKey) REFERENCES ContosoRetailDW.dbo.DimProductCategory(ProductCategoryKey),
	CONSTRAINT FK_FactStrategyPlan_DimScenario FOREIGN KEY (ScenarioKey) REFERENCES ContosoRetailDW.dbo.DimScenario(ScenarioKey)
);


-- ContosoRetailDW.dbo.DimMachine definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.DimMachine;

CREATE TABLE ContosoRetailDW.dbo.DimMachine (
	MachineKey int NOT NULL,
	MachineLabel nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	StoreKey int NOT NULL,
	MachineType nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	MachineName nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	MachineDescription nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	VendorName nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	MachineOS nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	MachineSource nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	MachineHardware nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	MachineSoftware nvarchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	Status nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ServiceStartDate datetime NOT NULL,
	DecommissionDate datetime NULL,
	LastModifiedDate datetime NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT PK_DimMachine_MachineKey PRIMARY KEY (MachineKey),
	CONSTRAINT FK_DimMachine_DimStore FOREIGN KEY (StoreKey) REFERENCES ContosoRetailDW.dbo.DimStore(StoreKey)
);


-- ContosoRetailDW.dbo.DimProduct definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.DimProduct;

CREATE TABLE ContosoRetailDW.dbo.DimProduct (
	ProductKey int IDENTITY(1,1) NOT NULL,
	ProductLabel nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ProductName nvarchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ProductDescription nvarchar(400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ProductSubcategoryKey int NULL,
	Manufacturer nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	BrandName nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ClassID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ClassName nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	StyleID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	StyleName nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ColorID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ColorName nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Size] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	SizeRange nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	SizeUnitMeasureID nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	Weight float NULL,
	WeightUnitMeasureID nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	UnitOfMeasureID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	UnitOfMeasureName nvarchar(40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	StockTypeID nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	StockTypeName nvarchar(40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	UnitCost money NULL,
	UnitPrice money NULL,
	AvailableForSaleDate datetime NULL,
	StopSaleDate datetime NULL,
	Status nvarchar(7) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ImageURL nvarchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ProductURL nvarchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT PK_DimProduct_ProductKey PRIMARY KEY (ProductKey),
	CONSTRAINT FK_DimProduct_DimProductSubcategory FOREIGN KEY (ProductSubcategoryKey) REFERENCES ContosoRetailDW.dbo.DimProductSubcategory(ProductSubcategoryKey)
);


-- ContosoRetailDW.dbo.FactITMachine definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.FactITMachine;

CREATE TABLE ContosoRetailDW.dbo.FactITMachine (
	ITMachinekey int IDENTITY(1,1) NOT NULL,
	MachineKey int NOT NULL,
	Datekey datetime NOT NULL,
	CostAmount money NULL,
	CostType nvarchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT PK_FactITMachine PRIMARY KEY (ITMachinekey),
	CONSTRAINT FK_FactITMachine_DimDate FOREIGN KEY (Datekey) REFERENCES ContosoRetailDW.dbo.DimDate(Datekey),
	CONSTRAINT FK_FactITMachine_DimMachine FOREIGN KEY (MachineKey) REFERENCES ContosoRetailDW.dbo.DimMachine(MachineKey)
);


-- ContosoRetailDW.dbo.FactITSLA definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.FactITSLA;

CREATE TABLE ContosoRetailDW.dbo.FactITSLA (
	ITSLAkey int IDENTITY(1,1) NOT NULL,
	DateKey datetime NOT NULL,
	StoreKey int NOT NULL,
	MachineKey int NOT NULL,
	OutageKey int NOT NULL,
	OutageStartTime datetime NOT NULL,
	OutageEndTime datetime NOT NULL,
	DownTime int NOT NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT PK_FactITSLA_ITSLAKey PRIMARY KEY (ITSLAkey),
	CONSTRAINT FK_FactITSLA_DimDate FOREIGN KEY (DateKey) REFERENCES ContosoRetailDW.dbo.DimDate(Datekey),
	CONSTRAINT FK_FactITSLA_DimMachine FOREIGN KEY (MachineKey) REFERENCES ContosoRetailDW.dbo.DimMachine(MachineKey),
	CONSTRAINT FK_FactITSLA_DimOutage FOREIGN KEY (OutageKey) REFERENCES ContosoRetailDW.dbo.DimOutage(OutageKey),
	CONSTRAINT FK_FactITSLA_DimStore FOREIGN KEY (StoreKey) REFERENCES ContosoRetailDW.dbo.DimStore(StoreKey)
);


-- ContosoRetailDW.dbo.FactInventory definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.FactInventory;

CREATE TABLE ContosoRetailDW.dbo.FactInventory (
	InventoryKey int IDENTITY(1,1) NOT NULL,
	DateKey datetime NOT NULL,
	StoreKey int NOT NULL,
	ProductKey int NOT NULL,
	CurrencyKey int NOT NULL,
	OnHandQuantity int NOT NULL,
	OnOrderQuantity int NOT NULL,
	SafetyStockQuantity int NULL,
	UnitCost money NOT NULL,
	DaysInStock int NULL,
	MinDayInStock int NULL,
	MaxDayInStock int NULL,
	Aging int NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT PK_FactInventory_InventoryKey PRIMARY KEY (InventoryKey),
	CONSTRAINT FK_FactInventory_DimCurrency FOREIGN KEY (CurrencyKey) REFERENCES ContosoRetailDW.dbo.DimCurrency(CurrencyKey),
	CONSTRAINT FK_FactInventory_DimDate FOREIGN KEY (DateKey) REFERENCES ContosoRetailDW.dbo.DimDate(Datekey),
	CONSTRAINT FK_FactInventory_DimProduct FOREIGN KEY (ProductKey) REFERENCES ContosoRetailDW.dbo.DimProduct(ProductKey),
	CONSTRAINT FK_FactInventory_DimStore FOREIGN KEY (StoreKey) REFERENCES ContosoRetailDW.dbo.DimStore(StoreKey)
);


-- ContosoRetailDW.dbo.FactOnlineSales definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.FactOnlineSales;

CREATE TABLE ContosoRetailDW.dbo.FactOnlineSales (
	OnlineSalesKey int IDENTITY(1,1) NOT NULL,
	DateKey datetime NOT NULL,
	StoreKey int NOT NULL,
	ProductKey int NOT NULL,
	PromotionKey int NOT NULL,
	CurrencyKey int NOT NULL,
	CustomerKey int NOT NULL,
	SalesOrderNumber nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	SalesOrderLineNumber int NULL,
	SalesQuantity int NOT NULL,
	SalesAmount money NOT NULL,
	ReturnQuantity int NOT NULL,
	ReturnAmount money NULL,
	DiscountQuantity int NULL,
	DiscountAmount money NULL,
	TotalCost money NOT NULL,
	UnitCost money NULL,
	UnitPrice money NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT PK_FactOnlineSales_SalesKey PRIMARY KEY (OnlineSalesKey),
	CONSTRAINT FK_FactOnlineSales_DimCurrency FOREIGN KEY (CurrencyKey) REFERENCES ContosoRetailDW.dbo.DimCurrency(CurrencyKey),
	CONSTRAINT FK_FactOnlineSales_DimCustomer FOREIGN KEY (CustomerKey) REFERENCES ContosoRetailDW.dbo.DimCustomer(CustomerKey),
	CONSTRAINT FK_FactOnlineSales_DimDate FOREIGN KEY (DateKey) REFERENCES ContosoRetailDW.dbo.DimDate(Datekey),
	CONSTRAINT FK_FactOnlineSales_DimProduct FOREIGN KEY (ProductKey) REFERENCES ContosoRetailDW.dbo.DimProduct(ProductKey),
	CONSTRAINT FK_FactOnlineSales_DimPromotion FOREIGN KEY (PromotionKey) REFERENCES ContosoRetailDW.dbo.DimPromotion(PromotionKey),
	CONSTRAINT FK_FactOnlineSales_DimStore FOREIGN KEY (StoreKey) REFERENCES ContosoRetailDW.dbo.DimStore(StoreKey)
);


-- ContosoRetailDW.dbo.FactSales definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.FactSales;

CREATE TABLE ContosoRetailDW.dbo.FactSales (
	SalesKey int IDENTITY(1,1) NOT NULL,
	DateKey datetime NOT NULL,
	channelKey int NOT NULL,
	StoreKey int NOT NULL,
	ProductKey int NOT NULL,
	PromotionKey int NOT NULL,
	CurrencyKey int NOT NULL,
	UnitCost money NOT NULL,
	UnitPrice money NOT NULL,
	SalesQuantity int NOT NULL,
	ReturnQuantity int NOT NULL,
	ReturnAmount money NULL,
	DiscountQuantity int NULL,
	DiscountAmount money NULL,
	TotalCost money NOT NULL,
	SalesAmount money NOT NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT PK_FactSales_SalesKey PRIMARY KEY (SalesKey),
	CONSTRAINT FK_FactSales_DimChannel FOREIGN KEY (channelKey) REFERENCES ContosoRetailDW.dbo.DimChannel(ChannelKey),
	CONSTRAINT FK_FactSales_DimCurrency FOREIGN KEY (CurrencyKey) REFERENCES ContosoRetailDW.dbo.DimCurrency(CurrencyKey),
	CONSTRAINT FK_FactSales_DimDate FOREIGN KEY (DateKey) REFERENCES ContosoRetailDW.dbo.DimDate(Datekey),
	CONSTRAINT FK_FactSales_DimProduct FOREIGN KEY (ProductKey) REFERENCES ContosoRetailDW.dbo.DimProduct(ProductKey),
	CONSTRAINT FK_FactSales_DimPromotion FOREIGN KEY (PromotionKey) REFERENCES ContosoRetailDW.dbo.DimPromotion(PromotionKey),
	CONSTRAINT FK_FactSales_DimStore FOREIGN KEY (StoreKey) REFERENCES ContosoRetailDW.dbo.DimStore(StoreKey)
);


-- ContosoRetailDW.dbo.FactSalesQuota definition

-- Drop table

-- DROP TABLE ContosoRetailDW.dbo.FactSalesQuota;

CREATE TABLE ContosoRetailDW.dbo.FactSalesQuota (
	SalesQuotaKey int IDENTITY(1,1) NOT NULL,
	ChannelKey int NOT NULL,
	StoreKey int NOT NULL,
	ProductKey int NOT NULL,
	DateKey datetime NOT NULL,
	CurrencyKey int NOT NULL,
	ScenarioKey int NOT NULL,
	SalesQuantityQuota money NOT NULL,
	SalesAmountQuota money NOT NULL,
	GrossMarginQuota money NOT NULL,
	ETLLoadID int NULL,
	LoadDate datetime NULL,
	UpdateDate datetime NULL,
	CONSTRAINT PK_FactSalesQuota_SalesQuotaKey PRIMARY KEY (SalesQuotaKey),
	CONSTRAINT FK_FactSalesQuota_DimChannel FOREIGN KEY (ChannelKey) REFERENCES ContosoRetailDW.dbo.DimChannel(ChannelKey),
	CONSTRAINT FK_FactSalesQuota_DimCurrency FOREIGN KEY (CurrencyKey) REFERENCES ContosoRetailDW.dbo.DimCurrency(CurrencyKey),
	CONSTRAINT FK_FactSalesQuota_DimDate FOREIGN KEY (DateKey) REFERENCES ContosoRetailDW.dbo.DimDate(Datekey),
	CONSTRAINT FK_FactSalesQuota_DimProduct FOREIGN KEY (ProductKey) REFERENCES ContosoRetailDW.dbo.DimProduct(ProductKey),
	CONSTRAINT FK_FactSalesQuota_DimScenario FOREIGN KEY (ScenarioKey) REFERENCES ContosoRetailDW.dbo.DimScenario(ScenarioKey),
	CONSTRAINT FK_FactSalesQuota_DimStore FOREIGN KEY (StoreKey) REFERENCES ContosoRetailDW.dbo.DimStore(StoreKey)
);
