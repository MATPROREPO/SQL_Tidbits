CREATE TABLE auxiliary.calendar (dt DATETIME, yr INT, qtr INT, mnth INT, wk INT, dy INT, dyNum INT, wkDyNum INT
	, mnthNme VARCHAR(10), dyNme VARCHAR(10), isWeekday BIT, isHoliday BIT, isMarketDay BIT, isLeapYear BIT
	, isLeapDay BIT, dtDesc VARCHAR(25),mthWk INT, mthDy INT)

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
	,NULL AS isHoliday
	,NULL AS isMarketDay
	/*Leap year logic from https://en.wikipedia.org/wiki/Leap_year */
	,CASE WHEN YEAR(dt.dt) % 4 = 0 AND YEAR(dt.dt) % 100 <> 0 OR YEAR(dt.dt) % 400 = 0 THEN 1 ELSE 0 END AS isLeapYear
	,CASE WHEN YEAR(dt.dt) % 4 = 0 AND YEAR(dt.dt) % 100 <> 0 OR YEAR(dt.dt) % 400 = 0 THEN CASE WHEN MONTH(dt.dt) = 2 AND DAY(dt.dt) = 29 THEN 1 ELSE 0 END ELSE 0 END AS isLeapDay
	,NULL AS dtDesc
	,NULL AS mthWk
	,NULL AS mthDy
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
SET a.mthWk = c.cnt
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
SET a.mthDy = c.cnt
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

/*Holidays*/
UPDATE auxiliary.calendar
SET isHoliday = 1
	,dtDesc = CASE WHEN mnth IN (1) AND dy IN (1) THEN 'New Year''s Day'
		WHEN mnth IN (7) AND dy IN (4) THEN 'Independence Day'
		WHEN mnth IN (11) AND dy IN (11) THEN 'Veteran''s Day'
		WHEN mnth IN (12) AND dy IN (25) THEN 'Christmas'
		WHEN mnth IN (1) AND wkDyNum IN (2) AND mthDy IN (3) THEN 'Martin Luther King Jr.''s Day'
		WHEN mnth IN (2) AND wkDyNum IN (2) AND mthDy IN (3) THEN 'Washington''s Birthday'


		WHEN wk IN (3) AND wkDyNum IN (2) THEN 'Birthday of Martin Luther King Jr.'
		WHEN 
