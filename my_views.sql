-- Question 1

CREATE OR REPLACE VIEW ALL_WORKERS AS                                               
SELECT                                                                              
    last_name,
    first_name,
    age,
    first_day AS start_date                                                         
FROM 
    WORKERS_FACTORY_1

WHERE                                                                               
    last_day IS NULL

UNION ALL

SELECT 
    last_name,
    first_name,
    NULL AS age,                                                                    
    start_date
FROM 
    WORKERS_FACTORY_2
WHERE
    end_date IS NULL                                                                

ORDER BY
    start_date DESC;


-- Question 2
CREATE OR REPLACE VIEW ALL_WORKERS_ELAPSED AS
SELECT 
    last_name,
    first_name,
    age,
    start_date,
	TRUNC(SYSDATE - start_date) AS day_elapsed
FROM
	ALL_WORKERS;

--Question 3

CREATE OR REPLACE VIEW BEST_SUPPLIERS AS
SELECT 
    s.supplier_id,
    s.name AS supplier_name,
    SUM(quantity) AS total_pieces_delivered
FROM 
    SUPPLIERS_BRING_TO_FACTORY_1 sf1
JOIN 
    SUPPLIERS s ON sf1.supplier_id = s.supplier_id
GROUP BY 
    s.supplier_id, s.name
HAVING 
    SUM(quantity) > 1000
UNION ALL
SELECT 
    s.supplier_id,
    s.name AS supplier_name,
    SUM(quantity) AS total_pieces_delivered
FROM 
    SUPPLIERS_BRING_TO_FACTORY_2 sf2
JOIN 
    SUPPLIERS s ON sf2.supplier_id = s.supplier_id
GROUP BY 
    s.supplier_id, s.name
HAVING 
    SUM(quantity) > 1000
ORDER BY 
    total_pieces_delivered DESC;

-- Question 4
CREATE VIEW ROBOTS_FACTORIES AS
SELECT r.id AS robot_id, r.model, f.main_location AS factory_location
FROM ROBOTS_FROM_FACTORY rf
JOIN ROBOTS r ON rf.robot_id = r.id
JOIN FACTORIES f ON rf.factory_id = f.id;

