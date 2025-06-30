-- Healthcare Data Set, Data Cleaning
    -- Data Cleaning Best Practices
		-- 1. Backup first
        -- 2. Work in Transactions
        -- 3. Standardize Data Formats
        -- 4. Handle NULLs Consistently
        -- 5. Remove Duplicates
        -- 6. Validate Data Quality
        
-- 1. Backup Raw Data First
CREATE TABLE healthcare_dataset2 AS SELECT * FROM healthcare_dataset;

-- 2. Standarize Data Formats
-- a. Properly capitalize & format names in "Name" field
-- Initial check of data
			SELECT name FROM healthcare_dataset;
-- Preview data change
			SELECT 
				Name AS original_name,
					(SELECT GROUP_CONCAT(
					CONCAT(UPPER(SUBSTRING(part, 1, 1)), LOWER(SUBSTRING(part, 2)) ) SEPARATOR ' ')
					FROM (
					SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(Name, ' ', numbers.n), ' ', -1) AS part
					FROM (
						SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
						) numbers
					WHERE numbers.n <= LENGTH(Name) - LENGTH(REPLACE(Name, ' ', '')) + 1
						) parts
						) AS proposed_name
						FROM healthcare_dataset
					WHERE Name REGEXP '[a-z]';
-- Commit to Update
UPDATE healthcare_dataset
SET name =  (SELECT GROUP_CONCAT(
					CONCAT(UPPER(SUBSTRING(part, 1, 1)), LOWER(SUBSTRING(part, 2)) ) SEPARATOR ' ')
					FROM (
					SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(Name, ' ', numbers.n), ' ', -1) AS part
					FROM (
						SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
						) numbers
					WHERE numbers.n <= LENGTH(Name) - LENGTH(REPLACE(Name, ' ', '')) + 1
						) parts)
					WHERE Name REGEXP '[a-z]';
-- Check that update applied 					
select name from healthcare_dataset;

-- Remove "Dr.", "Mr.", "Mrs." "Dds", "dvm"
UPDATE healthcare_dataset
SET name = TRIM(
    REGEXP_REPLACE(name, '^(Mr\\.|Mrs\\.|Dr\\.|Ms\\.|Prof\\.)\\s*', '')
);

-- Check that update applied
select name from healthcare_dataset; 

-- Removing Suffix at end of names
UPDATE healthcare_dataset
SET name = TRIM(
    REGEXP_REPLACE(name, '[,.]?\\s*(DDS|PhD|MD|Jr|Sr|III|IV|Esq)\\.?$', '')
)
WHERE name REGEXP '[,.]?\\s*(DDS|PhD|MD|Jr|Sr|III|IV|Esq)\\.?$';

-- Check that update applied
select name from healthcare_dataset; 

-- b.  Remove Suffix at end of "Doctor" field
UPDATE healthcare_dataset
SET doctor = TRIM(
    REGEXP_REPLACE(doctor, '[,.]?\\s*(DDS|PhD|MD|Jr|Sr|III|IV|Esq)\\.?$', '')
)
WHERE doctor REGEXP '[,.]?\\s*(DDS|PhD|MD|Jr|Sr|III|IV|Esq)\\.?$';

-- Check that update applied
select doctor from healthcare_dataset;

-- c. Remove unecessary commas, unecessary 'ands' names in "Hospital"

-- identifying 'ands' at beginning of values
select hospital from healthcare_dataset
where hospital like 'and %';

-- preview changes
SELECT 
    hospital AS original_name,
    TRIM(SUBSTRING(hospital, 4)) AS corrected_name
FROM healthcare_dataset
WHERE LOWER(TRIM(hospital)) LIKE 'and %';
-- commit changes
update healthcare_dataset
set hospital = TRIM(SUBSTRING(hospital, 4))
WHERE LOWER(TRIM(hospital)) LIKE 'and %';


-- standarizing names of hospitals with "and sons" 
select hospital from healthcare_dataset
where hospital like '% and%';
-- preview changes
SELECT 
    hospital AS original_name,
    CONCAT(
        TRIM(REGEXP_REPLACE(hospital, '^sons[[:space:]]+', '')), 
        ' sons'
    ) AS modified_name
FROM healthcare_dataset
WHERE hospital REGEXP '^sons[[:space:]]';

UPDATE healthcare_dataset
SET hospital = 
    CONCAT(
        TRIM(REGEXP_REPLACE(hospital, '^sons[[:space:]]+', '')), 
        ' sons'
    )
WHERE hospital REGEXP '^sons[[:space:]]';

UPDATE healthcare_dataset
SET hospital = 
    TRIM(
        REGEXP_REPLACE(
            hospital, 
            '(?<!and\\s)\\bsons\\b', 
            'and sons', 
            1, 0, 'i'
        )
    )
