drop index if exists title_pgroonga_idx cascade;
create index title_pgroonga_idx on titles using pgroonga (primaryTitle);
