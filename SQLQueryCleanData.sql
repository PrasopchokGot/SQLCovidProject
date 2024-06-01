---- CREATE temp table which is being used to delete duplicate data in CovidDeath and CovidVacination
--CREATE TABLE #TempCovidDeaths (
--    iso_code VARCHAR(255),
--    continent VARCHAR(255),
--    location VARCHAR(255),
--    date DATE,
--    total_cases INT,
--    duplicate INT
--)

--INSERT INTO #TempCovidDeaths
--SELECT iso_code, continent, location, date, total_cases,
--    ROW_NUMBER() OVER(PARTITION BY location, total_cases ORDER BY location, date) as duplicate
--FROM PortfolioProject.dbo.CovidDeaths

--DELETE FROM PortfolioProject.dbo.CovidDeaths
--WHERE EXISTS (
--    SELECT 1
--    FROM #TempCovidDeaths
--    WHERE PortfolioProject.dbo.CovidDeaths.location = #TempCovidDeaths.location
--    AND PortfolioProject.dbo.CovidDeaths.date = #TempCovidDeaths.date
--    AND #TempCovidDeaths.duplicate > 1
--)

--WITH CTE AS (
--    SELECT iso_code, continent, location, date, total_cases,
--        ROW_NUMBER() OVER(PARTITION BY location, total_cases ORDER BY location, date) as duplicate
--    FROM PortfolioProject.dbo.CovidDeaths
--)

--DELETE FROM PortfolioProject.dbo.CovidVaccination
--WHERE EXISTS (
--    SELECT 1
--    FROM #TempCovidDeaths
--    WHERE PortfolioProject.dbo.CovidVaccination.location = #TempCovidDeaths.location
--    AND PortfolioProject.dbo.CovidVaccination.date = #TempCovidDeaths.date 
--    AND #TempCovidDeaths.duplicate > 1
--)

-- Let's start with explore the CovidDeths table
SELECT *
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY location, date

-- Continent data is stored in location instead continent column itself
SELECT Distinct(location)
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is NULL

-- Some information fill continent in location but continent itself is NULL -> Swap these two columns
UPDATE PortfolioProject.dbo.CovidDeaths SET 
	continent = CASE WHEN Continent IS NULL THEN Location 
					 ELSE Continent
				END
UPDATE PortfolioProject.dbo.CovidDeaths SET 
	location = CASE WHEN location = continent THEN NULL 
					 ELSE location
				END

-- Recheck what we have done in previous query
SELECT DISTINCT(continent)
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY continent

SELECT DISTINCT(location)
FROM PortfolioProject.dbo.CovidDeaths
WHERE location IN ('Asia''Africa', 'Europe', 'Europe Union', 'North America', 'Oceania', 'South America', 'World')

-- Remove finantial status data, we just to group data by location.
SELECT COUNT(*)
FROM PortfolioProject.dbo.CovidDeaths
WHERE location IN ('Low income', 'Lower middle income', 'Upper middle income', 'High income')

DELETE FROM PortfolioProject.dbo.CovidDeaths
WHERE location IN ('Low income', 'Lower middle income', 'Upper middle income', 'High income')



