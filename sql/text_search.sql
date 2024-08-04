ALTER TABLE titles DROP COLUMN IF EXISTS title_search_col;
ALTER TABLE titles ADD COLUMN title_search_col tsvector;


DROP EXTENSION IF EXISTS unaccent;
CREATE EXTENSION unaccent;


DROP TEXT SEARCH CONFIGURATION IF EXISTS en;
CREATE TEXT SEARCH CONFIGURATION en ( COPY = pg_catalog.english );

ALTER TEXT SEARCH CONFIGURATION en
    ALTER MAPPING FOR hword, hword_part, word
    WITH unaccent, english_stem;


DROP INDEX IF EXISTS titles_text_search_idx;
CREATE INDEX titles_text_search_idx ON titles USING GIN (title_search_col);
UPDATE titles SET title_search_col =
    setweight(to_tsvector('en', coalesce(primaryTitle, '')), 'A') ||
    setweight(to_tsvector('en', coalesce(originalTitle, '')), 'C');


DROP FUNCTION IF EXISTS titles_trigger CASCADE;
CREATE FUNCTION titles_trigger() RETURNS trigger AS $$
begin
    new.title_search_col :=
        setweight(to_tsvector('en', coalesce(new.primaryTitle, '')), 'A') ||
        setweight(to_tsvector('en', coalesce(new.originalTitle, '')), 'C');
    return new;
end
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS ts_vector_titles_trigger ON titles;
CREATE TRIGGER ts_vector_titles_trigger BEFORE INSERT OR UPDATE
    ON titles FOR EACH ROW EXECUTE PROCEDURE titles_trigger();
