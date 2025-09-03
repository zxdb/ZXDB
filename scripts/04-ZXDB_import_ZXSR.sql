-- [ZXDB] Import Chris Bourne's ZXSR tables into ZXDB
-- by Einar Saukas

USE zxdb;

drop table if exists tmp_review;
drop table if exists tmp_score_groups;

-- BUGFIXES!
update zxsr.ssd_annualawards_details set zxdbId=1270 where zxdbId='1279';
update zxsr.ssd_annualawards_details set zxdbId=zxdbId-9000000 where zxdbId is not null and zxdbId<>'' and zxdbId>10000000;
update zxsr.ssd_review set game_id=31647 where game_id=31648; -- merged title
update zxsr.ssd_review set game_id=28642 where game_id=28643; -- merged title
delete from zxsr.ssd_review where review_id in (23888,22720,22837,22840); -- duplicated
delete from zxsr.ssd_review where review_id in (18249,24279,6807); -- duplicated
delete from zxsr.ssd_review where review_page in ('109110','120121','124125'); -- incorrect page numbers
delete from zxsr.ssd_review_score where review_id in (24323,24175,24176,22806);
delete from zxsr.ssd_review_score where review_id in (6993,6995,6996); -- duplicated
-- delete from zxsr.ssd_review_score where score_id=75052; -- duplicated

-- Stardard names
update zxsr.ssd_annualawards_details set AwardDescription='Best Coin-op Conversion' where AwardDescription='Best Coin-op conversion';
update zxsr.ssd_annualawards_details set AwardDescription='Best Licence (Not Coin-op) (Nick Roberts)' where AwardDescription='Best Licence (not coin-op) (Nick Roberts)';
update zxsr.ssd_annualawards_details set AwardDescription='Best Licence (Not Coin-op) (Oliver Frey)' where AwardDescription='Best Licence (not coin-op) (Oliver Frey)';
update zxsr.ssd_annualawards_details set AwardDescription='Best Licence (Not Coin-op) (Richard Eddy)' where AwardDescription='Best Licence (not coin-op) (Richard Eddy)';
update zxsr.ssd_annualawards_details set AwardDescription='Best Looking Advert To Appear In A Magazine' where AwardDescription='Best Looking Advert To Appear In a Magazine';
update zxsr.ssd_annualawards_details set AwardDescription='Best Shoot''Em Up' where AwardDescription='Best Shoot Em Up';
update zxsr.ssd_annualawards_details set AwardDescription='State Of The Art Award' where AwardDescription='State of the Art Award';
update zxsr.ssd_annualawards_details set AwardDescription='Best Coin-op Conversion of the Year 8-bit' where AwardDescription='Best Coin-Op Conversion of the Year 8-bit';
update zxsr.ssd_annualawards_details set AwardDescription='Best Coin-op Conversion of the Year 16-bit' where AwardDescription='Best Coin-Op Conversion of the Year 16-bit';

-- Delete previous ZXSR imports
delete from zxsr_captions where 1=1;
delete from zxsr_scores where 1=1;
select * from magrefs where id >= 300000;
delete from magreffeats where magref_id >= 300000;
delete from magrefs where id >= 300000;
update magrefs set review_id = null where 1=1;
update magrefs set award_id = null where award_id <> 50;
update magrefs set score_group='' where score_group not in ('Classic Adventure','Colossal Caves');
delete from zxsr_reviews where 1=1;
delete from members where tag_id in (select id from tags where tagtype_id='A' and (name like 'Big K - Readers Poll%' or name like 'C&VG %Top Ten%' or name like 'Crash Readers Awards %') or name like 'Golden Joystick Awards %' or name like 'Tilt Magazine Awards %' or name like 'Your Computer - Year''s Best %' or name like 'Your Spectrum Strangled Turkey Awards %');
select awarder, awarddescription from zxsr.ssd_annualawards_details where replace(awarddescription,' of 1986','') not in (select text from categories) and awarder in ('Big K','Computer and Video Games','Crash','Golden Joysticks','Your Computer','Your Spectrum') and awarddescription not like '% 16-bit' and awarddescription not like 'Console Game%' and zxdbid is not null and zxdbid<>'' group by awarder, awarddescription order by awarder, awarddescription;

