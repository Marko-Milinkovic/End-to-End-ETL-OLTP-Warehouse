-- =========================================================
-- skladiste-struktura.sql
-- Data Warehouse schema for IS2 assignment
-- Database name: warehouse
-- Star schema designed for:
-- 1) total + incremental ETL
-- 2) Mondrian XML mapping
-- 3) required MDX queries
-- =========================================================

DROP DATABASE IF EXISTS warehouse;
CREATE DATABASE warehouse
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE warehouse;

-- Needed if we want to insert surrogate key = 0 for UNKNOWN rows
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';

-- =========================================================
-- ETL CONTROL TABLE
-- Keeps track of last successful load for each ETL flow
-- =========================================================
CREATE TABLE ETL_CONTROL (
    ProcessName VARCHAR(100) NOT NULL,
    LastSuccessfulLoad DATETIME NULL,
    LastRunStatus VARCHAR(20) NULL,
    LastRunAt DATETIME NULL,
    Note VARCHAR(255) NULL,

    CONSTRAINT PK_ETL_CONTROL PRIMARY KEY (ProcessName)
) ENGINE=InnoDB;

-- Initial process rows
INSERT INTO ETL_CONTROL (ProcessName, LastSuccessfulLoad, LastRunStatus, LastRunAt, Note) VALUES
('DIM_TIME', NULL, NULL, NULL, 'Calendar dimension'),
('DIM_GENDER', NULL, NULL, NULL, 'Gender dimension'),
('DIM_AGE_GROUP', NULL, NULL, NULL, 'Age group dimension'),
('DIM_PLACE', NULL, NULL, NULL, 'Place dimension'),
('DIM_SELLER', NULL, NULL, NULL, 'Seller dimension'),
('DIM_ARTICLE', NULL, NULL, NULL, 'Article/category dimension'),
('FACT_SALES', NULL, NULL, NULL, 'Sales fact'),
('FACT_REVIEWS', NULL, NULL, NULL, 'Reviews fact');

-- =========================================================
-- DIM_TIME
-- Calendar dimension
-- Grain: one row per calendar date
-- =========================================================
CREATE TABLE DIM_TIME (
    TimeKey INT NOT NULL AUTO_INCREMENT,
    FullDate DATE NOT NULL,
    DayNumber INT NOT NULL,
    MonthNumber INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    QuarterNumber INT NOT NULL,
    YearNumber INT NOT NULL,
    DayOfWeekNumber INT NOT NULL,
    DayOfWeekName VARCHAR(20) NOT NULL,
    IsWeekend TINYINT(1) NOT NULL,
    SourceCreatedAt DATETIME NULL,
    DW_LoadedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT PK_DIM_TIME PRIMARY KEY (TimeKey),
    CONSTRAINT UQ_DIM_TIME_FullDate UNIQUE (FullDate)
) ENGINE=InnoDB;

CREATE INDEX IX_DIM_TIME_YearNumber ON DIM_TIME (YearNumber);
CREATE INDEX IX_DIM_TIME_MonthNumber ON DIM_TIME (MonthNumber);

-- Unknown row
INSERT INTO DIM_TIME
(TimeKey, FullDate, DayNumber, MonthNumber, MonthName, QuarterNumber, YearNumber,
 DayOfWeekNumber, DayOfWeekName, IsWeekend, SourceCreatedAt, DW_LoadedAt)
VALUES
(0, '1900-01-01', 1, 1, 'Unknown', 1, 1900, 1, 'Unknown', 0, NULL, CURRENT_TIMESTAMP);

-- =========================================================
-- DIM_GENDER
-- =========================================================
CREATE TABLE DIM_GENDER (
    GenderKey INT NOT NULL AUTO_INCREMENT,
    GenderCode CHAR(1) NOT NULL,
    GenderLabel VARCHAR(20) NOT NULL,
    SourceCreatedAt DATETIME NULL,
    DW_LoadedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT PK_DIM_GENDER PRIMARY KEY (GenderKey),
    CONSTRAINT UQ_DIM_GENDER_Code UNIQUE (GenderCode)
) ENGINE=InnoDB;

