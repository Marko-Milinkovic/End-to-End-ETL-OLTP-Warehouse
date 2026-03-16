USE oltp;

-- =====================================================
-- DODATNI PODACI ZA TESTIRANJE INKREMENTALNOG PUNJENJA
-- Pokrenuti ovaj skript NAKON inicijalnog punjenja
-- skladišta, pa ponovo pokrenuti global_loading_job
-- =====================================================

-- =====================================================
-- MESTO (2 nova grada)
-- =====================================================
INSERT INTO MESTO (Mesto) VALUES
('Kraljevo'),
('Užice');

-- =====================================================
-- KORISNIK (3 nova korisnika)
-- =====================================================
INSERT INTO KORISNIK (Ime, Prezime, Mobilni, Email, Godiste, Pol, IdM) VALUES
('Djordje','Djordjevic','0611234567','djordje@gmail.com',1990,'M',11),
('Tamara','Tomic','0627654321','tamara@gmail.com',2000,'Z',12),
('Milan','Milovanovic','0639876543','milan@gmail.com',1985,'M',1);

-- =====================================================
-- ARTIKAL (3 nova artikla — 3 nova prodavca u skladištu)
-- =====================================================
INSERT INTO ARTIKAL (Naziv, Opis, Cena, Popust, Kolicina, IdKor, IdKat) VALUES
('Razer mis','Gaming mis',400,5,30,11,8),
('MacBook Pro','Apple laptop 16 inch',2500,3,4,12,2),
('Sony WH-1000','Noise cancelling slusalice',300,10,15,13,5);

-- =====================================================
-- NARUDZBINA (3 nove narudžbine sa novim datumima)
-- =====================================================
INSERT INTO NARUDZBINA (IdKor, Datum, Vreme, Iznos) VALUES
(1, '2024-06-10','09:00:00',1600),
(11,'2024-07-15','12:30:00',2500),
(12,'2024-08-20','17:00:00',600);

-- =====================================================
-- STAVKA (4 nove stavke — neke narudžbine imaju >1 artikal)
-- =====================================================
INSERT INTO STAVKA (IdNar, IdArt, Iznos, Kolicina) VALUES
(11,11,800,2),
(11,2,800,1),
(12,12,2500,1),
(13,13,600,2);

-- =====================================================
-- KORPA
-- =====================================================
INSERT INTO KORPA (IdKor, IdArt, Kolicina) VALUES
(11,1,1),
(12,3,2),
(13,6,1);

-- =====================================================
-- RECENZIJA (3 nove recenzije sa novim datumima)
-- =====================================================
INSERT INTO RECENZIJA (IdKor, IdArt, Ocena, Opis, Datum, Vreme) VALUES
(1,11,4,'Dobar gaming mis','2024-06-15','10:00:00'),
(11,12,5,'Odlican laptop, preporuka','2024-07-20','14:00:00'),
(12,13,3,'Prosecne slusalice za tu cenu','2024-08-25','16:00:00');