WHERE hospital REGEXP '\\bsons\\b' 
AND hospital NOT REGEXP '\\band\\s+sons\\b';

-- Removing 'and' from 'and sons' so that it can be added later
-- Preview
SELECT 
    hospital AS original_name,
    TRIM(
        REGEXP_REPLACE(
            REGEXP_REPLACE(hospital, '\\band\\b', ' ', 1, 0, 'i'),
            '\\s+',
            ' '
        )
    ) AS modified_name
FROM healthcare_dataset
WHERE hospital REGEXP '\\bsons\\b' AND hospital REGEXP '\\band\\b';
-- commit change
UPDATE healthcare_dataset
SET hospital = 
    CASE 
        WHEN hospital REGEXP '\\bsons\\b' THEN 
            TRIM(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(hospital, '\\band\\b', ' ', 1, 0, 'i'),
                    '\\s+',
                    ' '
                )
            )
        ELSE hospital
    END
WHERE hospital REGEXP '\\bsons\\b' AND hospital REGEXP '\\band\\b';

-- removing ', and' comma instances in names of hospitals
-- preview
SELECT 
    hospital AS original_name,
    REGEXP_REPLACE(
        hospital,
        ',\\s+and\\b',
        ' and',
        1, 0, 'i'
    ) AS modified_name
FROM healthcare_dataset
WHERE hospital REGEXP ',\\s+and\\b';

-- commit

UPDATE healthcare_dataset
SET hospital = 
    TRIM(
        REGEXP_REPLACE(
            hospital,
            ',\\s*and\\b',
            ' and',
            1, 0, 'i'
        )
    )
WHERE hospital REGEXP ',\\s*and\\b';

-- changing instances where values of 'name, name and' are changed to 'name and name'
-- preview
SELECT 
    hospital AS original,
    CONCAT(
        TRIM(SUBSTRING_INDEX(hospital, ',', 1)),
        ' and ',
        TRIM(REGEXP_REPLACE(
            SUBSTRING_INDEX(hospital, ',', -1),
            '\\s+and$',
            ''
        ))
    ) AS corrected
FROM healthcare_dataset
WHERE hospital REGEXP ',.*\\s+and$';
-- commit
UPDATE healthcare_dataset
SET hospital = 
    REPLACE(
        CONCAT(
            SUBSTRING_INDEX(hospital, ',', 1),
            ' and',
            SUBSTRING_INDEX(
                SUBSTRING_INDEX(hospital, ',', -1),
                ' and',
                1
            )
        ),
        '  ', ' '  -- Replace double spaces if created
    )
WHERE hospital LIKE '%,% and%';

-- Change every instance of 'inc' or 'llc' at the start of values and put them at the end.
-- preview
SELECT 
    hospital AS original_name,
    CASE
        WHEN LOWER(TRIM(hospital)) LIKE 'inc %' THEN 
            CONCAT(TRIM(SUBSTRING(hospital, 4)), ' INC')
        WHEN LOWER(TRIM(hospital)) LIKE 'llc %' THEN 
            CONCAT(TRIM(SUBSTRING(hospital, 4)), ' LLC')
        ELSE hospital
    END AS modified_name
FROM healthcare_dataset
WHERE LOWER(TRIM(hospital)) LIKE 'inc %' OR LOWER(TRIM(hospital)) LIKE 'llc %';

-- commit 
UPDATE healthcare_dataset
SET hospital = 
    CASE
        WHEN hospital REGEXP '^(inc|llc)[[:space:]]' THEN
            CONCAT(
                TRIM(REGEXP_REPLACE(hospital, '^(inc|llc)[[:space:]]+', '', 1, 0, 'i')),
                ' ',
                UPPER(REGEXP_SUBSTR(hospital, '^(inc|llc)', 1, 1, 'i'))
            )
        ELSE hospital
    END
WHERE hospital REGEXP '^(inc|llc)[[:space:]]';

-- Changing more names 

UPDATE healthcare_dataset
SET hospital = 
    REGEXP_REPLACE(
        hospital,
        '^(.*)\\s(\\w+)\\s+and$',
        '$1 and $2',
        1, 0, 'i'
    )
WHERE hospital REGEXP '^.*\\s\\w+\\s+and$';

-- Move all instances of 'ltd' and 'group' from the beginning to end of values

SELECT 
    hospital AS original_name,
    CASE
        WHEN LOWER(TRIM(hospital)) LIKE 'ltd %' THEN 
            CONCAT(TRIM(SUBSTRING(hospital, 4)), ' LTD')
        WHEN LOWER(TRIM(hospital)) LIKE 'group %' THEN 
            CONCAT(TRIM(SUBSTRING(hospital, 6)), ' GROUP')
        ELSE hospital
    END AS modified_name
