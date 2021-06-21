-- [ZXDB] Create auxiliary tables to help database searches. They are only needed for systems that perform ZXDB searches directly in the database.
-- by Einar Saukas

USE zxdb;


-- Help search for entries (programs, books, computers and peripherals) by title or aliases (in lower case without space or punctuation)

drop table if exists search_by_titles;

create table search_by_titles (
    entry_title varchar(250) collate utf8_unicode_ci not null,
    entry_id int(11) not null,
    primary key (entry_title, entry_id),
    index (entry_id)
);

insert into search_by_titles (entry_title, entry_id) (select replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(lower(title),' ',''),'-' ,''),'.' ,''),',' ,''),'"' ,''),'''' ,''),'/' ,''),':' ,''),'!' ,''),'[sam]' ,''),'[' ,''),']' ,'') as tt, eid from (select id as eid, title from entries union all select id as eid, replace(title,' II', ' 2') from entries where title REGEXP ' II[ ,:+]' or title like '% II' union all select id as eid, replace(title,' III', ' 3') from entries where title REGEXP ' III[ ,:+]' or title like '% III' union all select id as eid, replace(title,' IV', ' 4') from entries where title REGEXP ' IV[ ,:+]' or title like '% IV' union all select id as eid, replace(title,' V', ' 5') from entries where title REGEXP ' V[ ,:+]' or title like '% V' union all select id as eid, replace(title,' VI', ' 6') from entries where title REGEXP ' VI[ ,:+]' or title like '% VI' union all select id as eid, replace(title,' VII', ' 7') from entries where title REGEXP ' VII[ ,:+]' or title like '% VII' union all select id as eid, replace(title,' VIII', ' 8') from entries where title REGEXP ' VIII[ ,:+]' or title like '% VIII' union all select entry_id as eid, title from aliases union all select entry_id as eid, replace(title,' II', ' 2') from aliases where title REGEXP ' II[ ,:+]' or title like '% II' union all select entry_id as eid, replace(title,' III', ' 3') from aliases where title REGEXP ' III[ ,:+]' or title like '% III' union all select entry_id as eid, replace(title,' IV', ' 4') from aliases where title REGEXP ' IV[ ,:+]' or title like '% IV' union all select entry_id as eid, replace(title,' V', ' 5') from aliases where title REGEXP ' V[ ,:+]' or title like '% V' union all select entry_id as eid, replace(title,' VI', ' 6') from aliases where title REGEXP ' VI[ ,:+]' or title like '% VI' union all select entry_id as eid, replace(title,' VII', ' 7') from aliases where title REGEXP ' VII[ ,:+]' or title like '% VII' union all select entry_id as eid, replace(title,' VIII', ' 8') from aliases where title REGEXP ' VIII[ ,:+]' or title like '% VIII' union all select entry_id as eid, alias as title from compilations where alias is not null and entry_id is not null ) as x group by tt, eid order by tt, eid);


-- Help search for labels (individuals or companies) by name (in lower case without space or punctuation)

drop table if exists search_by_names;

create table search_by_names (
    label_name varchar(100) collate utf8_unicode_ci not null,
    label_id int(11) not null,
    primary key (label_name, label_id),
    index (label_id)
);

insert into search_by_names (label_name, label_id) (select replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(lower(name),' ',''),'-' ,''),'.' ,''),',' ,''),'"' ,''),'''' ,''),'/' ,''),':' ,''),'!' ,''),'[' ,''),']' ,'') as nn, id from labels group by nn, id order by nn, id);


-- Help search for entries (programs, books, computers and peripherals) by authors

drop table if exists search_tmp0;

create table search_tmp0 (
    eid int(11) not null,
    lid int(11) not null,
    index (eid),
    index (lid)
);