INSERT INTO DIM_GENDER
(GenderKey, GenderCode, GenderLabel, SourceCreatedAt, DW_LoadedAt)
VALUES
(0, 'U', 'Unknown', NULL, CURRENT_TIMESTAMP),
(1, 'M', 'Muski', NULL, CURRENT_TIMESTAMP),
(2, 'Z', 'Zenski', NULL, CURRENT_TIMESTAMP);

-- =========================================================
-- DIM_AGE_GROUP
-- =========================================================
CREATE TABLE DIM_AGE_GROUP (
    AgeGroupKey INT NOT NULL AUTO_INCREMENT,
    AgeGroupLabel VARCHAR(20) NOT NULL,
    MinAge INT NULL,
    MaxAge INT NULL,
    SortOrder INT NOT NULL,
    SourceCreatedAt DATETIME NULL,
    DW_LoadedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT PK_DIM_AGE_GROUP PRIMARY KEY (AgeGroupKey),
    CONSTRAINT UQ_DIM_AGE_GROUP_Label UNIQUE (AgeGroupLabel)
) ENGINE=InnoDB;

INSERT INTO DIM_AGE_GROUP
(AgeGroupKey, AgeGroupLabel, MinAge, MaxAge, SortOrder, SourceCreatedAt, DW_LoadedAt)
VALUES
(0, 'Unknown', NULL, NULL, 0, NULL, CURRENT_TIMESTAMP),
(1, '<18', 0, 17, 1, NULL, CURRENT_TIMESTAMP),
(2, '18-25', 18, 25, 2, NULL, CURRENT_TIMESTAMP),
(3, '26-35', 26, 35, 3, NULL, CURRENT_TIMESTAMP),
(4, '36-45', 36, 45, 4, NULL, CURRENT_TIMESTAMP),
(5, '46-60', 46, 60, 5, NULL, CURRENT_TIMESTAMP),
(6, '60+', 61, NULL, 6, NULL, CURRENT_TIMESTAMP);

-- =========================================================
-- DIM_PLACE
-- Used as role-playing dimension:
-- buyer place / seller place
-- =========================================================
CREATE TABLE DIM_PLACE (
    PlaceKey INT NOT NULL AUTO_INCREMENT,
    SourcePlaceID INT NOT NULL,
    PlaceName VARCHAR(100) NOT NULL,
    SourceCreatedAt DATETIME NULL,
    DW_LoadedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT PK_DIM_PLACE PRIMARY KEY (PlaceKey),
    CONSTRAINT UQ_DIM_PLACE_SourcePlaceID UNIQUE (SourcePlaceID)
) ENGINE=InnoDB;

CREATE INDEX IX_DIM_PLACE_PlaceName ON DIM_PLACE (PlaceName);

INSERT INTO DIM_PLACE
(PlaceKey, SourcePlaceID, PlaceName, SourceCreatedAt, DW_LoadedAt)
VALUES
(0, 0, 'Unknown', NULL, CURRENT_TIMESTAMP);

-- =========================================================
-- DIM_SELLER
-- Needed because query e asks min/max rating per seller
-- =========================================================
CREATE TABLE DIM_SELLER (
    SellerKey INT NOT NULL AUTO_INCREMENT,
    SourceSellerID INT NOT NULL,
    SellerFullName VARCHAR(201) NOT NULL,
    SellerEmail VARCHAR(150) NULL,
    SellerMobile VARCHAR(30) NULL,
    SellerBirthYear YEAR NULL,
    SellerGenderCode CHAR(1) NULL,
    SellerPlaceName VARCHAR(100) NULL,
    SourcePlaceID INT NULL,
    SourceCreatedAt DATETIME NULL,
    DW_LoadedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT PK_DIM_SELLER PRIMARY KEY (SellerKey),
    CONSTRAINT UQ_DIM_SELLER_SourceSellerID UNIQUE (SourceSellerID)
) ENGINE=InnoDB;

CREATE INDEX IX_DIM_SELLER_FullName ON DIM_SELLER (SellerFullName);
CREATE INDEX IX_DIM_SELLER_PlaceName ON DIM_SELLER (SellerPlaceName);

