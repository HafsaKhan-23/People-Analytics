SELECT * 
FROM world_layoffs.layoffs;



-- creating a staging table. This is the one we will work in and clean the data. We want a table with the raw data in case something happens
CREATE TABLE world_layoffs.layoffs_staging 
LIKE world_layoffs.layoffs;

INSERT layoffs_staging 
SELECT * FROM world_layoffs.layoffs;


-- now when we are data cleaning we usually follow a few steps
-- 1. check for duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Filling null values
-- 4. remove any columns and rows that are not necessary - few ways



-- 1. Remove Duplicates

# First checking for duplicates

SELECT *
FROM layoffs_staging;


SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM layoffs_staging
) duplicates
WHERE 
	row_num > 1;
    
# Creating new table to delete so that the original remains the same

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
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

    INSERT INTO layoffs_staging2
SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions,
	ROW_NUMBER() OVER (
		PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
		) AS row_num
FROM layoffs_staging;    

#checking for duplicates
SELECT *
FROM layoffs_staging2
where row_num > 1;

Delete
FROM layoffs_staging2
WHERE row_num > 1;

# checking if duplicates got removed or not

SELECT *
FROM layoffs_staging2;

# Deleting the row numbers again for a clean look and effecient work flow


-- 2. Standardizig Data --

# checking and removing spaces at the start or end of the company name if any
select distinct company
from layoffs_staging2;

select company, TRIM(company)
from layoffs_staging2;

update layoffs_staging2
set company = TRIM(company);

# checking industry now
select distinct industry
from layoffs_staging2
order by 1;

# since industry "Crypto currency" and "cryptocurrency" appears as 2 different industries, will cause problems in visualization so correcing it
select *
from layoffs_staging2
where industry like 'Crypto%';

#correcting it
update layoffs_staging2
set industry = 'Crypto'
where industry like 'Crypto%';

# checking if it worked
select distinct industry
from layoffs_staging2
order by 1;

#checking location now 
select distinct location
from layoffs_staging2
order by 1;  
# no standardiztion needed

# checking country now
select distinct country
from layoffs_staging2
order by 1;  
# 2 United States present, 1 with a fullstop, so correctig it
select distinct country, trim(trailing '.' from country)
from layoffs_staging2
order by 1;  
#updating changes 
update layoffs_staging2
set country = trim(trailing '.' from country); 
# checking if it worked or not
select distinct country
from layoffs_staging2
order by 1;  


# now for dates, they should be in correct format and not be in text but in number/integer
select distinct `date`,
str_to_date(`date`, '%m/%d/%Y')
from layoffs_staging2;
#updating table
update layoffs_staging2
set `date` = str_to_date(`date`, '%m/%d/%Y');
#checking everything
SELECT * 
FROM layoffs_staging2;
#changing date format again for correction
select distinct `date`,
str_to_date(`date`, '%Y/%m/%d')
from layoffs_staging2;
#updating table
update layoffs_staging2
set `date` = str_to_date(`date`, '%Y/%m/%d');
# so far only format has been changed date is still in text
alter table layoffs_staging2
modify column `date` date;

-- 3. Filling null values
#checking industry
SELECT industry
from layoffs_staging2
where industry is null or industry = ('');
# converting all blanks to nulls
update layoffs_staging2
set industry = null
 where industry = '';

select t1.industry, t2.industry
from layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company = t2.company
where t1. industry is null
and t2.industry is not null;
#updating to original
update layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company = t2.company
set t1. industry = t2.industry 
where (t1. industry is null or t1. industry = '')
and t2.industry is not null;
#checking
select*
from layoffs_staging2
where company like 'Bally%';
#Bally's null wasn't filled due to the inavailibilty of the data 
select*
from layoffs_staging2
where industry is null;
#The reason of the other values left was because te data wasn't enough other wise the calculation would have been to fill total_lad_off and percentage laid off (i.e by total employees)
#same reason for funds_raised_millions
#Will be deleting the rows where total_laid_off and percentage_laid_offs are missing, as that data is of no use
delete 
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;
#Deleting row_num its of no use
alter table layoffs_staging2
drop column row_num;
#checking everything
select*
from layoffs_staging2;
#The data is Cleaned







