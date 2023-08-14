/*

DATA LINK ("https://www.kaggle.com/datasets/heesoo37/120-years-of-olympic-history-athletes-and-results")

*/

-- 1.How many olympics games have been held?
SELECT count (distinct games) no_of_olympics_games
FROM athlete_events

-- 2.List down all Olympics games held so far.
SELECT distinct games as olympics_games , city
FROM athlete_events
order by games 

-- 3.Mention the total no of nations who participated in each olympics game?
with nation as (
SELECT games , reg.region
FROM athlete_events ath
JOIN noc_region reg
ON ath.noc = reg.noc 
GROUP BY games , reg.region
)
select games , count(1) as countries 
from nation 
group by games
order by games 

-- 4.Which year saw the highest and lowest no of countries participating in olympics?
with nations as (
SELECT games , reg.region
FROM athlete_events ath
JOIN noc_region reg
ON ath.noc = reg.noc 
GROUP BY games , reg.region
),

no_of_countries as (
select games , count(1) as countries 
from nations 
group by games
order by games 
)
SELECT DISTINCT
	concat(first_value(games) OVER(order by countries), '-' , first_value(countries) OVER(order by countries )) as lowest,
	concat(first_value(games) OVER(order by countries desc), '-' ,first_value(countries) OVER(order by countries desc)) as highest  
FROM no_of_countries

-- 5.Which nation has participated in all of the olympic games?
SELECT  reg.region , count( distinct games)
FROM athlete_events ath
JOIN noc_region reg
ON ath.noc = reg.noc 
GROUP BY reg.region
HAVING count( distinct games) = 51



-- 6.Identify the sport which was played in all summer olympics.
SELECT 
	sport, count( distinct games) no_of_games, 
	(select COUNT( distinct games) FROM athlete_events WHERE season = 'Summer' ) as total_games
FROM athlete_events 
WHERE season = 'Summer'
GROUP BY sport
HAVING count( distinct games) = (select COUNT( distinct games) FROM athlete_events WHERE season = 'Summer' )

-- 7.Which Sports were just played only once in the olympics?
with t1 as (
SELECT distinct games, sport
FROM athlete_events 
),
t2 as (
SELECT sport, count(games) no_of_games
FROM t1
GROUP BY sport )
SELECT t2.* , t1.games
FROM t2 
JOIN t1  
ON t1.sport = t2.sport
WHERE t2.no_of_games = 1
order by t1.games


-- 8.Fetch the total no of sports played in each olympic games.

SELECT games, COUNT(distinct sport) no_of_sports 
FROM athlete_events
group by games 
ORDER BY games


-- 9.Fetch details of the oldest athletes to win a gold medal.
WITH  gold as (
	SELECT *
	FROM athlete_events
	WHERE medal = 'Gold' AND age <> 'NA'
	),
	ranking as (
	SELECT 
		* ,
		rank() OVER(order by age desc ) rnk 
	FROM gold)

SELECT * 
FROM ranking
WHERE rnk = 1 



-- 10.Find the Ratio of male and female athletes participated in all olympic games.
WITH no_of_sex as ( 
	SELECT
		sex,
		count( name) as sex_count,
		(select count( name) from athlete_events ) as count_all
	FROM athlete_events
	group by  sex )

SELECT sex , round(100*(cast(sex_count as numeric) / cast(count_all as numeric)),2) as sex_ratio
FROM  no_of_sex 

-- 11.Fetch the top 5 athletes who have won the most gold medals.
WITH medals as (
	SELECT 
		name,
		team,
		count(medal) as gold_medals,
		DENSE_RANK() OVER(ORDER BY count(medal) desc ) as rnk 
	FROM athlete_events
	WHERE medal = 'Gold'
	GROUP BY name, team
)
SELECT name, team, gold_medals
from medals
WHERE rnk < 6 