insert into search_tmp0(eid, lid) (select entry_id, label_id from authors);
insert into search_tmp0(eid, lid) (select entry_id, team_id from authors where team_id is not null);
insert into search_tmp0(eid, lid) (select x.entry_id, l2.id from (select entry_id, label_id from authors union all select entry_id, team_id as label_id from authors where team_id is not null) as x inner join labels l1 on x.label_id = l1.id inner join labels l2 on l2.id = l1.from_id or l2.id = l1.owner_id);
insert into search_tmp0(eid, lid) (select x.entry_id, l2.id from (select entry_id, label_id from authors union all select entry_id, team_id as label_id from authors where team_id is not null) as x inner join labels l1 on x.label_id = l1.id inner join labels l2 on l1.id = l2.from_id where l2.labeltype_id is null or l2.labeltype_id in ('+','-'));
insert into search_tmp0(eid, lid) (select x.entry_id, l2.id from (select entry_id, label_id from authors union all select entry_id, team_id as label_id from authors where team_id is not null) as x inner join labels l1 on x.label_id = l1.id inner join labels l2 on l1.id = l2.owner_id where l2.labeltype_id is null or l2.labeltype_id in ('+','-'));

drop table if exists search_by_authors;

create table search_by_authors (
    label_id int(11) not null,
    entry_id int(11) not null,
    primary key (label_id, entry_id),
    index (entry_id)
);

insert into search_by_authors(label_id, entry_id) (select lid, eid from search_tmp0 where lid is not null group by lid, eid order by lid, eid);

drop table search_tmp0;


-- Help search for entries (programs, books, computers and peripherals) by publishers

drop table if exists search_tmp1;

create table search_tmp1 (
    eid int(11) not null,
    lid int(11) not null,
    index (eid),
    index (lid)
);

insert into search_tmp1(lid, eid) (select label_id, entry_id from publishers);
insert into search_tmp1(lid, eid) (select p.label_id, c.entry_id from publishers p inner join compilations c on c.compilation_id = p.entry_id where c.is_original = 1 and p.release_seq = 0);
insert into search_tmp1(lid, eid) (select label_id, compilation_id from compilations where label_id is not null);

drop table if exists search_tmp2;

create table search_tmp2 (
    eid int(11) not null,
    lid int(11) not null,
    index (eid),
    index (lid)
);

insert into search_tmp2(lid, eid) (select lid, eid from search_tmp1);
insert into search_tmp2(lid, eid) (select b.from_id, x.eid from search_tmp1 x inner join labels b on x.lid = b.id where b.from_id is not null);
insert into search_tmp2(lid, eid) (select b.owner_id, x.eid from search_tmp1 x inner join labels b on x.lid = b.id where b.owner_id is not null);
insert into search_tmp2(lid, eid) (select b.id, x.eid from search_tmp1 x inner join labels b on x.lid = b.owner_id and (b.labeltype_id is null or b.labeltype_id in ('+','-')));
insert into search_tmp2(lid, eid) (select b.id, x.eid from search_tmp1 x inner join labels b on x.lid = b.from_id and (b.labeltype_id is null or b.labeltype_id in ('+','-')));

drop table if exists search_by_publishers;

create table search_by_publishers (
    label_id int(11) not null,
    entry_id int(11) not null,
    primary key (label_id, entry_id),
    index (entry_id)
);

insert into search_by_publishers(label_id, entry_id) (select lid, eid from search_tmp2 group by lid, eid order by lid, eid);

drop table search_tmp1;
drop table search_tmp2;


-- Example: Search for all entries with title similar to "sokoban"
select * from entries where id in (select entry_id from search_by_titles where entry_title like '%sokoban%') order by title;

-- Example: Search for all labels (person or company) with name similar to "zxsoft"
select * from labels where id in (select label_id from search_by_names where label_name like '%zxsoft%') order by name;

-- Example: Search for all entries authored by someone with name similar to "joffa"
select * from entries where id in (select entry_id from search_by_authors a inner join search_by_names n on a.label_id = n.label_id where label_name like '%joffa%') order by title;

-- Example: Search for all entries published by someone with name similar to "zxsoftbr"
select * from entries where id in (select entry_id from search_by_publishers p inner join search_by_names n on p.label_id = n.label_id where label_name like '%zxsoftbr%') order by title;


-- END
