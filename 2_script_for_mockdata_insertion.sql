USE oltp;

-- =====================================================
-- MESTO
-- =====================================================
INSERT INTO MESTO (Mesto) VALUES
('Beograd'),
('Novi Sad'),
('Niš'),
('Kragujevac'),
('Subotica'),
('Pančevo'),
('Zrenjanin'),
('Čačak'),
('Leskovac'),
('Valjevo');

-- =====================================================
-- KATEGORIJA
-- =====================================================
INSERT INTO KATEGORIJA (Naziv) VALUES
('Telefon'),
('Laptop'),
('Televizor'),
('Kamera'),
('Slusalice'),
('Monitor'),
('Tablet'),
('Konzola'),
('Pametni sat'),
('Dron');

-- =====================================================
-- KORISNIK
-- =====================================================
INSERT INTO KORISNIK (Ime, Prezime, Mobilni, Email, Godiste, Pol, IdM) VALUES
('Marko','Petrovic','061111111','marko1@gmail.com',1998,'M',1),
('Ana','Jovanovic','062222222','ana@gmail.com',1995,'Z',2),
('Nikola','Nikolic','063333333','nikola@gmail.com',1992,'M',3),
('Milica','Milic','064444444','milica@gmail.com',1999,'Z',4),
('Stefan','Stefanovic','065555555','stefan@gmail.com',1997,'M',5),
('Jelena','Jelic','066666666','jelena@gmail.com',1993,'Z',6),
('Luka','Lukic','067777777','luka@gmail.com',2000,'M',7),
('Ivana','Ivanovic','068888888','ivana@gmail.com',1996,'Z',8),
('Petar','Petrovic','069999999','petar@gmail.com',1994,'M',9),
('Sara','Saric','060000000','sara@gmail.com',2001,'Z',10);

-- =====================================================
-- ARTIKAL (prodavci su korisnici)
-- =====================================================
INSERT INTO ARTIKAL (Naziv, Opis, Cena, Popust, Kolicina, IdKor, IdKat) VALUES
('iPhone 13','Apple telefon',900,5,10,1,1),
('Samsung Galaxy S21','Samsung telefon',800,10,15,2,1),
('Dell XPS 13','Laptop Dell',1200,7,5,3,2),
('LG OLED','Smart TV',1500,12,7,4,3),
('Sony kamera','Digitalna kamera',600,5,8,5,4),
('AirPods','Bezicne slusalice',200,3,20,6,5),
('Samsung monitor','4K monitor',350,8,9,7,6),
('iPad','Apple tablet',500,5,12,8,7),
('Playstation 5','Gaming konzola',700,6,6,9,8),
('DJI Mini','Dron kamera',800,9,4,10,10);

-- =====================================================
-- NARUDZBINA
-- =====================================================
INSERT INTO NARUDZBINA (IdKor, Datum, Vreme, Iznos) VALUES
(2,'2024-01-10','10:10:00',900),
(3,'2024-01-12','12:00:00',800),
(4,'2024-02-01','09:30:00',1200),
(5,'2024-02-15','14:20:00',1500),
(6,'2024-03-01','11:11:00',600),
(7,'2024-03-20','15:45:00',200),
(8,'2024-04-05','18:30:00',350),
(9,'2024-04-10','19:20:00',500),
(10,'2024-05-01','13:00:00',700),
(1,'2024-05-20','16:40:00',800);

-- =====================================================
-- STAVKA (items inside order)
-- =====================================================
INSERT INTO STAVKA (IdNar, IdArt, Iznos, Kolicina) VALUES
(1,1,900,1),
(2,2,800,1),
(3,3,1200,1),
(4,4,1500,1),
(5,5,600,1),
(6,6,200,1),
(7,7,350,1),
(8,8,500,1),
(9,9,700,1),
(10,10,800,1);

-- =====================================================
-- KORPA (shopping cart)
-- =====================================================
INSERT INTO KORPA (IdKor, IdArt, Kolicina) VALUES
(1,2,1),
(2,3,1),
(3,4,2),
(4,5,1),
(5,6,3),
(6,7,1),
(7,8,1),
(8,9,2),
(9,10,1),
(10,1,1);

-- =====================================================
-- RECENZIJA
-- =====================================================
INSERT INTO RECENZIJA (IdKor, IdArt, Ocena, Opis, Datum, Vreme) VALUES
(2,1,5,'Odlican telefon','2024-01-11','10:00:00'),
(3,2,4,'Dobar odnos cene i kvaliteta','2024-01-15','11:00:00'),
(4,3,5,'Odlican laptop','2024-02-02','09:00:00'),
(5,4,3,'Skup ali kvalitetan','2024-02-20','13:00:00'),
(6,5,4,'Vrlo dobra kamera','2024-03-02','14:00:00'),
(7,6,5,'Sjajan zvuk','2024-03-22','15:00:00'),
(8,7,4,'Odlican monitor','2024-04-07','16:00:00'),
(9,8,5,'Tablet je brz','2024-04-15','17:00:00'),
(10,9,4,'Konzola radi savrseno','2024-05-02','18:00:00'),
(1,10,5,'Dron ima odlicnu kameru','2024-05-25','19:00:00');