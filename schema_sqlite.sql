-- ContosoRetailDW - SQLite Schema
-- Converted from T-SQL (MSSQL) to SQLite compatible syntax
--
-- Type mappings:
--   int, tinyint, smallint, bit  -> INTEGER
--   nvarchar, nchar, sysname     -> TEXT
--   datetime, date               -> TEXT  (store as ISO 8601: YYYY-MM-DD HH:MM:SS)
--   money, float                 -> REAL
--   varbinary                    -> BLOB
--   geometry, geography          -> TEXT  (no native spatial support in SQLite)
--   IDENTITY(1,1)                -> INTEGER PRIMARY KEY AUTOINCREMENT
--   ContosoRetailDW.dbo.Table    -> Table (no three-part names in SQLite)
--   DEFAULT N'...'               -> DEFAULT '...'
--   COLLATE SQL_Latin1_...       -> removed

PRAGMA foreign_keys = ON;

-- ============================================================
-- DIMENSION TABLES (no foreign key dependencies)
-- ============================================================

CREATE TABLE DimAccount (
    AccountKey          INTEGER PRIMARY KEY AUTOINCREMENT,
    ParentAccountKey    INTEGER,
    AccountLabel        TEXT,
    AccountName         TEXT,
    AccountDescription  TEXT,
    AccountType         TEXT,
    Operator            TEXT,
    CustomMembers       TEXT,
    ValueType           TEXT,
    CustomMemberOptions TEXT,
    ETLLoadID           INTEGER,
    LoadDate            TEXT,
    UpdateDate          TEXT
);

CREATE TABLE DimChannel (
    ChannelKey         INTEGER PRIMARY KEY AUTOINCREMENT,
    ChannelLabel       TEXT NOT NULL,
    ChannelName        TEXT,
    ChannelDescription TEXT,
    ETLLoadID          INTEGER,
    LoadDate           TEXT,
    UpdateDate         TEXT
);

CREATE TABLE DimCurrency (
    CurrencyKey         INTEGER PRIMARY KEY AUTOINCREMENT,
    CurrencyLabel       TEXT NOT NULL,
    CurrencyName        TEXT NOT NULL,
    CurrencyDescription TEXT NOT NULL,
    ETLLoadID           INTEGER,
    LoadDate            TEXT,
    UpdateDate          TEXT,
    CONSTRAINT AK_DimCurrency_CurrencyLabel UNIQUE (CurrencyLabel)
);

-- Datekey stored as TEXT in ISO 8601 format (YYYY-MM-DD HH:MM:SS)
CREATE TABLE DimDate (
    Datekey                TEXT NOT NULL PRIMARY KEY,
    FullDateLabel          TEXT NOT NULL,
    DateDescription        TEXT NOT NULL,
    CalendarYear           INTEGER NOT NULL,
    CalendarYearLabel      TEXT NOT NULL,
    CalendarHalfYear       INTEGER NOT NULL,
    CalendarHalfYearLabel  TEXT NOT NULL,
    CalendarQuarter        INTEGER NOT NULL,
    CalendarQuarterLabel   TEXT,
    CalendarMonth          INTEGER NOT NULL,
    CalendarMonthLabel     TEXT NOT NULL,
    CalendarWeek           INTEGER NOT NULL,
    CalendarWeekLabel      TEXT NOT NULL,
    CalendarDayOfWeek      INTEGER NOT NULL,
    CalendarDayOfWeekLabel TEXT NOT NULL,
    FiscalYear             INTEGER NOT NULL,
    FiscalYearLabel        TEXT NOT NULL,
    FiscalHalfYear         INTEGER NOT NULL,
    FiscalHalfYearLabel    TEXT NOT NULL,
    FiscalQuarter          INTEGER NOT NULL,
    FiscalQuarterLabel     TEXT NOT NULL,
    FiscalMonth            INTEGER NOT NULL,
    FiscalMonthLabel       TEXT NOT NULL,
    IsWorkDay              TEXT NOT NULL,
    IsHoliday              INTEGER NOT NULL,
    HolidayName            TEXT NOT NULL,
    EuropeSeason           TEXT,
    NorthAmericaSeason     TEXT,
    AsiaSeason             TEXT
);

CREATE TABLE DimEntity (
    EntityKey         INTEGER PRIMARY KEY AUTOINCREMENT,
    EntityLabel       TEXT,
    ParentEntityKey   INTEGER,
    ParentEntityLabel TEXT,
    EntityName        TEXT,
    EntityDescription TEXT,
    EntityType        TEXT,
    StartDate         TEXT,
    EndDate           TEXT,
    Status            TEXT DEFAULT 'Current',
    ETLLoadID         INTEGER,
    LoadDate          TEXT,
    UpdateDate        TEXT
);

