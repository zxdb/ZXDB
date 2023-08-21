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

insert into search_by_titles (entry_title, entry_id) (select replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(lower(title),' ',''),'-' ,''),'.' ,''),',' ,''),'"' ,''),'''' ,''),'/' ,''),':' ,''),'!' ,''),'[sam]' ,''),'[' ,''),']' ,'') as tt, eid from (select id as eid, title from entries union all select id as eid, replace(title,' II', ' 2') from entries where title REGEXP ' II[ ,:+]' or title like '% II' union all select id as eid, replace(title,' III', ' 3') from entries where title REGEXP ' III[ ,:+]' or title like '% III' union all select id as eid, replace(title,' IV', ' 4') from entries where title REGEXP ' IV[ ,:+]' or title like '% IV' union all select id as eid, replace(title,' V', ' 5') from entries where title REGEXP ' V[ ,:+]' or title like '% V' union all select id as eid, replace(title,' VI', ' 6') from entries where title REGEXP ' VI[ ,:+]' or title like '% VI' union all select id as eid, replace(title,' VII', ' 7') from entries where title REGEXP ' VII[ ,:+]' or title like '% VII' union all select id as eid, replace(title,' VIII', ' 8') from entries where title REGEXP ' VIII[ ,:+]' or title like '% VIII' union all select entry_id as eid, title from aliases union all select entry_id as eid, replace(title,' II', ' 2') from aliases where title REGEXP ' II[ ,:+]' or title like '% II' union all select entry_id as eid, replace(title,' III', ' 3') from aliases where title REGEXP ' III[ ,:+]' or title like '% III' union all select entry_id as eid, replace(title,' IV', ' 4') from aliases where title REGEXP ' IV[ ,:+]' or title like '% IV' union all select entry_id as eid, replace(title,' V', ' 5') from aliases where title REGEXP ' V[ ,:+]' or title like '% V' union all select entry_id as eid, replace(title,' VI', ' 6') from aliases where title REGEXP ' VI[ ,:+]' or title like '% VI' union all select entry_id as eid, replace(title,' VII', ' 7') from aliases where title REGEXP ' VII[ ,:+]' or title like '% VII' union all select entry_id as eid, replace(title,' VIII', ' 8') from aliases where title REGEXP ' VIII[ ,:+]' or title like '% VIII' union all select entry_id as eid, alias as title from contents where alias is not null and entry_id is not null) as x group by tt collate utf8_unicode_ci, eid order by tt, eid);


-- Help search for labels (individuals or companies) by name (in lower case without space or punctuation)

drop table if exists search_by_names;

create table search_by_names (
    label_name varchar(100) collate utf8_unicode_ci not null,
    label_id int(11) not null,
    primary key (label_name, label_id),
    index (label_id)
);

insert into search_by_names (label_name, label_id) (select replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(lower(name),' ',''),'-' ,''),'.' ,''),',' ,''),'"' ,''),'''' ,''),'/' ,''),':' ,''),'!' ,''),'[' ,''),']' ,'') as nn, id from labels group by nn collate utf8_unicode_ci, id order by nn, id);


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
insert into search_tmp1(lid, eid) (select p.label_id, c.entry_id from publishers p inner join contents c on c.container_id = p.entry_id where c.is_original = 1 and p.release_seq = 0);
insert into search_tmp1(lid, eid) (select label_id, container_id from contents where label_id is not null);

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


-- Fancy names for magazine issues

drop table if exists search_by_issues;

create table search_by_issues (
  issue_id int(11) not null primary key,
  name varchar(300) not null
);

drop table if exists tmp_month;

create table tmp_month (
  id smallint(6) not null primary key,
  text varchar(3) not null
);

