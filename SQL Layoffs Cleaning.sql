-- First look at data
SELECT *
FROM layoffs;

/* First glimpse
- Company has entries with spaces so needs to be trimmed
- NULL and blank values present
- date column is a text value rather than date
*/

-- Creating a staging table so I can change the data without changing the raw data
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT *
FROM layoffs;

--  Creating a system to see if there are duplicate rows
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`
) AS row_num
FROM layoffs_staging;

-- Creating a CTE that I can select information from to find if there are any duplicates 
WITH duplicate_cte AS 
(SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, 
industry, total_laid_off, percentage_laid_off, `date`, stage,
country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num >1;

/*Found there was duplicates so I will need to remove them
As I can't delete the duplicate rows from a CTE I created a new table with the row_num as a column enabling me to delete those rows
*/
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, 
industry, total_laid_off, percentage_laid_off, `date`, stage,
country, funds_raised_millions) AS row_num
FROM layoffs_staging;

DELETE 
FROM layoffs_staging2
WHERE row_num >1;

-- We will no longer need the row_num column so I am dropping it as it adds no value
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

/*Going through each column to make sure they are all standardised
Company column shows there was empty space in front of one of the names so trimming it to remove the empty space
*/
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

/*The Crypto industry has several different names so will combine them into 1 industry
There is a NULL value, this will be handled later
*/
SELECT DISTINCT industry
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE'Crypto%';

-- Found USA has 2 entries with DISTINCT due to there being "." at the end of one entry
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country, trim(TRAILING '.' FROM country)
FROM layoffs_staging2
WHERE country LIKE 'United States%'
ORDER BY 1;

UPDATE layoffs_staging2
SET country =trim(TRAILING '.' FROM country)
WHERE country LIKE 'United States%'; 

/*Date column is text rather than date type so changing the type to date
Getting the format into the correct type
*/
SELECT `date`,
str_to_date(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = str_to_date(`date`, '%m/%d/%Y');

-- Modifying the column to a date type
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Now I am going to eliminate NULL values starting with industry


/*Looking at industry to try and look at other companies to see if industry for that company is filled in on that row
As some of the industry areas are Null or blank I am going to search the company to see if it was filled in on a separate row 
*/
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- As they were filled in, I am going to do a self join to replace the Null and blank values with the industry provided on different rows
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- I am setting the blank values to NULL so I can use the below self join without the "OR t1.industry = ''"
UPDATE layoffs_staging2
SET industry = NULL 
WHERE industry = '';

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL)
AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
or industry ='';

/*The only Null Value that didn't get updated was Bally's Interactive because there is only 1 instance of this company and has Null Industry
After research Bally's interactive deals in Sports betting, iGaming and free-to-play products
As this doesn't fit into any category I will set this to Other, As this is the only Null value I will change all remaining NULL values to Other
*/
UPDATE layoffs_staging2
SET industry = 'Other'
WHERE industry IS NULL;

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'bally%';

/* I am unable to update the columns of total_laid_off, percentage_laid_off, funds_raised due to lack a lack of info
Due to this I have decided to delete these rows as we will use these columns a lot in later analysis
*/
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Data cleaning is now done, Please see my analysis project on this data I have cleaned