CREATE TABLE DimGeography (
    GeographyKey      INTEGER PRIMARY KEY AUTOINCREMENT,
    GeographyType     TEXT NOT NULL,
    ContinentName     TEXT NOT NULL,
    CityName          TEXT,
    StateProvinceName TEXT,
    RegionCountryName TEXT,
    Geometry          TEXT,
    ETLLoadID         INTEGER,
    LoadDate          TEXT,
    UpdateDate        TEXT
);

CREATE TABLE DimOutage (
    OutageKey                INTEGER PRIMARY KEY AUTOINCREMENT,
    OutageLabel              TEXT NOT NULL,
    OutageName               TEXT NOT NULL,
    OutageDescription        TEXT NOT NULL,
    OutageType               TEXT NOT NULL,
    OutageTypeDescription    TEXT NOT NULL,
    OutageSubType            TEXT NOT NULL,
    OutageSubTypeDescription TEXT NOT NULL,
    ETLLoadID                INTEGER,
    LoadDate                 TEXT,
    UpdateDate               TEXT
);

CREATE TABLE DimProductCategory (
    ProductCategoryKey         INTEGER PRIMARY KEY AUTOINCREMENT,
    ProductCategoryLabel       TEXT,
    ProductCategoryName        TEXT NOT NULL,
    ProductCategoryDescription TEXT NOT NULL,
    ETLLoadID                  INTEGER,
    LoadDate                   TEXT,
    UpdateDate                 TEXT,
    CONSTRAINT AK_DimProductCategory_ProductCategoryLabel UNIQUE (ProductCategoryLabel)
);

CREATE TABLE DimPromotion (
    PromotionKey         INTEGER PRIMARY KEY AUTOINCREMENT,
    PromotionLabel       TEXT,
    PromotionName        TEXT,
    PromotionDescription TEXT,
    DiscountPercent      REAL,
    PromotionType        TEXT,
    PromotionCategory    TEXT,
    StartDate            TEXT NOT NULL,
    EndDate              TEXT,
    MinQuantity          INTEGER,
    MaxQuantity          INTEGER,
    ETLLoadID            INTEGER,
    LoadDate             TEXT,
    UpdateDate           TEXT,
    CONSTRAINT AK_DimPromotion_PromotionLabel UNIQUE (PromotionLabel)
);

CREATE TABLE DimScenario (
    ScenarioKey         INTEGER PRIMARY KEY AUTOINCREMENT,
    ScenarioLabel       TEXT NOT NULL,
    ScenarioName        TEXT,
    ScenarioDescription TEXT,
    ETLLoadID           INTEGER,
    LoadDate            TEXT,
    UpdateDate          TEXT
);

CREATE TABLE sysdiagrams (
    name         TEXT NOT NULL,
    principal_id INTEGER NOT NULL,
    diagram_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    version      INTEGER,
    definition   BLOB,
    CONSTRAINT UK_principal_name UNIQUE (principal_id, name)
);

-- ============================================================
-- DIMENSION TABLES (with foreign key dependencies)
-- ============================================================

CREATE TABLE DimCustomer (
    CustomerKey          INTEGER PRIMARY KEY AUTOINCREMENT,
    GeographyKey         INTEGER NOT NULL,
    CustomerLabel        TEXT NOT NULL,
    Title                TEXT,
    FirstName            TEXT,
    MiddleName           TEXT,
    LastName             TEXT,
    NameStyle            INTEGER,
    BirthDate            TEXT,
    MaritalStatus        TEXT,
    Suffix               TEXT,
    Gender               TEXT,
    EmailAddress         TEXT,
    YearlyIncome         REAL,
    TotalChildren        INTEGER,
    NumberChildrenAtHome INTEGER,
    Education            TEXT,
    Occupation           TEXT,
    HouseOwnerFlag       TEXT,
    NumberCarsOwned      INTEGER,
    AddressLine1         TEXT,
    AddressLine2         TEXT,
    Phone                TEXT,
    DateFirstPurchase    TEXT,
    CustomerType         TEXT,
    CompanyName          TEXT,
    ETLLoadID            INTEGER,
    LoadDate             TEXT,
    UpdateDate           TEXT,
    CONSTRAINT IX_DimCustomer_CustomerLabel UNIQUE (CustomerLabel),
    CONSTRAINT FK_DimCustomer_DimGeography FOREIGN KEY (GeographyKey) REFERENCES DimGeography(GeographyKey)
);

