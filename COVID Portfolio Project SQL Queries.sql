/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/




select * 
from portfolioproject..CovidDeaths
where continent is not null
order by 3,4;

--select * 
--from portfolioproject..CovidVaccination
--order by 3,4;



select location, date, total_cases, new_cases, total_deaths, population
from portfolioproject..coviddeaths
order by 1,2;

-- Looking at Total Cases VS Total Deaths


select location, date, total_cases, total_deaths,
case 
when try_convert(float,total_cases) = 0 then null
else (try_convert(float,total_deaths)/try_convert(float,total_cases))*100 
end as DeathPercentage
from portfolioproject..coviddeaths
where location like '%states%'
order by 1,2;


-- Looking at Total Cases VS Population
--Shows what percentage of population got Covid


select location, date, total_cases,population, (total_cases/population)* 100 as PercentagepopulationInfected
from portfolioproject..coviddeaths
--where location like '%states%'
where continent is not null
order by 1,2;


-- Countries with Highest Infection Rate compared to Population

select location, population, max(total_cases) as HighestInfectionCount,  max((total_cases/population))* 100 
as PercentagepopulationInfected
from portfolioproject..coviddeaths
--where location like '%states%'
where continent is not null
group by location, population
order by PercentagepopulationInfected desc;

-- Showing countries with Highest Death Count per Population


select location, max(cast(total_deaths as int)) as HighestDeathCount
from portfolioproject..coviddeaths
--where location like '%states%'
where continent is not null
group by location
order by HighestDeathCount desc;

--LET'S Break Things Down By Continent

-- Showing the continenet with highest death count per population


select continent, max(cast(total_deaths as int)) as TotalDeathCount
from portfolioproject..coviddeaths
--where location like '%states%'
where continent is not null
group by continent
order by TotalDeathCount desc;


select location, max(cast(total_deaths as int)) as TotalDeathCount
from portfolioproject..coviddeaths
--where location like '%states%'
where continent is  null
group by location
order by TotalDeathCount desc;


-- GLOBAL NUMBERS



SELECT 
    
    SUM(new_cases) AS total_cases, 
    SUM(cast(new_deaths as int)) AS total_deaths,
    CASE 
        WHEN SUM(new_cases) = 0 THEN 0 
        ELSE SUM(cast(new_deaths as int)) * 100.0 / NULLIF(SUM(new_cases), 0)
    END AS DeathPercentage
FROM 
    portfolioproject..coviddeaths
--WHERE location LIKE '%states%'
WHERE continent IS not NULL
--GROUP BY date
ORDER BY 1,2;



SELECT  SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths,
    CASE 
        WHEN SUM(new_cases) = 0 THEN 0 
        ELSE SUM(cast(new_deaths as int)) * 100.0 / NULLIF(SUM(new_cases), 0)
    END AS DeathPercentage
FROM portfolioproject..coviddeaths
--WHERE location LIKE '%states%'
WHERE continent IS not NULL
--GROUP BY date
ORDER BY 1,2;


select * 
from portfolioproject..CovidVaccination

select * 
from portfolioproject..CovidDeaths dea
Join portfolioproject..CovidVaccination vac
on dea.location = vac.location
and dea.date = vac.date;

--Looking at Total Population VS Vaccination
-- Shows percentage of population that has received at least one Covid Vaccine


select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from portfolioproject..CovidDeaths dea
Join portfolioproject..CovidVaccination vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 1,2,3;

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint,isnull(vac.new_vaccinations,0))) OVER (Partition by dea.Location) as cumulative_vaccination
from portfolioproject..CovidDeaths dea
Join portfolioproject..CovidVaccination vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 1,2,3;


select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint,isnull(vac.new_vaccinations,0))) OVER (Partition by dea.Location order by dea.location, dea.date) 
as RollingPeopleVaccinated
from portfolioproject..CovidDeaths dea
Join portfolioproject..CovidVaccination vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3;


-- Using CTE to perform Calculation on Partition By in previous query


With PopvsVac (continent, location, date, population, new_vaccinations,RollingPeopleVaccinated)
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint,isnull(vac.new_vaccinations,0))) OVER (Partition by dea.Location order by dea.location, dea.date) 
as RollingPeopleVaccinated
from portfolioproject..CovidDeaths dea
Join portfolioproject..CovidVaccination vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
from PopvsVac


--Using Temp Table to perform Calculation on Partition By in previous query

Drop table if exists  #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
( 
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric 
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint,isnull(vac.new_vaccinations,0))) OVER (Partition by dea.Location order by dea.location, dea.date) 
as RollingPeopleVaccinated
from portfolioproject..CovidDeaths dea
Join portfolioproject..CovidVaccination vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated


-- Creating view to store data for later Visualization


Create View PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint,isnull(vac.new_vaccinations,0))) OVER (Partition by dea.Location order by dea.location, dea.date) 
as RollingPeopleVaccinated
from portfolioproject..CovidDeaths dea
Join portfolioproject..CovidVaccination vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3


Select * 
from PercentPopulationVaccinated;



/*

Queries used for Tableau Project

*/



-- 1. 

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2




-- 2. 

-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is null 
and location not in
('World', 'European Union', 'International','High Income','Upper middle income', 'Lower middle income','low income')
Group by location
order by TotalDeathCount desc


-- 3.

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- 4.


Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc






