INSERT INTO DIM_SELLER
(SellerKey, SourceSellerID, SellerFullName, SellerEmail, SellerMobile,
 SellerBirthYear, SellerGenderCode, SellerPlaceName, SourcePlaceID,
 SourceCreatedAt, DW_LoadedAt)
VALUES
(0, 0, 'Unknown', NULL, NULL, NULL, 'U', 'Unknown', 0, NULL, CURRENT_TIMESTAMP);

-- =========================================================
-- DIM_ARTICLE
-- Denormalized dimension:
-- category + article in one dimension
-- Great for Mondrian hierarchy:
-- Category -> Article
-- =========================================================
CREATE TABLE DIM_ARTICLE (
    ArticleKey INT NOT NULL AUTO_INCREMENT,
    SourceArticleID INT NOT NULL,
    SourceCategoryID INT NOT NULL,
    CategoryName VARCHAR(100) NOT NULL,
    ArticleName VARCHAR(150) NOT NULL,
    ArticleDescription TEXT NULL,
    CurrentPrice DECIMAL(10,2) NULL,
    CurrentDiscount DECIMAL(5,2) NULL,
    SellerSourceID INT NULL,
    SellerName VARCHAR(201) NULL,
    SourceCreatedAt DATETIME NULL,
    DW_LoadedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT PK_DIM_ARTICLE PRIMARY KEY (ArticleKey),
    CONSTRAINT UQ_DIM_ARTICLE_SourceArticleID UNIQUE (SourceArticleID)
) ENGINE=InnoDB;

CREATE INDEX IX_DIM_ARTICLE_CategoryName ON DIM_ARTICLE (CategoryName);
CREATE INDEX IX_DIM_ARTICLE_ArticleName ON DIM_ARTICLE (ArticleName);
CREATE INDEX IX_DIM_ARTICLE_SourceCategoryID ON DIM_ARTICLE (SourceCategoryID);

INSERT INTO DIM_ARTICLE
(ArticleKey, SourceArticleID, SourceCategoryID, CategoryName, ArticleName,
 ArticleDescription, CurrentPrice, CurrentDiscount, SellerSourceID,
 SellerName, SourceCreatedAt, DW_LoadedAt)
VALUES
(0, 0, 0, 'Unknown', 'Unknown', NULL, NULL, NULL, 0, 'Unknown', NULL, CURRENT_TIMESTAMP);

-- =========================================================
-- FACT_SALES
-- Grain: one sold article within one order item (one STAVKA row)
--
-- Supports:
-- - sales amount by category per year
-- - quantity sold by seller place
-- - analysis by buyer gender, age group, buyer place, seller place
-- =========================================================
CREATE TABLE FACT_SALES (
    SalesFactKey BIGINT NOT NULL AUTO_INCREMENT,

    TimeKey INT NOT NULL,
    ArticleKey INT NOT NULL,
    GenderKey INT NOT NULL,
    AgeGroupKey INT NOT NULL,
    BuyerPlaceKey INT NOT NULL,
    SellerPlaceKey INT NOT NULL,

    QuantitySold INT NOT NULL,
    SalesAmount DECIMAL(12,2) NOT NULL,

    SourceOrderID INT NOT NULL,
    SourceArticleID INT NOT NULL,
    SourceCreatedAt DATETIME NULL,
    DW_LoadedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT PK_FACT_SALES PRIMARY KEY (SalesFactKey),

    CONSTRAINT FK_FACT_SALES_TIME FOREIGN KEY (TimeKey)
        REFERENCES DIM_TIME(TimeKey),
    CONSTRAINT FK_FACT_SALES_ARTICLE FOREIGN KEY (ArticleKey)
        REFERENCES DIM_ARTICLE(ArticleKey),
    CONSTRAINT FK_FACT_SALES_GENDER FOREIGN KEY (GenderKey)
        REFERENCES DIM_GENDER(GenderKey),
    CONSTRAINT FK_FACT_SALES_AGE_GROUP FOREIGN KEY (AgeGroupKey)
        REFERENCES DIM_AGE_GROUP(AgeGroupKey),
    CONSTRAINT FK_FACT_SALES_BUYER_PLACE FOREIGN KEY (BuyerPlaceKey)
        REFERENCES DIM_PLACE(PlaceKey),
    CONSTRAINT FK_FACT_SALES_SELLER_PLACE FOREIGN KEY (SellerPlaceKey)
        REFERENCES DIM_PLACE(PlaceKey),

    CONSTRAINT UQ_FACT_SALES_SOURCE UNIQUE (SourceOrderID, SourceArticleID),

    CONSTRAINT CHK_FACT_SALES_QTY CHECK (QuantitySold >= 0),
    CONSTRAINT CHK_FACT_SALES_AMOUNT CHECK (SalesAmount >= 0)
) ENGINE=InnoDB;