CREATE TABLE DimEmployee (
    EmployeeKey           INTEGER PRIMARY KEY AUTOINCREMENT,
    ParentEmployeeKey     INTEGER,
    FirstName             TEXT NOT NULL,
    LastName              TEXT NOT NULL,
    MiddleName            TEXT,
    Title                 TEXT,
    HireDate              TEXT,
    BirthDate             TEXT,
    EmailAddress          TEXT,
    Phone                 TEXT,
    MaritalStatus         TEXT,
    EmergencyContactName  TEXT,
    EmergencyContactPhone TEXT,
    SalariedFlag          INTEGER,
    Gender                TEXT,
    PayFrequency          INTEGER,
    BaseRate              REAL,
    VacationHours         INTEGER,
    CurrentFlag           INTEGER NOT NULL,
    SalesPersonFlag       INTEGER NOT NULL,
    DepartmentName        TEXT,
    StartDate             TEXT,
    EndDate               TEXT,
    Status                TEXT,
    ETLLoadID             INTEGER,
    LoadDate              TEXT,
    UpdateDate            TEXT,
    CONSTRAINT FK_DimEmployee_DimEmployee FOREIGN KEY (ParentEmployeeKey) REFERENCES DimEmployee(EmployeeKey)
);

CREATE TABLE DimProductSubcategory (
    ProductSubcategoryKey         INTEGER PRIMARY KEY AUTOINCREMENT,
    ProductSubcategoryLabel       TEXT,
    ProductSubcategoryName        TEXT NOT NULL,
    ProductSubcategoryDescription TEXT,
    ProductCategoryKey            INTEGER,
    ETLLoadID                     INTEGER,
    LoadDate                      TEXT,
    UpdateDate                    TEXT,
    CONSTRAINT AK_DimProductSubcategory_ProductSubcategoryLabel UNIQUE (ProductSubcategoryLabel),
    CONSTRAINT FK_DimProductSubcategory_DimProductCategory FOREIGN KEY (ProductCategoryKey) REFERENCES DimProductCategory(ProductCategoryKey)
);

CREATE TABLE DimSalesTerritory (
    SalesTerritoryKey     INTEGER PRIMARY KEY AUTOINCREMENT,
    GeographyKey          INTEGER NOT NULL,
    SalesTerritoryLabel   TEXT,
    SalesTerritoryName    TEXT NOT NULL,
    SalesTerritoryRegion  TEXT NOT NULL,
    SalesTerritoryCountry TEXT NOT NULL,
    SalesTerritoryGroup   TEXT,
    SalesTerritoryLevel   TEXT,
    SalesTerritoryManager INTEGER,
    StartDate             TEXT,
    EndDate               TEXT,
    Status                TEXT,
    ETLLoadID             INTEGER,
    LoadDate              TEXT,
    UpdateDate            TEXT,
    CONSTRAINT AK_DimSalesTerritory_SalesTerritoryLabel UNIQUE (SalesTerritoryLabel),
    CONSTRAINT FK_DimSalesTerritory_DimGeography FOREIGN KEY (GeographyKey) REFERENCES DimGeography(GeographyKey)
);

CREATE TABLE DimStore (
    StoreKey         INTEGER PRIMARY KEY AUTOINCREMENT,
    GeographyKey     INTEGER NOT NULL,
    StoreManager     INTEGER,
    StoreType        TEXT,
    StoreName        TEXT NOT NULL,
    StoreDescription TEXT NOT NULL,
    Status           TEXT NOT NULL,
    OpenDate         TEXT NOT NULL,
    CloseDate        TEXT,
    EntityKey        INTEGER,
    ZipCode          TEXT,
    ZipCodeExtension TEXT,
    StorePhone       TEXT,
    StoreFax         TEXT,
    AddressLine1     TEXT,
    AddressLine2     TEXT,
    CloseReason      TEXT,
    EmployeeCount    INTEGER,
    SellingAreaSize  REAL,
    LastRemodelDate  TEXT,
    GeoLocation      TEXT,
    Geometry         TEXT,
    ETLLoadID        INTEGER,
    LoadDate         TEXT,
    UpdateDate       TEXT,
    CONSTRAINT FK_DimStore_DimGeography FOREIGN KEY (GeographyKey) REFERENCES DimGeography(GeographyKey)
);

