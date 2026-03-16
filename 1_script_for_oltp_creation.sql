-- =========================================================
-- operativna-struktura.sql
-- OLTP baza za sistem prodaje artikala preko interneta
-- Proširenje: svaka tabela ima CreatedAt kolonu radi ETL-a
-- =========================================================

DROP DATABASE IF EXISTS oltp;
CREATE DATABASE oltp
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE oltp;

-- =========================================================
-- MESTO
-- =========================================================
CREATE TABLE MESTO (
    IdMes INT NOT NULL AUTO_INCREMENT,
    Mesto VARCHAR(100) NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT PK_MESTO PRIMARY KEY (IdMes),
    CONSTRAINT UQ_MESTO_Mesto UNIQUE (Mesto)
) ENGINE=InnoDB;

CREATE INDEX IX_MESTO_CreatedAt ON MESTO (CreatedAt);

-- =========================================================
-- KORISNIK
-- =========================================================
CREATE TABLE KORISNIK (
    IdKor INT NOT NULL AUTO_INCREMENT,
    Ime VARCHAR(100) NOT NULL,
    Prezime VARCHAR(100) NOT NULL,
    Mobilni VARCHAR(30) NOT NULL,
    Email VARCHAR(150) NOT NULL,
    Godiste YEAR NOT NULL,
    Pol CHAR(1) NOT NULL,
    IdM INT NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT PK_KORISNIK PRIMARY KEY (IdKor),
    CONSTRAINT UQ_KORISNIK_Email UNIQUE (Email),
    CONSTRAINT UQ_KORISNIK_Mobilni UNIQUE (Mobilni),
    CONSTRAINT FK_KORISNIK_MESTO FOREIGN KEY (IdM)
        REFERENCES MESTO(IdMes)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT CHK_KORISNIK_Pol CHECK (Pol IN ('M', 'Z'))
) ENGINE=InnoDB;

CREATE INDEX IX_KORISNIK_IdM ON KORISNIK (IdM);
CREATE INDEX IX_KORISNIK_CreatedAt ON KORISNIK (CreatedAt);
CREATE INDEX IX_KORISNIK_Pol ON KORISNIK (Pol);
CREATE INDEX IX_KORISNIK_Godiste ON KORISNIK (Godiste);

-- =========================================================
-- KATEGORIJA
-- =========================================================
CREATE TABLE KATEGORIJA (
    IdKat INT NOT NULL AUTO_INCREMENT,
    Naziv VARCHAR(100) NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT PK_KATEGORIJA PRIMARY KEY (IdKat),
    CONSTRAINT UQ_KATEGORIJA_Naziv UNIQUE (Naziv)
) ENGINE=InnoDB;

CREATE INDEX IX_KATEGORIJA_CreatedAt ON KATEGORIJA (CreatedAt);

-- =========================================================
-- ARTIKAL
-- =========================================================
CREATE TABLE ARTIKAL (
    IdArt INT NOT NULL AUTO_INCREMENT,
    Naziv VARCHAR(150) NOT NULL,
    Opis TEXT NULL,
    Cena DECIMAL(10,2) NOT NULL,
    Popust DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    Kolicina INT NOT NULL,
    IdKor INT NOT NULL,      -- prodavac
    IdKat INT NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT PK_ARTIKAL PRIMARY KEY (IdArt),
    CONSTRAINT FK_ARTIKAL_KORISNIK FOREIGN KEY (IdKor)
        REFERENCES KORISNIK(IdKor)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT FK_ARTIKAL_KATEGORIJA FOREIGN KEY (IdKat)
        REFERENCES KATEGORIJA(IdKat)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT CHK_ARTIKAL_Cena CHECK (Cena >= 0),
    CONSTRAINT CHK_ARTIKAL_Popust CHECK (Popust >= 0 AND Popust <= 100),
    CONSTRAINT CHK_ARTIKAL_Kolicina CHECK (Kolicina >= 0)
) ENGINE=InnoDB;

CREATE INDEX IX_ARTIKAL_IdKor ON ARTIKAL (IdKor);
CREATE INDEX IX_ARTIKAL_IdKat ON ARTIKAL (IdKat);
CREATE INDEX IX_ARTIKAL_CreatedAt ON ARTIKAL (CreatedAt);

