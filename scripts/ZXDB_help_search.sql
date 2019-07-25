-- [ZXDB] Create auxiliary tables to help database searches. They are only needed for systems that perform ZXDB searches directly in the database.
-- by Einar Saukas

USE zxdb;


-- Help search for entries (programs, books, computers and peripherals) by title or aliases (in lower case without space or punctuation)

drop table if exists search_by_titles;

create table search_by_titles (
    entry_title varchar(250) collate utf8_unicode_ci not null,
    entry_id integer not null,
    primary key (entry_title, entry_id),
    index (entry_id)
);

insert into search_by_titles (entry_title, entry_id) (select replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(lower(title),' ',''),'-' ,''),'.' ,''),',' ,''),'"' ,''),'''' ,''),'/' ,''),':' ,''),'!' ,''),'[sam]' ,''),'[' ,''),']' ,'') as tt, eid from (select id as eid, title from entries union all select id as eid, replace(title,' II', ' 2') from entries where title REGEXP ' II[ ,:+]' or title like '% II' union all select id as eid, replace(title,' III', ' 3') from entries where title REGEXP ' III[ ,:+]' or title like '% III' union all select id as eid, replace(title,' IV', ' 4') from entries where title REGEXP ' IV[ ,:+]' or title like '% IV' union all select id as eid, replace(title,' V', ' 5') from entries where title REGEXP ' V[ ,:+]' or title like '% V' union all select id as eid, replace(title,' VI', ' 6') from entries where title REGEXP ' VI[ ,:+]' or title like '% VI' union all select id as eid, replace(title,' VII', ' 7') from entries where title REGEXP ' VII[ ,:+]' or title like '% VII' union all select id as eid, replace(title,' VIII', ' 8') from entries where title REGEXP ' VIII[ ,:+]' or title like '% VIII' union all select entry_id as eid, title from aliases union all select entry_id as eid, replace(title,' II', ' 2') from aliases where title REGEXP ' II[ ,:+]' or title like '% II' union all select entry_id as eid, replace(title,' III', ' 3') from aliases where title REGEXP ' III[ ,:+]' or title like '% III' union all select entry_id as eid, replace(title,' IV', ' 4') from aliases where title REGEXP ' IV[ ,:+]' or title like '% IV' union all select entry_id as eid, replace(title,' V', ' 5') from aliases where title REGEXP ' V[ ,:+]' or title like '% V' union all select entry_id as eid, replace(title,' VI', ' 6') from aliases where title REGEXP ' VI[ ,:+]' or title like '% VI' union all select entry_id as eid, replace(title,' VII', ' 7') from aliases where title REGEXP ' VII[ ,:+]' or title like '% VII' union all select entry_id as eid, replace(title,' VIII', ' 8') from aliases where title REGEXP ' VIII[ ,:+]' or title like '% VIII' union all select entry_id as eid, alias as title from compilations where alias is not null and entry_id is not null ) as x group by tt, eid order by tt, eid);


-- Help search for labels (individuals or companies) by name (in lower case without space or punctuation)

drop table if exists search_by_names;

create table search_by_names (
    label_name varchar(100) collate utf8_unicode_ci not null,
    label_id integer not null,
    primary key (label_name, label_id),
    index (label_id)
);

insert into search_by_names (label_name, label_id) (select replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(lower(name),' ',''),'-' ,''),'.' ,''),',' ,''),'"' ,''),'''' ,''),'/' ,''),':' ,''),'!' ,''),'[' ,''),']' ,'') as nn, id from labels group by nn, id order by nn, id);


-- Help search for entries (programs, books, computers and peripherals) by authors

drop table if exists search_by_authors;

create table search_by_authors (
    label_id integer not null,
    entry_id integer not null,
    primary key (label_id, entry_id),
    index (entry_id)
);

insert into search_by_authors(label_id, entry_id) (select lid, eid from (select x.label_id as lid, x.entry_id as eid from (select entry_id, label_id from authors union all select entry_id, team_id as label_id from authors) as x union all select l2.id as lid, x.entry_id as eid from (select entry_id, label_id from authors union all select entry_id, team_id as label_id from authors) as x inner join labels l1 on x.label_id = l1.id inner join labels l2 on l2.id = l1.from_id or l2.id = l1.owner_id union all select l2.id as lid, x.entry_id as eid from (select entry_id, label_id from authors union all select entry_id, team_id as label_id from authors) as x inner join labels l1 on x.label_id = l1.id inner join labels l2 on (l1.id = l2.from_id or l1.id = l2.owner_id) and (l2.labeltype_id is null or l2.labeltype_id in ('+','-'))) as y where lid is not null group by lid, eid order by lid, eid);


-- Help search for entries (programs, books, computers and peripherals) by publishers

drop table if exists search_by_publishers;

create table search_by_publishers (
    label_id integer not null,
    entry_id integer not null,
    primary key (label_id, entry_id),
    index (entry_id)
);

insert into search_by_publishers(label_id, entry_id) (select lid, eid from (select x.label_id as lid, x.entry_id as eid from publishers x union all select l2.id as lid, x.entry_id as eid from publishers x inner join labels l1 on x.label_id = l1.id inner join labels l2 on l2.id = l1.from_id or l2.id = l1.owner_id union all select l2.id as lid, x.entry_id as eid from publishers x inner join labels l1 on x.label_id = l1.id inner join labels l2 on (l1.id = l2.from_id or l1.id = l2.owner_id) and (l2.labeltype_id is null or l2.labeltype_id in ('+','-'))) as y where lid is not null group by lid, eid order by lid, eid);


-- Examples

select * from entries where id in (select entry_id from search_by_titles where entry_title like '%sokoban%') order by title;
select * from labels where id in (select label_id from search_by_names where label_name like '%zxsoft%') order by name;
select * from entries where id in (select entry_id from search_by_authors a inner join search_by_names n on a.label_id = n.label_id where label_name like '%joffa%') order by title; -- Joffa
select * from entries where id in (select entry_id from search_by_publishers p inner join search_by_names n on p.label_id = n.label_id where label_name like '%zxsoftbr%') order by title; -- ZX-SOFT Brasil Ltda


-- END
