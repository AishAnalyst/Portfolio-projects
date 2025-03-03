USE healthcare;

SELECT *
FROM hospital_dataset;

-- Data Cleaning
-- Replicating data
CREATE TABLE hospital_dataset1
LIKE hospital_dataset;

INSERT hospital_dataset1
SELECT *
FROM hospital_dataset;

-- Removing duplicates

SELECT `Name`, `Age`, `Blood Type`, `Date of Admission`, COUNT(*)
FROM hospital_dataset1
GROUP BY `Name`, `Age`, `Blood Type`, `Date of Admission`
HAVING COUNT(*) >1
ORDER BY 1;

WITH duplicates AS(
	SELECT *, 
    ROW_NUMBER() OVER(PARTITION BY `Name`, `Age`, `Blood Type`, `Date of Admission`) AS row_num
    FROM hospital_dataset1)
SELECT *
FROM duplicates
WHERE row_num >1;

CREATE TABLE `hospital_dataset2` (
  `Name` text,
  `Age` int DEFAULT NULL,
  `Gender` text,
  `Blood Type` text,
  `Medical Condition` text,
  `Date of Admission` text,
  `Discharge Date` text,
  `Doctor` text,
  `Insurance Provider` text,
  `Billing Amount` text,
  `Room Number` int DEFAULT NULL,
  `Admission Type` text,
  `Medication` text,
  `Test Results` text,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO hospital_dataset2
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY `Name`, `Age`, `Blood Type`, `Date of Admission`) AS row_num
FROM hospital_dataset1;

DELETE
FROM hospital_dataset2
WHERE row_num>1;

-- Standardizing data
UPDATE hospital_dataset2
SET Gender= UPPER(Gender);

SELECT `Medical Condition`, 
CONCAT(UPPER(LEFT(`Medical Condition`, 1)), LOWER(SUBSTRING(`Medical Condition`, 2))) 
FROM hospital_dataset2;

UPDATE hospital_dataset2
SET `Medical Condition` = CONCAT(UPPER(LEFT(`Medical Condition`, 1)), LOWER(SUBSTRING(`Medical Condition`, 2)));

SELECT MIN(Age), MAX(Age)
FROM hospital_dataset2;

UPDATE hospital_dataset2
SET `Age` = 90
WHERE `Age` > 100;

SELECT `Age`,
	CASE
		WHEN `Age` < 30 THEN 'Young'
		WHEN `Age` BETWEEN 30 AND 60 THEN 'Middle-Aged'
		ELSE 'Old' END AS Age_group
FROM hospital_dataset2;

ALTER TABLE hospital_dataset2
ADD COLUMN Age_group VARCHAR(50);

UPDATE hospital_dataset2
SET Age_group= CASE
		WHEN `Age` < 30 THEN 'Young'
		WHEN `Age` BETWEEN 30 AND 60 THEN 'Middle-Aged'
		ELSE 'Old' END;

--  Filling missing values
SELECT DISTINCT `Discharge Date`
FROM hospital_dataset2;

UPDATE hospital_dataset2
SET `Discharge Date` = NULL
WHERE `Discharge Date` = "" ;

ALTER TABLE hospital_dataset2
MODIFY COLUMN `Date of Admission` DATE;

ALTER TABLE hospital_dataset2
MODIFY COLUMN `Discharge Date` DATE;

UPDATE hospital_dataset2
SET `Billing Amount` = NULL
WHERE `Billing Amount` = "";

UPDATE hospital_dataset2
SET `Billing Amount`= (
	SELECT avg_value FROM(
		SELECT ROUND(AVG(`Billing Amount`)) AS avg_value
		FROM hospital_dataset2
        WHERE `Billing Amount` IS NOT NULL
        ) AS temp
        )
WHERE `Billing Amount` IS NULL;

ALTER TABLE hospital_dataset2
MODIFY COLUMN `Billing Amount` DOUBLE;

UPDATE hospital_dataset2
SET `Billing Amount`= ROUND(`Billing Amount`, 2);

UPDATE hospital_dataset2
SET `Test Results`= 'Inconclusive'
WHERE `Test Results` = "";


-- Exploratory Data Analysis (EDA)

-- Patients Age and Gender distribution
SELECT Age_group, Gender, COUNT(*) AS Patient_head_count
FROM hospital_dataset2
GROUP BY Age_group, Gender
ORDER BY Patient_head_count DESC;

-- Most common Medical Conditions
SELECT `Medical Condition`, COUNT(*) AS condition_count
FROM hospital_dataset2
GROUP BY `Medical Condition`
ORDER BY condition_count DESC;

-- Average length of stay per condition
SELECT `Medical Condition`, 
		ROUND(AVG(DATEDIFF(`Discharge Date`, `Date of Admission`)), 0) AS Avg_stay
FROM hospital_dataset2
WHERE `Discharge Date` IS NOT NULL
GROUP BY `Medical Condition`
ORDER BY Avg_stay DESC;

-- Billing patterns by Medical Condition, Admission Type and Insurance Provider
SELECT `Medical Condition`, ROUND(SUM(`Billing Amount`), 2) AS Total_revenue
FROM hospital_dataset2
GROUP BY `Medical Condition`
ORDER BY Total_revenue DESC;

SELECT `Admission Type`, ROUND(AVG(`Billing Amount`),2) AS Avg_revenue
FROM hospital_dataset2
GROUP BY `Admission Type`
ORDER BY Avg_revenue DESC;

SELECT `Insurance Provider`, ROUND(SUM(`Billing Amount`), 2) AS Total_revenue
FROM hospital_dataset2
GROUP BY `Insurance Provider`
ORDER BY Total_revenue DESC;

-- Yearly Revenue trends
SELECT YEAR(`Date of Admission`) AS Admission_year, 
		ROUND(SUM(`Billing Amount`),2) AS Total_revenue
FROM hospital_dataset2
GROUP BY Admission_year
ORDER BY Total_revenue DESC;

-- Admission trends by month
SELECT DATE_FORMAT(`Date of Admission`, '%m') AS month, COUNT(*) AS total_admissions
FROM hospital_dataset2
GROUP BY month
ORDER BY total_admissions DESC;

SELECT `Admission Type`, round(AVG(DATEDIFF(`Discharge Date`, `Date of Admission`)), 0) AS Avg_stay
FROM hospital_dataset2
GROUP BY `Admission Type`;

-- Frequently prescribed medications per condition
SELECT `Medication`, COUNT(*) AS Medication_count
FROM hospital_dataset2
GROUP BY `Medication`
ORDER BY Medication_count DESC;

SELECT `Medical Condition`, `Medication`, COUNT(*) AS Medication_count
FROM hospital_dataset2
GROUP BY `Medical Condition`, `Medication`
ORDER BY Medication_count DESC;

-- Doctors Specialization
SELECT `Doctor`, `Medical Condition`, COUNT(*) AS total_cases
FROM hospital_dataset2 
GROUP BY `Doctor`, `Medical Condition`
ORDER BY total_cases DESC;

-- Doctors workload
SELECT `Doctor`, COUNT(*) AS total_patients
FROM hospital_dataset2 
GROUP BY `Doctor`
ORDER BY total_patients DESC;

-- Patient Readmission Count
SELECT `Name`, COUNT(*) AS Readmission_count
FROM hospital_dataset2 
GROUP BY `Name`
HAVING Readmission_count > 1
ORDER BY Readmission_count DESC;
