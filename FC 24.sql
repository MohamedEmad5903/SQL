/* 
first, lets look at the important columns in the data
*/

select 
p.long_name as player, p.nationality_name, t.team_name, c.long_name as coach, c.nationality_name as coach_nationality, 
t.league_name, p.player_positions, p.club_position, 
p.preferred_foot, p.club_joined_date, p.club_contract_valid_until_year, p.overall, p.age, p.wage_eur, 
height_cm, weight_kg
from players p
join teams t
on t.team_id = p.club_team_id
join coaches c
on c.coach_id = t.coach_id
where p.league_level in (1,2)
order by overall desc

-- Q1 What is the preferred foot ratio?

with no_players as (
SELECT 
	preferred_foot, cast(count(long_name) as numeric) as players_count,
	(Select cast(count(long_name) as numeric) from players) as all_players
FROM players
group by preferred_foot
)
SELECT preferred_foot, round((players_count/all_players)*100,2) as percet_of_preferred_foot
from no_players

-- Q2 Who are team managers?

select t.team_name as team, c.long_name as name 
from teams t 
join coaches c
on t.coach_id = c.coach_id
order by t.overall desc

-- Q3 Who are the club managers in the top 5 leagues?

select t.league_name, t.team_name as team, c.long_name as coach_name
from teams t 
join coaches c
on t.coach_id = c.coach_id
where
	t.league_name <> 'Friendly International' and 
	t.league_name IN ('Serie A', 'Premier League', 'Bundesliga', 'Ligue 1', 'La Liga') and
	t.nationality_name in ('Italy', 'Monaco', 'England', 'France', 'Germany', 'Spain')
order by  t.league_name, t.overall desc



-- Q4 What is the number and percentage of local and foreign coaches in the top 5 leagues?

WITH coach_type as (
SELECT 
	t.league_name as league, 
	CASE WHEN t.nationality_name = c.nationality_name then 'same' ELSE 'different' end as coach_type
FROM teams t 
JOIN coaches c
ON t.coach_id = c.coach_id 
WHERE 
	t.league_name <> 'Friendly International' and 
	t.league_name IN ('Serie A', 'Premier League', 'Bundesliga', 'Ligue 1', 'La Liga') and
	t.nationality_name in ('Italy', 'Monaco', 'England', 'France', 'Germany', 'Spain')
),
coaches_num as (
SELECT 
	league, coach_type, cast(COUNT(coach_type)as numeric)  as no_of_coaches
FROM coach_type t
group by league, coach_type 
)
SELECT  
	league, coach_type, no_of_coaches,
	round(100*(no_of_coaches/ SUM(no_of_coaches) Over(Partition by league)), 2) as percentage
FROM coaches_num

-- Q5 What is the highest rated team in each league?

WITH rat_max as( 
SELECT 
	league_name, team_name, MAX(overall) as rating,
	RANK() OVER(PARTITION BY league_name ORDER BY MAX(overall) desc) rnk
FROM teams
GROUP BY league_name, team_name
)
SELECT league_name, team_name, rating 
FROM rat_max
WHERE rnk= 1
ORDER BY rating desc


-- Q6 Who are the highest rated players on each team?

WITH rate as(
SELECT 
	t.team_name as team, p.long_name as player, MAX(p.overall) as rating,
	RANK() OVER(PARTITION BY t.team_name ORDER BY  MAX(p.overall) DESC ) AS rnk
FROM players p 
JOIN teams t
ON p.club_team_id = t.team_id 
group by t.team_name, p.long_name
)

SELECT team, player, rating
FROM rate
WHERE rnk = 1 
order by rating desc


-- Q7 Who are the lowest rated players on each team?

WITH t1 as (
SELECT 
	t.team_name as team, p.long_name as player, MIN(p.overall) as rating,
	RANK() OVER(PARTITION BY t.team_name ORDER BY  MIN(p.overall)  ) AS rnk
FROM players p 
JOIN teams t
ON p.club_team_id = t.team_id 
group by t.team_name, p.long_name
)

SELECT team, player, rating
FROM t1 
WHERE rnk = 1 
order by rating 

-- Q8 What is the age distribution of players?

WITH groups as (
SELECT
	p.age,
	CASE WHEN p.age > 40 then '+40'
		 WHEN p.age > 35 then '36:40'
		 WHEN p.age > 30 then '31:35'
		 WHEN p.age > 25 then '26:30'
		 WHEN p.age >= 20 then '21:25'
		 ELSE 'under 20,' end as age_group
FROM players p 
JOIN teams t
ON p.club_team_id = t.team_id  
)
SELEcT age_group, COUNT(age_group) as players_count
from groups
group by age_group
order by players_count desc

-- Q9 Who are the ten highest-paid players in the top 5 leagues?

SELECT top 10 long_name as names , SUM(wage_eur) as total_wages
FROM players  
group by long_name
order by SUM(wage_eur) desc 


-- Q10 What are the ten highest paid clubs in the top 5 leagues?

SELECT top 10 t.team_name as team , SUM(p.wage_eur) as total_wages
FROM players p 
JOIN teams t
ON p.club_team_id = t.team_id
group by t.team_name
order by SUM(p.wage_eur) desc 


-- Q11 Who are the highest rated players by position?

WITH positions as (
SELECT 
	short_name as player, 
	PARSENAME(REPLACE(player_positions, ',', '.'),1) as position, overall as overall_rating,
	pace, shooting, passing, dribbling, defending, physic
FROM players
WHERE pace is not null 
),

