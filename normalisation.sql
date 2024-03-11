-- Maintenant, passons aux choses sérieuses, vous devez modifier votre base de données pour la normaliser avec des requêtes SQL. 
-- Vous devez faire des requêtes SQL pour chacune de ces étapes :
-- Regrouper les attributs qui dépendent fonctionnellement les uns des autres en des tables distinctes. Donc, créer des tables normalisées.
use harrypotter;
create table classe as (select registered_course FROM project_normalisation where registered_course);
INSERT INTO classe SELECT distinct registered_course FROM project_normalisation;

create table maison as (select house, prefet FROM project_normalisation where house and prefet);
INSERT INTO maison SELECT distinct house, prefet FROM project_normalisation;

create table eleve as (select student_name, house, registered_course, email, year 
FROM project_normalisation where student_name and email and year);
INSERT INTO eleve SELECT student_name, house, registered_course, email, year FROM project_normalisation;
alter table eleve add firstname text;
SET SQL_SAFE_UPDATES = 0;
update eleve set firstname = SUBSTRING(student_name, 1, locate(' ', student_name) - 1);
alter table eleve add lastname text;
update eleve set lastname = SUBSTRING(student_name, locate(' ', student_name) + 1, length(student_name) - locate(' ', student_name));
SET SQL_SAFE_UPDATES = 1;
-- Créer une clé primaire pour chaque table nouvellement créée.
ALTER TABLE classe ADD id_classe INT PRIMARY KEY AUTO_INCREMENT;

ALTER TABLE maison ADD id_maison INT PRIMARY KEY AUTO_INCREMENT;

ALTER TABLE eleve ADD id_eleve INT PRIMARY KEY AUTO_INCREMENT;

-- Ajouter des clés étrangères pour les tables qui ont des dépendances fonctionnelles avec d'autres tables.
CREATE TABLE eleve_classe (
  id_eleve INT NOT NULL,
  id_classe INT NOT NULL,
  FOREIGN KEY (id_eleve) REFERENCES eleve(id_eleve),
  FOREIGN KEY (id_classe) REFERENCES classe(id_classe)
);



INSERT INTO eleve_classe (id_eleve, id_classe)
SELECT  id_eleve, id_classe FROM eleve 
join classe ON  eleve.registered_course = classe.registered_course;

ALTER TABLE eleve ADD id_maison INT;
ALTER TABLE eleve ADD FOREIGN KEY (id_maison) REFERENCES maison (id_maison);
SET SQL_SAFE_UPDATES = 0;
UPDATE eleve SET id_maison = (SELECT id_maison FROM maison WHERE maison.house = eleve.house);
SET SQL_SAFE_UPDATES = 1;
-- Supprimer des données si nécessaire.

alter table eleve drop student_name;
alter table eleve drop house;
alter table eleve drop registered_course;

select * from maison;
select * from eleve;
select * from classe;
select * from eleve_classe order by id_eleve ASC;