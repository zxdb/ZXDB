-- [ZXDB] TODO list.
-- by Einar Saukas

USE zxdb;

select * from (
        select e.id as entry_id,e.title,concat(m.name,' #',coalesce(lpad(i.number,3,'0'),'?'),' ',coalesce(i.date_year,'?'),'/',coalesce(i.date_month,'?'),' page ',r.page) as details,'review from major magazine missing from ZXSR' as todo from magrefs r inner join issues i on i.id = r.issue_id inner join magazines m on m.id = i.magazine_id inner join entries e on e.id = r.entry_id where r.referencetype_id = 10 and r.review_id is null and m.id in (select i.magazine_id from magrefs r inner join issues i on i.id = r.issue_id where r.referencetype_id = 10 and r.review_id is not null) and r.id not in (select magref_id from magreffeats where feature_id = 6455) and (e.machinetype_id is null or e.machinetype_id <= 10) and (i.magazine_id <> 51 or i.volume <> 2)
) as tasks
order by todo,entry_id,details;

-- END
