-- [ZXDB] Identify data inconsistencies.
-- by Einar Saukas

USE zxdb;

-- ERRORS
select * from (
        select a.entry_id,e.title,a.author_seq-1 as details,'skipped author sequence in authors' as error from authors a inner join entries e on a.entry_id = e.id where a.author_seq > 1 and a.author_seq-1 not in (select a2.author_seq from authors a2 where a2.entry_id = a.entry_id)
    union all
        select id,title,'0','no release number in releases' from entries where id not in (select entry_id from releases)
    union all
        select e.id,e.title,r.release_seq-1,'skipped release number in releases' from releases r inner join entries e on r.entry_id = e.id where r.release_seq > 0 and r.release_seq-1 not in (select r2.release_seq from releases r2 where r2.entry_id = r.entry_id)
    union all
        select id,title,library_title,'possible mismatch between title and library title' from entries where title <> library_title and left(title,4) = left(library_title,4) and title not like '%+%'
    union all
        select e.id,e.title,concat(c.media_seq,'-',c.media_side,'-',c.prog_seq-1),'skipped item in contents' from contents c inner join entries e on c.container_id = e.id where c.prog_seq > 1 and c.prog_seq-1 not in (select c2.prog_seq from contents c2 where c2.container_id = c.container_id and c2.media_seq = c.media_seq and c2.media_side = c.media_side)
    union all
        select m.entry_id,e.title,concat(g.name,' (',g.id,')'),'missing sequence number in series' from tags g inner join members m on m.tag_id = g.id left join entries e on m.entry_id = e.id where m.member_seq is null and g.tagtype_id = 'S'
    union all
        select m.entry_id,e.title,concat(g.name,' (',g.id,')'),'skipped sequence number in series' from tags g inner join members m on m.tag_id = g.id left join entries e on m.entry_id = e.id where g.tagtype_id = 'S' and m.member_seq > 1 and m.member_seq-1 not in (select m2.member_seq from members m2 where m2.tag_id = m.tag_id)
    union all
        select m.entry_id,e.title,concat(g.name,' (',g.id,')'),'invalid sequence number in tag that is not series' from tags g inner join members m on m.tag_id = g.id left join entries e on m.entry_id = e.id where m.member_seq is not null and g.tagtype_id not in ('S','C')
    union all
        select p.entry_id,e.title,p.publisher_seq-1,'skipped publisher sequence in publishers' from publishers p inner join entries e on p.entry_id = e.id where p.publisher_seq > 1 and p.publisher_seq-1 not in (select p2.publisher_seq from publishers p2 where p2.entry_id = p.entry_id and p2.release_seq = p.release_seq)
    union all
        select e.id,e.title,text,'malformed reference to another entry in notes' from notes n left join entries e on e.id = n.entry_id where (text like '%{%}%' and text not like '%{%|%|%}%') or (text like '%{%}%{%}%' and text not like '%{%|%|%}%{%|%|%}%') or (text like '%{%}%{%}%{%}%' and text not like '%{%|%|%}%{%|%|%}%{%|%|%}%') or text regexp '[a-zA-Z]}'
    union all
        select e.id,e.title,g.text,'program authored with another program that is not programming tool or utility' from relations r inner join entries e on r.original_id = e.id left join genretypes g on e.genretype_id = g.id where r.relationtype_id = 'a' and g.text not like 'Utility:%' and g.text not like 'Programming:%' and r.original_id not in (3032)
    union all
        select e.id,e.title,g.text,'game editor that is not utility' from relations r inner join entries e on r.entry_id = e.id left join genretypes g on e.genretype_id = g.id where r.relationtype_id = 'e' and g.text not like 'Utility:%'
    union all
        select null,null,b1.name,'possibly unnecessary index in unique label name' from labels b1 left join labels b2 on b1.id <> b2.id and b2.name like concat(trim(substring_index(b1.name, '[', 1)),'%') where b1.name like '% [%]' and b2.id is null and b1.id <> 14006
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
        select null,null,concat(s.name,' / ',b.name),'license of "people" must not have owner' from licensors l inner join licenses s on l.license_id = s.id inner join labels b on b.id = l.label_id where s.licensetype_id = '-'
    union all
        select null,null,concat(b.name,' / ',b2.name),'nickname must be owned by person' from labels b inner join labels b2 on b.owner_id = b2.id where b.labeltype_id = '-' and b2.labeltype_id <> '+'
    union all
        select e.id,e.title,d.file_link,'invalid archive.org link in downloads' from downloads d inner join entries e on d.entry_id = e.id where d.file_link like '%/archive.org/%' and d.file_link not like 'https://archive.org/download/%'
    union all
        select e.id,e.title,d.file_link,'invalid remote link' from downloads d inner join entries e on d.entry_id = e.id where d.filetype_id = 0 and d.file_link not like 'http%'
    union all
        select e.id,e.title,d.file_link,'source code with incorrect filetype' from downloads d inner join entries e on d.entry_id = e.id where d.file_link like '%SourceCode%' and d.filetype_id not in (32,71)
    union all
        select e.id,e.title,d.file_link,'ZX80/ZX81 cannot have non-white border' from downloads d inner join entries e on d.entry_id = e.id where coalesce(d.machinetype_id, e.machinetype_id) between 18 and 24 and d.filetype_id between 1 and 3 and d.scr_border<>7
    union all
        select e.id,e.title,d.file_link,'ZX80/ZX81 cannot have loading screen' from downloads d inner join entries e on d.entry_id = e.id where coalesce(d.machinetype_id, e.machinetype_id) between 18 and 24 and d.filetype_id = 1 and e.id not in (31929)
    union all
        select e.id,e.title,d.file_link,'loading screen does not follow filename convention' from entries e inner join downloads d on d.entry_id = e.id where d.filetype_id = 1 and d.file_link regexp '/zxdb/sinclair/entries/[0-9]*/[0-9]{3}.*' and d.file_link not regexp '^/zxdb/sinclair/entries/[0-9]{7}/[0-9]{7}-load-[0-9]\.' and e.id not in (39503)
    union all
        select e.id,e.title,d.file_link,'running screen does not follow filename convention' from entries e inner join downloads d on d.entry_id = e.id where d.filetype_id = 2 and d.file_link regexp '/zxdb/sinclair/entries/[0-9]*/[0-9]{3}.*' and d.file_link not regexp '^/zxdb/sinclair/entries/[0-9]{7}/[0-9]{7}-run-[0-9]\.' and d.file_link not like '%-RUN-%'
    union all
        select e.id,e.title,d.file_link,'opening screen does not follow filename convention' from entries e inner join downloads d on d.entry_id = e.id where d.filetype_id = 3 and d.file_link regexp '/zxdb/sinclair/entries/[0-9]*/[0-9]{3}.*' and d.file_link not regexp '^/zxdb/sinclair/entries/[0-9]{7}/[0-9]{7}-open-[0-9]\.'
    union all
        select null,null,concat(m.name,' #',i1.number),'duplicated magazine number' from issues i1 inner join magazines m on m.id = i1.magazine_id inner join issues i2 on i1.id < i2.id and i1.magazine_id = i2.magazine_id and i1.number = i2.number and coalesce(i1.volume, -1) = coalesce(i2.volume, -1) and coalesce(i1.special,'') = coalesce(i2.special,'') and coalesce(i1.supplement,'') = coalesce(i2.supplement,'')
    union all
        select null,null,concat(m.name,' ',i1.date_year,'/',i1.date_month),'duplicated magazine issue' from issues i1 inner join magazines m on m.id = i1.magazine_id inner join issues i2 on i1.id < i2.id and i1.magazine_id = i2.magazine_id and i1.number is null and i2.number is null and coalesce(i1.volume, -1) = coalesce(i2.volume, -1) and coalesce(i1.special,'') = coalesce(i2.special,'') and coalesce(i1.supplement,'') = coalesce(i2.supplement,'') and coalesce(i1.date_year,-1) = coalesce(i2.date_year,-1) and coalesce(i1.date_month,-1) = coalesce(i2.date_month,-1) and coalesce(i1.date_day,-1) = coalesce(i2.date_day,-1)
    union all
        select null,null,concat(m.name,' #',coalesce(lpad(i1.number,3,'0'),'?'),' supplement'),'mismatch between magazine issue and supplement' from issues i1 inner join magazines m on m.id = i1.magazine_id inner join issues i2 on i1.parent_id = i2.id where i1.magazine_id<>i2.magazine_id or coalesce(i1.label_id,-1)<>coalesce(i2.label_id,-1) or coalesce(i1.label2_id,-1)<>coalesce(i2.label2_id,-1) or coalesce(i1.date_year,'')<>coalesce(i2.date_year,'') or coalesce(i1.date_month,'')<>coalesce(i2.date_month,'') or coalesce(i1.date_day,'')<>coalesce(i2.date_day,'') or coalesce(i1.volume,'')<>coalesce(i2.volume,'') or coalesce(i1.number,'')<>coalesce(i2.number,'') or coalesce(i1.special,'')<>coalesce(i2.special,'') or i2.parent_id is not null
    union all
        select null,null,i.id,'magazine supplements cannot have their own supplements' from issues p inner join issues i on i.parent_id = p.id where p.parent_id is not null
    union all
        select e.id,e.title,concat(m.name,' #',coalesce(lpad(i.number,3,'0'),'?'),' ',coalesce(i.date_year,'?'),'/',coalesce(i.date_month,'?'),' page ',r.page), 'mismatch between review and award' from magrefs r inner join issues i on r.issue_id = i.id inner join magazines m on i.magazine_id = m.id inner join zxsr_awards a on r.award_id = a.id left join entries e on e.id = r.entry_id where i.magazine_id <> a.magazine_id
    union all
        select null,null,concat(k.magref_id,' - ',k.link),'mismatch between magazine reference link and host' from magreflinks k inner join hosts h on k.host_id = h.id where k.link not like concat(h.link, '%')
    union all
        select e.id,e.title,d.file_link,'file located in wrong directory' from downloads d inner join entries e on e.id = d.entry_id where d.file_link like '/zxdb/sinclair/entries%' and d.file_link not like concat('%',lpad(entry_id,7,'0'),'%')
    union all
        select null,null,concat(t.text,': ',g.name,' (',g.id,')'),'tag without any members' from tags g inner join tagtypes t on t.id = g.tagtype_id where g.id not in (select tag_id from members)
    union all
        select e.id,e.title,concat(t.text,': ',g.name,' (',g.id,')'),'series (or set) with a single title' from tags g inner join tagtypes t on g.tagtype_id = t.id inner join members m on m.tag_id = g.id inner join entries e on m.entry_id = e.id left join members m2 on m2.tag_id = g.id and m2.entry_id <> m.entry_id where m2.entry_id is null and t.id in ('S','U')
    union all
        select null,null,concat('License: ',name,' (',id,')'),'license without any entries' from licenses where id not in (select license_id from relatedlicenses)
    union all
        select e.id,e.title,t.text,'container that is not compilation, covertape or e-magazine' from entries e left join genretypes t on t.id = e.genretype_id where e.id in (select container_id from contents) and e.id not in (select container_id from contents where container_id = entry_id) and (e.genretype_id is null or e.genretype_id < 80)
    union all
        select null,null,name,'non e-magazine incorrectly classified as e-magazine' from magazines where id not in (select magazine_id from issues j inner join entries e on j.id = e.issue_id where e.genretype_id = 82) and magtype_id = 'E'
    union all
        select null,null,name,'e-magazine incorrectly classified as non e-magazine' from magazines where id in (select magazine_id from issues j inner join entries e on j.id = e.issue_id where e.genretype_id = 82) and magtype_id <> 'E'
    union all
        select e.id,e.title,r.release_year,'re-release of never released title' from entries e inner join releases r on e.id = r.entry_id where e.availabletype_id in ('N','R') and r.release_seq > 0 and e.id not in (10180)  -- exception to this rule: when a title was planned to be published in different countries by different publishers
    union all
        select e.id,e.title,t.text,'program must be associated with magazine issue' from entries e left join genretypes t on t.id = e.genretype_id where (e.genretype_id in (81,82) or e.title like '% issue %') and e.issue_id is null and (e.availabletype_id is null or e.availabletype_id <> '*')
    union all
        select e.id,e.title,f.text,'duplicated ports' from entries e inner join ports p1 on e.id = p1.entry_id inner join platforms f on p1.platform_id = f.id inner join ports p2 on p1.entry_id = p2.entry_id and p1.platform_id = p2.platform_id and coalesce(p1.title,'') = coalesce(p2.title,'') and p1.is_official = p2.is_official and p1.id < p2.id where p1.link_system is null or p2.link_system is null or p1.link_system = p2.link_system
    union all
        select id,title,null,'deprecated entry containing possibly redundant data' from entries where availabletype_id = '*' and (id in (select entry_id from aliases) or id in (select entry_id from authors) or id in (select entry_id from booktypeins) or id in (select book_id from booktypeins) or id in (select entry_id from contents where entry_id is not null) or id in (select container_id from contents) or id in (select entry_id from magrefs where entry_id is not null) or id in (select entry_id from members) or id in (select entry_id from ports) or id in (select entry_id from publishers) or id in (select entry_id from relatedlicenses) or id in (select entry_id from relations where relationtype_id <> '*') or id in (select original_id from relations) or id in (select entry_id from remakes) or id in (select entry_id from webrefs) or id in (select entry_id from downloads))
    union all
        select null,null,concat(g1.name,' (',g1.id,') x ',g2.name,' (',g2.id,')'),'possibly duplicated tags with same elements' from (select g.id, g.name, group_concat(m.entry_id order by m.entry_id separator ',') as k from tags g left join members m on m.tag_id = g.id group by g.id) as g1 inner join (select g.id, g.name, group_concat(m.entry_id order by m.entry_id separator ',') as k from tags g left join members m on m.tag_id = g.id group by g.id) as g2 on g1.id < g2.id and g1.k = g2.k
    union all
        select id,title,library_title,'library title should not start with article "The"' from entries where library_title like 'The %'
    union all
        select e.id,e.title,g.name,'CSSCGC title missing from compilation' from entries e inner join members m on m.entry_id = e.id inner join tags g on g.id = m.tag_id and g.name like 'CSSCGC Crap Games Contest%' left join entries k on k.title like 'CSSCGC Crap Games Competition%' and e.id <> k.id left join contents c on c.container_id = k.id and c.entry_id = e.id where k.title = concat('CSSCGC Crap Games Competition',right(g.name,5)) and c.entry_id is null
    union all
        select e.id,e.title,k.title,'CSSCGC title missing from contest' from entries e inner join contents c on c.entry_id = e.id inner join entries k on k.id = c.container_id and k.title like 'CSSCGC Crap Games Competition%' left join tags g on g.name like 'CSSCGC Crap Games Contest%' and g.name = concat('CSSCGC Crap Games Contest',right(k.title,5)) left join members m on g.id = m.tag_id and m.entry_id = e.id where m.entry_id is null
    union all
        select null,null,d.file_link,'archived file in use' from scraps x inner join downloads d where x.file_link = d.file_link
    union all
        select e.id,e.title,g.text,'entry linked to magazine must be Covertape or Electronic Magazine' from entries e inner join issues i on i.id = e.issue_id left join genretypes g on e.genretype_id = g.id where e.title not like 'DigiTape%' and i.magazine_id <> 323 and (e.genretype_id is null or e.genretype_id not in (81,82))
    union all
        select null,null,name,'magazine cannot be both paper and electronic' from magazines where id in (select magazine_id from entries e inner join issues i on e.issue_id = i.id where e.genretype_id = 82) and (link_mask is not null or archive_mask is not null)
    union all
        select e.id,e.title,concat(b2.name,' & ',b1.name),'same author credited twice' from entries e inner join authors a1 on a1.entry_id = e.id inner join labels b1 on a1.label_id = b1.id inner join authors a2 on a2.entry_id = e.id inner join labels b2 on a2.label_id = b2.id where (b1.owner_id = b2.id or (b1.id < b2.id and b1.labeltype_id = '-' and b2.labeltype_id = '-' and b1.owner_id = b2.owner_id)) and e.id not in (4448,15020)
    union all
        select e.id,e.title,null,'redundant alias identical to entry title' from entries e inner join aliases a on e.id = a.entry_id and a.release_seq = 0 where a.title = e.title
    union all
        select e.id,e.title,null,'missing playable file from recovered title' from entries e where e.availabletype_id = 'R' and e.id not in (select entry_id from downloads where filetype_id in (8,10,11,17) and is_demo=0)
    union all
        select e.id,e.title,d.file_link,'playable file from never released title' from entries e inner join downloads d on d.entry_id = e.id where e.availabletype_id = 'N' and d.filetype_id in (8,10,11,17) and d.is_demo = 0
    union all
         select id,title,null,'deprecated title without related original title' from entries where id not in (select entry_id from relations where relationtype_id = '*') and availabletype_id = '*'
    union all
         select id,title,null,'deprecated title cannot be an original' from entries where id in (select original_id from relations) and availabletype_id = '*'
    union all
         select id,title,null,'duplicated title not marked as deprecated' from entries where id in (select entry_id from relations where relationtype_id = '*') and (availabletype_id is null or availabletype_id <> '*')
    union all
        select null,null,concat(name,' (',id,')'),'missing list of magazine issues' from magazines where (link_mask is not null or archive_mask is not null) and id not in (select magazine_id from issues)
    union all
        select e.id,e.title,t.text,'title cannot have multiple origins' from entries e inner join relations r1 on r1.entry_id = e.id inner join relationtypes t on t.id = r1.relationtype_id inner join relations r2 on r2.entry_id = e.id and r2.relationtype_id = r1.relationtype_id and r2.original_id > r1.original_id where t.id in ('p','u')
    union all
        select e.id,e.title,d.file_link,'itch.io links must be moved to webrefs' from entries e inner join downloads d on e.id = d.entry_id where d.filetype_id = 0 and d.file_link like '%itch.io%'
    union all
        select e.id,e.title,c.container_id,'redundant alias in contents' from entries e inner join contents c on e.id = c.entry_id where e.title = c.alias
    union all
        select e.id,e.title,t.text,'possibly misclassified game editor' from entries e inner join genretypes t on e.genretype_id = t.id where e.genretype_id = 52 and e.id in (select entry_id from relations where relationtype_id = 'e')
    union all
        select e.id,e.title,concat(m.text,' / ',n.text),'expected ZX-Spectrum 128 emulating ZX81' from entries e inner join relations r on e.id = r.entry_id and r.relationtype_id = 'z' inner join entries k on r.original_id = k.id left join machinetypes m on e.machinetype_id = m.id left join machinetypes n on k.machinetype_id = n.id where coalesce(m.text,'') not like 'ZX-Spectrum 128%' or coalesce(n.text,'') not like 'ZX81%'
    union all
        select e.id,e.title,null,'non-review cannot have ZXSR content' from magrefs r inner join entries e on r.entry_id = e.id where r.referencetype_id <> 10 and (r.id in (select magref_id from zxsr_scores) or r.id in (select magref_id from zxsr_captions))
    union all
        select e.id,e.title,t.text,'game editor for unidentified game' from entries e inner join genretypes t on e.genretype_id = t.id where e.genretype_id = 53 and e.id not in (select entry_id from relations where relationtype_id = 'e')
    union all
        select e.id,e.title,r.link,'mismatching web link' from entries e inner join webrefs r on r.entry_id = e.id inner join websites w on r.website_id = w.id where not (
r.link like concat(w.link,'%') or (r.website_id=10 and r.link like 'https://%.wikipedia.org/wiki/%') or (r.website_id in (16,19,36,37) and r.link like 'https://youtu.be/%') or (r.website_id in (16,19) and r.link like 'https://www.youtube.com/%') or (r.website_id=31 and r.link like 'https://%.itch.io/%'))
    union all
        select e.id,e.title,concat(coalesce(r.release_year,'-'),'/',coalesce(r.release_month,'-'),'/',coalesce(r.release_day,'-'),' vs ',coalesce(i.date_year,'-'),'/',coalesce(i.date_month,'-'),'/',coalesce(i.date_day,'-')),'conflicting original publication date between tape and magazine' from entries e inner join releases r on r.entry_id = e.id and r.release_seq = 0 inner join issues i on i.id = e.issue_id where e.genretype_id <> 81 and e.id not in (select entry_id from contents where is_original=1) and e.id not in (select entry_id from booktypeins where is_original=1) and e.id not in (select entry_id from magrefs where is_original=1) and (coalesce(r.release_year,-1) <> coalesce(i.date_year,-1) or coalesce(r.release_month,-1) <> coalesce(i.date_month,-1) or coalesce(r.release_day,-1) <> coalesce(i.date_day,-1))
    union all
        select x.id,x.title,concat(nc+nr+nb,' original publications'),'multiple original publications' from (select e.id, e.title, count(distinct c.is_original) as nc, count(distinct i.magazine_id) as nr, count(distinct b.book_id) as nb from entries e left join contents c on c.entry_id = e.id and c.is_original = 1 left join magrefs r on r.entry_id = e.id and r.is_original = 1 left join issues i on r.issue_id = i.id left join booktypeins b on b.entry_id = e.id and b.is_original = 1 group by e.id) as x where nc+nr+nb > 1
    union all
        select e.id,e.title,null,'inconsistent or missing information in CSSCGC compilation' from entries e inner join releases r on r.entry_id = e.id and r.release_seq = 0 where e.title like 'CSSCGC%' and (r.release_year is null or r.release_month is not null or e.title <> concat('CSSCGC Crap Games Competition ',r.release_year) or e.genretype_id is null or e.genretype_id <> 80 or e.id not in (select entry_id from members where tag_id=3581))
    union all
        select null,e1.title,concat(e1.id,' and ',e2.id),'duplicated type-in entry' from issues i inner join magrefs r1 on r1.issue_id = i.id and r1.is_original = 1 inner join magrefs r2 on r2.issue_id = i.id and r2.is_original = 1 and r2.entry_id > r1.entry_id inner join entries e1 on e1.id = r1.entry_id inner join entries e2 on e2.id = r2.entry_id left join relations k on (k.entry_id = e1.id and k.original_id = e2.id) or (k.entry_id = e2.id and k.original_id = e1.id) where e1.title = e2.title and k.entry_id is null
    union all
        select e.id,e.title,k.title,'conflicting original publication date in CSSCGC entry' from entries e inner join releases r on r.entry_id = e.id and r.release_seq = 0 inner join contents t on t.entry_id = e.id and t.is_original = 1 inner join entries k on k.id = t.container_id inner join releases s on s.entry_id = k.id and s.release_seq = 0 left join contents t2 on t2.entry_id = e.id and t2.is_original = 1 and t2.container_id < t.container_id where t2.container_id is null and k.id in (select entry_id from members where tag_id=3581) and r.release_year is not null and r.release_year <> s.release_year and r.release_year <> s.release_year+1
    union all
        select e.id,e.title,k.title,'reciprocal relationship' from entries e inner join relations r1 on r1.entry_id = e.id inner join relations r2 on r1.entry_id = r2.original_id and r1.original_id = r2.entry_id inner join entries k on r1.original_id = k.id
    union all
        select null,null,concat(b.name,' [',c.text,'] x ',b2.name,' [',c2.text,']'),'mismatching countries' from labels b inner join countries c on b.country_id = c.id inner join labels b2 on b.owner_id = b2.id inner join countries c2 on b2.country_id = c2.id where b.labeltype_id='-' and c.id <> c2.id
) as warnings
order by entry_id, details;

