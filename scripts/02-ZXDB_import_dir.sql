-- [ZXDB] Import into ZXDB the list of files stored at SC obtained from:
--        find zxdb/sinclair -type f -printf \'%s\t/%p\t\' -exec md5sum \{\} \;
-- by Einar Saukas

USE zxdb;

create table tmp_dir (
    file_size int(11) not null,
    file_link varchar(250) not null primary key,
    file_md5 varchar(32) not null
);

load data local infile 'dir.txt' into table tmp_dir character set latin2 fields terminated by '\t' lines terminated by '\n';

select * from tmp_dir where file_link not in (select file_link from downloads) and file_link not in (select file_link from files) and file_link not in (select file_link from scraps where file_link is not null) order by file_link;

select * from downloads where file_link like '/zxdb/%' and file_link not in (select file_link from tmp_dir) order by file_link;
select * from files where file_link like '/zxdb/%' and file_link not in (select file_link from tmp_dir) order by file_link;
select * from scraps where file_link like '/zxdb/%' and file_link not in (select file_link from tmp_dir) order by file_link;

update downloads set file_md5 = null where file_md5 is not null;
update files set file_md5 = null where file_md5 is not null;

update downloads d inner join tmp_dir t on d.file_link = t.file_link set d.file_size = t.file_size, d.file_md5 = t.file_md5 where d.file_link like '/zxdb/%';
update files d inner join tmp_dir t on d.file_link = t.file_link set d.file_size = t.file_size, d.file_md5 = t.file_md5 where d.file_link like '/zxdb/%';
update scraps d inner join tmp_dir t on d.file_link = t.file_link set d.file_size = t.file_size where d.file_link like '/zxdb/%';

drop table tmp_dir;

-- END
