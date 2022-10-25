/*Using the auxiliary integers table*/

/*Params table*/
WITH params AS (SELECT 1000 AS ubound)

/*Identify all primes between 0 and ubound*/
WITH first_thousand AS (
	SELECT i_n.i,i_d.i,i_n.i%i_d.i
	FROM auxiliary.integers AS i_n
	LEFT JOIN auxiliary.integers AS i_d
		ON i_d.i > 1
		AND i_n.i >= i_d.i * 2 -- Convenient cutoff here...  no need to look for divisors > 0.5 * i as these would be non-whole number divisors
		AND i_n.i % i_d.i = 0
    CROSS JOIN params AS p
	WHERE i_d.i IS NULL
		AND i_n.i < p.ubound
	ORDER BY i_n.i
)

/*Ultimately script loses a lot of efficiency through unnecessary and repeated calculation...*/
/* for example, when we're checking whether 21 is prime, the above divides 21 by all integers 2 - 10*/
/* but, if treated ordinally, we would already know that 2, 3, 5, and 7 are Prime and thus only need to check those four numbers, rather than all nine*/
/*We could affect something like this using a recursive loop (i.e. for next number in sequence, divide by all prior primes) ...*/