CREATE INDEX IX_FACT_SALES_TimeKey ON FACT_SALES (TimeKey);
CREATE INDEX IX_FACT_SALES_ArticleKey ON FACT_SALES (ArticleKey);
CREATE INDEX IX_FACT_SALES_GenderKey ON FACT_SALES (GenderKey);
CREATE INDEX IX_FACT_SALES_AgeGroupKey ON FACT_SALES (AgeGroupKey);
CREATE INDEX IX_FACT_SALES_BuyerPlaceKey ON FACT_SALES (BuyerPlaceKey);
CREATE INDEX IX_FACT_SALES_SellerPlaceKey ON FACT_SALES (SellerPlaceKey);
CREATE INDEX IX_FACT_SALES_SourceCreatedAt ON FACT_SALES (SourceCreatedAt);

-- =========================================================
-- FACT_REVIEWS
-- Grain: one review
--
-- Supports:
-- - number of reviews by month
-- - average rating by category and seller place
-- - min/max rating by seller
-- - analysis by article, gender, age group, buyer place, seller, seller place
-- =========================================================
CREATE TABLE FACT_REVIEWS (
    ReviewFactKey BIGINT NOT NULL AUTO_INCREMENT,

    TimeKey INT NOT NULL,
    ArticleKey INT NOT NULL,
    SellerKey INT NOT NULL,
    SellerPlaceKey INT NOT NULL,
    GenderKey INT NOT NULL,
    AgeGroupKey INT NOT NULL,
    BuyerPlaceKey INT NOT NULL,

    ReviewCount INT NOT NULL DEFAULT 1,
    Rating DECIMAL(4,2) NOT NULL,
    MinRating DECIMAL(4,2) NOT NULL,
    MaxRating DECIMAL(4,2) NOT NULL,

    SourceReviewerID INT NOT NULL,
    SourceArticleID INT NOT NULL,
    ReviewDate DATE NOT NULL,
    ReviewTime TIME NOT NULL,
    SourceCreatedAt DATETIME NULL,
    DW_LoadedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT PK_FACT_REVIEWS PRIMARY KEY (ReviewFactKey),

    CONSTRAINT FK_FACT_REVIEWS_TIME FOREIGN KEY (TimeKey)
        REFERENCES DIM_TIME(TimeKey),
    CONSTRAINT FK_FACT_REVIEWS_ARTICLE FOREIGN KEY (ArticleKey)
        REFERENCES DIM_ARTICLE(ArticleKey),
    CONSTRAINT FK_FACT_REVIEWS_SELLER FOREIGN KEY (SellerKey)
        REFERENCES DIM_SELLER(SellerKey),
    CONSTRAINT FK_FACT_REVIEWS_SELLER_PLACE FOREIGN KEY (SellerPlaceKey)
        REFERENCES DIM_PLACE(PlaceKey),
    CONSTRAINT FK_FACT_REVIEWS_GENDER FOREIGN KEY (GenderKey)
        REFERENCES DIM_GENDER(GenderKey),
    CONSTRAINT FK_FACT_REVIEWS_AGE_GROUP FOREIGN KEY (AgeGroupKey)
        REFERENCES DIM_AGE_GROUP(AgeGroupKey),
    CONSTRAINT FK_FACT_REVIEWS_BUYER_PLACE FOREIGN KEY (BuyerPlaceKey)
        REFERENCES DIM_PLACE(PlaceKey),

    CONSTRAINT UQ_FACT_REVIEWS_SOURCE UNIQUE
        (SourceReviewerID, SourceArticleID, ReviewDate, ReviewTime),

    CONSTRAINT CHK_FACT_REVIEWS_COUNT CHECK (ReviewCount >= 0),
    CONSTRAINT CHK_FACT_REVIEWS_RATING CHECK (Rating BETWEEN 1 AND 5),
    CONSTRAINT CHK_FACT_REVIEWS_MIN CHECK (MinRating BETWEEN 1 AND 5),
    CONSTRAINT CHK_FACT_REVIEWS_MAX CHECK (MaxRating BETWEEN 1 AND 5)
) ENGINE=InnoDB;