FROM healthcare_dataset
WHERE LOWER(TRIM(hospital)) LIKE 'ltd %' OR LOWER(TRIM(hospital)) LIKE 'group %';


-- Changing positioning of commas
UPDATE healthcare_dataset
SET hospital = 
    CASE
        WHEN LOWER(hospital) REGEXP '^ltd[[:space:]]' THEN
            CONCAT(
                TRIM(REGEXP_REPLACE(hospital, '^ltd[[:space:]]+', '', 1, 0, 'i')),
                ' LTD'
            )
        WHEN LOWER(hospital) REGEXP '^group[[:space:]]' THEN
            CONCAT(
                TRIM(REGEXP_REPLACE(hospital, '^group[[:space:]]+', '', 1, 0, 'i')),
                ' Group'
            )
        ELSE hospital
    END
WHERE LOWER(hospital) REGEXP '^(ltd|group)[[:space:]]';

-- Remove all commas at the end of values
-- preview
SELECT 
    hospital AS original,
    REGEXP_REPLACE(hospital, ',\\s*$', '') AS cleaned
FROM healthcare_dataset
WHERE hospital REGEXP ',\\s*$';
-- Commit 
UPDATE healthcare_dataset
SET hospital = REGEXP_REPLACE(hospital, ',\\s*$', '')
WHERE hospital REGEXP ',\\s*$';

select hospital from healthcare_dataset;

-- standarizing names of hospitals with "group" by moving group from beginning to end
UPDATE healthcare_dataset
SET hospital = 
    CASE 
        WHEN LOWER(TRIM(hospital)) LIKE 'group %' 
        THEN CONCAT(
                TRIM(SUBSTRING(hospital, 5)),  -- Remove 'sons ' from start (5 chars)
                ' group'                        -- Add 'group' to end
             )
        ELSE hospital 
    END
WHERE LOWER(TRIM(hospital)) LIKE 'group %';

-- capitalize all instances of "llc", "LTD", and "INC"
UPDATE healthcare_dataset
SET hospital = 
    CASE
        WHEN hospital REGEXP '\\bltd\\b|\\bllc\\b' THEN
            REGEXP_REPLACE(
                REGEXP_REPLACE(hospital, '\\bltd\\b', 'LTD', 1, 0, 'i'),
                '\\bllc\\b', 
                'LLC', 
                1, 0, 'i'
            )
        ELSE hospital
    END
WHERE hospital REGEXP '\\bltd\\b|\\bllc\\b';

UPDATE healthcare_dataset
SET hospital = 
    CASE
        WHEN hospital REGEXP '\\binc\\b' THEN
            REGEXP_REPLACE(hospital, '\\binc\\b', 'INC', 1, 0, 'i')
        ELSE hospital
    END
WHERE hospital REGEXP '\\binc\\b';

-- Change names like 'Jackson and Lane, Dillon' to 'Dillon, Jackson, and Lane"

UPDATE healthcare_dataset
SET hospital = 
    REGEXP_REPLACE(
        hospital,
        '^([A-Za-z]+) and ([A-Za-z]+), ([A-Za-z]+)$',
        '$3, $1, and $2',
        1, 0, 'i'
    )
WHERE hospital REGEXP '^[A-Za-z]+ and [A-Za-z]+, [A-Za-z]+$';

-- Change names like 'Howell Brooks, Rogers' to 'Rogers, Howell, and Brooks'

UPDATE healthcare_dataset
SET hospital = 
    REGEXP_REPLACE(
        hospital,
        '^([A-Za-z]+) ([A-Za-z]+), ([A-Za-z]+)$',
        '$3, $1, and $2',
        1, 0, 'i'
    )
WHERE hospital REGEXP '^[A-Za-z]+ [A-Za-z]+, [A-Za-z]+$';

-- Change names like 'Decker Glover and Christensen' to 'Decker, Glover, and Christensen'

UPDATE healthcare_dataset
SET hospital = 
    CONCAT(
        SUBSTRING_INDEX(hospital, ' and ', 1),  -- Get part before "and"
        ', and ',
        SUBSTRING_INDEX(hospital, ' and ', -1)   -- Get part after "and"
    )
WHERE hospital LIKE '% and %'
AND hospital NOT LIKE '%,%';  -- Only affect names without existing commas;

UPDATE healthcare_dataset
SET hospital = 
    REPLACE(
        REPLACE(hospital, ', and sons', ' and sons'),
        ',  and sons', ' and sons'
    )
WHERE hospital LIKE '%,% and sons%';

-- Change names like 'Pierce Ward, and Torres' to 'Pierce, Ward, and Torres'
-- Preview 
SELECT 
    hospital AS original_name,
    REGEXP_REPLACE(
        hospital,
        '^([A-Za-z]+) ([A-Za-z]+), and ([A-Za-z]+)$',
        '$1, $2, and $3',
        1, 0, 'i'
    ) AS formatted_name
