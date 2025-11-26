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
where name not in (select name from zxdb.tags) and name not like 'Comp Sys Sinclair Crap Games Competition %'
group by id
order by name;

-- Categories from Demozoo not in ZXDB
select concat('(''',category,'''),') as 'insert into categories(text) values'
from (
select replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(c.name,'CAFePARTY 2019 Invitations','Invitation'),'BASIC 10Liner Contest ',''),'Old School Demo','Oldschool Demo'),'Combined - Game','Combined Game'),'64 Byte Intro Oldschool','Oldschool 64b Intro'),'256 Byte Intro Oldschool','Oldschool 256b Intro'),'Low End','LowEnd'),' Tiny Intro (256b)',' 256b Intro'),' Intro 256B',' 256b Intro'),' Intro 4KB',' 4K Intro'),' Intro 4Kb',' 4K Intro'),' Intro 4k',' 4K Intro'),'640k ','640K '),' Byte ','b '),'Kb ','K '),'kb ','K '),'1k','1K'),'4k','4K'),'8-bit - ','8Bit '),'8-bit ','8Bit '),'8bit','8Bit'),' plattform ',' Platform '),' showcase',' Showcase'),' intro',' Intro'),' demo',' Demo'),' game',' Game'),'WILD','Wild'),'(normal results)',''),'(alternative results)','') as category
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
select concat('(',eid,',',tid,',',gid,',',if(pos REGEXP '^[0-9]+$',pos,'null'),'),') as 'insert into members(entry_id, tag_id, category_id, member_seq) values' from (
select e.id as eid, t.id as tid, g.id as gid, replace(replace(replace(replace(n.ranking,'=',''),'#',''),'Split',''),' ','') as pos
from zxdb.entries e
inner join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 48
inner join public.productions_production p on p.id = replace(replace(w.link,'https://demozoo.org/productions/',''),'/','')
inner join public.parties_competitionplacing n on p.id = n.production_id
inner join public.parties_competition c on n.competition_id = c.id
inner join public.parties_party y on c.party_id = y.id
inner join zxdb.tags t on t.name = y.name
inner join zxdb.categories g on g.text = replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(c.name,'CAFePARTY 2019 Invitations','Invitation'),'BASIC 10Liner Contest ',''),'Old School Demo','Oldschool Demo'),'Combined - Game','Combined Game'),'64 Byte Intro Oldschool','Oldschool 64b Intro'),'256 Byte Intro Oldschool','Oldschool 256b Intro'),'Low End','LowEnd'),' Tiny Intro (256b)',' 256b Intro'),' Intro 256B',' 256b Intro'),' Intro 4KB',' 4K Intro'),' Intro 4Kb',' 4K Intro'),' Intro 4k',' 4K Intro'),'640k ','640K '),' Byte ','b '),'Kb ','K '),'kb ','K '),'1k','1K'),'4k','4K'),'8-bit - ','8Bit '),'8-bit ','8Bit '),'8bit','8Bit'),' plattform ',' Platform '),' showcase',' Showcase'),' intro',' Intro'),' demo',' Demo'),' game',' Game'),'WILD','Wild'),'(normal results)',''),'(alternative results)','')
left join zxdb.members m on m.tag_id = t.id and m.entry_id = e.id and m.category_id = g.id
where m.tag_id is null and t.id not in (30046)
union all
select e.id, t.id, g.id, ''
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
select e.id, t.id, 1, ''
from zxdb.entries e
inner join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 48
inner join public.productions_production p on p.id = replace(replace(w.link,'https://demozoo.org/productions/',''),'/','')
inner join public.parties_party_releases n on p.id = n.production_id
inner join public.parties_party y on n.party_id = y.id
inner join zxdb.tags t on t.name = y.name
left join zxdb.members m on m.tag_id = t.id and m.entry_id = e.id
where m.tag_id is null) as z order by eid, tid;

-- Add missing Pouet links
select concat('(',w.entry_id,', ''https://www.pouet.net/prod.php?which=',k.parameter,''', ''en'', 49),')
as 'insert into webrefs(entry_id, link, language_id, website_id) values'
from zxdb.entries e
inner join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 48
inner join public.productions_production p on p.id = replace(replace(w.link,'https://demozoo.org/productions/',''),'/','')
inner join public.productions_productionlink k on p.id = k.production_id and k.link_class = 'PouetProduction'
where e.id not in (select entry_id from zxdb.webrefs where website_id=49)
order by e.id;

