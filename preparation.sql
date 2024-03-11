use harrypotter;

SHOW FULL TABLES;

-- Afficher l'ensemble des tables en SQL 
DESCRIBE project_normalisation;

-- Le nombre d'étudiants dans la base de données 
select count(student_name) from project_normalisation;

-- Les différents cours dans la base de données
select distinct registered_course from project_normalisation;

-- Les différentes maisons dans la base de données
select distinct house from project_normalisation;

-- Les différents préfets dans la base de données
select distinct prefet from project_normalisation;

-- Quel est le préfet pour chaque maison ?
select distinct house, prefet  from project_normalisation ;

-- Pour compter le nombre d'étudiants par année 
select  count(student_name), year from project_normalisation group by year;

-- Pour afficher les noms et les emails des étudiants qui suivent le cours "potion" 
select student_name, email from project_normalisation where registered_course = "potion";

-- Pour afficher les étudiants qui ont une année supérieure à 2 
select distinct student_name from project_normalisation where year > 2;

-- Pour trier les étudiants par ordre alphabétique de leur nom 
select DISTINCT student_name from project_normalisation order by student_name ASC;

-- Pour trouver le nombre d'étudiants de chaque maison qui suivent le cours "potion" 
select count(student_name) , house, registered_course from project_normalisation where registered_course = "potion" group by house; 

-- Afficher les maisons des étudiants et le nombre d'étudiants dans chaque maison 
select  count(student_name) , house from project_normalisation group by house;

-- Afficher le nombre de cours pour chaque année 
select count(registered_course) , year , registered_course from project_normalisation group by year, registered_course;

-- Afficher le nombre d'étudiants inscrits à chaque cours
select count(student_name), registered_course from project_normalisation group by registered_course;

-- Afficher les cours auxquels les étudiants de chaque maison sont inscrits
select  group_concat( distinct registered_course,' '), house from project_normalisation group by 2 order by house ASC ; 

-- Afficher le nombre d'étudiants dans chaque année pour chaque maison
select count(student_name), year , house from project_normalisation group by year , house;
 
-- Afficher les cours auxquels les étudiants de chaque année sont inscrits
select registered_course , year from project_normalisation group by year, registered_course order by year ASC;

-- Afficher les maisons des étudiants et le nombre d'étudiants dans chaque maison, triés 
-- par ordre décroissant
select house , count(student_name) as numberStudent from project_normalisation group by house order by numberStudent DESC;

-- Afficher le nombre d'étudiants inscrits à chaque cours, triés par ordre décroissant
select count(student_name) , registered_course a from project_normalisation group by registered_course order by numberStudent DESC;

-- Afficher les préfets de chaque maison, triés par ordre alphabétique des maisons
select distinct  house,prefet from project_normalisation order by house ASC ;  