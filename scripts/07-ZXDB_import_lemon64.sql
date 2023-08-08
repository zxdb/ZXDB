-- [ZXDB] Import into ZXDB all links from lemon64.
-- Simply download latest version of https://www.lemon64.com/games/export/?key=9zU47xNvqXWg to the same directory of this script, then run it!
-- by Einar Saukas

USE zxdb;

drop table if exists tmp_lemon;

create table tmp_lemon (
    lemon_name varchar(250) not null,
    lemon_slug varchar(250) not null,
    lemon_id int(11) not null primary key,
    spectrum_id varchar(250),
    date_added varchar(250) not null,
    date_year int(4),
    publisher varchar(250),
    genre varchar(250) not null
);

load data local infile 'www.lemon64.com.html' into table tmp_lemon character set latin2 fields terminated by '\t' lines terminated by '\n' ignore 3 lines;

delete from tmp_lemon where lemon_name = '</body></html>';
update tmp_lemon set lemon_name = replace(lemon_name, '&amp;', '&') where lemon_name like '%&amp;%';
update tmp_lemon set spectrum_id=null where spectrum_id='';
update tmp_lemon set date_year=null where date_year=0;
update tmp_lemon set publisher=null where publisher='(unknown)';
update tmp_lemon set genre=replace(genre, '</body></html>', '') where genre like '%</body></html>%';
alter table tmp_lemon add column entry_id int(11);
alter table tmp_lemon add constraint fk_lemon_entry foreign key (entry_id) references entries(id);
update tmp_lemon set entry_id=SUBSTRING_INDEX(spectrum_id,'/',1) where spectrum_id is not null;
alter table tmp_lemon add column lemon_link varchar(250);
update tmp_lemon set lemon_link=concat('https://www.lemon64.com/game/',lemon_slug) where lemon_slug is not null;

-- List mutual links stored in lemon64 but not in ZXDB
select * from entries e
inner join tmp_lemon x on e.id = x.entry_id
left join ports p on p.entry_id = e.id and p.platform_id = 7 and p.link_system = x.lemon_link
where p.id is null;

-- List mutual links stored in ZXDB but not in lemon64 (except never released titles)
select * from entries e
inner join ports p on p.entry_id = e.id and p.platform_id = 7
left join tmp_lemon x on e.id = x.entry_id and p.link_system = x.lemon_link
where p.link_system like 'https://www.lemon64.com/%'
and (coalesce(e.availabletype_id,'') <> 'N' or e.id in (select entry_id from downloads where filetype_id in (8,10,11)))
and x.lemon_id is null;

-- List elsewhere links stored in ZXDB that don't exist in lemon64 (except never released titles)
select * from entries e
inner join ports p on p.entry_id = e.id and p.platform_id = 7
left join tmp_lemon x on e.id = x.entry_id
where p.link_system is not null
and p.link_system not like 'https://www.lemon64.com/%'
and p.link_system not like 'https://www.gamesthatwerent.com/%'
and x.lemon_id is null
order by e.title;

-- List of ZXDB titles missing links to corresponding C64 titles
select e.id,e.title,GROUP_CONCAT(b.name ORDER BY k.publisher_seq SEPARATOR ' / ') as publishers
from entries e
inner join ports p on p.entry_id = e.id and p.platform_id = 7
left join publishers k on k.entry_id = e.id and k.release_seq = 0 
left join labels b on k.label_id = b.id
where coalesce(e.genretype_id,0) < 80
and p.link_system is null
group by e.id
order by e.title;

drop table tmp_lemon;

-- END