CREATE INDEX IX_FACT_REVIEWS_TimeKey ON FACT_REVIEWS (TimeKey);
CREATE INDEX IX_FACT_REVIEWS_ArticleKey ON FACT_REVIEWS (ArticleKey);
CREATE INDEX IX_FACT_REVIEWS_SellerKey ON FACT_REVIEWS (SellerKey);
CREATE INDEX IX_FACT_REVIEWS_SellerPlaceKey ON FACT_REVIEWS (SellerPlaceKey);
CREATE INDEX IX_FACT_REVIEWS_GenderKey ON FACT_REVIEWS (GenderKey);
CREATE INDEX IX_FACT_REVIEWS_AgeGroupKey ON FACT_REVIEWS (AgeGroupKey);
CREATE INDEX IX_FACT_REVIEWS_BuyerPlaceKey ON FACT_REVIEWS (BuyerPlaceKey);
CREATE INDEX IX_FACT_REVIEWS_SourceCreatedAt ON FACT_REVIEWS (SourceCreatedAt);

-- =========================================================
-- OPTIONAL HELPER VIEWS FOR EASIER VALIDATION
-- Not required for Mondrian, but useful when testing ETL
-- =========================================================

CREATE OR REPLACE VIEW VW_SALES_CHECK AS
SELECT
    fs.SalesFactKey,
    dt.FullDate,
    da.CategoryName,
    da.ArticleName,
    dg.GenderLabel,
    dag.AgeGroupLabel,
    bp.PlaceName AS BuyerPlace,
    sp.PlaceName AS SellerPlace,
    fs.QuantitySold,
    fs.SalesAmount,
    fs.SourceOrderID,
    fs.SourceArticleID
FROM FACT_SALES fs
JOIN DIM_TIME dt ON fs.TimeKey = dt.TimeKey
JOIN DIM_ARTICLE da ON fs.ArticleKey = da.ArticleKey
JOIN DIM_GENDER dg ON fs.GenderKey = dg.GenderKey
JOIN DIM_AGE_GROUP dag ON fs.AgeGroupKey = dag.AgeGroupKey
JOIN DIM_PLACE bp ON fs.BuyerPlaceKey = bp.PlaceKey
JOIN DIM_PLACE sp ON fs.SellerPlaceKey = sp.PlaceKey;

CREATE OR REPLACE VIEW VW_REVIEWS_CHECK AS
SELECT
    fr.ReviewFactKey,
    dt.FullDate,
    da.CategoryName,
    da.ArticleName,
    ds.SellerFullName,
    sp.PlaceName AS SellerPlace,
    dg.GenderLabel,
    dag.AgeGroupLabel,
    bp.PlaceName AS BuyerPlace,
    fr.ReviewCount,
    fr.Rating,
    fr.MinRating,
    fr.MaxRating,
    fr.SourceReviewerID,
    fr.SourceArticleID
FROM FACT_REVIEWS fr
JOIN DIM_TIME dt ON fr.TimeKey = dt.TimeKey
JOIN DIM_ARTICLE da ON fr.ArticleKey = da.ArticleKey
JOIN DIM_SELLER ds ON fr.SellerKey = ds.SellerKey
JOIN DIM_PLACE sp ON fr.SellerPlaceKey = sp.PlaceKey
JOIN DIM_GENDER dg ON fr.GenderKey = dg.GenderKey
JOIN DIM_AGE_GROUP dag ON fr.AgeGroupKey = dag.AgeGroupKey
JOIN DIM_PLACE bp ON fr.BuyerPlaceKey = bp.PlaceKey;

-- =========================================================
-- END
-- =========================================================