-- (due to a bug with str_to_date() in certain MySQL versions, it's safer to convert manually!)
insert into tmp_month (id, text) values
(1, 'Jan'),
(2, 'Feb'),
(3, 'Mar'),
(4, 'Apr'),
(5, 'May'),
(6, 'Jun'),
(7, 'Jul'),
(8, 'Aug'),
(9, 'Sep'),
(10, 'Oct'),
(11, 'Nov'),
(12, 'Dec');

insert into search_by_issues(issue_id, name) (select i.id, trim(concat(if(i.volume is not null,concat('v.',i.volume),''),if(i.number is not null,concat(' #',i.number),''),if(i.date_year is not null,concat(' - ',i.date_year,if(i.date_month is not null,concat('/',m.text,if(i.date_day is not null,concat('/',i.date_day),'')),'')),''),if(i.special is not null,concat(' special "',i.special,'"'),''),if(i.supplement is not null,concat(' supplement "',i.supplement,'"'),''))) from issues i left join tmp_month m on i.date_month = m.id);

update search_by_issues set name = trim(substr(name,2)) where name like '- %';
update search_by_issues set name = '?' where name = '';

drop table tmp_month;


-- Help search for magazine publishers

drop table if exists search_by_magazines;

create table search_by_magazines (
    magazine_id smallint(6) not null,
    label_id int(11) not null,
    primary key (magazine_id, label_id),
    index (label_id)
);

insert into search_by_magazines (magazine_id, label_id) (select magazine_id, lid from (select magazine_id, label_id as lid from issues where label_id is not null union all select magazine_id, label2_id as lid from issues where label2_id is not null) as x group by magazine_id, lid);


-- Help search for magazine references

drop table if exists search_tmp0;

create table search_tmp0 (
    eid int(11) not null,
    mid int(11) not null,
    index (eid),
    index (mid)
);

insert into search_tmp0(eid, mid) (select entry_id, id from magrefs where entry_id is not null);
insert into search_tmp0(eid, mid) (select c.entry_id, r.id from magrefs r inner join contents c on r.entry_id = c.container_id where c.entry_id is not null);
insert into search_tmp0(eid, mid) (select c.container_id, r.id from magrefs r inner join contents c on r.entry_id = c.entry_id);
insert into search_tmp0(eid, mid) (select e.id, r.id from magrefs r inner join entries e on r.issue_id = e.issue_id where r.referencetype_id = 21 and e.genretype_id = 81);

drop table if exists search_by_magrefs;

create table search_by_magrefs (
    entry_id int(11) not null,
    magref_id int(11) not null,
    primary key (entry_id, magref_id),
    index (magref_id)
);

insert into search_by_magrefs(entry_id, magref_id) (select eid, mid from search_tmp0 group by eid, mid order by eid, mid);

drop table search_tmp0;


-- Help search for original publication details

drop table if exists search_by_origins;

create table search_by_origins (
  entry_id int(11) not null primary key,
  library_title varchar(300) collate utf8_unicode_ci not null,
  origintype_id char(1) not null,
  container_id int(11),
  issue_id int(11),
  date_year smallint(6),
  date_month smallint(6),
  date_day smallint(6),
  publication varchar(300),
  index (origintype_id),
  index (container_id, origintype_id),
  index (issue_id, origintype_id)
);

-- Covertapes
insert into search_by_origins(entry_id, library_title, origintype_id, container_id, issue_id, date_year, date_month, date_day) (select e.id, e.title, 'C', null, e.issue_id, i.date_year, i.date_month, i.date_day from entries e inner join issues i on e.issue_id = i.id where e.genretype_id = 81 and e.id not in (select entry_id from search_by_origins));

-- Book type-ins
insert into search_by_origins(entry_id, library_title, origintype_id, container_id, issue_id, date_year, date_month, date_day) (select b.entry_id, e.title, 'B', b.book_id, null, r.release_year, r.release_month, r.release_day from booktypeins b inner join entries e on b.entry_id = e.id inner join entries k on b.book_id = k.id inner join releases r on r.entry_id = k.id and r.release_seq = 0 where b.is_original = 1 and b.entry_id not in (select entry_id from search_by_origins));

-- Magazine type-ins
insert into search_by_origins(entry_id, library_title, origintype_id, container_id, issue_id, date_year, date_month, date_day) (select x.entry_id, x.title, 'M', null, x.issue_id, i.date_year, i.date_month, i.date_day from (select r.entry_id, e.title, min(r.issue_id) as issue_id from magrefs r inner join entries e on e.id = r.entry_id where r.is_original = 1 group by e.id) as x inner join issues i on x.issue_id = i.id where x.entry_id not in (select entry_id from search_by_origins));

-- Within covertape
insert into search_by_origins(entry_id, library_title, origintype_id, container_id, issue_id, date_year, date_month, date_day) (select c.entry_id, e.title, 'T', c.container_id, i.id, i.date_year, i.date_month, i.date_day from contents c inner join entries e on c.entry_id = e.id inner join entries k on c.container_id = k.id inner join issues i on k.issue_id = i.id where c.is_original = 1 and k.genretype_id = 81 and c.entry_id not in (select entry_id from search_by_origins) group by c.entry_id);

-- Within all
insert into search_by_origins(entry_id, library_title, origintype_id, container_id, issue_id, date_year, date_month, date_day) (select c.entry_id, e.title, (case when k.genretype_id in (80,111,112,113,114) then 'A' when k.genretype_id = 81 then 'T' when k.genretype_id = 82 then 'E' else 'P' end), c.container_id, null, r.release_year, r.release_month, r.release_day from contents c inner join entries e on c.entry_id = e.id inner join entries k on c.container_id = k.id inner join releases r on r.entry_id = k.id and r.release_seq = 0 where c.is_original = 1 and c.entry_id not in (select entry_id from search_by_origins) group by c.entry_id);

-- Original publication
update search_by_origins a inner join (select x.entry_id,concat(coalesce(m.name,group_concat(b.name ORDER BY p.publisher_seq SEPARATOR ', '),'?'),' - ',t.text,' ', if(k.title is not null,concat('"',k.title,'"'),if(i.id is not null,s.name,'?'))) as publication from search_by_origins x inner join origintypes t on x.origintype_id = t.id left join issues i on x.issue_id = i.id left join search_by_issues s on s.issue_id = i.id left join magazines m on i.magazine_id = m.id left join entries k on x.container_id = k.id left join releases r on r.entry_id = k.id and r.release_seq = 0 left join publishers p on p.entry_id = k.id and p.release_seq = 0 left join labels b on b.id = p.label_id group by x.entry_id) as y on a.entry_id = y.entry_id set a.publication = y.publication;

-- Standalone releases
insert into search_by_origins(entry_id, library_title, origintype_id, date_year, date_month, date_day, publication) (select e.id, e.title, 'S', r.release_year, r.release_month, r.release_day, group_concat(b.name ORDER BY p.publisher_seq SEPARATOR ', ') from entries e inner join releases r on r.entry_id = e.id and r.release_seq = 0 left join publishers p on p.entry_id = e.id and p.release_seq = 0 left join labels b on b.id = p.label_id where e.id not in (select entry_id from search_by_origins) group by e.id);

-- Library title
update search_by_origins s inner join prefixes p on s.library_title like concat(p.text,'%') left join prefixexempts x on s.library_title like concat(x.text,'%') set s.library_title = trim(concat(substr(s.library_title,length(p.text)+1),', ',left(s.library_title, length(p.text)))) where x.text is null;


-- Help search for aliases

drop table if exists search_by_aliases;

create table search_by_aliases (
  entry_id int(11) not null,
  title varchar(250) not null,
  library_title varchar(300) collate utf8_unicode_ci not null,
  primary key(entry_id, title)
);

insert into search_by_aliases(entry_id, title, library_title) (select entry_id, title, title from aliases group by entry_id, title);

update search_by_aliases s inner join prefixes p on s.library_title like concat(p.text,'%') left join prefixexempts x on s.library_title like concat(x.text,'%') set s.library_title = trim(concat(substr(s.library_title,length(p.text)+1),', ',left(s.library_title, length(p.text)))) where x.text is null;

-- END
