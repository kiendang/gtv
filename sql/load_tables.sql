\cd :data_dir


-- Insert data into tables
\copy titles(tconst, titletype, primarytitle, originaltitle, isadult, startyear, endyear, runtimeminutes, genres) from program 'gzip -dc title.basics.tsv.gz' delimiter E'\t' null as '\N' csv header quote E'\b';
\copy episodes from program 'gzip -dc title.episode.tsv.gz' delimiter E'\t' null as '\N' csv header quote E'\b';
\copy ratings from program 'gzip -dc title.ratings.tsv.gz' delimiter E'\t' null as '\N' csv header quote E'\b';


-- Build indices
DROP INDEX IF EXISTS titles_idx01;
CREATE INDEX titles_idx01
  ON titles (tconst);

DROP INDEX IF EXISTS titles_idx02;
CREATE INDEX titles_idx02
  ON titles (simplifiedType);


DROP INDEX IF EXISTS episodes_idx01;
CREATE INDEX episodes_idx01
  ON episodes (tconst);

DROP INDEX IF EXISTS episodes_idx02;
CREATE INDEX episodes_idx02
  ON episodes (parentTconst);


DROP INDEX IF EXISTS ratings_idx01;
CREATE INDEX ratings_idx01
  ON ratings (tconst);


-- Clean up
delete from ratings
where tconst = any (select tconst from titles where isAdult);
reindex table ratings;

delete from episodes
where parentTconst = any (select tconst from titles where isAdult);
delete from episodes
where tconst = any (select tconst from titles where isAdult);
reindex table episodes;

delete from titles where isAdult;
reindex table titles;

do $$
declare
   count integer;
begin
   select count(*)
   into count
   from titles
   where isAdult;

   assert count <= 0, 'Cleanup failed';
end $$;
