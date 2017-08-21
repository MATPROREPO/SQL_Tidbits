/*Creation of an auxiliary calendar table within Microsoft TSQL; note query relies upon the auxiliary integers table; 
  this reliance could be replaced by using any other source of a series of integer values*/
/*Table is constructed over a series of queries, with the first populating the initial date data, and subsequent updates 
  adding useful information such as holiday, day number, occurrance of a specific date within the month, etc.*/

/*First construct base table*/
CREATE TABLE auxiliary.calendar (dt DATETIME, yr INT, qtr INT, mnth INT, wk INT, dy INT, dyNum INT, wkDyNum INT
	, mnthNme VARCHAR(10), dyNme VARCHAR(10), isWeekday BIT, isHoliday BIT, isMarketDay BIT, isLeapYear BIT
	, isLeapDay BIT, dtDesc VARCHAR(50),mnthWk INT, mnthDy INT,isLastWeekdayInMonth BIT)

INSERT INTO auxiliary.calendar
SELECT dt.dt
	,YEAR(dt.dt) AS yr
	,(MONTH(dt.dt)-1)/3+1 AS qtr /*implicit integer conversion*/
	,MONTH(dt.dt) AS mnth
	,DATEDIFF(DAY,DATEADD(YEAR,YEAR(dt.dt)-1753,CAST('01/01/1753' AS DATETIME)),dt.dt)/7+1 AS wk /*implicit integer conversion*/
	,DAY(dt.dt) AS dy
	,DATEDIFF(DAY,DATEADD(YEAR,YEAR(dt.dt)-1753,CAST('01/01/1753' AS DATETIME)),dt.dt) + 1 AS dyNum
	/*Jan 1 1753 was a Monday*/
	,(DATEDIFF(DAY,DATEADD(DAY,(DATEDIFF(DAY,CAST('01/01/1753' AS DATETIME),dt.dt)/7)*7,CAST('01/01/1753' AS DATETIME)),dt.dt) + 1) % 7 + 1 AS wkDyNum
	,mnth.mnthNme
	,dy.dyNme
	,CASE WHEN dy.dyNme IN ('Saturday','Sunday') THEN 0 ELSE 1 END AS isWeekday
	,0 AS isHoliday
	,1 AS isMarketDay
	/*Leap year logic from https://en.wikipedia.org/wiki/Leap_year */
	,CASE WHEN YEAR(dt.dt) % 4 = 0 AND YEAR(dt.dt) % 100 <> 0 OR YEAR(dt.dt) % 400 = 0 THEN 1 ELSE 0 END AS isLeapYear
	,CASE WHEN YEAR(dt.dt) % 4 = 0 AND YEAR(dt.dt) % 100 <> 0 OR YEAR(dt.dt) % 400 = 0 THEN CASE WHEN MONTH(dt.dt) = 2 AND DAY(dt.dt) = 29 THEN 1 ELSE 0 END ELSE 0 END AS isLeapDay
	,NULL AS dtDesc
	,0 AS mnthWk
	,0 AS mnthDy
	,0 AS isLastWeekdayInMonth
FROM (
	SELECT DATEADD(DAY,i.i,CAST('01/01/1753' AS DATETIME)) AS dt
	FROM auxiliary.integers AS i
	WHERE i <= DATEDIFF(DAY,CAST('01/01/1753' AS DATETIME),CAST('12/31/9999' AS DATETIME))
) AS dt
INNER JOIN (
	SELECT 1 AS mnth,'January' AS mnthNme UNION SELECT 2,'February' UNION SELECT 3,'March' UNION SELECT 4,'April' UNION SELECT 5,'May' UNION SELECT 6,'June' UNION SELECT 7,'July' UNION SELECT 8,'August' UNION SELECT 9,'September' UNION SELECT 10,'October' UNION SELECT 11,'November' UNION SELECT 12,'December'
) AS mnth
	ON MONTH(dt.dt) = mnth.mnth
INNER JOIN (
	SELECT 1 AS wkDyNum,'Sunday' AS dyNme UNION SELECT 2,'Monday' UNION SELECT 3,'Tuesday' UNION SELECT 4,'Wednesday' UNION SELECT 5,'Thursday' UNION SELECT 6,'Friday' UNION SELECT 7,'Saturday'
) AS dy
	ON (DATEDIFF(DAY,DATEADD(DAY,(DATEDIFF(DAY,CAST('01/01/1753' AS DATETIME),dt.dt)/7)*7,CAST('01/01/1753' AS DATETIME)),dt.dt) + 1) % 7 + 1 = dy.wkDyNum
ORDER BY dt.dt

