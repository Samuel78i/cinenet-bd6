-- — une requête qui porte sur au moins trois tables ;
-- Cette requête récupère les noms des utilisateurs, les films qu'ils ont critiqués et les textes des critiques.
SELECT Utilisateur.pseudo AS user_name,
       Film.nom           AS film_name,
       Review.texte       AS review_text
FROM Review
         JOIN
     Utilisateur ON Review.u_id = Utilisateur.u_id
         JOIN
     Film ON Review.f_id = Film.f_id;



-- — une ’auto jointure’ (jointure de deux copies d’une même table)
-- Cette requête récupère les noms des genres et de leurs sous-genres en joignant la table Genre à elle-même via la table sousGenreDe
SELECT parent.nom AS genre_parent,
       child.nom  AS sous_genre
FROM sousGenreDe
         JOIN
     Genre parent ON sousGenreDe.g_id2 = parent.g_id
         JOIN
     Genre child ON sousGenreDe.g_id1 = child.g_id
ORDER BY genre_parent, sous_genre;


--— une sous-requête corrélée ;
--Cette requête récupère le nom de chaque film avec la note moyenne, mais uniquement pour les films avec une note moyenne supérieure à 9.
SELECT f.nom,
       (SELECT AVG(r.note)
        FROM Review r
        WHERE r.f_id = f.f_id) AS avg_rating
FROM Film f
WHERE (SELECT AVG(r.note)
       FROM Review r
       WHERE r.f_id = f.f_id) > 9;


--— une sous-requête dans le FROM ;
--Cette requête récupère le film le mieux noté pour chaque genre.
SELECT nom_genre, nom_film, note_max
FROM (SELECT Genre.nom                                                        AS nom_genre,
             f.nom                                                            AS nom_film,
             r.note                                                           AS note_max,
             ROW_NUMBER() OVER (PARTITION BY Genre.g_id ORDER BY r.note DESC) AS row_num
      FROM Genre
               JOIN Film f ON Genre.g_id = f.f_genre
               JOIN Review r ON f.f_id = r.f_id) AS ranked_films
WHERE row_num = 1;

-- — une sous-requête dans le WHERE ;
--Cette requête récupère les noms des films dont la note moyenne des critiques est inférieure à la note moyenne globale de tous les films.
SELECT f.nom
FROM Film f
WHERE (SELECT AVG(r.note)
       FROM Review r
       WHERE r.f_id = f.f_id) <
      (SELECT AVG(r2.note)
       FROM Review r2);


--— deux agrégats nécessitant GROUP BY et HAVING ;
--Cette requête récupère les genres et le nombre de films dans chaque genre, mais uniquement pour les genres ayant plus de 2 films avec une note moyenne supérieure à 5.
SELECT g.nom         AS genre_nom,
       COUNT(f.f_id) AS nombre_de_films,
       AVG(r.note)   AS note_moyenne
FROM Genre g
         JOIN
     Film f ON g.g_id = f.f_genre
         JOIN
     Review r ON f.f_id = r.f_id
GROUP BY g.nom
HAVING COUNT(f.f_id) > 2
   AND AVG(r.note) > 5;


--— une requête impliquant le calcul de deux agrégats ;
-- La moyenne et le total des notes données par utilisateur, trié par utilisateur
SELECT R.u_id        AS u_id,
       AVG(R.note)   AS moyenne,
       COUNT(R.note) AS total
FROM Review R,
     Utilisateur U
WHERE R.u_id = U.u_id
GROUP BY R.u_id
ORDER BY R.u_id;

--— une jointure externe (LEFT JOIN, RIGHT JOIN ou FULL JOIN) ;
-- Tous les posts postés par des utilisateurs ayant un pseudo qui commence par j, en associant l'utilisateur à son ou ses posts par jointure
SELECT *
FROM Utilisateur
         LEFT JOIN Post
                   ON Utilisateur.u_id = Post.posteePar
WHERE Utilisateur.pseudo LIKE 'j%';

--— deux requêtes équivalentes exprimant une condition de totalité, l’une avec des sous requêtes corrélées et l’autre avec de l’agrégation ;
-- Les (premier) posts parlant des films qui ont été dirigé par Christopher Nolan
-- agrégation --
SELECT p.*
FROM premierpost p
         JOIN film f ON p.f_id = f.f_id
WHERE f.directeur = 'Christopher Nolan'
GROUP BY p.p_id, p.texte, p.posteePar, p.f_id, p.date_de_post, sujet, titre
HAVING COUNT(p.p_id) > 0;


-- sous requetes corrélées  --
SELECT *
FROM premierpost
WHERE f_id IN
      (SELECT F.f_id
       FROM film F
       WHERE F.directeur = 'Christopher Nolan')
GROUP BY p_id, posteepar, f_id, date_de_post, texte, sujet, titre;

