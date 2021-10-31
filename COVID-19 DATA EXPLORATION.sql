SELECT *
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 'location','date' 

--select data for analysis

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 'location', 'date'


--Compare total cases vs total death
--shows the likelihood of death for individual countries at specific times

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM PortfolioProjects..CovidDeaths
WHERE location like '%Nigeria%'
AND continent IS NOT NULL 
AND date = '2021-09-17'
ORDER BY 1,2

--Total cases vs population
--Shows the percentage of the population that is positive with COVID at a given time

SELECT location, date, population,total_cases, (total_cases/population)*100 AS infected_percentage
FROM PortfolioProjects..CovidDeaths
WHERE location like '%Nigeria%'
AND continent IS NOT NULL
ORDER BY 1,2

--Countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS highest_infection_rate, 
MAX((total_cases/population))*100 AS infected_percentage
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

--shows countries with highest death rate  per population

SELECT location, MAX(cast(total_deaths AS INT)) AS most_deaths
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY most_deaths DESC

--IMPACT BY CONTINENT
--Continents with highest death rate per population

SELECT continent, MAX(cast(total_deaths AS INT)) AS most_deaths
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY most_deaths DESC

--GLOBAL IMPACT

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS 
total_deaths, SUM(CAST(new_deaths AS INT))/SUM(New_Cases)*100 AS DeathPercentage
FROM PortfolioProjects..CovidDeaths
--Where location like '%states%'
WHERE continent IS NOT NULL 
--GROUP BY DATE
ORDER BY 1,2



SELECT *
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date

--TOTAL GLOBAL POPULATION VS VACCINATIONS

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
	--AND dea.location LIKE '%Nigeria%'
ORDER BY 2,3

--TOTAL VACCINATION BY LOCATION

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY 
dea.location, dea.date) AS cumulative_vaccinations
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
	--AND dea.location LIKE '%Nigeria%'
ORDER BY 2,3

-- Using CTE to perform Calculation on Partition By in previous query

WITH pop_vs_vac (continent, location, date, population, new_vaccinations, cumulative_vaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cumulative_vaccinations
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
	--AND dea.location LIKE '%Nigeria%'
--ORDER BY 2,3
)
SELECT *
FROM pop_vs_vac


--CUMULATIVE PERCENTAGE OF THE POPULATION VACCINATED

WITH pop_vs_vac (continent, location, date, population, new_vaccinations, cumulative_vaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cumulative_vaccinations
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
	--AND dea.location LIKE '%Nigeria%'
--ORDER BY 2,3
)
SELECT *, (cumulative_vaccinations/population)*100
FROM pop_vs_vac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopVaccinated
Create Table #PercentPopVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by 
dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProjects..CovidDeaths dea
Join PortfolioProjects..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopVaccinated

--CREATING VIEW TO STORE DATA FOR LATER VISUALIZATION

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cumulative_vaccinations
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
	