/*Update week in month*/
UPDATE a
SET a.mnthWk = c.cnt
FROM auxiliary.calendar AS a
INNER JOIN (
	SELECT c.dt,COUNT(*) AS cnt
	FROM (
		SELECT c.dt
		FROM auxiliary.calendar AS c
		INNER JOIN (SELECT yr,mnth,wk FROM auxiliary.calendar GROUP BY yr,mnth,wk) AS x
			ON c.yr = x.yr
			AND c.mnth = x.mnth
			AND c.wk >= x.wk
		GROUP BY c.dt,x.wk
	) AS c
	GROUP BY c.dt
) AS c
	ON a.dt = c.dt

/*Update day in month*/
UPDATE a
SET a.mnthDy = c.cnt
FROM auxiliary.calendar AS a
INNER JOIN (
	SELECT c.dt,COUNT(*) AS cnt
	FROM (
		SELECT c.dt
		FROM auxiliary.calendar AS c
		INNER JOIN (SELECT yr,mnth,wkDyNum,wk FROM auxiliary.calendar GROUP BY yr,mnth,wkDyNum,wk) AS x
			ON c.yr = x.yr
			AND c.mnth = x.mnth
			AND c.wkDyNum = x.wkDyNum
			AND c.wk >= x.wk
		GROUP BY c.dt,x.wk
	) AS c
	GROUP BY c.dt
) AS c
	ON a.dt = c.dt

/*Update for last weekday in month*/
UPDATE a
SET a.isLastWeekdayInMonth = 1
FROM auxiliary.calendar AS a
INNER JOIN (
	SELECT yr,mnth,wkDyNum,MAX(mnthDy) AS mnthDy
	FROM auxiliary.calendar
	GROUP BY yr,mnth,wkDyNum
) AS x
	ON a.yr = x.yr
	AND a.mnth = x.mnth
	AND a.wkDyNum = x.wkDyNum
	AND a.mnthDy = x.mnthDy


/*Holidays; note that this list does not necessarily contemplate the observance of the below holidays
	Need a seperate update for Good Friday/Easter as well as the Friday after Thanksgiving
	Need a seperate update for observed holidays (for instance, nearest Friday/Monday for fixed holidays on weekends*/
UPDATE auxiliary.calendar
SET isHoliday = 1
	,dtDesc = CASE WHEN mnth IN (1) AND dy IN (1) THEN 'New Year''s Day'
		WHEN mnth IN (1) AND wkDyNum IN (2) AND mnthDy IN (3) THEN 'Martin Luther King Jr.''s Day'
		WHEN mnth IN (2) AND wkDyNum IN (2) AND mnthDy IN (3) THEN 'Washington''s Birthday'
		WHEN mnth IN (5) AND wkDyNum IN (2) AND isLastWeekdayInMonth IN (1) THEN 'Memorial Day'
		WHEN mnth IN (7) AND dy IN (4) THEN 'Independence Day'
		WHEN mnth IN (9) AND wkDyNum IN (2) AND mnthDy IN (1) THEN 'Labor Day'
		WHEN mnth IN (10) AND wkDyNum IN (2) AND mnthDy IN (2) THEN 'Columbus Day'
		WHEN mnth IN (11) AND dy IN (11) THEN 'Veteran''s Day'
		WHEN mnth IN (11) AND wkDyNum IN (5) AND mnthDy IN (4) THEN 'Thanksgiving'
		WHEN mnth IN (12) AND dy IN (25) THEN 'Christmas'
		WHEN mnth IN (12) AND dy IN (31) THEN 'New Year''s Eve' END
WHERE mnth IN (1) AND dy IN (1) 
	OR mnth IN (1) AND wkDyNum IN (2) AND mnthDy IN (3) 
	OR mnth IN (2) AND wkDyNum IN (2) AND mnthDy IN (3)
	OR mnth IN (5) AND wkDyNum IN (2) AND isLastWeekdayInMonth IN (1)
	OR mnth IN (7) AND dy IN (4)
	OR mnth IN (9) AND wkDyNum IN (2) AND mnthDy IN (1)
	OR mnth IN (10) AND wkDyNum IN (2) AND mnthDy IN (2)
	OR mnth IN (11) AND dy IN (11)
	OR mnth IN (11) AND wkDyNum IN (5) AND mnthDy IN (4)
	OR mnth IN (12) AND dy IN (25)
	OR mnth IN (12) AND dy IN (31)

UPDATE auxiliary.calendar
SET isHoliday = 1, dtDesc = 'Friday after Thanksgiving'
WHERE dt IN (SELECT DATEADD(DAY,1,dt) FROM auxiliary.calendar WHERE dtDesc = 'Thanksgiving')

