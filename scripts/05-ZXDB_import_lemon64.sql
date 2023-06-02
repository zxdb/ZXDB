-- [ZXDB] Import into ZXDB all links from lemon64.
-- Simply download latest version of https://www.lemon64.com/games/export/?key=9zU47xNvqXWg to the same directory of this script, then run it!
-- by Einar Saukas

USE zxdb;

drop table if exists tmp_lemon;

create table tmp_lemon (
    lemon64_name varchar(250) not null,
    lemon64_slug varchar(250) not null,
    lemon64_id int(11),
    spectrum_id varchar(250) not null,
    date_added varchar(250) not null
);

load data local infile 'www.lemon64.com.html' into table tmp_lemon character set latin2 fields terminated by '\t' lines terminated by '\n' ignore 3 lines;

delete from tmp_lemon where lemon64_name = '</body></html>';
alter table tmp_lemon modify column lemon64_id int(11) not null primary key;
update tmp_lemon set lemon64_name = replace(lemon64_name, '&amp;', '&') where lemon64_name like '%&amp;%';
alter table tmp_lemon add column entry_id int(11);
alter table tmp_lemon add constraint fk_lemon_entry foreign key (entry_id) references entries(id);
update tmp_lemon set entry_id=SUBSTRING_INDEX(spectrum_id,'/',1) where spectrum_id is not null;
alter table tmp_lemon modify column entry_id int(11) not null;
alter table tmp_lemon add column lemon64_link varchar(250);
update tmp_lemon set lemon64_link=concat('https://www.lemon64.com/game/',lemon64_slug) where lemon64_slug is not null;

-- List mutual links stored in lemon64 but not in ZXDB
select * from entries e
inner join tmp_lemon x on e.id = x.entry_id
left join ports p on p.entry_id = e.id and p.platform_id = 7 and p.link_system = x.lemon64_link
where p.id is null;

-- List mutual links stored in ZXDB but not in lemon64 (except never released titles)
select * from entries e
inner join ports p on p.entry_id = e.id and p.platform_id = 7
left join tmp_lemon x on e.id = x.entry_id and p.link_system = x.lemon64_link
where p.link_system like 'https://www.lemon64.com/%'
and (coalesce(e.availabletype_id,'') <> 'N' or e.id in (select entry_id from downloads where filetype_id in (8,10,11)))
and x.lemon64_id is null;

-- List elsewhere links stored in ZXDB that don't exist in lemon64 (except never released titles)
select * from entries e
inner join ports p on p.entry_id = e.id and p.platform_id = 7
left join tmp_lemon x on e.id = x.entry_id
where p.link_system is not null
and p.link_system not like 'https://www.lemon64.com/%'
and p.link_system not like 'https://www.gamesthatwerent.com/%'
and x.lemon64_id is null
order by e.title;

-- List of ZXDB titles missing links to corresponding C64 titles
select * from entries e
inner join ports p on p.entry_id = e.id and p.platform_id = 7
where coalesce(e.genretype_id,0) < 80
and p.link_system is null
order by e.title;

drop table tmp_lemon;

-- END
