-- [ZXDB] Identify data inconsistencies.
-- by Einar Saukas

USE zxdb;

select * from (
        select a.entry_id,e.title,a.author_seq-1 as details,'skipped an author sequence in authors' as error from authors a inner join entries e on a.entry_id = e.id where a.author_seq > 1 and a.author_seq-1 not in (select a2.author_seq from authors a2 where a2.entry_id = a.entry_id)
    union all
        select id,title,'0','no release number in releases' from entries where id not in (select entry_id from releases)
    union all
        select e.id,e.title,r.release_seq-1,'skipped a release number in releases' from releases r inner join entries e on r.entry_id = e.id where r.release_seq > 0 and r.release_seq-1 not in (select r2.release_seq from releases r2 where r2.entry_id = r.entry_id)
    union all
        select id,title,library_title,'possible mismatch between title and library title' from entries where title <> library_title and left(title,4) = left(library_title,4) and title not like '%+%'
    union all
         select e.id,e.title,concat(c.tape_seq,'-',c.tape_side,'-',c.prog_seq-1),'skipped an item in compilation' from compilations c inner join entries e on c.compilation_id = e.id where c.prog_seq > 1 and c.prog_seq-1 not in (select c2.prog_seq from compilations c2 where c2.compilation_id = c.compilation_id and c2.tape_seq = c.tape_seq and c2.tape_side = c.tape_side)
    union all
         select m.entry_id,e.title,concat(g.name,' (',g.id,')'),'missing a sequence number in series' from groups g inner join members m on m.group_id = g.id left join entries e on m.entry_id = e.id where m.series_seq is null and g.grouptype_id = 'S'
    union all
         select m.entry_id,e.title,concat(g.name,' (',g.id,')'),'skipped a sequence number in series' from groups g inner join members m on m.group_id = g.id left join entries e on m.entry_id = e.id where m.series_seq > 1 and m.series_seq-1 not in (select m2.series_seq from members m2 where m2.group_id = m.group_id)
    union all
         select m.entry_id,e.title,concat(g.name,' (',g.id,')'),'invalid sequence number in group that is not series' from groups g inner join members m on m.group_id = g.id left join entries e on m.entry_id = e.id where m.series_seq is not null and g.grouptype_id <> 'S'
    union all
         select p.entry_id,e.title,p.publisher_seq-1,'skipped a publisher sequence in publishers' from publishers p inner join entries e on p.entry_id = e.id where p.publisher_seq > 1 and p.publisher_seq-1 not in (select p2.publisher_seq from publishers p2 where p2.entry_id = p.entry_id and p2.release_seq = p.release_seq)
    union all
         select id,title,comments,'malformed reference to another entry in comments' from entries where (comments like '%{%}%' and comments not like '%{%|%|%}%') or (comments like '%{%}%{%}%' and comments not like '%{%|%|%}%{%|%|%}%') or (comments like '%{%}%{%}%{%}%' and comments not like '%{%|%|%}%{%|%|%}%{%|%|%}%')
    union all
         select e.id,e.title,g.text,'program authored with another program that is not utility' from relations r inner join entries e on r.original_id = e.id left join genretypes g on e.genretype_id = g.id where r.relationtype_id = 'a' and g.text not like 'Utility:%'
    union all
         select e.id,e.title,g.text,'game editor that is not utility' from relations r inner join entries e on r.entry_id = e.id left join genretypes g on e.genretype_id = g.id where r.relationtype_id = 'e' and g.text not like 'Utility:%'
    union all
         select e.id,e.title,concat(b.name,' / ',t.name),'author''s team must be a company' from entries e inner join authors a on e.id = a.entry_id inner join labels t on t.id = a.team_id inner join labels b on b.id = a.label_id where t.labeltype_id in ('+','-') or t.labeltype_id is null
    union all
        select e.id,e.title,t.text,'timex programs should have ID above 4000000' from entries e inner join machinetypes t on e.machinetype_id = t.id where t.text like 'Timex%' and e.id not between 4000000 and 4999999
    union all
        select e.id,e.title,g.text,'books should have ID above 2000000' from entries e inner join genretypes g on e.genretype_id = g.id where g.text like 'Book%' and e.id not between 2000000 and 2999999
    union all
        select e.id,e.title,g.text,'hardware devices should have ID above 1000000' from entries e inner join genretypes g on e.genretype_id = g.id where g.text like 'Hardware%' and e.id not between 1000000 and 1999999
    union all
        select e.id,e.title,t.text,'title with ID above 4000000 that is not timex program' from entries e left join machinetypes t on e.machinetype_id = t.id where coalesce(t.text,'?') not like 'Timex%' and e.id between 4000000 and 4999999
    union all
        select e.id,e.title,g.text,'title with ID above 2000000 that is not book' from entries e left join genretypes g on e.genretype_id = g.id where coalesce(g.text,'') not like 'Book%' and e.id between 2000000 and 2999999
    union all
        select e.id,e.title,g.text,'title with ID above 1000000 that is not hardware device' from entries e left join genretypes g on e.genretype_id = g.id where coalesce(g.text,'') not like 'Hardware%' and e.id between 1000000 and 1999999
    union all
        select e.id,e.title,d.file_link,'unknown file extension' from downloads d inner join entries e on d.entry_id = e.id left join extensions x on d.file_link like CONCAT('%',x.ext) where x.ext is null and d.file_link not like 'http%' and d.file_link not like '%.zip' and d.file_link not like '/pub/sinclair/%' and d.file_link not like '%_SourceCode.tar.bz2'
    union all
        select e.id,e.title,d.file_link,'mispelled file extension' from downloads d inner join entries e on d.entry_id = e.id where d.file_link like '%,zip'
    union all
        select null,null,concat(s.name,' / ',b.name),'license of "people" must not have owner' from licensors l inner join licenses s on l.license_id = s.id inner join labels b on b.id = l.label_id where s.licensetype_id = '-'
    union all
        select e.id,e.title,d.file_link,'invalid archive.org link in downloads' from downloads d inner join entries e on d.entry_id = e.id where d.file_link like '%/archive.org/%' and d.file_link not like 'https://archive.org/download/%'
    union all
        select null,null,m.archive_mask,'invalid archive.org mask in magazines' from magazines m where m.archive_mask is not null and m.archive_mask not like 'https://archive.org/download/%'
    union all
        select null,null,concat(m.name,' #',i1.number),'duplicated magazine number' from issues i1 inner join magazines m on m.id = i1.magazine_id inner join issues i2 on i1.id < i2.id and i1.magazine_id = i2.magazine_id and i1.number = i2.number and coalesce(i1.volume, -1) = coalesce(i2.volume, -1) and coalesce(i1.special,'') = coalesce(i2.special,'')
    union all
        select null,null,concat(m.name,' ',i1.date_year,'/',i1.date_month),'duplicated magazine issue' from issues i1 inner join magazines m on m.id = i1.magazine_id inner join issues i2 on i1.id < i2.id and i1.magazine_id = i2.magazine_id and i1.number is null and i2.number is null and coalesce(i1.volume, -1) = coalesce(i2.volume, -1) and coalesce(i1.special,'') = coalesce(i2.special,'') and coalesce(i1.date_year,-1) = coalesce(i2.date_year,-1) and coalesce(i1.date_month,-1) = coalesce(i2.date_month,-1) and coalesce(i1.date_day,-1) = coalesce(i2.date_day,-1)
    union all
        select null,null,concat(name,' (',id,')'),'available magazine without catalogued issues' from magazines where (link_mask is not null or archive_mask is not null) and id not in (select magazine_id from issues)
    union all
        select id,title,mag_issue,'title is apparently not a magazine issue' from (select e.id, e.title, i.number, replace(replace(replace(replace(replace(m.name,'ACE (Advanced Computer Entertainment)','ACE'),'Sinclair User Club-DE','Sinclair User Club'),'Your Computer-ES','Your Computer'),'16-48 Magazine','16/48 Magazine Tape'),'C&VG (Computer & Video Games)','C&VG') as mag_name, concat(m.name,' #',coalesce(i.number,'?'),' ',coalesce(i.date_year,'?'),'/',coalesce(i.date_month,'?')) as mag_issue from entries e inner join issues i on i.id = e.issue_id inner join magazines m on i.magazine_id = m.id) as x where title not like '%DigiTape%' and not (title = mag_name or title = CONCAT(mag_name,' ',number) or title = CONCAT(mag_name,' 0',number) or title = CONCAT(mag_name,' No ',number) or title = CONCAT(mag_name,' No 0',number) or lower(title) = lower(CONCAT(mag_name,' Nr 0',number)) or lower(title) = lower(CONCAT(mag_name,' issue ',number)) or lower(title) = lower(CONCAT(mag_name,' issue 0',number)) or lower(title) = lower(CONCAT(mag_name,' issue 00',number)) or title like CONCAT(mag_name,' issue 0',number,':%') or title like CONCAT(mag_name,' issue ',number,':%') or title like CONCAT(mag_name,' issue 0',number,' -%') or title like CONCAT(mag_name,' issue #',number,' -%'))
    union all
        select null,null,concat(k.magref_id,' - ',k.link),'mismatch between magazine reference link and host' from magreflinks k inner join hosts h on k.host_id = h.id where k.link not like concat(h.link, '%')
    union all
        select e.id,e.title,d.file_link,'file located in wrong directory' from downloads d inner join entries e on e.id = d.entry_id where d.file_link like '/zxdb/sinclair/entries%' and d.file_link not like concat('%',lpad(entry_id,7,'0'),'%')
    union all
        select null,null,concat(t.text,': ',name,' (',g.id,')'),'group without any members' from groups g inner join grouptypes t on t.id = g.grouptype_id where g.id not in (select group_id from members)
    union all
        select e.id,e.title,t.text,'compilation that is not compilation' from entries e left join genretypes t on t.id = e.genretype_id where e.id in (select compilation_id from compilations) and (e.genretype_id is null or e.genretype_id < 80)
    union all
        select e.id,e.title,t.text,'program must be associated with magazine issue' from entries e left join genretypes t on t.id = e.genretype_id where e.title like '% issue %' and e.issue_id is null
    union all
        select e.id,e.title,e.comments,'programs in compilation must be indexed properly' from entries e where comments like '[%+%]'
    union all
        select e.id,e.title,e.spot_comments,'programs in compilation must be indexed properly' from entries e where spot_comments like '[%+%]'
    union all
        select null,null,concat(g1.name,' (',g1.id,') x ',g2.name,' (',g2.id,')'),'possibly duplicated groups with same elements' from (select g.id, g.name, group_concat(m.entry_id order by m.entry_id separator ',') as k from groups g left join members m on m.group_id = g.id group by g.id) as g1 inner join (select g.id, g.name, group_concat(m.entry_id order by m.entry_id separator ',') as k from groups g left join members m on m.group_id = g.id group by g.id) as g2 on g1.id < g2.id and g1.k = g2.k
    union all
        select e.id,e.title,d.file_link,'download link containing spaces' from entries e inner join downloads d on d.entry_id = e.id where d.file_link like '/zxdb/% %' and d.file_link not like '/zxdb/sinclair/pokes/%'
    union all
        select e.id,e.title,concat('#',r1.release_seq,' (',r1.release_year,') and #',r2.release_seq,' (',r2.release_year,')'),'incorrect release order' from releases r1 inner join releases r2 on r1.entry_id = r2.entry_id and r1.release_seq < r2.release_seq and r1.release_year > r2.release_year inner join entries e on e.id = r1.entry_id
    union all
        select id,title,library_title,'library title should not start with article "The"' from entries where library_title like 'The %'
    union all
        select e.id,e.title,g.name,'CSSCGC title missing from compilation' from entries e inner join members m on m.entry_id = e.id inner join groups g on g.id = m.group_id and g.name like 'CSSCGC Crap Games Contest%' left join entries k on k.title like 'CSSCGC Crap Games Competition%' and e.id <> k.id left join compilations c on c.compilation_id = k.id and c.entry_id = e.id where k.title = concat('CSSCGC Crap Games Competition',right(g.name,5)) and c.entry_id is null
    union all
        select e.id,e.title,k.title,'CSSCGC title missing from contest' from entries e inner join compilations c on c.entry_id = e.id inner join entries k on k.id = c.compilation_id and k.title like 'CSSCGC Crap Games Competition%' left join groups g on g.name like 'CSSCGC Crap Games Contest%' and g.name = concat('CSSCGC Crap Games Contest',right(k.title,5)) left join members m on g.id = m.group_id and m.entry_id = e.id where m.entry_id is null
    union all
         select e.id,e.title,g.text,'software must be bundled with hardware or book (not the opposite)' from relations r inner join entries e on r.entry_id = e.id left join genretypes g on e.genretype_id = g.id where r.relationtype_id = 'w' and e.id between 1000000 and 2999999 and r.original_id not between 1000000 and 2999999
    union all
         select e.id,e.title,g.text,'only hardware can be required' from relations r inner join entries e on r.original_id = e.id left join genretypes g on e.genretype_id = g.id where r.relationtype_id = 'h' and coalesce(g.text,'') not like 'Hardware%'
    union all
        select e.id,e.title,x.file_link,'non-historical file archived' from extras x left join entries e on e.id = x.entry_id where x.file_link like '/zxdb/%'
    union all
        select null, null, concat('"',name,'"'), 'label with extra spaces' from labels where name like '% ' or name like ' %' or name like '%  %'
    union all
        select id, concat('"',title,'"'), concat('"',library_title,'"'), 'title with extra spaces' from entries where title like '% ' or title like ' %' or title like '%  %' or library_title like '% ' or library_title like ' %' or library_title like '%  %'
    union all
        select e.id,e.title,g.text,'entry linked to magazine must be Covertape or Electronic Magazine' from entries e left join genretypes g on e.genretype_id = g.id where e.issue_id is not null and e.title not like 'DigiTape%' and (e.genretype_id is null or e.genretype_id not in (81,82))
    union all
        select e.id,e.title,concat(b2.name,' / ',b1.name),'same author credited twice' from entries e inner join authors a1 on a1.entry_id = e.id inner join labels b1 on a1.label_id = b1.id inner join authors a2 on a2.entry_id = e.id inner join labels b2 on a2.label_id = b2.id where b1.owner_id = b2.id
    union all
        select id, title, replace(replace(title, ' ', '%'), '–', '%'), 'invalid character in entries.title' from entries where title like '% %' or title like '%–%'
    union all
        select id, library_title, replace(replace(library_title, ' ', '%'), '–', '%'), 'invalid character in entries.library_title' from entries where library_title like '% %' or library_title like '%–%'
    union all
        select entry_id, title, replace(replace(title, ' ', '%'), '–', '%'), 'invalid character in aliases.title' from aliases where title like '% %' or title like '%–%'
    union all
        select entry_id, library_title, replace(library_title, ' ', '%'), 'invalid character in aliases.library_title' from aliases where library_title like '% %' or library_title like '%–%'
    union all
        select id, title, replace(replace(comments, ' ', '%'), '–', '%'), 'invalid character in entries.comments' from entries where comments like '% %' or comments like '%–%'
    union all
        select id, title, replace(replace(spot_comments, ' ', '%'), '–', '%'), 'invalid character in entries.spot_comments' from entries where spot_comments like '% %' or spot_comments like '%–%'
    union all
        select null, null, replace(name, ' ', '%'), 'invalid space character in labels.name' from labels where name like '% %' or name like '%–%'
) as errors order by entry_id, details;

-- END