/*Easter, coded using Anonymous Gregorian Algorithm at https://en.wikipedia.org/wiki/Computus */
UPDATE a
SET a.isHoliday = 1, a.dtDesc = 'Easter Sunday'
FROM auxiliary.calendar AS a
INNER JOIN (
	SELECT x.yr
		,FLOOR((((19 * (yr % 19) + FLOOR(yr * 0.01) - FLOOR(FLOOR(yr * 0.01) * 0.25) - FLOOR((FLOOR(yr * 0.01) - FLOOR((FLOOR(yr * 0.01) + 8) * 0.04) + 1) / 3) + 15) % 30) + ((32 + 2 * (FLOOR(yr * 0.01) % 4) + 2 * FLOOR((yr % 100) * 0.25) - ((19 * (yr % 19) + FLOOR(yr * 0.01) - FLOOR(FLOOR(yr * 0.01) * 0.25) - FLOOR((FLOOR(yr * 0.01) - FLOOR((FLOOR(yr * 0.01) + 8) * 0.04) + 1) / 3) + 15) % 30) - ((yr % 100) % 4)) % 7) - 7 * FLOOR(((yr % 19) + 11 * ((19 * (yr % 19) + FLOOR(yr * 0.01) - FLOOR(FLOOR(yr * 0.01) * 0.25) - FLOOR((FLOOR(yr * 0.01) - FLOOR((FLOOR(yr * 0.01) + 8) * 0.04) + 1) / 3) + 15) % 30) + 22 * ((32 + 2 * (FLOOR(yr * 0.01) % 4) + 2 * FLOOR((yr % 100) * 0.25) - ((19 * (yr % 19) + FLOOR(yr * 0.01) - FLOOR(FLOOR(yr * 0.01) * 0.25) - FLOOR((FLOOR(yr * 0.01) - FLOOR((FLOOR(yr * 0.01) + 8) * 0.04) + 1) / 3) + 15) % 30) - ((yr % 100) % 4)) % 7)) / 451) + 114) / 31) AS mnth
		,((((19 * (yr % 19) + FLOOR(yr * 0.01) - FLOOR(FLOOR(yr * 0.01) * 0.25) - FLOOR((FLOOR(yr * 0.01) - FLOOR((FLOOR(yr * 0.01) + 8) * 0.04) + 1) / 3) + 15) % 30) + ((32 + 2 * (FLOOR(yr * 0.01) % 4) + 2 * FLOOR((yr % 100) * 0.25) - ((19 * (yr % 19) + FLOOR(yr * 0.01) - FLOOR(FLOOR(yr * 0.01) * 0.25) - FLOOR((FLOOR(yr * 0.01) - FLOOR((FLOOR(yr * 0.01) + 8) * 0.04) + 1) / 3) + 15) % 30) - ((yr % 100) % 4)) % 7) - 7 * FLOOR(((yr % 19) + 11 * ((19 * (yr % 19) + FLOOR(yr * 0.01) - FLOOR(FLOOR(yr * 0.01) * 0.25) - FLOOR((FLOOR(yr * 0.01) - FLOOR((FLOOR(yr * 0.01) + 8) * 0.04) + 1) / 3) + 15) % 30) + 22 * ((32 + 2 * (FLOOR(yr * 0.01) % 4) + 2 * FLOOR((yr % 100) * 0.25) - ((19 * (yr % 19) + FLOOR(yr * 0.01) - FLOOR(FLOOR(yr * 0.01) * 0.25) - FLOOR((FLOOR(yr * 0.01) - FLOOR((FLOOR(yr * 0.01) + 8) * 0.04) + 1) / 3) + 15) % 30) - ((yr % 100) % 4)) % 7)) / 451) + 114) % 31) + 1 AS dy
	FROM (SELECT yr FROM auxiliary.calendar GROUP BY yr) AS x
) AS x
	ON a.yr = x.yr
	AND a.mnth = x.mnth
	AND a.dy = x.dy

/*Update for Good Friday*/
UPDATE auxiliary.calendar
SET isHoliday = 1, dtDesc = 'Good Friday'
WHERE dt IN (SELECT DATEADD(DAY,-2,dt) FROM auxiliary.calendar WHERE dtDesc IN ('Easter Sunday'))

/*Update market days for floating holidays*/
UPDATE auxiliary.calendar
SET isMarketDay = 0
WHERE wkDyNum IN (1,7)
OR dtDesc IN ('New Year''s Day','Martin Luther King Jr.''s Day','Washington''s Birthday','Independence Day','Good Friday','Memorial Day','Labor Day','Thanksgiving','Christmas')

/*Update market days for fixed days falling on weekends (excl. New Year's Day*/
UPDATE auxiliary.calendar
SET isMarketDay = 0, dtDesc = 'Observation of weekend holiday'
WHERE dt IN (
	SELECT CASE WHEN wkDyNum IN (1) THEN DATEADD(DAY,1,dt) 
		WHEN wkDyNum IN (7) THEN DATEADD(DAY,-1,dt) END AS dt 
	FROM auxiliary.calendar 
	WHERE wkDyNum IN (1,7)
		AND dtDesc IN ('Independence Day','Christmas'))