-- 12.Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
WITH medals as (
	SELECT 
		name,
		team,
		count(medal) as medal,
		DENSE_RANK() OVER(ORDER BY count(medal) desc ) as rnk 
	FROM athlete_events
	WHERE medal <> 'NA'
	GROUP BY name, team
)
SELECT name, team, medal
from medals
WHERE rnk < 6 



-- 13.Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
	WITH medals as (
	SELECT  
		reg.region as country, 
		count(medal) as medal,
		DENSE_RANK() OVER(ORDER BY count(medal) desc ) as rnk 
	FROM athlete_events ath
	JOIN noc_region reg
	ON ath.noc = reg.noc 
	WHERE medal <> 'NA'
	GROUP BY reg.region
)
SELECT country, medal
from medals
WHERE rnk < 6


-- 14.List down total gold, silver and broze medals won by each country.

CREATE EXTENSION TABLEFUNC;

SELECT
	country,
	coalesce(gold,0) as gold,
	coalesce(silver,0) as silver,
	coalesce(bronze,0) as bronze
FROM crosstab('
				SELECT  
					reg.region as country,
			  		medal,
					count(medal)
				FROM athlete_events ath
				JOIN noc_region reg
				ON ath.noc = reg.noc 
				WHERE medal <> ''NA''
				GROUP BY reg.region, medal
			    ORDER BY reg.region, medal',
			    'VALUES (''Bronze''), (''Gold''), (''Silver'')')
			  as 
			  (country varchar(50), bronze bigint, gold bigint , silver bigint )
			  




-- 15.List down total gold, silver and broze medals won by each country corresponding to each olympic games.

SELECT
	country,
	games,
	coalesce(gold,0) as gold,
	coalesce(silver,0) as silver,
	coalesce(bronze,0) as bronze
FROM crosstab('
				SELECT  
					reg.region as country,
			  		games,
			  		medal,
					count(medal)
				FROM athlete_events ath
				JOIN noc_region reg
				ON ath.noc = reg.noc 
				WHERE medal <> ''NA''
				GROUP BY reg.region, medal, games
			    ORDER BY reg.region, medal, games' ,
			    'VALUES (''Bronze''), (''Gold''), (''Silver'')')
			  as 
			  (country varchar(50), games varchar(50), bronze bigint, gold bigint , silver bigint )
			  


-- 16.Identify which country won the most gold, most silver and most bronze medals in each olympic games.
WITH t1 as(
SELECT
	 substring(games, 1, position(' - ' in games)-1) as games
    , substring(games, position(' - ' in games)+3) as country,
	coalesce(gold,0) as gold,
	coalesce(silver,0) as silver,
	coalesce(bronze,0) as bronze
FROM crosstab('
				SELECT  
					concat(games , '' - '' ,reg.region) as games ,
			  		medal,
					count(medal) 
				FROM athlete_events ath
				JOIN noc_region reg
				ON ath.noc = reg.noc 
				WHERE medal <> ''NA''
				GROUP BY reg.region, medal, games
			    ORDER BY reg.region, medal, games',
			    'VALUES (''Bronze''), (''Gold''), (''Silver'')')
			  as 
			  ( games varchar(50), bronze bigint, gold bigint , silver bigint ))
SELECT 	
	distinct games,
	concat(first_value(country) OVER(PARTITION BY games order by gold desc),
		   ' - ' , 
		   first_value(gold) OVER(PARTITION BY games order by gold desc)) as gold,
	concat(first_value(country) OVER(PARTITION BY games order by silver desc),
		   ' - ' , 
		   first_value(silver) OVER(PARTITION BY games order by silver desc)) as silver,
	concat(first_value(country) OVER(PARTITION BY games order by bronze desc),
		   ' - ' , 
		   first_value(bronze) OVER(PARTITION BY games order by bronze desc)) as bronze
FROM t1
order by games





-- 17.Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