rank_ as(
SELECT 
	player,position, overall_rating, pace, shooting, passing, dribbling, defending, physic, 
	RANK() OVER(PARTITION BY position ORDER BY overall_rating desc) as rnk
FROM positions
)
SELECT player,position, overall_rating, pace, shooting, passing, dribbling, defending, physic
FROM rank_ 
WHERE rnk =1 
ORDER BY overall_rating desc

-- Q12 Who are the top-rated players in each country with their teams and league?

WITH ranks as (
SELECT 
	p.short_name as player, p.nationality_name as country, t.team_name as team, 
	p.overall as rate, p.player_positions as position, 
	RANK()  OVER(PARTITION BY p.nationality_name ORDER BY p.overall desc ) as rnk 
FROM players p 
JOIN teams t
ON p.club_team_id = t.team_id
)
SELECT player, country, team, rate, position
FROM ranks
WHERE rnk = 1 
ORDER BY rate desc

-- Q13 What is the proportion of local and foreign players in each league?

WITH players_dis as (
SELECT
	p.nationality_name as country, CAST(COUNT(p.short_name)AS decimal) as players_count
FROM players p 
JOIN teams t
ON p.club_team_id = t.team_id
WHERE t.league_name = 'Serie A' AND  t.nationality_name = 'Italy'
GROUP BY t.league_name, p.nationality_name
),
total_players AS(
SELECT
	country,players_count, SUM(CAST(players_count AS decimal)) OVER ()  as all_players
FROM players_dis
)

SELECT country, players_count, CAST(100*(players_count/all_players)AS decimal) percentage_
FROM total_players
ORDER BY percentage_ desc

-- Q14 What is the average age of teams in the top 5 leagues?

SELECT t.team_name as team, ROUND(AVG(CAST(p.age as decimal)),2) as team_average_age
FROM players p 
JOIN teams t
ON p.club_team_id = t.team_id
WHERE 
	t.league_name <> 'Friendly International' and 
	t.league_name IN ('Serie A', 'Premier League', 'Bundesliga', 'Ligue 1', 'La Liga') and
	t.nationality_name in ('Italy', 'Monaco', 'England', 'France', 'Germany', 'Spain')
GROUP BY t.team_name
ORDER BY AVG(CAST(p.age as decimal))

-- Q15 What is the top 5 leagues players average age?

SELECT t.league_name as league, ROUND(AVG(CAST(p.age as decimal)),2) as team_average_age
FROM players p 
JOIN teams t
ON p.league_id = t.league_id
WHERE 
	t.league_name <> 'Friendly International' and 
	t.league_name IN ('Serie A', 'Premier League', 'Bundesliga', 'Ligue 1', 'La Liga') and
	t.nationality_name in ('Italy', 'Monaco', 'England', 'France', 'Germany', 'Spain')
GROUP BY t.league_name
ORDER BY AVG(CAST(p.age as decimal))


-- Q16 What are the ages of the coaches?

select c.long_name as coach , t.team_name, c.nationality_name, DATEDIFF(YEAR, dob ,'2023-10-21') as coach_age 
from coaches c
join teams t
ON c.coach_id = t.coach_id
WHERE dob IS NOT NULL
	/* if you want just the top 5 leagues
	AND t.league_name <> 'Friendly International' and 
	t.league_name IN ('Serie A', 'Premier League', 'Bundesliga', 'Ligue 1', 'La Liga') and
	t.nationality_name in ('Italy', 'Monaco', 'England', 'France', 'Germany', 'Spain')*/
ORDER BY 4

-- Deep analysis for "Serie A"

-- All players for each team
select 
	short_name, player_positions, overall, club_jersey_number,  
	preferred_foot, skill_moves, height_cm, weight_kg, work_rate, nationality_name
from players 
WHERE league_name ='Serie A' AND club_name = 'Milan' -- you can change the club name with any club you want
ORDER BY overall desc

--- Q17 What are the teams rating and coaches?

SELECT 
	t.team_name as team, overall, t.attack, t.midfield, t.defence,
	CONCAT(c.long_name,' - ',c.nationality_name) as coach
FROM teams t 
JOIN coaches c
ON t.coach_id = c.coach_id
WHERE league_name ='Serie A' AND t.nationality_name = 'Italy'
ORDER BY overall desc


-- Q18 What is the number of italian & not italian players in each team ?

WITH italian as(
SELECT
	t.team_name, COUNT(p.player_id) AS italian_players
FROM players p
JOIN teams t
ON p.club_team_id = t.team_id
WHERE P.league_name ='Serie A' AND t.nationality_name = 'Italy' AND p.nationality_name = 'Italy'
GROUP BY t.team_name 
),
not_italian as (
SELECT
	t.team_name as team, COUNT(p.player_id) AS not_italian_players
FROM players p
JOIN teams t
ON p.club_team_id = t.team_id
WHERE P.league_name ='Serie A' AND t.nationality_name = 'Italy' AND p.nationality_name <> 'Italy'
GROUP BY t.team_name 
)
SELECT team, italian_players, not_italian_players
FROM italian 
JOIN not_italian 
ON italian.team_name = not_italian.team

-- Q19 Who is the top paid player in each team?

WITH ranks as (
SELECT	
	p.short_name as name, t.team_name as team , p.wage_eur as wages,
	RANK()  OVER(PARTITION BY t.team_name ORDER BY p.wage_eur desc ) as rnk 
FROM players p 
JOIN teams t
ON p.club_team_id = t.team_id
WHERE P.league_name ='Serie A' AND t.nationality_name = 'Italy'
)
SELECT name, team, wages
FROM ranks
WHERE rnk = 1
ORDER BY wages desc















select * from players WHERE league_name ='Serie A'
select *  from teams WHERE league_name = 'Serie A'
select * from coaches	
