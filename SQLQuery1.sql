SELECT *
FROM PortfolioProject.dbo.CovidDeaths
WHERE location Like 'Thailand'
ORDER BY location, date

-- Looking at Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location Like 'Thailand'
ORDER BY location, date

-- Shows what percentage of population who have infected by COVID19
SELECT location, date, population, total_cases, (total_cases/population)*100 as infected_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location Like 'Thailand'
ORDER BY location, date

-- Consider the percentage of the DeathPercentage of other countries > Thailand
SELECT location, population, MAX(total_deaths) AS total_deaths_count, 
	MAX(total_deaths/population)*100 as death_rate_per_pop
FROM PortfolioProject.dbo.CovidDeaths
WHERE population >= (SELECT MAX(population) FROM PortfolioProject.dbo.CovidDeaths WHERE location like 'Thailand')
	AND location IS NOT NULL
GROUP BY location, population
ORDER BY death_rate_per_pop DESC

-- GLOBAL NUMBERS
-- Total deaths of people separated by continent
WITH max_total_deaths_location (continent, location, total_deaths) AS 
(
	SELECT continent, location, MAX(total_deaths)
	FROM PortfolioProject.dbo.CovidDeaths
	WHERE location IS NOT NULL
	GROUP BY continent, location
)
SELECT continent, SUM(total_deaths) AS total_deaths_continent
FROM max_total_deaths_location 
GROUP BY continent

-- Another way is sum over daily deaths in each location
-- These two method do not give the same result but close
WITH max_total_deaths_location2 AS 
(
	SELECT continent, location, SUM(new_deaths) AS new_deaths
	FROM PortfolioProject.dbo.CovidDeaths
	WHERE location IS NOT NULL
	GROUP BY continent, location
)
SELECT continent, SUM(new_deaths) AS total_deaths_continent
FROM max_total_deaths_location2
GROUP BY continent

-- It look like there is something wrong with non-coutry entering data
-- Because only some of deaths in this data, it over the actual death from internet
Select SUM(new_deaths)
FROM PortfolioProject.dbo.CovidDeaths
WHERE location is NULL

Select SUM(new_deaths)
FROM PortfolioProject.dbo.CovidDeaths
WHERE location is NOT NULL

-- Looking at total population vs Vaccinations
-- bigint is 8 byte(64-bit) data (two's complement)
-- UNBOUNDED PRECEDING start at the first row of the partition
-- Full clause: ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
WITH PopvsVac (continent, location, date, population, new_people_first_vaccine, cummulative_first_vaccine) AS
(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed,
			SUM(CONVERT(bigint, vac.new_people_vaccinated_smoothed)) 
				OVER (PARTITION BY dea.location ORDER BY dea.date 
				RANGE UNBOUNDED PRECEDING) AS cummulative_first_vaccine
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccination vac
		ON dea.location = vac.location
		AND dea.date = vac.date
)
SELECT *, (cummulative_first_vaccine/population*100) AS cummulative_first_vaccine_percentage
FROM PopvsVac
WHERE new_people_first_vaccine IS NOT NULL
		AND location Like 'Thailand'

-- Temp Table
Drop table if exists #PercentPopulationFirstVacination
Create Table #PercentPopulationFirstVacination
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_people_first_vaccine numeric, 
	cummulative_first_vaccine numeric
)
Insert into #PercentPopulationFirstVacination
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_people_vaccinated_smoothed,
			SUM(CONVERT(bigint, vac.new_people_vaccinated_smoothed)) 
				OVER (PARTITION BY dea.location ORDER BY dea.date 
				RANGE UNBOUNDED PRECEDING) AS cummulative_first_vaccine
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccination vac
		ON dea.location = vac.location
		AND dea.date = vac.date

-- Some country have duplicated data in theie daily first vaccine people 
-- Therefore, their cummulative first vaccine exceed 100%
SELECT *, (cummulative_first_vaccine/population*100) AS cummulative_first_vaccine_percentage
FROM #PercentPopulationFirstVacination
WHERE new_people_first_vaccine IS NOT NULL
		AND (cummulative_first_vaccine/population*100) > 100

-- Creating View to store data for visualizations
-- Drop the existing view if it exists
--'U': User table
--'V': View
--'P': Stored procedure
--'FN': Scalar function
--'IF': Inline table-valued function
--'TF': Table-valued function
--'TR': Trigger
IF OBJECT_ID('PercentPopulationFirstvacination', 'V') IS NOT NULL
    DROP VIEW PercentPopulationFirstvacination;
GO

-- Create the new view
CREATE VIEW PercentPopulationFirstvacination AS 
(
    SELECT dea.continent, 
           dea.location, 
           dea.date, 
           dea.population, 
           vac.new_people_vaccinated_smoothed,
           SUM(CONVERT(bigint, vac.new_people_vaccinated_smoothed)) OVER (PARTITION BY dea.location ORDER BY dea.date RANGE UNBOUNDED PRECEDING) AS cumulative_first_vaccine
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccination vac
    ON dea.location = vac.location
    AND dea.date = vac.date
);

Select *
From PercentPopulationFirstvacination