-- Store awards in ZXDB
insert into members(tag_id, entry_id, category_id, member_seq) (select t.id, s.zxdbid, c.id, s.placing from tags t inner join zxsr.ssd_annualawards_details s on t.tagtype_id='A' and t.name=concat('Big K - Readers Poll ',s.year) inner join categories c on c.text=s.awarddescription where s.awarder='Big K' and s.zxdbid is not null and s.zxdbid<>'');
insert into members(tag_id, entry_id, category_id, member_seq) (select t.id, s.zxdbid, 1, NULL from tags t inner join zxsr.ssd_annualawards_details s on t.tagtype_id='A' and t.name like concat('C&VG %Top Ten ',s.year) where s.awarder='Computer and Video Games' and s.zxdbid is not null and s.zxdbid<>'');
insert into members(tag_id, entry_id, category_id, member_seq) (select t.id, s.zxdbid, c.id, s.placing from tags t inner join zxsr.ssd_annualawards_details s on t.tagtype_id='A' and t.name=concat('Crash Readers Awards ',s.year) inner join categories c on c.text=s.awarddescription where s.awarder='Crash' and s.zxdbid is not null and s.zxdbid<>'');
insert into members(tag_id, entry_id, category_id, member_seq) (select t.id, s.zxdbid, c.id, s.placing from tags t inner join zxsr.ssd_annualawards_details s on t.tagtype_id='A' and t.name=concat('Golden Joystick Awards ',s.year) inner join categories c on c.text=s.awarddescription where s.awarder='Golden Joysticks' and s.zxdbid is not null and s.zxdbid<>'');
insert into members(tag_id, entry_id, category_id, member_seq) (select t.id, s.zxdbid, c.id, s.placing from tags t inner join zxsr.ssd_annualawards_details s on t.tagtype_id='A' and t.name=concat('Tilt Magazine Awards ',s.year) inner join categories c on c.text=s.awarddescription where s.awarder='Computer and Video Games' and s.zxdbid is not null and s.zxdbid<>'');
insert into members(tag_id, entry_id, category_id, member_seq) (select t.id, s.zxdbid, c.id, s.placing from tags t inner join zxsr.ssd_annualawards_details s on t.tagtype_id='A' and t.name=concat('Your Computer - Year''s Best ',s.year) inner join categories c on c.text=replace(s.awarddescription,concat(' of ',s.year),'') where s.awarder='Your Computer' and s.zxdbid is not null and s.zxdbid<>'');
insert into members(tag_id, entry_id, category_id, member_seq) (select t.id, s.zxdbid, c.id, s.placing from tags t inner join zxsr.ssd_annualawards_details s on t.tagtype_id='A' and t.name=concat('Your Spectrum Strangled Turkey Awards ',s.year) inner join categories c on c.text=s.awarddescription where s.awarder='Your Spectrum' and s.zxdbid is not null and s.zxdbid<>'');

-- Store review text in ZXDB
insert into zxsr_reviews(id, review_text, review_comments, review_rating, reviewers) (select text_id, replace(review_text,'\r',''), replace(replace(review_comments,'\r',''),'¬','\n\n\n\n'), replace(review_rating,'\r',''), reviewers from zxsr.ssd_review_text);

update zxsr_reviews set review_text = SUBSTR(review_text,2) where review_text like '\n%';
update zxsr_reviews set review_text = SUBSTR(review_text,1,CHAR_LENGTH(review_text)-1) where review_text like '%\n';
update zxsr_reviews set review_text = SUBSTR(review_text,1,CHAR_LENGTH(review_text)-1) where review_text like '%\n';

update zxsr_reviews set review_comments = SUBSTR(review_comments,1,CHAR_LENGTH(review_comments)-1) where review_comments like '%\n';

update zxsr_reviews set review_rating = SUBSTR(review_rating,1,CHAR_LENGTH(review_rating)-1) where review_rating like '%\n';
update zxsr_reviews set review_rating = SUBSTR(review_rating,1,CHAR_LENGTH(review_rating)-1) where review_rating like '%\n';
update zxsr_reviews set review_rating = SUBSTR(review_rating,1,CHAR_LENGTH(review_rating)-1) where review_rating like '%\n';

