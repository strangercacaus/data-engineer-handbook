-- Struct types definition

-- drop type films cascade;

create type films as
     (
         film text,
         votes integer,
         rating real,
         filmid text
     );

-- drop type quality_scoring cascade;

create type quality_scoring as enum ('star','good','average','bad');

-- Cumulative Table definition

drop table actors;

create table actors
    (
        actor_name text,
        actorid text,
        films films[],
        quality_class quality_scoring,
        is_active bool,
        current_year integer
    );

-- Cumulative Actors Insert Query Definition
insert into actors
with
    previous as
(
    select * from actors where current_year = 1970
),
    current as
(
    select
        actorid,
        actor,
        year,
        case
            when year is null then array[]::films[]
            else array_agg(row(film,rating,votes,filmid)::films)
        end as films,
        case
            when year is not null then
                case
                    when avg(rating) > 8 then 'star'
                    when avg(rating) > 7 and avg(rating) <= 8 then 'good'
                    when avg(rating) > 6 and avg(rating) <= 7 then 'average'
                    when avg(rating) <= 6 then 'bad'
                    else null
                end
        end::quality_scoring as quality_class
    from actor_films where year = 1971
    group by actorid, actor, year
)
select
    coalesce(c.actor, p.actor_name) as actor_name,
    coalesce(c.actorid, p.actorid) as actorid,
    case
        when p.films is null then c.films
        when c.films is not null then c.films || p.films
        else p.films
    end as films,
    coalesce(c.quality_class, p.quality_class) as quality_class,
    case
        when c.year is not null then true
        else false
    end as is_active,
    coalesce(c.year, p.current_year + 1) as current_year
from previous p
    full outer join current c
        on c.actor = p.actor_name;


-- Check on actors results

table actors;
