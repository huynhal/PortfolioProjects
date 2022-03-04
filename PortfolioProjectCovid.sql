/*
COVID 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select * 
From PortfolioProject.dbo.CovidDeaths
Where continent is not null
order by 3,4

--Select *
--From PortfolioProject.dbo.CovidVaccinations
--order by 3,4


--Select Data that we are going to be starting with

Select Location, date, population, total_cases, new_cases, total_deaths
From PortfolioProject.dbo.CovidDeaths
Where continent is not null
order by 1,2



-- Total Cases vs Total Deaths 
-- Shows the likelihood of dying if you contract Covid in your country

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject.dbo.CovidDeaths
Where location like '%state%'
Where continent is not null
order by 1,2



-- Total Cases vs Population 
-- Shows what percentage of population got Covid

Select Location, date, Population, total_cases,(total_cases/population)*100 as PercentPopulationInfected 
From PortfolioProject.dbo.CovidDeaths
--Where location like '%state%'
order by 1,2



-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectedCount, MAX((total_cases/population))*100 as PercentPopulationInfected 
From PortfolioProject.dbo.CovidDeaths
--Where location like '%state%'
Group by Location, Population
order by PercentPopulationInfected desc



-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject.dbo.CovidDeaths
--Where location like '%state%' 
Where continent is not null
Group by Location
order by TotalDeathCount desc



-- BREAK THIS DOWN BY CONTINENT

-- Showing continents with the highest death count per population 

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject.dbo.CovidDeaths
--Where location like '%state%' 
Where continent is not null
Group by continent
order by TotalDeathCount desc




-- GLOBAL NUMBERS

-- Shows the death percentage per day across the world 

Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
(SUM(cast(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
From PortfolioProject.dbo.CovidDeaths
--Where location like '%state%'
where continent is not null
Group by date
order by 1,2


-- Shows the death percentage across the world 
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
(SUM(cast(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
From PortfolioProject.dbo.CovidDeaths
--Where location like '%state%'
where continent is not null
--Group by date
order by 1,2



--Joining the two tables 

Select *
From PortfolioProject.dbo.CovidDeaths dea
Join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date 



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From PortfolioProject.dbo.CovidDeaths dea
Join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date 
where dea.continent is not null
order by 2,3




-- Showing rolling count 
-- Partition is breaking it up by ..... because once there is a new location we want the count to start over 
-- Had to use bigint instead of int beacause it gave me a error *Arithmetic overflow error converting expression to data type int.*

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(Convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date)
as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population* 100 
--can't do this here because you can't use a colunm you just created in the same entry. Need to make a CTE or Temp table
From PortfolioProject.dbo.CovidDeaths dea
Join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date 
where dea.continent is not null
order by 2,3



-- Using CTE to perform Calculation on Partition By in previous query 

-- THe number of column in the CTE needs to be the same
With PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(Convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date)
as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population* 100 
From PortfolioProject.dbo.CovidDeaths dea
Join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date 
where dea.continent is not null
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 
From PopvsVac



-- Using TEMP TABLE to perform Calculation on Partition By in previous query 

Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)


Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(Convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date)
as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population* 100 
From PortfolioProject.dbo.CovidDeaths dea
Join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date 
where dea.continent is not null


Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated



-- Creating View to store data for later visualizations 

Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(Convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date)
as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population* 100 
From PortfolioProject.dbo.CovidDeaths dea
Join PortfolioProject.dbo.CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date 
where dea.continent is not null




