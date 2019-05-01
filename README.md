# SQL_Tidbits
Various SQL scripts for functions, functional tables, etc.

## Auxiliary tables
Creation of several useful auxiliary tables for use in other queries:
* Integers: utilizing binary multiplication, constructs a table consisting only of integers 0 through 2^n-1
* Calendar: relies upon the integer auxiliary table, constructs a table of dates, including useful fields like week number, holiday name, a market day flag, etc.
