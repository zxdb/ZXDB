-- [ZXDB] TODO list.
-- by Einar Saukas

USE zxdb;

select * from (
        select e.id as entry_id,e.title,n.text as details,'check ZXSR comment to be approved or deleted' as todo from entries e inner join notes n on e.id = n.entry_id where n.notetype_id = 'Z'
    union all
        select e.id,e.title,d2.file_link,'compare and discard thumbnail if duplicated' from entries e inner join downloads d1 on d1.entry_id = e.id and d1.release_seq = 0 inner join downloads d2 on d2.entry_id = e.id where (d1.file_link like '/pub/sinclair/books-pics/%' and d2.file_link like '/zxdb/sinclair/pics/books/%') or (d1.file_link like '/pub/sinclair/hardware-pics/%' and d2.file_link like '/zxdb/sinclair/pics/hw/%')
    union all
        select e.id,e.title,n.text,'convert note into compilation or relation' from entries e inner join notes n on e.id = n.entry_id where n.text like 'Came%'
    union all
        select e.id,e.title,n.text,'convert note into relation' from entries e inner join notes n on e.id = n.entry_id where n.text like 'Almost%'
    union all
        select null,null,file_link,'identify file to be moved to table "downloads"' from files where label_id is null and issue_id is null and tool_id is null and (file_link like '/pub/sinclair/books-pics/%' or file_link like '/pub/sinclair/games-%' or file_link like '/pub/sinclair/hardware-%' or file_link like '/pub/sinclair/slt/%' or file_link like '/pub/sinclair/technical-%' or file_link like '/pub/sinclair/zx81/%')
    union all
        select e.id,e.title,concat(m.name,' #',coalesce(lpad(i.number,3,'0'),'?'),' ',coalesce(i.date_year,'?'),'/',coalesce(i.date_month,'?'),' page ',r.page),'review from major magazine missing from ZXSR' from magrefs r inner join issues i on i.id = r.issue_id inner join magazines m on m.id = i.magazine_id inner join entries e on e.id = r.entry_id where r.referencetype_id = 10 and r.review_id is null and m.id in (select i.magazine_id from magrefs r inner join issues i on i.id = r.issue_id where r.referencetype_id = 10 and r.review_id is not null) and r.id not in (select magref_id from magreffeats where feature_id = 6455) and (e.machinetype_id is null or e.machinetype_id <= 10)
    union all
        select e.id,e.title,n.text,'solve mismatching magazine reference' from entries e inner join notes n on e.id = n.entry_id where n.text like 'Appeared on issue%'
) as tasks
order by todo,entry_id,details;

-- END
