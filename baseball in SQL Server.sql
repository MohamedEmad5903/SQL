select * from LastPitch
select * from PitchingStatus

--Question 1 AVG Pitches Per at Bat Analysis
 
--1a AVG Pitches Per At Bat (LastPitch)
SELECT AVG(pitch_number) avg_num_of_pitches_per_pat
FROM LastPitch

--1b AVG Pitches Per At Bat Home Vs Away (LastPitch) -> Union
SELECT 'home' game_type ,AVG(1.00 * pitch_number)  avg_num_of_pitches_per_pat
FROM LastPitch	
WHERE home_team = 'TB'
 
UNION
SELECT 'away' game_type ,AVG(1.00 * pitch_number) avg_num_of_pitches_per_pat
FROM LastPitch
WHERE away_team = 'TB'


--1c AVG Pitches Per At Bat Lefty Vs Righty  -> Case Statement 
SELECT AVG(CASE WHEN  batter_position = 'R' THEN (1.00 * pitch_number)END ) as righty,
AVG(CASE WHEN  batter_position = 'L' THEN (1.00 * pitch_number) END ) as lifty
from LastPitch


--1d AVG Pitches Per At Bat Lefty Vs Righty Pitcher | Each Away Team -> Partition By
SELECT  DISTINCT home_team , batter_position , AVG(1.00 * pitch_number)
from LastPitch 
WHERE away_team = 'TB'
GROUP BY home_team, batter_position
ORDER BY home_team 
--1e Top 3 Most Common Pitch for at bat 1 through 10, and total amounts (LastPitch)

with t1 as (
	SELECT DISTINCT pitch_name , pitch_number , 
		   COUNT(pitch_name) OVER (PARTITION BY  pitch_name , pitch_number) pitch_frequency
	from LastPitch
	WHERE pitch_number < 11 
),
	t2 as (
	SELECT * , rank() OVER(PARTITION BY pitch_number ORDER BY pitch_frequency desc) rnk
	from t1)
	
	SELECT * 
	FROM t2 
	WHERE rnk < 4


--1f AVG Pitches Per at Bat Per Pitcher with 20+ Innings | Order in descending (LastPitch + PitchingStatus)
SELECT sta.Name , AVG(1.00 * la.pitch_number) avg_pitch_num
FROM LastPitch la
JOIN PitchingStatus sta
ON la.pitcher = sta.Pitcher_id
WHERE sta.IP >= 20 
GROUP BY sta.Name
order by AVG(1.00 * la.pitch_number) desc

--Question 2 Last Pitch Analysis

--2a Count of the Last Pitches Thrown in Desc Order (LastPitch)
SELECT pitch_name , count(pitch_name) thrown_number 
FROM LastPitch
GROUP BY pitch_name 
ORDER BY count(pitch_name) desc 


--2b Count of the different last pitches Fastball or Offspeed (LastPitch)
SELECT sum(CASE WHEN pitch_name in ('4-Seam Fastball','Cutter') then 1 else 0 end ) fast_ball,
	   sum(CASE WHEN pitch_name not in ('4-Seam Fastball','Cutter') then 1 else 0 end ) off_speed
FROM LastPitch

--2c Percentage of the different last pitches Fastball or Offspeed (LastPitch)
SELECT 
	100 * sum(CASE WHEN pitch_name in ('4-Seam Fastball','Cutter') then 1 else 0 end ) /count(*) fast_ball_percent,
	100 * sum(CASE WHEN pitch_name not in ('4-Seam Fastball','Cutter') then 1 else 0 end ) /count(*) off_speed_percent
FROM LastPitch

--2d Top 5 Most common last pitch for a Relief Pitcher vs Starting Pitcher (LastPitch + PitchingStatus)

WITH t1 as (
SELECT 
	sta.Pos, la.pitch_name as pitch_name , COUNT(*) time_thrown,
	rank() OVER(PARTITION BY sta.Pos order by  COUNT(*) desc ) rnk 
FROM LastPitch la
JOIN PitchingStatus sta
ON la.pitcher = sta.Pitcher_id
GROUP BY la.pitch_name, sta.Pos
)
SELECT * 
FROM t1 
WHERE rnk <=5

