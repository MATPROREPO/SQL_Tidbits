/*Script is designed for use in T-SQL; similar functionality can be acheived in PL SQL through use of the DUAL table,
or through DB2 through use of the SYSIBM.SYSDUMMY1 table*/
/*Script returns a series of unsorted integers between 0 and 2^10-1*/
SELECT i0.i + i1.i + i2.i + i3.i + i4.i + i5.i + i6.i + i7.i + i8.i + i9.i + i10.i
FROM (SELECT 0 AS i UNION SELECT POWER(2,0)) AS i0
CROSS JOIN (SELECT 0 AS i UNION SELECT POWER(2,1)) AS i1
CROSS JOIN (SELECT 0 AS i UNION SELECT POWER(2,2)) AS i2
CROSS JOIN (SELECT 0 AS i UNION SELECT POWER(2,3)) AS i3
CROSS JOIN (SELECT 0 AS i UNION SELECT POWER(2,4)) AS i4
CROSS JOIN (SELECT 0 AS i UNION SELECT POWER(2,5)) AS i5
CROSS JOIN (SELECT 0 AS i UNION SELECT POWER(2,6)) AS i6
CROSS JOIN (SELECT 0 AS i UNION SELECT POWER(2,7)) AS i7
CROSS JOIN (SELECT 0 AS i UNION SELECT POWER(2,8)) AS i8
CROSS JOIN (SELECT 0 AS i UNION SELECT POWER(2,9)) AS i9
CROSS JOIN (SELECT 0 AS i UNION SELECT POWER(2,10)) AS i10
