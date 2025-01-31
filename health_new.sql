-- Identified that there are 55500 Rows and 15 Columns.
SELECT 
    (SELECT COUNT(*) FROM health_data1) AS row_count,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = 'healthcare_data' AND TABLE_NAME = 'health_data1') AS column_count
     ;
---------------------------------------------------------------------------------------------
-- Created several tables to secure the original data on the data set.
CREATE TABLE health_data5
LIKE health_data4
;

INSERT health_data5
SELECT *
FROM health_data4
;

SELECT *
FROM health_data5
;
---------------------------------------------------------------------------------------------
-- DATA CLEANING PROCESS --
-- STANDARDIZING THE NAMES USING SUBSTRINGS (Can also update the names using this query)
UPDATE health_data3
	SET `Name` =CONCAT(
	UPPER(SUBSTRING(`Name`, 1, 1)),
	LOWER(SUBSTRING(SUBSTRING_INDEX(`Name`, ' ', 1), 2)),
    ' ',
    UPPER(SUBSTRING(SUBSTRING_INDEX(`Name`, ' ', -1), 1, 1)),
    LOWER(SUBSTRING(SUBSTRING_INDEX(`Name`, ' ', -1), 2))
	)
WHERE `Name` IS NOT NULL
;
---------------------------------------------------------------------------------------------
-- Updated the name into a proper format Hospital names.
UPDATE health_data2
SET Hospital = CONCAT(
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Hospital, ' and', 1), ' ', -1)), -- Extract "Rich"
    ' and Sons' -- Append "and Sons"
)
WHERE Hospital LIKE 'Sons % and';

UPDATE health_data3
SET Hospital = CONCAT(
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Hospital, ' and', 1), ' ', 1)),
    ' and Sons' -- Append "and Sons"
)
WHERE Hospital LIKE '% Sons and';

-- Removed dash line extra "and" and extra spaces using this query.
UPDATE health_data3
SET Hospital = TRIM(REPLACE(Hospital, ' and', ''))
WHERE Hospital LIKE '% and';
---------------------------------------------------------------------------------------------
-- Updating the patient's gender. 
SELECT DISTINCT `Name`, Gender
FROM health_data4
WHERE `Name` LIKE 'A%'
GROUP BY `Name`, Gender
ORDER BY `Name`
;

UPDATE health_data4
SET Gender = 'Male'
WHERE `Name` LIKE 'Zach%'
AND Gender = 'Female'
;

UPDATE health_data3
SET Gender = 'Female'
WHERE `Name` LIKE 'Zoe%'
AND Gender = 'Male'
;
---------------------------------------------------------------------------------------------
-- Rounded the Billing Amount to lessen the decimal point
-- and Change the data type of Date of Admission and Discharge Date to DATE.
UPDATE health_data4
SET `Billing Amount` = ROUND(`Billing Amount`, 2)
WHERE `Billing Amount` IS NOT NULL
;
ALTER TABLE health_data4
MODIFY COLUMN `Date of Admission` DATE
;
ALTER TABLE health_data4
MODIFY COLUMN `Discharge Date` DATE
;
---------------------------------------------------------------------------------------------
-- Identified that there are duplicate data in the data set using CTE.
WITH CTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY `Name`,
                `Date of Admission`,
                `Discharge Date`,
                `Billing Amount`,
                `Insurance Provider`
        ) AS Duplicates
    FROM health_data5
)
SELECT * 
FROM CTE 
WHERE Duplicates > 1;

-- Removing or Deleting duplicates in the data set using CTE.
WITH CTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY `Name`,
                `Date of Admission`,
                `Discharge Date`,
                `Billing Amount`,
                `Insurance Provider`
        ) AS Duplicates
    FROM health_data5
)
DELETE
FROM health_data5
WHERE (`Name`, `Date of Admission`, `Discharge Date`, `Billing Amount`, `Insurance Provider`) IN (
    SELECT `Name`, `Date of Admission`, `Discharge Date`, `Billing Amount`, `Insurance Provider`
    FROM CTE 
    WHERE Duplicates > 1)
;

