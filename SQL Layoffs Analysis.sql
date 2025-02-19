/*Data Analysis

Explore the data and identify patterns to answer the below questions
- Time frame this data set covers
- What companies and industries had the most layoffs
- Is there a pattern for the layoffs
- Which country was hit the hardest with layoffs
- Does how well established a company is increase or decrease layoffs
*/

-- Overview of the data
Select * 
FROM layoffs_staging2;

-- Checking the date range so I understand how much time this data covers
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;
-- Start date is March 2020 ending in March 2023, This indicates COVID will play a role in this analysis

-- Checking the max percentage laid off & max laid off
-- Companies with 100% laid off(went under), Max laid is 12000
SELECT MAX(percentage_laid_off), MAX(total_laid_off)
FROM layoffs_staging2;

/* Exploring the total laid off and percentage laid of
Found Google as the company that laid off 12000
There are 116 companies that went under
*/
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off = 12000;

Select * 
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;


SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER by 2 ASC;
/*Results
Top Companies effected by layoffs
Amazon - 18150
Google - 12000 (This shows Google only had 1 round of layoffs but is still second highest)
Meta - 11000
Salesforce - 10090
Microsoft - 10000
Philips - 10000

Excluding NULL lowest laid off was Branch - 3
*/


SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER by 2 DESC;
/* Top Industries effected by layoffs
Consumer - 45182
Retail - 43613
Other - 36289
Transportation - 33748
Finance - 28344

Lowest laid off was Manufacturing - 20
*/

-- Checking what stage the companies were for sum of laid off
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER by 2 DESC;
/*The most lay offs happened when companies are in Post-IPO stage with 204132 layoffs
The least was Subsidiary with 1094
*/

SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER by 1 DESC;
/*How may laid offs per year DESC
2023 - 125677
2022 - 160661
2021 - 15823
2020 - 80998
*/

-- How many laid off per month
SELECT substring(`date`, 1,7) as `MONTH`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE substring(`date`, 1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC;

-- Creating a rolling total to review how each month adds to the total
WITH Rolling_Total AS 
(SELECT substring(`date`, 1,7) as `MONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE substring(`date`, 1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)
SELECT `MONTH`, total_off
,SUM(total_off) OVER(ORDER BY `MONTH`) as rolling_total 
FROM Rolling_Total;
/* 2020 March to May had a large amount of lay offs (62142) likely due to covid but reduced later into the year
Jan 2021 also had a large jump of 6813 in lay offs 
2022 has the largest amount of lay offs going from 80998 to 96821 by the end of the year
2023 has almost reached the same amount of layoffs as 2022 but only has 3 months of data
*/


WITH Company_Year (company, years, total_laid_off) AS
(SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS
(SELECT *, 
DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT * 
FROM Company_Year_Rank
WHERE Ranking <=5
;
/*This Breaks down the top 5 companies per year with the most amount of layoffs
2020 - Uber - 7525
2021 - Bytedance - 3600
2022 - Meta - 11000
2023 - Google - 12000
*/

WITH Industry_Year (industry, years, total_laid_off) AS
(SELECT industry, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry, YEAR(`date`)
), 
Industry_Year_Rank AS
(SELECT *, 
DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Industry_Year
WHERE years IS NOT NULL
)
SELECT * 
FROM Industry_Year_Rank
WHERE Ranking <=5
;
/*This Breaks down the top 5 industries per year with the most amount of layoffs
2020 - Transportation - 14656
2021 - Consumer - 3600
2022 - Retail - 20914
2023 - Other - 28512
*/

