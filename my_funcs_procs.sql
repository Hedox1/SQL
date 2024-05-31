--1. Créer la fonction GET_NB_WORKERS(FACTORY NUMBER) RETURN
FUNCTION GET_NB_WORKERS( 
    FACTOR NUMBER 
) 
RETURN NUMBER 
IS 
    NUM_WORKERS NUMBER; 
BEGIN 
    SELECT COUNT(*) INTO NUM_WORKERS 
    FROM ( 
        SELECT 1  
        FROM WORKERS_FACTORY_1  
        WHERE last_day IS NULL AND FACTOR = 1 
        AND EXISTS ( 
            SELECT 1 
            FROM FACTORIES 
            WHERE id = 1 
        ) 
        UNION ALL 
        SELECT 1  
        FROM WORKERS_FACTORY_2  
        WHERE end_date IS NULL AND FACTOR = 2 
        AND EXISTS ( 
            SELECT 1 
            FROM FACTORIES 
            WHERE id = 2 
        ) 
    ); 
     
    RETURN NUM_WORKERS; 
EXCEPTION 
    WHEN NO_DATA_FOUND THEN 
        RETURN 0; 
END GET_NB_WORKERS;/
 
 --Créer la fonction GET_NB_BIG_ROBOTS RETURN NUMBER
CREATE OR REPLACE FUNCTION GET_NB_BIG_ROBOTS RETURN NUMBER IS
    NUM_BIG_ROBOTS NUMBER;
BEGIN
    -- Compter le nombre de robots ayant plus de 3 pièces détachées
    SELECT COUNT(*)
    INTO NUM_BIG_ROBOTS
    FROM (
        SELECT robot_id
        FROM ROBOTS_HAS_SPARE_PARTS
        GROUP BY robot_id
        HAVING COUNT(spare_part_id) > 3
    );

    RETURN NUM_BIG_ROBOTS;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'An error occurred: ' || SQLERRM);
END GET_NB_BIG_ROBOTS;
/

--Créer la fonction GET_BEST_SUPPLIER RETURN VARCHAR2(100)

CREATE OR REPLACE FUNCTION GET_BEST_SUPPLIER
RETURN VARCHAR2
IS
    best_supplier_name VARCHAR2(100);
BEGIN
   
    SELECT supplier_name
    INTO best_supplier_name
    FROM BEST_SUPPLIERS
    WHERE ROWNUM = 1; 

    RETURN best_supplier_name;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'No Supplier Found';
    WHEN OTHERS THEN
        RETURN 'Error Occurred';
END GET_BEST_SUPPLIER;
/

 
 --Créer la fonction GET_OLDEST_WORKER RETURN NUMBER

CREATE OR REPLACE FUNCTION GET_OLDEST_WORKER
RETURN NUMBER
IS
    oldest_worker_id NUMBER;
BEGIN
    
    SELECT worker_id
    INTO oldest_worker_id
    FROM WORKERS_VIEW
    ORDER BY start_date ASC
    FETCH FIRST ROW ONLY; 

    RETURN oldest_worker_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL; 
    WHEN OTHERS THEN
        RETURN NULL; 
END GET_OLDEST_WORKER;
/


 -- Procédures
    -- Question 1 : SEED_DATA_WORKERS
CREATE OR REPLACE PROCEDURE SEED_DATA_WORKERS(
    NB_WORKERS NUMBER,
    FACTORY_ID NUMBER
) AS
    v_first_name VARCHAR2(100);
    v_last_name VARCHAR2(100);
    v_start_date DATE;
    v_end_date DATE;
BEGIN
    FOR i IN 1..NB_WORKERS LOOP
        v_first_name := 'worker_f_' || i;
        v_last_name := 'worker_l_' || i;
        v_start_date := TO_DATE('01-JAN-2065', 'DD-MON-YYYY') + DBMS_RANDOM.VALUE(0, 1826); -- 1826 days is approximately 5 years
        
        IF FACTORY_ID = 1 THEN
            INSERT INTO WORKERS_FACTORY_1 (first_name, last_name, age, first_day, last_day)
            VALUES (v_first_name, v_last_name, ROUND(DBMS_RANDOM.VALUE(20, 60)), v_start_date, NULL);
        ELSIF FACTORY_ID = 2 THEN
            INSERT INTO WORKERS_FACTORY_2 (first_name, last_name, start_date, end_date)
            VALUES (v_first_name, v_last_name, v_start_date, NULL);
        ELSE
            RAISE_APPLICATION_ERROR(-20001, 'Invalid FACTORY_ID. Must be 1 or 2.');
        END IF;
    END LOOP;
END;
/

    -- Question 2 : ADD_NEW_ROBOT
CREATE OR REPLACE PROCEDURE ADD_NEW_ROBOT(MODEL_NAME VARCHAR2) AS
    v_robot_id NUMBER;
    v_factory_id NUMBER;
BEGIN
    -- Étape 1: Insérer le nouveau robot dans la table ROBOTS et obtenir l'ID généré
    INSERT INTO ROBOTS (model)
    VALUES (MODEL_NAME)
    RETURNING id INTO v_robot_id;

    -- Étape 2: Sélectionner l'usine avec le moins de robots
    BEGIN
        SELECT factory_id
        INTO v_factory_id
        FROM (
            SELECT factory_id, COUNT(*) AS num_robots
            FROM ROBOTS_FROM_FACTORY
            GROUP BY factory_id
            ORDER BY num_robots ASC
        )
        WHERE ROWNUM = 1;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Si aucune usine n'est trouvée (cas rare), affecter une usine par défaut (par exemple, 1)
            v_factory_id := 1;
    END;

    -- Étape 3: Insérer l'ID du robot et l'ID de l'usine dans la table ROBOTS_FROM_FACTORY
    INSERT INTO ROBOTS_FROM_FACTORY (robot_id, factory_id)
    VALUES (v_robot_id, v_factory_id);

    -- Étape 4: Afficher un message de confirmation
    DBMS_OUTPUT.PUT_LINE('New robot with model ' || MODEL_NAME || ' added with ID ' || v_robot_id || ' to factory ' || v_factory_id);

EXCEPTION
    WHEN OTHERS THEN
        -- Gestion des erreurs générales
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
        ROLLBACK;
END;
/

    -- Question 3 : SEED_DATA_SPARE_PARTS
CREATE OR REPLACE PROCEDURE SEED_DATA_SPARE_PARTS(NB_SPARE_PARTS NUMBER) AS
    v_color VARCHAR2(10);
    v_name VARCHAR2(100);
    v_colors SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('red', 'gray', 'black', 'blue', 'silver');
BEGIN
    FOR i IN 1..NB_SPARE_PARTS LOOP
        -- Sélection d'une couleur aléatoire parmi les options disponibles
        v_color := v_colors(TRUNC(DBMS_RANDOM.VALUE(1, 6)));
        -- Génération du nom de la pièce détachée
        v_name := 'SparePart_' || i;
        -- Insertion de la pièce détachée dans la table SPARE_PARTS
        INSERT INTO SPARE_PARTS (color, name) VALUES (v_color, v_name);
    END LOOP;

    -- Message de confirmation
    DBMS_OUTPUT.PUT_LINE(NB_SPARE_PARTS || ' spare parts inserted.');
END;
/
-- Triggers
    --Question 1 : ALL_WORKERS_ELAPSED
