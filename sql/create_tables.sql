DROP TYPE IF EXISTS api.simplified_type CASCADE;
CREATE TYPE api.simplified_type as enum (
    'MOVIE',
    'SERIES',
    'EPISODE'
);


DROP TABLE IF EXISTS titles CASCADE;
CREATE TABLE titles (
    tconst char(10) primary key,
    titleType varchar(20),
    primaryTitle text,
    originalTitle text,
    isAdult boolean,
    startYear smallint,
    endYear smallint,
    runtimeMinutes integer,
    genres text,
    simplifiedType api.simplified_type
);


CREATE OR REPLACE FUNCTION titles_simplified_type()
RETURNS trigger as $$
BEGIN
    NEW.simplifiedType := (
        CASE
            WHEN NEW.titleType IN ('tvSeries', 'tvMiniSeries') THEN 'SERIES'
            WHEN NEW.titleType = 'tvEpisode' THEN 'EPISODE'
            ELSE 'MOVIE'
        END
    )::api.simplified_type;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS titles_simplified_type_trigger ON titles CASCADE;
CREATE TRIGGER titles_simplified_type_trigger
    BEFORE INSERT OR UPDATE ON titles
    FOR EACH ROW EXECUTE PROCEDURE titles_simplified_type();


DROP TABLE IF EXISTS episodes CASCADE;
CREATE TABLE episodes (
    tconst char(10) PRIMARY KEY REFERENCES titles(tconst) ON DELETE CASCADE,
    parentTconst char(10) REFERENCES titles(tconst) ON DELETE CASCADE,
    seasonNumber integer,
    episodeNumber integer
);


DROP TABLE IF EXISTS ratings CASCADE;
CREATE TABLE ratings (
    tconst char(10) PRIMARY KEY REFERENCES titles(tconst) ON DELETE CASCADE,
    averageRating real,
    numVotes integer
);
