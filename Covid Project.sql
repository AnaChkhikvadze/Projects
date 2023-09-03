select * from [covid deaths] order by 3, 4

select * from [covid vaccinations] order by 3, 4

select location, date, total_cases, new_cases, total_deaths, population from [covid deaths] order by 1,2

--total deaths vs total cases

SELECT
    location, date, total_cases, total_deaths,
    CASE
        WHEN total_cases = 0 THEN NULL
        ELSE (CONVERT(FLOAT, total_deaths) / CONVERT(FLOAT, total_cases)) * 100
    END AS deathPercentage
FROM
    [covid deaths]
	where location like '%eorgia'
ORDER BY
    location,
    date;

--population vs total cases

SELECT
    location, date, population, total_cases,
    CASE
        WHEN total_cases = 0 THEN NULL
        ELSE (CONVERT(FLOAT, total_cases) / CONVERT(FLOAT, population)) * 100
    END AS deathPercentage
FROM
    [covid deaths]
	where location like '%eorgia'
ORDER BY
    location,
    date;

--countries with highest infection rate compared to population

SELECT
    Location,
    Population,
    MAX(total_cases) as highestInfectionCount,
    MAX(CAST(total_cases AS FLOAT) / Population) * 100 as percPopulationInfected
FROM
    [covid deaths]
	--where location = 'Georgia'
GROUP BY
    Location, Population
ORDER BY
    percPopulationInfected DESC;

--countries with highest death rate compared to population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [covid deaths]
--Where location like '%states%'
Group by Location
order by TotalDeathCount desc


--countries with lowest death count

Select Location, Min(cast(Total_deaths as int)) as TotalDeathCount
From [covid deaths]
--Where location like '%states%'
Group by Location
order by TotalDeathCount desc


--global numbers
WITH TotalCasesAndDeaths AS (
    SELECT
        SUM(CONVERT(FLOAT, new_cases)) AS total_cases,
        SUM(CONVERT(FLOAT, new_deaths)) AS total_deaths,
        date
    FROM [covid deaths]
    GROUP BY date
)

SELECT
    total_cases,
    total_deaths,
    CASE
        WHEN total_cases = 0 THEN NULL
        ELSE (total_deaths / total_cases) * 100
    END AS deathPercentage
FROM TotalCasesAndDeaths;

-- number of people vaccinated
SELECT
    d.continent,
    d.location,
    d.date,
    d.population,
    v.new_vaccinations,
	sum(convert(float, v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as eventualCount
FROM [covid deaths] d
JOIN [covid vaccinations] v ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.continent <> ''

--queries withing CTE

with populvsvacc (continent, location, date, population, new_vaccinations, eventualCount) as 
(
SELECT
    d.continent,
    d.location,
    d.date,
    d.population,
    v.new_vaccinations,
	sum(convert(float, v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as eventualCount
FROM [covid deaths] d
JOIN [covid vaccinations] v ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.continent <> ''
)
select *, (eventualCount/population)*100 as res from populvsvacc order by res desc

--creating temp table
drop table if exists #populVaccinatedPerc
create table #populVaccinatedPerc
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population varchar(255),
New_vaccinations varchar(255),
eventualCountVaccinated numeric)
insert into #populVaccinatedPerc
SELECT
    d.continent,
    d.location,
    d.date,
    d.population,
    v.new_vaccinations,
	sum(convert(float, v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as eventualCount
FROM [covid deaths] d
JOIN [covid vaccinations] v ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.continent <> ''

select *,
    CASE
        WHEN population = 0 THEN NULL
        ELSE (CONVERT(FLOAT, eventualCountVaccinated) / population) * 100
    END as res
from #populVaccinatedPerc
order by res desc;

--creating view for that query -- showing percentage of people vaccinated
create view PercentPeopleVaccinated as 
SELECT
    d.continent,
    d.location,
    d.date,
    d.population,
    v.new_vaccinations,
	sum(convert(float, v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as eventualCount
FROM [covid deaths] d
JOIN [covid vaccinations] v ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.continent <> ''