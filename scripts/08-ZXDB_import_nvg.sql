-- [ZXDB] Import into ZXDB the list of files stored in the NVG mirror at https://archive.org/details/mirror-ftp-nvg
-- by Einar Saukas

USE zxdb;

create table tmp_nvg (
    id int(11) not null primary key auto_increment,
    file_size int(12),
    file_date varchar(10),
    file_time varchar(10),
    file_attr varchar(5),
    file_link varchar(250),
    UNIQUE INDEX uk_nvg(file_link)    
);

load data local infile 'Mirror_ftp_nvg.txt' into table tmp_nvg character set latin2 lines terminated by '\n' ignore 4 lines (@row) SET file_size=trim(substr(@row,27,12)), file_date=trim(substr(@row,1,10)), file_time=trim(substr(@row,12,8)), file_attr=trim(substr(@row,21,5)), file_link=concat('/nvg/',replace(trim(substr(@row,54)),'\r',''));

delete from tmp_nvg where id = (select max(id) from tmp_nvg);
delete from tmp_nvg where id = (select max(id) from tmp_nvg);
delete from tmp_nvg where file_attr = 'D....';

select * from downloads where file_link like '/nvg/%' and file_link not in (select file_link from tmp_nvg) order by file_link;
select * from files where file_link like '/nvg/%' and file_link not in (select file_link from tmp_nvg) order by file_link;
select * from scraps where file_link like '/nvg/%' and file_link not in (select file_link from tmp_nvg) order by file_link;
select * from nvgs where file_link not in (select file_link from tmp_nvg) order by file_link;

select * from tmp_nvg where file_link not in (select file_link from downloads) and file_link not in (select file_link from files) and file_link not in (select file_link from scraps where file_link is not null) and file_link not in (select file_link from nvgs where file_link is not null) and file_link like '/nvg/sinclair/%' and file_link not like '%/.message' order by file_link;

drop table tmp_nvg;              

-- END
