set search_path to api;


drop view if exists titles cascade;
create view titles as (
  select
    tconst,
    titleType as title_type,
    primaryTitle as primary_title,
    originalTitle as original_title,
    startYear as start_year,
    endYear as end_year,
    runtimeMinutes as runtime,
    genres,
    numVotes as num_votes,
    averageRating as average_rating,
    simplifiedType as simplified_type
  from original.titles
  left outer join original.ratings using (tconst)
);


create or replace function title_search(
  search text,
  type api.simplified_type[] default array['MOVIE'::api.simplified_type, 'SERIES'::api.simplified_type]
)
  returns setof titles as $$
    with stg0 as (
      select
        tconst,
        titleType as title_type,
        primaryTitle as primary_title,
        originalTitle as original_title,
        startYear as start_year,
        endYear as end_year,
        runtimeMinutes as runtime,
        genres,
        simplifiedType as simplified_type,
        title_search_col
      from original.titles
      where simplifiedType = any (type)
    )

    , stg1 as (
      select *
      from stg0
      left outer join (
        select
          tconst,
          numVotes as num_votes,
          averageRating as average_rating
        from original.ratings
      ) r using (tconst)
    )

    , stg2 as (
      select *
        , ts_rank_cd(title_search_col, plainto_tsquery(search), 1) as rank
      from stg1
      where plainto_tsquery(search) @@ title_search_col
      order by
        num_votes >= 10000 desc nulls last,
        num_votes >= 1000 desc nulls last,
        primary_title ilike ('%' || search || '%') desc nulls last,
        num_votes / 100 desc nulls last,
        rank desc nulls last,
        start_year desc nulls last
    )

    select
      tconst,
      title_type,
      primary_title,
      original_title,
      start_year,
      end_year,
      runtime,
      genres,
      num_votes,
      average_rating,
      simplified_type
    from stg2
$$ language sql stable;

drop function if exists title_search cascade;


create or replace function title_pgroonga_search(
  search text,
  type api.simplified_type[] default array['MOVIE'::api.simplified_type, 'SERIES'::api.simplified_type]
)
  returns setof titles as $$
    with stg0 as (
      select
        tconst,
        titleType as title_type,
        primaryTitle as primary_title,
        originalTitle as original_title,
        startYear as start_year,
        endYear as end_year,
        runtimeMinutes as runtime,
        genres,
        simplifiedType as simplified_type,
        title_search_col
      from original.titles
      where simplifiedType = any (type)
    )

    , stg1 as (
      select *
      from stg0
      left outer join (
        select
          tconst,
          numVotes as num_votes,
          averageRating as average_rating
        from original.ratings
      ) r using (tconst)
    )

    , stg2 as (
      select *
      from stg1
      where primary_title OPERATOR(original.&@*) search
      order by
        num_votes >= 10000 desc nulls last,
        num_votes >= 1000 desc nulls last,
        primary_title ilike ('%' || search || '%') desc nulls last,
        num_votes / 100 desc nulls last,
        start_year desc nulls last
    )

    select
      tconst,
      title_type,
      primary_title,
      original_title,
      start_year,
      end_year,
      runtime,
      genres,
      num_votes,
      average_rating,
      simplified_type
    from stg2
$$ language sql stable;

comment on function title_pgroonga_search(text, api.simplified_type[]) is
  E'@name titleSearch';


drop view if exists movies cascade;
create view movies as (
  select tconst
  from titles
  where simplified_type = 'MOVIE'::simplified_type
);


drop view if exists series cascade;
create view series as (
  select tconst
  from titles
  where simplified_type = 'SERIES'::simplified_type
);


drop view if exists episodes cascade;
create view episodes as (
  select
    tconst,
    parenttconst,
    seasonNumber as season_number,
    episodeNumber as episode_number
  from original.episodes
);


comment on view movies is $$
  @primaryKey tconst
  @foreignKey (tconst) references titles
  @behavior -singularRelation:resource:single
$$;


comment on view series is $$
  @primaryKey tconst
  @foreignKey (tconst) references titles | @behavior -singularRelation:resource:single
$$;


comment on view episodes is $$
  @primaryKey tconst
  @foreignKey (tconst) references titles
  @foreignKey (parenttconst) references series | @foreignConnectionFieldName episodes
  @behavior -singularRelation:resource:single
$$;


comment on view titles is $$
  @interface mode:relational type:simplified_type
  @type MOVIE name:Movie references:movies
  @type SERIES name:Series references:series
  @type EPISODE name:Episode references:episodes
  @primaryKey tconst
$$;