--— deux requêtes qui renverraient le même résultat si vos tables ne contenaient pas de nulls, 
--  mais qui renvoient des résultats différents ici (vos données devront donc contenir quelques nulls), 
--  vous proposerez également de petites modifications de vos requêtes (dans l’esprit de ce qui a été présenté en cours) afin qu’elles retournent le même résultat ;
-- Renvoie les films les mieux notés (enfin non, du aux nulls)
SELECT F1.nom, F1.note
FROM film F1
WHERE NOT EXISTS
          (SELECT *
           FROM film F2
           WHERE F2.note > F1.note);
-- Renvoie aussi les films les mieux notés (le fait, même si y'a des nulls) 
SELECT nom, note
FROM film
WHERE note =
      (SELECT MAX(note) FROM film);
-- Petite modification de la 1ere requete (on précise qu'on veut pas faire la condition avec un null)
SELECT F1.nom, F1.note
FROM film F1
WHERE F1.note IS NOT NULL
  AND NOT EXISTS
    (SELECT *
     FROM film F2
     WHERE F2.note > F1.note);



-- — Une requête récursive;
-- Cette requete récursive permet de trouver les amis d'amis d'un utilisateur donné (ici l'utilisateur 1)
WITH RECURSIVE AmisRecursif(u_id1, u_id2, niveau) AS (SELECT u_id1,
                                                             u_id2,
                                                             1
                                                      FROM amis
                                                      WHERE u_id1 = 1
                                                      UNION ALL
                                                      SELECT a.u_id1,
                                                             a.u_id2,
                                                             ar.niveau + 1
                                                      FROM amis a
                                                               INNER JOIN
                                                           AmisRecursif ar ON a.u_id1 = ar.u_id2
                                                      WHERE ar.niveau < 2 -- Limite le nombre de niveaux d'amis (amis d'amis)
)
SELECT DISTINCT u_id2 AS amis_damis
FROM AmisRecursif
WHERE niveau = 2;


-- — Une requête utilisant le fenêtrage
--   (par exemple, pour chaque mois de 2023, les dix cinémas dont les événements ont eu le plus de succès ce mois-ci, 
--   en termes de nombre d’utilisateurs ayant indiqué y participer)

-- Cette requete recupere les trois films les mieux notés pour chaque genre.
WITH FilmRatings AS (SELECT f.f_id,
                            f.nom,
                            f.date_de_sortie,
                            f.note,
                            g.nom                                                           AS genre_nom,
                            ROW_NUMBER() OVER (PARTITION BY f.f_genre ORDER BY f.note DESC) AS rank
                     FROM film f
                              JOIN
                          genre g ON f.f_genre = g.g_id
                     WHERE f.note IS NOT NULL)

SELECT fr.f_id,
       fr.nom,
       fr.date_de_sortie,
       fr.note,
       fr.genre_nom
FROM FilmRatings fr
WHERE fr.rank <= 3
ORDER BY fr.genre_nom, fr.rank;



--RECOMMANDATION
--Cette requête recommande les événements suivis par l'utilisateur jdoe (1) et ses amis, triés par date de sortie.
SELECT distinct e.nom AS evenement_recommande,
                e.date_de_sortie
FROM evenement e
         JOIN
     participeouinteresse p ON e.e_id = p.e_id
         JOIN
     amis a ON p.u_id = a.u_id2
WHERE a.u_id1 = 1
ORDER BY e.date_de_sortie;


--Une requete de recommandation qui permet de mettre en avant le film d'Action le mieux noté parmis les utilsateurs qui préfere les films d'action
WITH UtilisateursPreferentAction AS (
    SELECT u.u_id
    FROM utilisateur u
    JOIN review r ON u.u_id = r.u_id
    JOIN film f ON r.f_id = f.f_id
    JOIN genre g ON f.f_genre = g.g_id
    WHERE g.nom = 'Action'
    GROUP BY u.u_id
    HAVING COUNT(f.f_id) > 2
),

MeilleurFilmActionParUtilisateursPref AS (
    SELECT f.f_id, f.nom, f.directeur, f.date_de_sortie, AVG(COALESCE(r.note, 0)) AS note_moyenne
    FROM film f
    JOIN review r ON f.f_id = r.f_id
    JOIN UtilisateursPreferentAction upa ON r.u_id = upa.u_id
    JOIN genre g ON f.f_genre = g.g_id
    WHERE g.nom = 'Action'
    GROUP BY f.f_id, f.nom, f.directeur, f.date_de_sortie
    ORDER BY AVG(COALESCE(r.note, 0)) DESC
    LIMIT 1
)

SELECT mfap.f_id, mfap.nom, mfap.directeur, mfap.date_de_sortie, mfap.note_moyenne
FROM MeilleurFilmActionParUtilisateursPref mfap;