SELECT *
FROM health_data5
;
---------------------------------------------------------------------------------------------
-- Categorizing the Case Level of the patients based on the days they were admitted using CASE STATEMENT.
SELECT `Name`,
       DATEDIFF(`Discharge Date`, `Date of Admission`) AS `Admission Days`,
       CASE
           WHEN DATEDIFF(`Discharge Date`, `Date of Admission`) <= 10 THEN 'Primary Care'
           WHEN DATEDIFF(`Discharge Date`, `Date of Admission`) <= 20 THEN 'Secondary Care'
           ELSE 'Tertiary Care'
       END AS `Case Level`
FROM health_data5
;
---------------------------------------------------------------------------------------------
-- Questions
-- What is the total number of patients admitted?
SELECT COUNT(*) AS Total_Admitted
FROM health_data5
;
-- What is the average billing amount?
SELECT ROUND(AVG(`Billing Amount`), 2) AS Average_Bill
FROM health_data5
;
-- How many patients are admitted by each Doctor?
SELECT DISTINCT Doctor, COUNT(*) AS Patient_Count
FROM health_data5
GROUP BY Doctor
ORDER BY Patient_Count DESC
LIMIT 10
;
-- What is the Gender distribution of admitted patients?
SELECT Gender, COUNT(*) Gender_Count
FROM health_data5
GROUP BY Gender
;
-- What is the total number of admission per day?
SELECT `Date of Admission`, COUNT(*) AS Daily_Admission
FROM health_data5
GROUP BY `Date of Admission`
ORDER BY `Date of Admission`
;
-- How many patients have been discharged?
SELECT `Discharge Date`, COUNT(*) AS Discharge_Count
FROM health_data5
GROUP BY `Discharge Date`
ORDER BY `Discharge Date`
;
-- What is the average duration of hospital stays (from admission to discharge)?
SELECT AVG(DATEDIFF(`Discharge Date`, `Date of Admission`)) AS Hospital_Stay
FROM health_data5
WHERE `Discharge Date` IS NOT NULL
;
-- Which hospital has the highest total billing amount?
SELECT Hospital, ROUND(SUM(`Billing Amount`)) AS Highest_Bill
FROM health_data5
GROUP BY Hospital
ORDER BY Highest_Bill DESC
LIMIT 1
;
-- What is the total billing amount for each insurance provider?
SELECT `Insurance Provider`, ROUND(AVG(`Billing Amount`)) AS Total_Bill
FROM health_data5
GROUP BY `Insurance Provider`
ORDER BY Total_Bill DESC
;
-- What is the highest billing amount, and which patient incurred it?
SELECT `Name`, ROUND(SUM(`Billing Amount`)) AS Highest_Patient_Bill
FROM health_data5
GROUP BY `Name`
ORDER BY Highest_Patient_Bill DESC
LIMIT 5
;
--  Which blood type is the most common among admitted patients?
SELECT `Blood Type`, COUNT(*) AS Blood_Type_Count
FROM health_data5
GROUP BY `Blood Type`
ORDER BY Blood_Type_Count DESC
LIMIT 8
;
-- What are the most common medical conditions among admitted patients?
SELECT `Medical Condition`, COUNT(*) AS Common_Condition
FROM health_data5
GROUP BY `Medical Condition`
ORDER BY Common_Condition DESC
;
-- What is the distribution of admission types?
SELECT `Admission Type`, COUNT(*) AS Admission_Count
FROM health_data5
GROUP BY `Admission Type`
;
-- Which room numbers have been used the most?
SELECT `Room Number`, COUNT(*) Room_Usage
FROM health_data5
GROUP BY `Room Number`
ORDER BY Room_Usage DESC
;
-- Which doctor has handled the most discharges?
SELECT Doctor, COUNT(*) AS Discharge_Count
FROM health_data5
WHERE `Discharge Date` IS NOT NULL
GROUP BY Doctor
ORDER BY Discharge_Count DESC
LIMIT 10
;
-- What medications are prescribed most frequently?
SELECT `Medication`, COUNT(*) AS Most_Prescribed
FROM health_data5
GROUP BY `Medication`
ORDER BY Most_Prescribed
;
-- Which test results are the most common?
SELECT `Test Results`, COUNT(*) AS Common_Result
FROM health_data5
GROUP BY `Test Results`
ORDER BY Common_Result DESC
;
---------------------------------------------------------------------------------------------
SELECT *
FROM health_data5
;
