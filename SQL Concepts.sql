-- THE BELOW ARE SQL EXAMPLES WITH PSUEDO-CODE TO DISPLAY CONCEPTS OF HOW THE VARIOUS METHODS WORK

/* CTE EXAMPLES */

--T-SQL, SQL Server

;With CTE as (select * from sometable), 
select * from CTE 

-- Snowflake/Postrgres/etc. 

With CTE as (select * from sometable) 
select * from CTE

/* PIVOT */ 

-- Snowflake, using ANY condition

select * from sometable /*source table/query */ 
pivot(count(condition) for items in (ANY ORDER BY DATE DESC)) /*pivot with aggregate condition */


/* LEAD/LAG */ 
select 
  field1, 
  field2, 
  lead(field2, 1)over(partition by field3 order by field1) as field4 -- This function pulls a row based on the set offset for the next row based on the order-by clause (lag pulls the previous row based on the same condition)
from sometable 

/* OTHER FUNCTIONS & WINDOW FUNCITONS */ 

-- deduplicaiton with distinct

select distinct ID, * from sometable 

-- deduplication with row_number() 
select * exclude rn  from ( -- excluding erroneous rn field
select 
  *, 
  row_number()over(partition by ID order by DateTime desc) as rn 
from sometable ) -- T-SQL would require an alias here, but snowflake/postgres does not
where rn = 1 


-- All togehter 

WITH CTE as (select
                ID, 
                DATETIME,
                WEBSITELOGINCHANNEL, 
                USERNAME, 
                COUNT(DISTINCT ) as field2ct
              from sometable
              GROUP BY ALL ), -- This portion of the query gives a count of each of the rows, but it's not completely aggregating them , this is still row-level data based on normal table design
CTE2 as (select 
            *, 
            LEAD(DATETIME, 1)OVER(PARTITION BY USERNAME ORDER BY DATETIME DESC) as LAST_LOGIN_TIME,  -- since I am using DATETIME DESC and this is looking at the next row, this is pulling the previous datetime for each username
            CASE 
              WHEN LEAD(DATETIME, 1)OVER(PARTITION BY USERNAME ORDER BY DATETIME DESC) is not null then DATEDIFF(day, LEAD(DATETIME, 1)OVER(PARTITION BY USERNAME ORDER BY DATETIME DESC), datetime)
              else 0
            END as DAYS_SINCE_PREVIOUS_LOGIN -- this is the datediff case statement to show this and replace any null values (i.e. no prior login) with 0 
      from CTE), 
--- This is purely an example of how you could join this back to the previous table, but it's redundant and inefficient in the CTE to do this this way
ALTJOINTEXAMPLE AS (select CTE.*, CTE2.* EXCLUDE (ID, DATETIME, WEBSITELOGINCHANNEL) from CTE 
            left join CTE2 
            on CTE.DATETIME = CTE2.DATETIME 
            and CTE.USERNAME = CTE2.USERNAME)
select * from CTE2

    