WITH t1 as(
SELECT
	 substring(games, 1, position(' - ' in games)-1) as games
    , substring(games, position(' - ' in games)+3) as country,
	coalesce(gold,0) as gold,
	coalesce(silver,0) as silver,
	coalesce(bronze,0) as bronze
FROM crosstab('
				SELECT  
					concat(games , '' - '' ,reg.region) as games ,
			  		medal,
					count(medal) 
				FROM athlete_events ath
				JOIN noc_region reg
				ON ath.noc = reg.noc 
				WHERE medal <> ''NA''
				GROUP BY reg.region, medal, games
			    ORDER BY reg.region, medal, games',
			    'VALUES (''Bronze''), (''Gold''), (''Silver'')')
			  as 
			  ( games varchar(50), bronze bigint, gold bigint , silver bigint )),
			  
		t2 as (
			SELECT
				games,
				reg.region as country,
				count(games) as total_medals
			FROM athlete_events ath
			JOIN noc_region reg
			ON ath.noc = reg.noc 
			WHERE medal <> 'NA'
			GROUP BY games, reg.region
			ORDER BY games, reg.region)
SELECT 	
	distinct f.games,
	concat(first_value(f.country) OVER(PARTITION BY f.games order by f.gold desc),
		   ' - ' , 
		   first_value(f.gold) OVER(PARTITION BY f.games order by f.gold desc)) as gold,
	concat(first_value(f.country) OVER(PARTITION BY f.games order by f.silver desc),
		   ' - ' , 
		   first_value(f.silver) OVER(PARTITION BY f.games order by f.silver desc)) as silver,
	concat(first_value(f.country) OVER(PARTITION BY f.games order by f.bronze desc),
		   ' - ' , 
		   first_value(f.bronze) OVER(PARTITION BY f.games order by f.bronze desc)) as bronze,
	concat(first_value(s.country) OVER(PARTITION BY s.games order by s.total_medals desc),
		   ' - ' , 
		   first_value(s.total_medals) OVER(PARTITION BY s.games order by s.total_medals desc )) as most_medals_won   
FROM t1 f
JOIN t2 s
ON f.games = s.games and f.country = s.country
order by games





-- 18.Which countries have never won gold medal but have won silver/bronze medals?
with t1 as (
SELECT
	country,
	coalesce(gold,0) as gold,
	coalesce(silver,0) as silver,
	coalesce(bronze,0) as bronze
FROM crosstab('
				SELECT  
					reg.region as country,
			  		medal,
					count(medal)
				FROM athlete_events ath
				JOIN noc_region reg
				ON ath.noc = reg.noc 
				WHERE medal <> ''NA''
				GROUP BY reg.region, medal
			    ORDER BY reg.region, medal',
			    'VALUES (''Bronze''), (''Gold''), (''Silver'')')
			  as 
			  (country varchar(50), bronze bigint, gold bigint , silver bigint ))
SELECT *
FROM t1 
WHERE gold = 0 and (silver > 0 or bronze > 0)
ORDER BY bronze desc





-- 19.In which Sport/event, egypt has won highest medals.
SELECT  
	sport,
	count(medal) as medals
FROM athlete_events ath
JOIN noc_region reg
ON ath.noc = reg.noc 
WHERE medal <> 'NA' AND reg.region = 'Egypt'
GROUP BY sport
ORDER BY count(medal) desc
limit 1 


-- 20.Break down all olympic games where egypt won medal for Weightlifting and how many medals in each olympic games.
SELECT
	reg.region as country,
	sport,
	games,
	count(medal) as Weightlifting_medals,
	(SELECT COUNT(medal) FROM athlete_events ath
	JOIN noc_region reg
	ON ath.noc = reg.noc  WHERE reg.region = 'Egypt' AND  medal <> 'NA'  ) as all_medals
FROM athlete_events ath
JOIN noc_region reg
ON ath.noc = reg.noc 
WHERE medal <> 'NA' AND sport = 'Weightlifting' AND reg.region = 'Egypt'
GROUP BY reg.region, sport, games
ORDER BY games