FROM healthcare_dataset
WHERE hospital REGEXP '^[A-Za-z]+ [A-Za-z]+, and [A-Za-z]+$';

-- Commit

UPDATE healthcare_dataset
SET hospital = 
    REGEXP_REPLACE(
        hospital,
        '^([A-Za-z]+) ([A-Za-z]+), and ([A-Za-z]+)$',
        '$1, $2, and $3',
        1, 0, 'i'
    )
WHERE hospital REGEXP '^[A-Za-z]+ [A-Za-z]+, and [A-Za-z]+$';

-- Change names like 'Brown, and Jones Weaver' to 'Brown, Jones, and Weaver' but not names like 'and sons'

-- Preview 
SELECT 
    hospital AS original_name,
    REGEXP_REPLACE(
        hospital,
        '^([A-Za-z]+), and ([A-Za-z]+) ([A-Za-z]+)$',
        '$1, $2, and $3',
        1, 0, 'i'
    ) AS formatted_name
FROM healthcare_dataset
WHERE hospital REGEXP '^[A-Za-z]+, and [A-Za-z]+ [A-Za-z]+$'
AND hospital NOT LIKE '%and sons%';
-- Commit
UPDATE healthcare_dataset
SET hospital = 
    CONCAT(
        SUBSTRING_INDEX(hospital, ',', 1),  -- First name (before comma)
        ', ',
        SUBSTRING_INDEX(
            SUBSTRING_INDEX(hospital, ' ', 2),  -- Gets "and Jones" part
            ' ', 
            -1
        ),  -- Middle name (Jones)
        ', and ',
        SUBSTRING_INDEX(hospital, ' ', -1)  -- Last name (Weaver)
    )
WHERE hospital LIKE '%, and % %'
AND hospital NOT LIKE '%and sons%'
AND LENGTH(hospital) - LENGTH(REPLACE(hospital, ' ', '')) = 3;

-- Specifically change the name ''Parsons, and, and Martinez' to 'Parsons and Martinez"

UPDATE healthcare_dataset
SET hospital = 
    REGEXP_REPLACE(
        hospital,
        '^([A-Za-z]+), and, and ([A-Za-z]+)$',
        '$1 and $2',
        1, 0, 'i'
    )
WHERE hospital REGEXP '^[A-Za-z]+, and, and [A-Za-z]+$';

-- Remove commas from names like 'May, and Mullins' and change them to 'May and Mullins' but leave out names with two commas in them.

UPDATE healthcare_dataset
SET hospital = 
    REGEXP_REPLACE(
        hospital,
        '^([A-Za-z]+), and ([A-Za-z]+)$',
        '$1 and $2',
        1, 0, 'i'
    )
WHERE hospital REGEXP '^[A-Za-z]+, and [A-Za-z]+$'
AND (LENGTH(hospital) - LENGTH(REPLACE(hospital, ',', ''))) = 1;  -- Only single comma

-- Checking for any other naming issues
select hospital from healthcare_dataset;

-- 2. Identify & Remove Duplicates
SELECT Name, Age, Gender, Blood_Type, Medical_Condition, Date_of_Admission, Doctor, Hospital, Insurance_Provider, Billing_Amount, Room_Number, Admission_Type, Discharge_Date, Medication, Test_Results, COUNT(*) as duplicate_count
FROM healthcare_dataset
GROUP BY Name, Age, Gender, Blood_Type, Medical_Condition, Date_of_Admission, Doctor, Hospital, Insurance_Provider, Billing_Amount, Room_Number, Admission_Type, Discharge_Date, Medication, Test_Results
HAVING COUNT(*) > 1;

-- Create a temporary table with distinct rows
CREATE TABLE healthcare_dataset_temp AS 
SELECT DISTINCT * FROM healthcare_dataset;

-- Empty the original table
TRUNCATE TABLE healthcare_dataset;

-- Copy data back from temp table
INSERT INTO healthcare_dataset SELECT * FROM healthcare_dataset_temp;

-- Clean up
DROP TABLE healthcare_dataset_temp;

-- 3. Identify & Remove Nulls
SELECT *
FROM healthcare_dataset
WHERE 
    Name IS NULL OR
    Age IS NULL OR
    Gender IS NULL OR
    Blood_Type IS NULL OR
    Medical_Condition IS NULL OR
    Date_of_Admission IS NULL OR
    Doctor IS NULL OR
    Hospital IS NULL OR
    Insurance_Provider IS NULL OR
    Billing_Amount IS NULL OR
    Room_Number IS NULL OR
    Admission_Type IS NULL OR
    Discharge_Date IS NULL OR
    Medication IS NULL OR
    Test_Results IS NULL;
    
    -- No nulls exist in dataset
    
    -- Final Check
    
    select * from healthcare_dataset