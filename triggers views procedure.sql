-- compter le nombre d'étudiants qui sont dans la maison "Gryffindor" ;
select count(id_eleve) from eleve
join maison on eleve.id_maison = maison.id_maison
where maison.house = "Gryffondor";

-- creation d'index 
create index idx_house_id on eleve(id_maison);

-- mesurer le temps de la requête avec la commande SHOW PROFILE
set profiling = 1;
select count(id_eleve) from eleve use index(idx_house_id)
join maison on eleve.id_maison = maison.id_maison
where maison.house = "Gryffondor";
SHOW PROFILES;


-- Requête a avec index 
SET profiling = 1;
ALTER TABLE eleve ADD INDEX (id_eleve);
ALTER TABLE eleve_classe ADD INDEX (id_eleve, id_classe);
ALTER TABLE classe ADD INDEX (id_classe, registered_course(50));
ALTER TABLE maison ADD INDEX (id_maison);

SELECT maison.house, classe.registered_course, COUNT(*) AS 
num_students
FROM eleve
JOIN eleve_classe ON eleve.id_eleve = eleve_classe.id_eleve
JOIN classe ON classe.id_classe = eleve_classe.id_classe
JOIN maison ON eleve.id_maison = maison.id_maison
GROUP BY maison.house, classe.registered_course
ORDER BY num_students DESC;
SHOW PROFILES;



-- Requete b : 
SET profiling = 1;

select * from eleve;
SELECT firstname,lastname, email
FROM eleve 
JOIN eleve_classe ON eleve.id_eleve = eleve_classe.id_eleve
JOIN classe ON classe.id_classe = eleve_classe.id_classe
WHERE classe.id_classe IS NULL;
SHOW PROFILES;

CREATE INDEX index_name ON eleve (firstname(50), lastname(50), email(50));

-- Requête c
set profiling = 1 ;
SELECT maison.house, COUNT(*) AS num_students
FROM eleve use index(id_eleve)
JOIN maison use index(id_maison)  ON eleve.id_maison = maison.id_maison
JOIN eleve_classe use index(id_classe, id_eleve) ON eleve.id_eleve = eleve_classe.id_eleve
JOIN classe ON classe.id_classe = eleve_classe.id_classe
WHERE EXISTS (
SELECT *
 FROM classe
 WHERE registered_course IN ('Potion', 'Sortilege', 'Botanique')
 AND id_classe = eleve_classe.id_classe
)
GROUP BY maison.house;
SHOW PROFILES;


-- Requête d



select * from classe;
set profiling = 1 ;
SELECT e.lastname AS student_name, e.email
FROM eleve e use index(id_eleve)
JOIN (
SELECT id_eleve,COUNT(DISTINCT id_classe) AS num_courses
FROM eleve_classe use index(id_classe, id_eleve)
GROUP BY id_eleve
) AS sub
ON e.id_eleve = sub.id_eleve 
JOIN (
SELECT COUNT(DISTINCT id_classe) AS num_courses
FROM classe
) AS total
ON sub.num_courses = total.num_courses
WHERE sub.num_courses = total.num_courses;
SHOW PROFILES;

-- Rajouter 2 étudiants qui suivent un cours de potion
Create or replace view student as select eleve.firstname, eleve.lastname, eleve.email, maison.house, classe.registered_course from eleve
join eleve_classe on eleve.id_eleve = eleve_classe.id_eleve 
join classe on eleve_classe.id_classe = classe.id_classe 
join maison on eleve.id_maison = maison.id_maison and classe.registered_course = 'potion';
SELECT * FROM student;

-- Ajouter deux étudiants à la table eleve
INSERT INTO eleve (email, year, firstname, lastname, id_maison, id_eleve)
VALUES 
('harry.potter@hogwarts.edu', 5, 'Harry', 'Potter', 1, 100999),
('hermione.granger@hogwarts.edu', 5, 'Hermione', 'Granger', 2, 100995);

select * from eleve; 


-- Ajouter les correspondances dans la table eleve_classe pour les deux étudiants
INSERT INTO eleve_classe (id_eleve, id_classe)
VALUES
((SELECT id_eleve 
FROM eleve 
WHERE email = 'harry.potter@hogwarts.edu'), (SELECT id_classe FROM classe WHERE registered_course = 'Potion')),
((SELECT id_eleve FROM eleve WHERE email = 'hermione.granger@hogwarts.edu'), 
(SELECT id_classe FROM classe WHERE registered_course = 'Potion'));

