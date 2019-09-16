-- [ZXDB] Import into ZXDB all links to game maps from "Speccy Screenshot Maps".
-- Simply download latest version of file https://maps.speccy.cz/mapy.txt to the same directory of this script, then run it!
-- by Einar Saukas

USE zxdb;

drop table if exists tmp_mapy;

create table tmp_mapy (
    title varchar(250) not null,
    file_image varchar(250) not null,
    file_res varchar(250) not null,
    file_size varchar(250) not null,
    file_type varchar(250) not null,
    file_date varchar(250) not null,
    comments varchar(250) not null,
    file_text varchar(250) not null,
    none1 varchar(250) not null,
    file_zip varchar(250) not null,
    numb varchar(250) not null,
    author varchar(250) not null,
    id varchar(250) not null,
    genre varchar(250) not null,
    none2 varchar(250) not null
);

load data local infile 'mapy.txt' into table tmp_mapy character set latin2 fields terminated by ';' lines terminated by '\n';

delete from webrefs where website_id = 6;

insert into webrefs(entry_id, link, website_id, idiom_id) (select id, concat('http://maps.speccy.cz/map.php?id=',left(file_image,length(file_image)-4)), 6, 'en' from tmp_mapy where id <> '' and id in (select id from entries) group by id, file_image order by id);

drop table tmp_mapy;

-- END