-- =========================================================
-- NARUDZBINA
-- =========================================================
CREATE TABLE NARUDZBINA (
    IdNar INT NOT NULL AUTO_INCREMENT,
    IdKor INT NOT NULL,      -- kupac
    Datum DATE NOT NULL,
    Vreme TIME NOT NULL,
    Iznos DECIMAL(12,2) NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT PK_NARUDZBINA PRIMARY KEY (IdNar),
    CONSTRAINT FK_NARUDZBINA_KORISNIK FOREIGN KEY (IdKor)
        REFERENCES KORISNIK(IdKor)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT CHK_NARUDZBINA_Iznos CHECK (Iznos >= 0)
) ENGINE=InnoDB;

CREATE INDEX IX_NARUDZBINA_IdKor ON NARUDZBINA (IdKor);
CREATE INDEX IX_NARUDZBINA_Datum ON NARUDZBINA (Datum);
CREATE INDEX IX_NARUDZBINA_CreatedAt ON NARUDZBINA (CreatedAt);

-- =========================================================
-- STAVKA
-- =========================================================
CREATE TABLE STAVKA (
    IdNar INT NOT NULL,
    IdArt INT NOT NULL,
    Iznos DECIMAL(12,2) NOT NULL,
    Kolicina INT NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT PK_STAVKA PRIMARY KEY (IdNar, IdArt),
    CONSTRAINT FK_STAVKA_NARUDZBINA FOREIGN KEY (IdNar)
        REFERENCES NARUDZBINA(IdNar)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT FK_STAVKA_ARTIKAL FOREIGN KEY (IdArt)
        REFERENCES ARTIKAL(IdArt)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT CHK_STAVKA_Iznos CHECK (Iznos >= 0),
    CONSTRAINT CHK_STAVKA_Kolicina CHECK (Kolicina > 0)
) ENGINE=InnoDB;

CREATE INDEX IX_STAVKA_IdArt ON STAVKA (IdArt);
CREATE INDEX IX_STAVKA_CreatedAt ON STAVKA (CreatedAt);

-- =========================================================
-- KORPA
-- =========================================================
CREATE TABLE KORPA (
    IdKor INT NOT NULL,
    IdArt INT NOT NULL,
    Kolicina INT NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT PK_KORPA PRIMARY KEY (IdKor, IdArt),
    CONSTRAINT FK_KORPA_KORISNIK FOREIGN KEY (IdKor)
        REFERENCES KORISNIK(IdKor)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT FK_KORPA_ARTIKAL FOREIGN KEY (IdArt)
        REFERENCES ARTIKAL(IdArt)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT CHK_KORPA_Kolicina CHECK (Kolicina > 0)
) ENGINE=InnoDB;

CREATE INDEX IX_KORPA_IdArt ON KORPA (IdArt);
CREATE INDEX IX_KORPA_CreatedAt ON KORPA (CreatedAt);

-- =========================================================
-- RECENZIJA
-- Napomena:
-- Zadatak ne definiše poseban IdRec, pa koristimo složeni PK.
-- =========================================================
CREATE TABLE RECENZIJA (
    IdKor INT NOT NULL,      -- korisnik koji ostavlja recenziju
    IdArt INT NOT NULL,
    Ocena INT NOT NULL,
    Opis TEXT NULL,
    Datum DATE NOT NULL,
    Vreme TIME NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT PK_RECENZIJA PRIMARY KEY (IdKor, IdArt, Datum, Vreme),
    CONSTRAINT FK_RECENZIJA_KORISNIK FOREIGN KEY (IdKor)
        REFERENCES KORISNIK(IdKor)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT FK_RECENZIJA_ARTIKAL FOREIGN KEY (IdArt)
        REFERENCES ARTIKAL(IdArt)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT CHK_RECENZIJA_Ocena CHECK (Ocena BETWEEN 1 AND 5)
) ENGINE=InnoDB;

CREATE INDEX IX_RECENZIJA_IdArt ON RECENZIJA (IdArt);
CREATE INDEX IX_RECENZIJA_Datum ON RECENZIJA (Datum);
CREATE INDEX IX_RECENZIJA_CreatedAt ON RECENZIJA (CreatedAt);

-- =========================================================
-- KRAJ
-- =========================================================