
1. 

CREATE TRIGGER InterceptInsert
INSTEAD OF INSERT
ON ALL_WORKERS_ELAPSED
FOR EACH ROW
AS
BEGIN
    -- Insérer dans la bonne table
    INSERT INTO YourCorrectTable (worker_id, ...) -- Remplacez "YourCorrectTable" par le nom de la table correcte
    VALUES (NEW.worker_id, ...); -- Remplacez "worker_id" et "..." par les colonnes appropriées
END;
GO

-- Création du déclencheur pour lever des erreurs lors des opérations de mise à jour
CREATE TRIGGER UpdateError
ON ALL_WORKERS_ELAPSED
INSTEAD OF UPDATE
AS
BEGIN
    -- Lever une erreur
    RAISEERROR('Modification interdite', 16, 1);
END;
GO

-- Création du déclencheur pour lever des erreurs lors des opérations de suppression
CREATE TRIGGER DeleteError
ON ALL_WORKERS_ELAPSED
INSTEAD OF DELETE
AS
BEGIN
    -- Lever une erreur
    RAISEERROR('Suppression interdite', 16, 1);
END;
GO

-------------------------------------------------------

2. 

CREATE TRIGGER RecordRobotCreation
AFTER INSERT
ON VotreTableDeRobots -- Remplacez "VotreTableDeRobots" par le nom de votre table de robots
FOR EACH ROW
BEGIN
    INSERT INTO AUDIT_ROBOT (robot_id, date_added)
    VALUES (NEW.robot_id, GETDATE()); -- Utilisation de GETDATE() pour obtenir la date actuelle
END;

-----------------------------------------------------------

3. 

CREATE TRIGGER CheckFactoryCount
INSTEAD OF UPDATE
ON ROBOTS_FACTORIES
AS
BEGIN
    DECLARE @FactoryCount INT;
    DECLARE @WorkerFactoryCount INT;

    -- Compter le nombre d'usines dans la table FACTORIES
    SELECT @FactoryCount = COUNT(*) FROM FACTORIES;

    -- Compter le nombre de tables respectant le format WORKERS_FACTORY_<N>
    SELECT @WorkerFactoryCount = COUNT(*)
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME LIKE 'WORKERS_FACTORY_%';

    -- Vérifier si les compteurs sont égaux
    IF @FactoryCount = @WorkerFactoryCount
    BEGIN
        -- Autoriser la mise à jour des données dans la vue ROBOTS_FACTORIES
        UPDATE ROBOTS_FACTORIES SET ...; -- Mettez à jour les données comme requis
    END
    ELSE
    BEGIN
        -- Empêcher la mise à jour des données et lever une erreur
        RAISEERROR('Impossible de mettre à jour les données tant que les conditions ne sont pas remplies.', 16, 1);
    END
END;

--------------------------------------------------------------------

4. 

ALTER TABLE WORKERS
ADD COLUMN time_spent_in_factory INT; -- Adapter le type de données en fonction de vos besoins

-- Créer un déclencheur AFTER INSERT/UPDATE pour calculer la durée du temps passé dans l'usine
CREATE TRIGGER CalculateTimeSpent
AFTER INSERT, UPDATE
ON WORKERS
FOR EACH ROW
BEGIN
    -- Vérifier si la date de départ a été ajoutée
    IF NEW.departure_date IS NOT NULL THEN
        -- Calculer la durée du temps passé dans l'usine
        DECLARE time_spent INT;
        SET time_spent = DATEDIFF(NEW.departure_date, NEW.entry_date); -- Calcul de la différence en jours

        -- Mettre à jour la nouvelle colonne avec la durée calculée
        UPDATE WORKERS
        SET time_spent_in_factory = time_spent
        WHERE worker_id = NEW.worker_id;
    END IF;
END;