-- Associate reviews between ZXSR and ZXDB
create table tmp_review (
    id int(11) not null primary key,
    magref_id int(11) unique,
    page smallint(6) not null,
    score_group varchar(100) not null default '',
    variant tinyint(4) not null default 0,
    constraint fk_tmp_review_magref foreign key (magref_id) references magrefs(id)
);

insert into tmp_review (id, page) (select review_id, trim(substring_index(replace(replace(replace(lower(review_page),'(supplement)',''),'.',','),'-',','),',',1)) from zxsr.ssd_review);

-- Whenever the same review of the same game appears twice in ZXSR, give each one a "score_group" name to distinguish between them
create table tmp_score_groups (
    entry_id int(11) not null,
    issue_id int(11) not null,
    page smallint(6) not null,
    overall_score varchar(255) not null,
    variant tinyint(4) not null,
    score_group varchar(100) not null,
    primary key(entry_id, issue_id, page, overall_score)
);

insert into tmp_score_groups (entry_id, issue_id, page, overall_score, variant, score_group) values
(176, 1007, 116, 92, 0, '48K'),         -- Amaurote
(176, 1007, 116, 94, 1, '128K'),
(2054, 1001, 18, 80, 0, '48K'),         -- Glider Rider
(2054, 1001, 18, 92, 1, '128K'),
(4863, 1003, 22, 95, 0, '48K'),         -- Starglider
(4863, 1003, 22, 97, 1, '128K'),
(5061, 995, 24, 86, 0, 'Pros'),         -- SuperCom
(5061, 995, 24, 21, 1, 'Cons'),
(4448, 94, 50, 85, 0, 'Charles Wood'),  -- Shark
(4448, 94, 50, 78, 1, 'Garth Sumpter'),
(5218, 94, 50, 65, 0, 'Editor'),        -- Thanatos
(5218, 94, 50, 73, 1, 'Garth Sumpter'),
(5630, 94, 51, 35, 0, 'Andrew Buchan'), -- War Machine
(5630, 94, 51, 61, 1, 'Garth Sumpter'),
(2081, 298, 59, 30, 0, 'Standalone');   -- Golden Axe

update tmp_review t
inner join zxsr.ssd_review z on t.id = z.review_id
inner join zxsr.ssd_review_score s on t.id = s.review_id
inner join tmp_score_groups x on z.game_id = x.entry_id and z.zxdb_issue_id = x.issue_id and t.page = x.page
set t.variant = x.variant, t.score_group = x.score_group
where s.review_header='Overall' and s.review_score = x.overall_score;

drop table tmp_score_groups;

update tmp_review t
inner join zxsr.ssd_review z on t.id = z.review_id
inner join zxsr.ssd_review_text x on z.text_id = x.text_id
set t.variant = 0, t.score_group = 'Classic Adventure', t.magref_id = 99567
where z.game_id = 6087 and z.zxdb_issue_id = 971 and t.page = 73 and x.review_text like 'Producer: M%';

update tmp_review t
inner join zxsr.ssd_review z on t.id = z.review_id
inner join zxsr.ssd_review_text x on z.text_id = x.text_id
set t.variant = 1, t.score_group = 'Colossal Caves', t.magref_id = 237072
where z.game_id = 6087 and z.zxdb_issue_id = 971 and t.page = 73 and x.review_text like 'Producer: C%';

update tmp_review t
inner join zxsr.ssd_review z on t.id = z.review_id
inner join magrefs r on z.game_id = r.entry_id and z.zxdb_issue_id = r.issue_id and t.page = r.page
set t.magref_id = r.id, r.score_group = t.score_group
where t.variant = 0 and t.magref_id is null and r.score_group = '' and r.referencetype_id = 10;

-- Add a magazine reference in magrefs if it's not already there
insert into magrefs(id, referencetype_id, entry_id, issue_id, page, score_group) (select 300000+t.id, 10, z.game_id, z.zxdb_issue_id, t.page, t.score_group from tmp_review t inner join zxsr.ssd_review z on z.review_id = t.id where t.magref_id is null);

update tmp_review set magref_id = 300000+id where magref_id is null;

