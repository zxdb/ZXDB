-- [ZXDB] Import into ZXDB some data from Demozoo.
-- The latest Demozoo database dump is available for download at https://demozoo.org/pages/faq/
-- by Einar Saukas

USE zxdb;

-- Demo parties from Demozoo not in ZXDB
select concat('insert into tags(id, name, tagtype_id, link) values ((select k from (select max(id)+1 as k from tags where tagtype_id=''D'') as x), ''',name,''', ''D'', ',if(website<>'',concat('''',website,''''),'null'),');') as qry
from (
select y.* from zxdb.entries e
inner join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 48
inner join public.productions_production p on p.id = replace(replace(w.link,'https://demozoo.org/productions/',''),'/','')
inner join public.parties_competitionplacing n on p.id = n.production_id
inner join public.parties_competition c on n.competition_id = c.id
inner join public.parties_party y on c.party_id = y.id
union all
select y.* from zxdb.entries e
inner join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 48
inner join public.productions_production p on p.id = replace(replace(w.link,'https://demozoo.org/productions/',''),'/','')
inner join public.parties_party_releases n on p.id = n.production_id
inner join public.parties_party y on n.party_id = y.id
union all
select y.* from zxdb.entries e
inner join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 48
inner join public.productions_production p on p.id = replace(replace(w.link,'https://demozoo.org/productions/',''),'/','')
inner join public.parties_party_invitations i on p.id = i.production_id
inner join public.parties_party y on i.party_id = y.id) as x
where name not in (select name from zxdb.tags)
group by id
order by name;

-- Categories from Demozoo not in ZXDB
select concat('(''',category,'''),') as 'insert into categories(text) values'
from (
select replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(c.name,'CAFePARTY 2019 Invitations','Invitation'),' Tiny Intro (256b)',' 256b Intro'),' Intro 256B',' 256b Intro'),' Intro 4KB',' 4K Intro'),'640k ','640K '),' Byte ','b '),'Kb ','K '),'kb ','K '),'1k','1K'),'4k','4K'),'8-bit - ','8Bit '),'8-bit ','8Bit '),'8bit','8Bit'),' plattform ',' Platform '),' intro',' Intro'),' demo',' Demo'),'(normal results)',''),'(alternative results)','') as category
from zxdb.entries e
inner join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 48
inner join public.productions_production p on p.id = replace(replace(w.link,'https://demozoo.org/productions/',''),'/','')
inner join public.parties_competitionplacing n on p.id = n.production_id
inner join public.parties_competition c on n.competition_id = c.id
inner join public.parties_party y on c.party_id = y.id) as x
where category not in (select text from zxdb.categories)
group by category
order by category;

-- Demo party members from Demozoo not in ZXDB
select concat('(',eid,',',tid,',',gid,',',if(pos REGEXP '^[0-9]+$',pos,'null'),',''',variant,'''),') as 'insert into members(entry_id, tag_id, category_id, member_seq, variant) values' from (
select e.id as eid, t.id as tid, g.id as gid, replace(replace(replace(replace(n.ranking,'=',''),'#',''),'Split',''),' ','') as pos, (case when c.name like '%(normal results)' then 'normal results' when c.name like '%(alternative results)' then 'alternative results' else '*' end) as variant
from zxdb.entries e
inner join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 48
inner join public.productions_production p on p.id = replace(replace(w.link,'https://demozoo.org/productions/',''),'/','')
inner join public.parties_competitionplacing n on p.id = n.production_id
inner join public.parties_competition c on n.competition_id = c.id
inner join public.parties_party y on c.party_id = y.id
inner join zxdb.tags t on t.name = y.name
inner join zxdb.categories g on g.text = replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(c.name,'CAFePARTY 2019 Invitations','Invitation'),' Tiny Intro (256b)',' 256b Intro'),' Intro 256B',' 256b Intro'),' Intro 4KB',' 4K Intro'),'640k ','640K '),' Byte ','b '),'Kb ','K '),'kb ','K '),'1k','1K'),'4k','4K'),'8-bit - ','8Bit '),'8-bit ','8Bit '),'8bit','8Bit'),' plattform ',' Platform '),' intro',' Intro'),' demo',' Demo'),'(normal results)',''),'(alternative results)','')
left join zxdb.members m on m.tag_id = t.id and m.entry_id = e.id and m.category_id = g.id
where m.tag_id is null and t.id not in (30046)
union all
select e.id, t.id, g.id, '', '*'
from zxdb.entries e
inner join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 48
inner join public.productions_production p on p.id = replace(replace(w.link,'https://demozoo.org/productions/',''),'/','')
inner join public.parties_party_invitations i on p.id = i.production_id
inner join public.parties_party y on i.party_id = y.id
inner join zxdb.tags t on t.name = y.name
inner join zxdb.categories g on g.text = 'Invitation'
left join zxdb.members m on m.tag_id = t.id and m.entry_id = e.id
where m.tag_id is null
union all
select e.id, t.id, 'null', '', '*'
from zxdb.entries e
inner join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 48
inner join public.productions_production p on p.id = replace(replace(w.link,'https://demozoo.org/productions/',''),'/','')
inner join public.parties_party_releases n on p.id = n.production_id
inner join public.parties_party y on n.party_id = y.id
inner join zxdb.tags t on t.name = y.name
left join zxdb.members m on m.tag_id = t.id and m.entry_id = e.id
where m.tag_id is null) as z order by eid, tid, variant;

-- Add missing Pouet links
select concat('(',w.entry_id,', ''https://www.pouet.net/prod.php?which=',k.parameter,''', ''en'', 49),')
as 'insert into webrefs(entry_id, link, language_id, website_id) values'
from zxdb.entries e
inner join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 48
inner join public.productions_production p on p.id = replace(replace(w.link,'https://demozoo.org/productions/',''),'/','')
inner join public.productions_productionlink k on p.id = k.production_id and k.link_class = 'PouetProduction'
where e.id not in (select entry_id from zxdb.webrefs where website_id=49)
order by e.id;

-- Mismatching Pouet links
select w2.link, k.parameter
from zxdb.entries e
inner join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 48
inner join public.productions_production p on p.id = replace(replace(w.link,'https://demozoo.org/productions/',''),'/','')
inner join public.productions_productionlink k on p.id = k.production_id and k.link_class = 'PouetProduction'
inner join zxdb.webrefs w2 on w2.entry_id = e.id and w2.website_id = 49
where w2.link <> concat('https://www.pouet.net/prod.php?which=',k.parameter)
order by e.id;

-- ZXDB links missing from Demozoo
select concat('https://spectrumcomputing.co.uk/entry/',e.id),w.link
from zxdb.entries e
inner join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 48
inner join public.productions_production p on p.id = replace(replace(w.link,'https://demozoo.org/productions/',''),'/','')
left join public.productions_productionlink k on p.id = k.production_id and k.link_class = 'SpectrumComputingRelease'
where k.link_class is null;

-- Demozoo links missing from ZXDB
select e.id, concat('https://demozoo.org/productions/',p.id,'/')
from public.productions_production p
inner join public.productions_productionlink k on p.id = k.production_id and k.link_class = 'SpectrumComputingRelease'
inner join zxdb.entries e on e.id = k.parameter
left join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 48 and concat('https://demozoo.org/productions/',p.id,'/') = w.link
where w.entry_id is null;

-- END