-- WARNINGS
select * from (
        select a.entry_id,e.title,concat(b.name,' / ',t.name) as details,'team member must be a person' as warning from entries e inner join authors a on e.id = a.entry_id inner join labels b on a.label_id = b.id inner join labels t on a.team_id = t.id where b.labeltype_id not in ('+','-')
    union all
        select e1.id,e1.title,null,'possibly unnecessary index in unique entry title' from entries e1 left join entries e2 on e1.id <> e2.id and e2.title like concat(trim(substring_index(e1.title, '[', 1)),'%') where e1.title like '% [%]' and e2.id is null
    union all
        select e.id,e.title,null,'covertape shouldn''t have separate price' from entries e inner join releases r on e.id = r.entry_id where e.genretype_id = 81 and r.currency_id is not null
    union all
        select null,null,concat(m.name,' #',coalesce(lpad(i.number,3,'0'),'?'),' ',coalesce(i.date_year,'?'),'/',coalesce(i.date_month,'?'),' page ',r.page),'unidentified interview' from magrefs r inner join issues i on r.issue_id = i.id inner join magazines m on i.magazine_id = m.id where r.entry_id is null and r.label_id is null and r.topic_id is null
    union all
        select e.id,e.title,text,'programs in compilation must be indexed properly' from notes n left join entries e on e.id = n.entry_id where text like '[%+%]'
    union all
        select e.id,e.title,text,'aliases must be indexed properly' from notes n left join entries e on e.id = n.entry_id where text like 'aka. %' or text like 'a.k.a. %'
    union all
        select e.id,e.title,d.file_link,'probably demo version not marked as demo' from downloads d inner join entries e on d.entry_id = e.id left join genretypes t on t.id = e.genretype_id where lower(d.file_link) like '%(demo%' and t.text not like '%Demo%' and d.is_demo=0 and d.filetype_id between 8 and 11
    union all
        select e.id,e.title,d.file_link,'possibly file with incorrect release_seq' from downloads d inner join entries e on d.entry_id = e.id where e.id between 2000000 and 3000000 and d.file_link like '%)%' and d.release_seq=0 and e.id not in (2000113)
    union all
        select e.id,e.title,concat('#',r1.release_seq,' (',r1.release_year,') and #',r2.release_seq,' (',r2.release_year,')'),'incorrect release order' from releases r1 inner join releases r2 on r1.entry_id = r2.entry_id and r1.release_seq < r2.release_seq and r1.release_year > r2.release_year inner join entries e on e.id = r1.entry_id
    union all
        select e.id,e.title,x.file_link,'archived non-historical file' from scraps x left join entries e on e.id = x.entry_id where x.file_link like '/zxdb/%'
    union all
         select null,null,concat('/zxdb/sinclair/entries/.../',filename),'duplicated filename (to be avoided if possible)' from (select substring_index(file_link,'/',-1) as filename, count(id) as n from downloads where file_link like '/zxdb/sinclair/entries/%.tap.zip' or file_link like '/zxdb/sinclair/entries/%.tzx.zip' group by filename) as x where n>1
    union all
        select e.id,e.title,n.text,'note probably conversible to license' from entries e inner join notes n on e.id = n.entry_id where n.text like 'Based%'
    union all
        select e.id,e.title,t.text,'missing list of contents' as todo from entries e inner join genretypes t on e.genretype_id = t.id where (e.genretype_id in (80,81) or e.genretype_id >= 110) and e.id not in (select container_id from contents)
    union all
        select e.id,e.title,concat(t.text,': ',m.name,' (issue-id ',i.id,')'),'invalid page number reference' from issues i inner join magazines m on i.magazine_id = m.id inner join magrefs r on r.issue_id = i.id inner join referencetypes t on r.referencetype_id = t.id left join entries e on e.id = r.entry_id where r.page < i.cover_page
    union all
        select e.id,e.title,k.title,'conflicting original publication date in program within compilation, covertape or e-magazine' from entries e inner join releases r on r.entry_id = e.id and r.release_seq = 0 inner join contents t on t.entry_id = e.id and t.is_original = 1 inner join entries k on k.id = t.container_id inner join releases s on s.entry_id = k.id and s.release_seq = 0 left join contents t2 on t2.entry_id = e.id and t2.is_original = 1 and t2.container_id < t.container_id where t2.container_id is null and k.id not in (select entry_id from members where tag_id=3581) and r.release_year is not null and (coalesce(r.release_year,-1) <> coalesce(s.release_year,-1) or coalesce(r.release_month,-1) <> coalesce(s.release_month,-1) or coalesce(r.release_day,-1) <> coalesce(s.release_day,-1))
    union all
        select e.id,e.title,k.title,'conflicting original publication date in book type-in' from entries e inner join releases r on r.entry_id = e.id and r.release_seq = 0 inner join booktypeins t on t.entry_id = e.id and t.is_original = 1 inner join entries k on k.id = t.book_id inner join releases s on s.entry_id = k.id and s.release_seq = 0 left join booktypeins t2 on t2.entry_id = e.id and t2.is_original = 1 and t2.book_id < t.book_id where t2.book_id is null and r.release_year is not null and (coalesce(r.release_year,-1) <> coalesce(s.release_year,-1) or coalesce(r.release_month,-1) <> coalesce(s.release_month,-1) or coalesce(r.release_day,-1) <> coalesce(s.release_day,-1))
    union all
        select e.id,e.title,m.name,'conflicting original publication date in magazine type-in' from entries e inner join releases r on r.entry_id = e.id and r.release_seq = 0 inner join magrefs t on t.entry_id = e.id and t.is_original = 1 inner join issues i on i.id = t.issue_id inner join magazines m on m.id = i.magazine_id left join magrefs t2 on t2.entry_id = e.id and t2.is_original = 1 and t2.issue_id < i.id where t2.id is null and r.release_year is not null and (coalesce(r.release_year,-1) <> coalesce(i.date_year,-1) or coalesce(r.release_month,-1) <> coalesce(i.date_month,-1) or coalesce(r.release_day,-1) <> coalesce(i.date_day,-1))
    union all
        select e.id,e.title,null,'conflicting original publisher' from entries e where e.id in (select entry_id from publishers where release_seq = 0) and (e.id in (select entry_id from contents where is_original=1) or e.id in (select entry_id from booktypeins where is_original=1) or e.id in (select entry_id from magrefs where is_original=1))
    union all
        select e.id,e.title,null,'conflicting original price' from entries e inner join releases r on r.entry_id = e.id and r.release_seq = 0 where r.currency_id is not null and (e.id in (select entry_id from contents where is_original=1) or e.id in (select entry_id from booktypeins where is_original=1) or e.id in (select entry_id from magrefs where is_original=1))
    union all
        select e.id,e.title,n.text,'note to be converted into compilation or relation' from entries e inner join notes n on e.id = n.entry_id where n.text like 'Came%'
    union all
        select e.id,e.title,n.text,'note to be converted into relation' from entries e inner join notes n on e.id = n.entry_id where n.text like 'Almost%'
    union all
        select e.id,e.title,n.text,'note to be converted into relation or license' from entries e inner join notes n on e.id = n.entry_id where n.text like 'Conversion of%'
    union all
        select null,null,file_link,'file to be identified and moved to table "downloads"' from files where label_id is null and issue_id is null and tool_id is null and (file_link like '/pub/sinclair/books-pics/%' or file_link like '/pub/sinclair/games-%' or file_link like '/pub/sinclair/hardware-%' or file_link like '/pub/sinclair/slt/%' or file_link like '/pub/sinclair/technical-%' or file_link like '/pub/sinclair/zx81/%')
    union all
        select null,null,m.name,'label and magazine with same name' from magazines m inner join labels b on m.name = b.name where b.name not in ('48K','Gamestar','Kiddisoft','Maximum')
    union all
        select e.id,e.title,group_concat(b.name order by p.publisher_seq separator ' / '),'scene demo without Demozoo link' from entries e inner join publishers p on p.entry_id = e.id and p.release_seq = 0 inner join labels b on p.label_id = b.id where e.genretype_id = 79 and e.id not in (select entry_id from webrefs where website_id = 48) group by e.id
) as warnings
order by entry_id, details;

-- END