-- Store review information in magrefs
update magrefs r inner join tmp_review t on r.id = t.magref_id inner join zxsr.ssd_review z on t.id = z.review_id set r.award_id = if(z.award_id not in (999,41), z.award_id, null), r.review_id = z.text_id where 1=1;

-- Store review scores in ZXDB
insert into zxsr_scores(magref_id, score_seq, category, is_overall, score, comments) (select t.magref_id, s.header_order, s.review_header, 0, nullif(concat(coalesce(trim(s.review_score),''),coalesce(trim(s.score_suffix),'')),''), nullif(replace(s.score_text,'\r',''),'') from tmp_review t inner join zxsr.ssd_review_score s on s.review_id = t.id order by t.magref_id, s.header_order);

-- Add a reference to the compilation content's review in ZXDB if it's not already there
insert into magrefs(id, referencetype_id, entry_id, issue_id, page, score_group, review_id) (select 350000+c.score_id, 10, c.game_id, z.zxdb_issue_id, t.page, if(c.game_id=2081,'Compilation',''), z.text_id from zxsr.ssd_review_score_compilations c inner join zxsr.ssd_review z on c.review_id = z.review_id inner join tmp_review t on z.review_id = t.id left join magrefs r on c.game_id = r.entry_id and z.zxdb_issue_id = r.issue_id and t.page = r.page and r.referencetype_id = 10 and r.score_group = '' where r.id is null group by c.game_id, z.zxdb_issue_id, t.page order by c.game_id, z.zxdb_issue_id, t.page);

-- Store compilation content's review information in magrefs
update zxsr.ssd_review_score_compilations c
inner join zxsr.ssd_review z on c.review_id = z.review_id
inner join tmp_review t on z.review_id = t.id
inner join magrefs r on c.game_id = r.entry_id and z.zxdb_issue_id = r.issue_id and t.page = r.page and r.referencetype_id = 10
set r.review_id = z.text_id
where r.review_id is null;

-- Store compilation content's review scores in ZXDB
insert into zxsr_scores(magref_id, score_seq, category, is_overall, score) (select r.id, if(c.review_header like '%(%',c.header_order,1), c.review_header, 0, nullif(concat(coalesce(trim(c.review_score),''),coalesce(trim(c.score_suffix),'')),'')
from zxsr.ssd_review_score_compilations c
inner join zxsr.ssd_review z on c.review_id = z.review_id
inner join tmp_review t on z.review_id = t.id
inner join magrefs r on c.game_id = r.entry_id and z.zxdb_issue_id = r.issue_id and t.page = r.page and r.referencetype_id = 10 and r.score_group <> 'Standalone'
order by r.id, c.header_order);

-- Identify overall scores
update zxsr_scores s1 left join zxsr_scores s2 on s1.magref_id = s2.magref_id and s2.score_seq > s1.score_seq set s1.is_overall = 1 where s2.magref_id is null and (s1.score_seq = 1 or s1.category = 'Ace Rating' or s1.category = 'ACE Rating' or s1.category = 'Verdict' or (s1.category like 'Overall%' and s1.category not in ('Overall (Richard Eddy)','Overall (Dominic Handy)')) and s1.score not like '%K)');

-- Store review picture descriptions in ZXDB
alter table zxsr_captions drop primary key;
alter table zxsr_captions add column id int(11) not null primary key auto_increment;

insert into zxsr_captions(magref_id, caption_seq, text, is_banner) (select t.magref_id, 0, replace(p.pic_text,'\r',''), p.is_banner
from zxsr.ssd_review_picture s
inner join zxsr.ssd_review_picture_text p on s.text_id = p.text_id
inner join tmp_review t on s.ReviewId = t.id
group by t.magref_id, p.is_banner, p.pic_text
order by t.magref_id, p.is_banner, p.pic_text);

-- Calculate review picture description sequences
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);
update zxsr_captions set caption_seq=(select max(caption_seq)+1 from zxsr_captions) where id in (select min(id) from zxsr_captions where caption_seq=0 group by magref_id);

alter table zxsr_captions modify id int(11);
alter table zxsr_captions drop primary key, add primary key(magref_id,caption_seq);
alter table zxsr_captions drop column id;

drop table tmp_review;

-- END
