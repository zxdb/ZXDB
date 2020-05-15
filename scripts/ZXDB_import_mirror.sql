-- [ZXDB] Import into ZXDB the list of files stored at WoS mirror from Archive.org.
-- by Einar Saukas

USE zxdb;

create table tmp_mirror (
    id int(11) not null primary key auto_increment,
    file_size int(11),
    file_date varchar(50),
    file_time varchar(50),
    file_link varchar(300),
    UNIQUE INDEX uk_mirror(file_link)
);

load data local infile 'World of Spectrum June 2017 Mirror.txt' into table tmp_mirror character set latin2 fields terminated by '\t' lines terminated by '\n' ignore 3 lines (@row) SET file_size=trim(substr(@row,1,11)), file_date=trim(substr(@row,12,11)), file_time=trim(substr(@row,23,6)), file_link=replace(trim(substr(@row,29)),'World of Spectrum June 2017 Mirror/','/pub/');

delete from tmp_mirror where id = (select max(id) from tmp_mirror);
delete from tmp_mirror where id = (select max(id) from tmp_mirror);

select * from downloads where file_link like '/pub/%' and file_link not in (select file_link from tmp_mirror) order by file_link;
select * from extras where file_link like '/pub/%' and file_link not in (select file_link from tmp_mirror) and comments not in ('** unavailable (distribution denied) **','** broken link at www.worldofspectrum.org **','** missing file at archive.org mirror replaced by pdf **') order by file_link;
select * from labelfiles where file_link like '/pub/%' and file_link not in (select file_link from tmp_mirror) order by file_link;
select * from magfiles where file_link like '/pub/%' and file_link not in (select file_link from tmp_mirror) order by file_link;

select * from tmp_mirror where file_link not in (select file_link from downloads) and file_link not in (select file_link from extras where file_link is not null) and file_link not in (select file_link from labelfiles) and file_link not in (select file_link from magfiles) and file_link not like '/pub/sinclair/magazines/%' order by file_link;

drop table tmp_mirror;

-- END