-- Add missing Itch.io links
select concat('(',w.entry_id,', ''',k.parameter,''', ''en'', 31),')
as 'insert into webrefs(entry_id, link, language_id, website_id) values'
from zxdb.entries e
inner join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 48
inner join public.productions_production p on p.id = replace(replace(w.link,'https://demozoo.org/productions/',''),'/','')
inner join public.productions_productionlink k on p.id = k.production_id and k.link_class = 'BaseUrl' and k.parameter like '%.itch.io/%'
where e.id not in (select entry_id from zxdb.webrefs where website_id=31)
order by e.id;

-- List mismatching Pouet links
select w2.link, k.parameter,w.entry_id,p.id
from zxdb.entries e
inner join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 48
inner join public.productions_production p on p.id = replace(replace(w.link,'https://demozoo.org/productions/',''),'/','')
inner join public.productions_productionlink k on p.id = k.production_id and k.link_class = 'PouetProduction'
inner join zxdb.webrefs w2 on w2.entry_id = e.id and w2.website_id = 49
where w2.link <> concat('https://www.pouet.net/prod.php?which=',k.parameter)
order by e.id;

-- List mismatching Itch.io links
select w2.link, k.parameter,w.entry_id,p.id
from zxdb.entries e
inner join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 48
inner join public.productions_production p on p.id = replace(replace(w.link,'https://demozoo.org/productions/',''),'/','')
inner join public.productions_productionlink k on p.id = k.production_id and k.link_class = 'BaseUrl' and k.parameter like '%.itch.io/%'
inner join zxdb.webrefs w2 on w2.entry_id = e.id and w2.website_id = 31
where w2.link <> k.parameter
order by e.id;

-- ZXDB links missing from Demozoo
select concat('https://spectrumcomputing.co.uk/entry/',e.id),w.link
from zxdb.entries e
inner join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 48
inner join public.productions_production p on p.id = replace(replace(w.link,'https://demozoo.org/productions/',''),'/','')
left join public.productions_productionlink k on p.id = k.production_id and k.link_class = 'SpectrumComputingRelease'
where k.link_class is null;

-- Demozoo links missing from ZXDB
select concat('(',entry_id,', ''https://demozoo.org/productions/',production_id,'/'', ''en'', 48),')
as 'insert into webrefs(entry_id, link, language_id, website_id) values'
from (
-- Link from Demozoo to ZXDB but not vice-versa
  select e.id as entry_id, k.production_id
  from public.productions_production p
  inner join public.productions_productionlink k on p.id = k.production_id and k.link_class = 'SpectrumComputingRelease'
  inner join zxdb.entries e on e.id = k.parameter
  left join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 48 and concat('https://demozoo.org/productions/',p.id,'/') = w.link
  where w.entry_id is null
union all
-- Both sites sharing links to Pouet
  select w.entry_id, k.production_id
  from zxdb.entries e
  inner join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 49
  inner join public.productions_productionlink k on k.link_class = 'PouetProduction' and w.link = concat('https://www.pouet.net/prod.php?which=',k.parameter)
  inner join public.productions_production p on p.id = k.production_id
  where e.id not in (select entry_id from zxdb.webrefs where website_id = 48)
union all
-- Both sites sharing links to Itch.io
  select w.entry_id, k.production_id
  from zxdb.entries e
  inner join zxdb.webrefs w on w.entry_id = e.id and w.website_id = 31
  inner join public.productions_productionlink k on k.link_class = 'BaseUrl' and k.parameter like '%.itch.io/%' and w.link = k.parameter
  inner join public.productions_production p on p.id = k.production_id
  inner join public.productions_production_platforms r on p.id = r.production_id
  where e.id not in (select entry_id from zxdb.webrefs where website_id = 48)
  and ((r.platform_id=2 and e.machinetype_id between 1 and 10) or (r.platform_id=45 and e.machinetype_id between 19 and 24) or (r.platform_id=95 and e.machinetype_id=17) or (r.platform_id=51 and e.machinetype_id=16) or (r.platform_id=69 and e.machinetype_id in (14,15,25,26,27)))
) as z
group by entry_id, production_id
order by entry_id, production_id;

-- END
