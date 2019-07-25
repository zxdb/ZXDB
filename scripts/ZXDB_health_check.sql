-- [ZXDB] Identify data inconsistencies.
-- by Einar Saukas

USE zxdb;

select * from (
        select a.entry_id, e.title, a.author_seq-1 as details,'skipped an author sequence in authors' as error from authors a inner join entries e on a.entry_id = e.id where a.author_seq > 1 and a.author_seq-1 not in (select a2.author_seq from authors a2 where a2.entry_id = a.entry_id)
    union all
        select id, title, '0', 'missing a release number in releases' from entries where id not in (select entry_id from releases)
    union all
        select e.id, e.title, r.release_seq-1, 'skipped a release number in releases' from releases r inner join entries e on r.entry_id = e.id where r.release_seq > 0 and r.release_seq-1 not in (select r2.release_seq from releases r2 where r2.entry_id = r.entry_id)
    union all
        select id, title, library_title, 'possible mismatch between title and library title' from entries where title <> library_title and left(title,4) = left(library_title,4) and title not like '%+%'
    union all
         select e.id, e.title, concat(c.tape_seq,'-',c.tape_side,'-',c.prog_seq-1), 'skipped an item in compilation' from compilations c inner join entries e on c.compilation_id = e.id where c.prog_seq > 1 and c.prog_seq-1 not in (select c2.prog_seq from compilations c2 where c2.compilation_id = c.compilation_id and c2.tape_seq = c.tape_seq and c2.tape_side = c.tape_side)
    union all
         select m.entry_id, e.title, g.name, 'missing a sequence number in series' from groups g inner join members m on m.group_id = g.id left join entries e on m.entry_id = e.id where m.series_seq is null and g.grouptype_id = 'S'
    union all
         select m.entry_id, e.title, g.name, 'skipped a sequence number in series' from groups g inner join members m on m.group_id = g.id left join entries e on m.entry_id = e.id where m.series_seq > 1 and m.series_seq-1 not in (select m2.series_seq from members m2 where m2.group_id = m.group_id)
    union all
         select m.entry_id, e.title, g.name, 'invalid sequence number in group that is not series' from groups g inner join members m on m.group_id = g.id left join entries e on m.entry_id = e.id where m.series_seq is not null and g.grouptype_id <> 'S'
    union all
         select p.entry_id, e.title, p.publisher_seq-1, 'skipped a publisher sequence in publishers' from publishers p inner join entries e on p.entry_id = e.id where p.publisher_seq > 1 and p.publisher_seq-1 not in (select p2.publisher_seq from publishers p2 where p2.entry_id = p.entry_id and p2.release_seq = p.release_seq)
    union all
         select id, title, comments, 'malformed reference to another entry in comments' from entries where (comments like '%{%}%' and comments not like '%{%|%|%}%') or (comments like '%{%}%{%}%' and comments not like '%{%|%|%}%{%|%|%}%') or (comments like '%{%}%{%}%{%}%' and comments not like '%{%|%|%}%{%|%|%}%{%|%|%}%')
    union all
         select e.id, e.title, g.text, 'program authored with another program that is not utility' from relations r inner join entries e on r.original_id = e.id left join genretypes g on e.genretype_id = g.id where r.relationtype_id = 'a' and g.text not like 'Utility:%'
    union all
         select e.id, e.title, g.text, 'game editor that is not utility' from relations r inner join entries e on r.entry_id = e.id left join genretypes g on e.genretype_id = g.id where r.relationtype_id = 'e' and g.text not like 'Utility:%'
    union all
         select e.id, e.title, concat(b.name,' / ',t.name), 'author''s team must be a company' from entries e inner join authors a on e.id = a.entry_id inner join labels t on t.id = a.team_id inner join labels b on b.id = a.label_id where t.labeltype_id in ('+','-') or t.labeltype_id is null
    union all
        select e.id, e.title, '', 'Timex programs require ID above 4000000' from entries e inner join machinetypes t on e.machinetype_id = t.id where t.text like 'Timex%' and e.id not between 4000000 and 4999999
    union all
        select e.id, e.title, '', 'books require ID above 2000000' from entries e inner join genretypes g on e.genretype_id = g.id where g.text like 'Book%' and e.id not between 2000000 and 2999999
    union all
        select e.id, e.title, '', 'hardwares require ID above 1000000' from entries e inner join genretypes g on e.genretype_id = g.id where g.text like 'Hardware%' and e.id not between 1000000 and 1999999
) as errors order by entry_id;

-- END