-- DimMachine has no IDENTITY — MachineKey is manually assigned
CREATE TABLE DimMachine (
    MachineKey         INTEGER PRIMARY KEY,
    MachineLabel       TEXT,
    StoreKey           INTEGER NOT NULL,
    MachineType        TEXT NOT NULL,
    MachineName        TEXT NOT NULL,
    MachineDescription TEXT NOT NULL,
    VendorName         TEXT NOT NULL,
    MachineOS          TEXT NOT NULL,
    MachineSource      TEXT NOT NULL,
    MachineHardware    TEXT,
    MachineSoftware    TEXT NOT NULL,
    Status             TEXT NOT NULL,
    ServiceStartDate   TEXT NOT NULL,
    DecommissionDate   TEXT,
    LastModifiedDate   TEXT,
    ETLLoadID          INTEGER,
    LoadDate           TEXT,
    UpdateDate         TEXT,
    CONSTRAINT FK_DimMachine_DimStore FOREIGN KEY (StoreKey) REFERENCES DimStore(StoreKey)
);

CREATE TABLE DimProduct (
    ProductKey            INTEGER PRIMARY KEY AUTOINCREMENT,
    ProductLabel          TEXT,
    ProductName           TEXT,
    ProductDescription    TEXT,
    ProductSubcategoryKey INTEGER,
    Manufacturer          TEXT,
    BrandName             TEXT,
    ClassID               TEXT,
    ClassName             TEXT,
    StyleID               TEXT,
    StyleName             TEXT,
    ColorID               TEXT,
    ColorName             TEXT NOT NULL,
    Size                  TEXT,
    SizeRange             TEXT,
    SizeUnitMeasureID     TEXT,
    Weight                REAL,
    WeightUnitMeasureID   TEXT,
    UnitOfMeasureID       TEXT,
    UnitOfMeasureName     TEXT,
    StockTypeID           TEXT,
    StockTypeName         TEXT,
    UnitCost              REAL,
    UnitPrice             REAL,
    AvailableForSaleDate  TEXT,
    StopSaleDate          TEXT,
    Status                TEXT,
    ImageURL              TEXT,
    ProductURL            TEXT,
    ETLLoadID             INTEGER,
    LoadDate              TEXT,
    UpdateDate            TEXT,
    CONSTRAINT FK_DimProduct_DimProductSubcategory FOREIGN KEY (ProductSubcategoryKey) REFERENCES DimProductSubcategory(ProductSubcategoryKey)
);

-- ============================================================
-- FACT TABLES
-- ============================================================

CREATE TABLE FactExchangeRate (
    ExchangeRateKey INTEGER PRIMARY KEY AUTOINCREMENT,
    CurrencyKey     INTEGER NOT NULL,
    DateKey         TEXT NOT NULL,
    AverageRate     REAL NOT NULL,
    EndOfDayRate    REAL NOT NULL,
    ETLLoadID       INTEGER,
    LoadDate        TEXT,
    UpdateDate      TEXT,
    CONSTRAINT FK_FactExchangeRate_DimCurrency FOREIGN KEY (CurrencyKey) REFERENCES DimCurrency(CurrencyKey),
    CONSTRAINT FK_FactExchangeRate_DimDate FOREIGN KEY (DateKey) REFERENCES DimDate(Datekey)
);

CREATE TABLE FactStrategyPlan (
    StrategyPlanKey    INTEGER PRIMARY KEY AUTOINCREMENT,
    Datekey            TEXT NOT NULL,
    EntityKey          INTEGER NOT NULL,
    ScenarioKey        INTEGER NOT NULL,
    AccountKey         INTEGER NOT NULL,
    CurrencyKey        INTEGER NOT NULL,
    ProductCategoryKey INTEGER,
    Amount             REAL NOT NULL,
    ETLLoadID          INTEGER,
    LoadDate           TEXT,
    UpdateDate         TEXT,
    CONSTRAINT FK_FactStrategyPlan_DimAccount FOREIGN KEY (AccountKey) REFERENCES DimAccount(AccountKey),
    CONSTRAINT FK_FactStrategyPlan_DimCurrency FOREIGN KEY (CurrencyKey) REFERENCES DimCurrency(CurrencyKey),
    CONSTRAINT FK_FactStrategyPlan_DimDate FOREIGN KEY (Datekey) REFERENCES DimDate(Datekey),
    CONSTRAINT FK_FactStrategyPlan_DimEntity FOREIGN KEY (EntityKey) REFERENCES DimEntity(EntityKey),
    CONSTRAINT FK_FactStrategyPlan_DimProductCategory FOREIGN KEY (ProductCategoryKey) REFERENCES DimProductCategory(ProductCategoryKey),
    CONSTRAINT FK_FactStrategyPlan_DimScenario FOREIGN KEY (ScenarioKey) REFERENCES DimScenario(ScenarioKey)
);