--Question 3 Homerun analysis
select * from LastPitch

--3a What pitches have given up the most HRs (LastPitchRays) 
SELECT pitch_name, count(*) HRs
FROM LastPitch
WHERE events = 'home_run'
GROUP BY pitch_name
ORDER BY count(*) DESC 

--3b Show HRs given up by zone and pitch, show top 5 most common
SELECT TOP 5   zone, pitch_name, count(*) HRs
FROM LastPitch
WHERE events = 'home_run'
GROUP BY zone, pitch_name
ORDER BY count(*) DESC 

--3c Show HRs for each count type -> Balls/Strikes + Type of Pitcher
SELECT 
	sta.Pos, la.balls, la.strikes , COUNT(*) HRs
FROM LastPitch la
JOIN PitchingStatus sta
ON la.pitcher = sta.Pitcher_id
WHERE events = 'home_run'
GROUP BY sta.Pos, la.balls, la.strikes
ORDER BY count(*) DESC 

--3d Show Each Pitchers Most Common count to give up a HR (Min 30 IP)

with hrs as (
SELECT sta.Name name , la.balls balls , la.strikes strikes , COUNT(*) HRs
FROM LastPitch la
JOIN PitchingStatus sta
ON la.pitcher = sta.Pitcher_id
WHERE events = 'home_run' and IP >= 30 
GROUP BY sta.Name, la.balls, la.strikes ),

hrs_rnk as
(
SELECT *
,rank() OVER(PARTITION BY name order by  HRs desc ) rnk
FROM hrs 
) 

SELECT name, balls, strikes, HRs
FROM hrs_rnk 
WHERE rnk = 1


--Question 4 Shane McClanahan

--4a AVG Release speed, spin rate,  strikeouts, most popular zone ONLY USING LastPitch
SELECT
	AVG(release_speed) avg_release_speed ,
	AVG(release_spin_rate) avg_spin_rate,
	SUM(case when events = 'strikeout' then 1 else 0 end ) as strikouts,
	max(zones.zone) as zone
FROM LastPitch la

join(
	SELECT top 1 pitcher, zone , count(*) pop_zone 
	from LastPitch la
	WHERE player_name =   'Yacabonis, Jimmy'
	group by pitcher, zone 
	order by count(*) desc  ) zones		
ON zones.pitcher = la.pitcher


--4b top pitches for each infield position where total pitches are over 5, rank them
WITH position as (
SELECT  pitch_name, count(*) timeshit, 'third' position
FROM LastPitch
WHERE hit_location = 5 and player_name =   'Fleming, Josh'
GROUP BY pitch_name 
UNION 
SELECT  pitch_name, count(*) timeshit, 'short' position
FROM LastPitch
WHERE hit_location = 6 and player_name =   'Fleming, Josh'
GROUP BY pitch_name 
UNION 
SELECT  pitch_name, count(*) timeshit, 'second' position
FROM LastPitch
WHERE hit_location = 4 and player_name =   'Fleming, Josh'
GROUP BY pitch_name 
UNION 
SELECT  pitch_name, count(*) timeshit, 'first' position
FROM LastPitch
WHERE hit_location = 3 and player_name = 'Fleming, Josh'
GROUP BY pitch_name )

SELECT * 
from position
where timeshit > 4

--4c Show different balls/strikes as well as frequency when someone is on base 
SELECT balls, strikes, count(*) frequency
FROM  LastPitch 
WHERE (on_1b IS NOT NULL or on_2b IS NOT NULL or on_3b IS NOT NULL) and player_name = 'McClanahan, Shane'
group by  balls, strikes
order by count(*) desc 

--4d What pitch causes the lowest launch speed

SELECT top 1  pitch_name , AVG(launch_speed) avg_ls
FROM LastPitch
WHERE  player_name = 'Fleming, Josh'
GROUP BY pitch_name
order by AVG(launch_speed) 


