-- [ZXDB] Import into ZXDB the list of files stored at SC obtained from "find zxdb/sinclair -type f -printf \'%s\t/%p\n\'".
-- by Einar Saukas

USE zxdb;

create table tmp_dir (
    file_size int(11) not null,
    file_link varchar(250) not null primary key
);

load data local infile 'dir.txt' into table tmp_dir character set latin2 fields terminated by '\t' lines terminated by '\n';

select * from tmp_dir where file_link not in (select file_link from downloads) and file_link not in (select file_link from magfiles) and file_link not in (select file_link from labelfiles) and file_link not in (select file_link from extras where file_link is not null) order by file_link;

select * from downloads where file_link like '/zxdb/%' and file_link not in (select file_link from tmp_dir) order by file_link;
select * from magfiles where file_link like '/zxdb/%' and file_link not in (select file_link from tmp_dir) order by file_link;
select * from labelfiles where file_link like '/zxdb/%' and file_link not in (select file_link from tmp_dir) order by file_link;
select * from extras where file_link like '/zxdb/%' and file_link not in (select file_link from tmp_dir) order by file_link;

update downloads d inner join tmp_dir t on d.file_link = t.file_link set d.file_size = t.file_size where d.file_size is null;
update magfiles d inner join tmp_dir t on d.file_link = t.file_link set d.file_size = t.file_size where d.file_size is null;
update labelfiles d inner join tmp_dir t on d.file_link = t.file_link set d.file_size = t.file_size where d.file_size is null;
update extras d inner join tmp_dir t on d.file_link = t.file_link set d.file_size = t.file_size where d.file_size is null;

drop table tmp_dir;

-- END