CREATE TABLE FactITMachine (
    ITMachinekey INTEGER PRIMARY KEY AUTOINCREMENT,
    MachineKey   INTEGER NOT NULL,
    Datekey      TEXT NOT NULL,
    CostAmount   REAL,
    CostType     TEXT NOT NULL,
    ETLLoadID    INTEGER,
    LoadDate     TEXT,
    UpdateDate   TEXT,
    CONSTRAINT FK_FactITMachine_DimDate FOREIGN KEY (Datekey) REFERENCES DimDate(Datekey),
    CONSTRAINT FK_FactITMachine_DimMachine FOREIGN KEY (MachineKey) REFERENCES DimMachine(MachineKey)
);

CREATE TABLE FactITSLA (
    ITSLAkey        INTEGER PRIMARY KEY AUTOINCREMENT,
    DateKey         TEXT NOT NULL,
    StoreKey        INTEGER NOT NULL,
    MachineKey      INTEGER NOT NULL,
    OutageKey       INTEGER NOT NULL,
    OutageStartTime TEXT NOT NULL,
    OutageEndTime   TEXT NOT NULL,
    DownTime        INTEGER NOT NULL,
    ETLLoadID       INTEGER,
    LoadDate        TEXT,
    UpdateDate      TEXT,
    CONSTRAINT FK_FactITSLA_DimDate FOREIGN KEY (DateKey) REFERENCES DimDate(Datekey),
    CONSTRAINT FK_FactITSLA_DimMachine FOREIGN KEY (MachineKey) REFERENCES DimMachine(MachineKey),
    CONSTRAINT FK_FactITSLA_DimOutage FOREIGN KEY (OutageKey) REFERENCES DimOutage(OutageKey),
    CONSTRAINT FK_FactITSLA_DimStore FOREIGN KEY (StoreKey) REFERENCES DimStore(StoreKey)
);

CREATE TABLE FactInventory (
    InventoryKey        INTEGER PRIMARY KEY AUTOINCREMENT,
    DateKey             TEXT NOT NULL,
    StoreKey            INTEGER NOT NULL,
    ProductKey          INTEGER NOT NULL,
    CurrencyKey         INTEGER NOT NULL,
    OnHandQuantity      INTEGER NOT NULL,
    OnOrderQuantity     INTEGER NOT NULL,
    SafetyStockQuantity INTEGER,
    UnitCost            REAL NOT NULL,
    DaysInStock         INTEGER,
    MinDayInStock       INTEGER,
    MaxDayInStock       INTEGER,
    Aging               INTEGER,
    ETLLoadID           INTEGER,
    LoadDate            TEXT,
    UpdateDate          TEXT,
    CONSTRAINT FK_FactInventory_DimCurrency FOREIGN KEY (CurrencyKey) REFERENCES DimCurrency(CurrencyKey),
    CONSTRAINT FK_FactInventory_DimDate FOREIGN KEY (DateKey) REFERENCES DimDate(Datekey),
    CONSTRAINT FK_FactInventory_DimProduct FOREIGN KEY (ProductKey) REFERENCES DimProduct(ProductKey),
    CONSTRAINT FK_FactInventory_DimStore FOREIGN KEY (StoreKey) REFERENCES DimStore(StoreKey)
);