CREATE VIEW house_student_count AS
SELECT maison.house AS house_name, COUNT(eleve.id_eleve) AS student_count
FROM eleve
JOIN maison ON eleve.id_maison = maison.id_maison
GROUP BY maison.house;

update house_student_count
SET student_count = 10
WHERE house_name = 'Gryffondor';


CREATE TABLE house_student_count_materialized AS
SELECT maison.house, COUNT(*) AS
	student_count
	FROM eleve
	JOIN maison ON eleve.id_maison = maison.id_maison
	GROUP BY maison.house
	ORDER BY student_count DESC;
    
-- 2b) b. Créez une procédure stockée pour rafraîchir la vue matérialisée house_student_count_materialized
DELIMITER //
CREATE PROCEDURE refresh_house_student_count_materialized()
BEGIN
    TRUNCATE TABLE house_student_count_materialized;
    INSERT INTO house_student_count_materialized (house, student_count)
    SELECT house, COUNT(*) AS student_count
    FROM eleve
    JOIN maison USING (id_maison)
    GROUP BY house;
END//
DELIMITER ;

-- 2c. Exécutez la procédure stockée pour rafraîchir la vue matérialisée
call refresh_house_student_count_materialized();

-- 3a) Ajoutez un nouvel étudiant à la table eleve 
insert into eleve (firstname,lastname, email, year, id_maison, id_eleve) values ("Harry"," Pitter", "harry.pitter@poudlard.edu", 5, 2, 1000096);

-- 3b) Affichez le contenu de la table house_student_count_materialized pour vérifier si le nouvel étudiant a été pris en compte 
select * from house_student_count_materialized;

-- 3c) Exécutez la procédure stockée refresh_house_student_count_materialized() pour mettre à jour les données de la vue matérialisée house_student_count_materialized 
call refresh_house_student_count_materialized;

-- 3d) Affichez à nouveau le contenu de la vue matérialisée house_student_count_materialized pour vérifier si le nouvel étudiant a été pris en compte après l'exécution de la procédure stockée
select * from house_student_count_materialized;

-- 4a) Créez un trigger AFTER INSERT pour mettre à jour automatiquement 
-- la vue matérialisée house_student_count_materialized chaque fois qu'un étudiant est ajouté ou supprimé dans la base de données
 DELIMITER //
CREATE TRIGGER insert_update_house_count
    AFTER INSERT ON eleve
    FOR EACH ROW
    BEGIN
		DELETE FROM house_student_count_materialized;
        INSERT INTO house_student_count_materialized (house, student_count)
        SELECT house, COUNT(*) AS student_count
        FROM eleve
        JOIN maison USING (id_maison)
        GROUP BY house;
    END //
DELIMITER ;
drop trigger insert_update_house_count;

 -- 4b) Créez un trigger AFTER DELETE pour mettre à jour automatiquement la vue matérialisée house_student_count_materialized chaque fois qu'un étudiant est supprimé dans la base de données
 DELIMITER //
CREATE TRIGGER delete_update_house_count
    AFTER DELETE ON eleve
    FOR EACH ROW
    BEGIN
        DELETE FROM house_student_count_materialized;
        INSERT INTO house_student_count_materialized (house, student_count)
        SELECT house, COUNT(*) AS student_count
        FROM eleve
        JOIN maison USING (id_maison)
        GROUP BY house;
    END //
DELIMITER ;
 drop trigger delete_update_house_count;
 
 -- 5a) Affichez le contenu de la table house_student_count_materialized avant d'effectuer des modifications 
 select * from house_student_count_materialized;
 
 -- 5b) Insérez un nouvel étudiant dans la table eleve

 SET SQL_SAFE_UPDATES = 0;
insert into eleve (firstname,lastname, email, year, id_maison, id_eleve) values ("Harry"," Patter", "harry.patter@poudlard.edu", 5, 1, 888000);
SET SQL_SAFE_UPDATES = 1;
 -- 5c) Affichez le contenu de la table house_student_count_materialized après l'insertion pour vérifier si le trigger AFTER INSERT a fonctionné
 select * from house_student_count_materialized;
 
 -- 5d) Supprimez l'étudiant précédemment inséré de la table eleve
 
select * from eleve where id_eleve = '888000';
DELETE FROM eleve
WHERE id_eleve = '888000';

 -- 5e) Affichez le contenu de la table house_student_count_materialized après la suppression pour vérifier si le trigger AFTER DELETE a fonctionné 
 select * from house_student_count_materialized;
    