-- [ZXDB] Import into ZXDB all links to RZX files and videos from "RZX Archive".
-- Simply download latest version of file https://spectrumcomputing.co.uk/RZXArchiveZXDB.txt to the same directory of this script, then run it!
-- by Einar Saukas

USE zxdb;

drop table if exists tmp_rzx;

create table tmp_rzx (
    game varchar(250) not null,
    wos_id varchar(250),
    zxdb_id varchar(250),
    video_id varchar(250) not null,
    youtube_url varchar(250),
    embed_html varchar(250) not null,
    download_url varchar(250) not null,
    last_updated varchar(250) not null
);

load data local infile 'RZXArchiveZXDB.txt' into table tmp_rzx character set latin2 fields terminated by '\t' lines terminated by '\n' ignore 1 lines;

update tmp_rzx set wos_id = null where wos_id = 'NULL';
update tmp_rzx set zxdb_id = wos_id where zxdb_id = 'NULL';
update tmp_rzx set youtube_url = null where youtube_url in ('NULL', 'https://youtu.be/');

delete from webrefs where website_id in (15,16);

insert into webrefs(entry_id, link, website_id, idiom_id) (select zxdb_id, download_url, 15, 'en' from tmp_rzx where zxdb_id is not null and download_url is not null order by zxdb_id);
insert into webrefs(entry_id, link, website_id, idiom_id) (select zxdb_id, youtube_url, 16, 'en' from tmp_rzx where zxdb_id is not null and youtube_url is not null order by zxdb_id);

drop table tmp_rzx;

-- END