CREATE TABLE FactOnlineSales (
    OnlineSalesKey       INTEGER PRIMARY KEY AUTOINCREMENT,
    DateKey              TEXT NOT NULL,
    StoreKey             INTEGER NOT NULL,
    ProductKey           INTEGER NOT NULL,
    PromotionKey         INTEGER NOT NULL,
    CurrencyKey          INTEGER NOT NULL,
    CustomerKey          INTEGER NOT NULL,
    SalesOrderNumber     TEXT NOT NULL,
    SalesOrderLineNumber INTEGER,
    SalesQuantity        INTEGER NOT NULL,
    SalesAmount          REAL NOT NULL,
    ReturnQuantity       INTEGER NOT NULL,
    ReturnAmount         REAL,
    DiscountQuantity     INTEGER,
    DiscountAmount       REAL,
    TotalCost            REAL NOT NULL,
    UnitCost             REAL,
    UnitPrice            REAL,
    ETLLoadID            INTEGER,
    LoadDate             TEXT,
    UpdateDate           TEXT,
    CONSTRAINT FK_FactOnlineSales_DimCurrency FOREIGN KEY (CurrencyKey) REFERENCES DimCurrency(CurrencyKey),
    CONSTRAINT FK_FactOnlineSales_DimCustomer FOREIGN KEY (CustomerKey) REFERENCES DimCustomer(CustomerKey),
    CONSTRAINT FK_FactOnlineSales_DimDate FOREIGN KEY (DateKey) REFERENCES DimDate(Datekey),
    CONSTRAINT FK_FactOnlineSales_DimProduct FOREIGN KEY (ProductKey) REFERENCES DimProduct(ProductKey),
    CONSTRAINT FK_FactOnlineSales_DimPromotion FOREIGN KEY (PromotionKey) REFERENCES DimPromotion(PromotionKey),
    CONSTRAINT FK_FactOnlineSales_DimStore FOREIGN KEY (StoreKey) REFERENCES DimStore(StoreKey)
);

CREATE TABLE FactSales (
    SalesKey         INTEGER PRIMARY KEY AUTOINCREMENT,
    DateKey          TEXT NOT NULL,
    channelKey       INTEGER NOT NULL,
    StoreKey         INTEGER NOT NULL,
    ProductKey       INTEGER NOT NULL,
    PromotionKey     INTEGER NOT NULL,
    CurrencyKey      INTEGER NOT NULL,
    UnitCost         REAL NOT NULL,
    UnitPrice        REAL NOT NULL,
    SalesQuantity    INTEGER NOT NULL,
    ReturnQuantity   INTEGER NOT NULL,
    ReturnAmount     REAL,
    DiscountQuantity INTEGER,
    DiscountAmount   REAL,
    TotalCost        REAL NOT NULL,
    SalesAmount      REAL NOT NULL,
    ETLLoadID        INTEGER,
    LoadDate         TEXT,
    UpdateDate       TEXT,
    CONSTRAINT FK_FactSales_DimChannel FOREIGN KEY (channelKey) REFERENCES DimChannel(ChannelKey),
    CONSTRAINT FK_FactSales_DimCurrency FOREIGN KEY (CurrencyKey) REFERENCES DimCurrency(CurrencyKey),
    CONSTRAINT FK_FactSales_DimDate FOREIGN KEY (DateKey) REFERENCES DimDate(Datekey),
    CONSTRAINT FK_FactSales_DimProduct FOREIGN KEY (ProductKey) REFERENCES DimProduct(ProductKey),
    CONSTRAINT FK_FactSales_DimPromotion FOREIGN KEY (PromotionKey) REFERENCES DimPromotion(PromotionKey),
    CONSTRAINT FK_FactSales_DimStore FOREIGN KEY (StoreKey) REFERENCES DimStore(StoreKey)
);

CREATE TABLE FactSalesQuota (
    SalesQuotaKey      INTEGER PRIMARY KEY AUTOINCREMENT,
    ChannelKey         INTEGER NOT NULL,
    StoreKey           INTEGER NOT NULL,
    ProductKey         INTEGER NOT NULL,
    DateKey            TEXT NOT NULL,
    CurrencyKey        INTEGER NOT NULL,
    ScenarioKey        INTEGER NOT NULL,
    SalesQuantityQuota REAL NOT NULL,
    SalesAmountQuota   REAL NOT NULL,
    GrossMarginQuota   REAL NOT NULL,
    ETLLoadID          INTEGER,
    LoadDate           TEXT,
    UpdateDate         TEXT,
    CONSTRAINT FK_FactSalesQuota_DimChannel FOREIGN KEY (ChannelKey) REFERENCES DimChannel(ChannelKey),
    CONSTRAINT FK_FactSalesQuota_DimCurrency FOREIGN KEY (CurrencyKey) REFERENCES DimCurrency(CurrencyKey),
    CONSTRAINT FK_FactSalesQuota_DimDate FOREIGN KEY (DateKey) REFERENCES DimDate(Datekey),
    CONSTRAINT FK_FactSalesQuota_DimProduct FOREIGN KEY (ProductKey) REFERENCES DimProduct(ProductKey),
    CONSTRAINT FK_FactSalesQuota_DimScenario FOREIGN KEY (ScenarioKey) REFERENCES DimScenario(ScenarioKey),
    CONSTRAINT FK_FactSalesQuota_DimStore FOREIGN KEY (StoreKey) REFERENCES DimStore(StoreKey)
);
