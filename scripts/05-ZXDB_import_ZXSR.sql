-- [ZXDB] Import Chris Bourne's ZXSR tables into ZXDB
-- by Einar Saukas

USE zxdb;

-- BUGFIXES!
-- update ssd.ssd_reviews set game_id = 8481 where review_id = 20923 and game_id = 8965;
-- update ssd.ssd_reviews set game_id = 1976 where review_id = 4752 and game_id = 16628;
-- update ssd.ssd_reviews set game_id = 5106 where game_id = 10675;
-- update ssd.ssd_reviews set game_id = 11417 where game_id = 12197;
-- update ssd.ssd_reviews set game_id = 9914 where game_id = 15920;
-- update ssd.ssd_reviews set game_id = 5007 where game_id = 26392;

-- Map SSD_Magazines(mag_id) from/to ZXDB.magazines(id)
create table tmp_magazines(
  ssd_mag_id INT(11) NOT NULL primary key,
  magazine_id SMALLINT(6) not null,
  foreign key fk_tmp_magazine (magazine_id) references magazines(id),
  foreign key fk_tmp_ssd_magazine (ssd_mag_id) references ssd.ssd_magazines(mag_id)
);

insert into tmp_magazines(ssd_mag_id, magazine_id) (
  select s.mag_id,m.id from ssd.ssd_magazines s inner join magazines m on
  lower(replace(replace(replace(s.mag_name,
  'Which Micro Software Review','Which Micro? & Software Review'),
  'ACE','ACE (Advanced Computer Entertainment)'),
  'Computer & Videogames','C&VG (Computer & Video Games)')
  ) = lower(m.name) where 1=1);

select * from ssd.ssd_magazines where mag_id not in (select ssd_mag_id from tmp_magazines);
select * from ssd.ssd_issues s where s.mag_id not in (select ssd_mag_id from tmp_magazines);
select * from ssd.ssd_reviewers r where r.MagazineId not in (select ssd_mag_id from tmp_magazines);
select * from ssd.ssd_lookreviewaward r where r.mag_type not in (select ssd_mag_id from tmp_magazines);

-- Map SSD_Issues(IssueCode) from/to ZXDB.issues(id)
create table tmp_issues(
  ssd_issuecode INT(11) NOT NULL primary key,
  issue_id INT(11) not null,
  foreign key fk_tmp_issue (issue_id) references issues(id),
  foreign key fk_tmp_ssd_issue (ssd_issuecode) references ssd.ssd_issues(IssueCode)
);

insert into tmp_issues(ssd_issuecode, issue_id) values
((select s.IssueCode from ssd.ssd_issues s inner join ssd.ssd_magazines m on m.mag_id=s.mag_id where s.Issue = '1984 Annual' and m.mag_name = 'Sinclair User Annual'),(select i.id from issues i inner join magazines m on i.magazine_id = m.id where i.parent_id is null and m.name = 'Sinclair User' and i.special = 'Annual 1984')),
((select s.IssueCode from ssd.ssd_issues s inner join ssd.ssd_magazines m on m.mag_id=s.mag_id where s.Issue = 'Issue December 1984' and m.mag_name = 'ZX Collection'),(select i.id from issues i inner join magazines m on i.magazine_id = m.id where i.parent_id is null and m.name = 'ZX Collection' and i.date_year = 1984)),
((select s.IssueCode from ssd.ssd_issues s inner join ssd.ssd_magazines m on m.mag_id=s.mag_id where s.Issue = 'Issue May 1986' and m.mag_name = 'Popular Computing Weekly Supplement'),(select i.id from issues i inner join magazines m on i.magazine_id = m.id where i.parent_id is not null and m.name = 'Popular Computing Weekly' and i.number = 21)),
((select s.IssueCode from ssd.ssd_issues s inner join ssd.ssd_magazines m on m.mag_id=s.mag_id where s.Issue = 'Issue September 1982' and m.mag_name = 'ZX Computing'),(select i.id from issues i inner join magazines m on i.magazine_id = m.id where i.parent_id is null and m.name = 'ZX Computing' and i.date_year = 1982 and i.date_month = 8)),
((select s.IssueCode from ssd.ssd_issues s inner join ssd.ssd_magazines m on m.mag_id=s.mag_id where s.Issue = 'Top 50 Spectrum Software Classics' and m.mag_name = 'Sinclair User'),(select i.id from issues i inner join magazines m on i.magazine_id = m.id where m.name = 'Sinclair User' and i.supplement = 'Top 50 Spectrum Software Classics'));

insert into tmp_issues(ssd_issuecode, issue_id) (select s.IssueCode,i.id from ssd.ssd_issues s inner join tmp_magazines t on t.ssd_mag_id = s.mag_id inner join issues i on i.magazine_id = t.magazine_id and s.Issue = concat('Issue ',i.number,', ',MONTHNAME(STR_TO_DATE(i.date_month, '%m')),' ',i.date_year) where i.parent_id is null and i.date_year is not null and i.date_month is not null and i.number is not null);

insert into tmp_issues(ssd_issuecode, issue_id) (select s.IssueCode,i.id from ssd.ssd_issues s inner join tmp_magazines t on t.ssd_mag_id = s.mag_id inner join issues i on i.magazine_id = t.magazine_id and s.Issue = concat('Issue 0',i.number,', ',MONTHNAME(STR_TO_DATE(i.date_month, '%m')),' ',i.date_year) where i.parent_id is null and i.date_year is not null and i.date_month is not null and i.number is not null);

insert into tmp_issues(ssd_issuecode, issue_id) (select s.IssueCode,i.id from ssd.ssd_issues s inner join tmp_magazines t on t.ssd_mag_id = s.mag_id inner join issues i on i.magazine_id = t.magazine_id and s.Issue = concat('Issue ',MONTHNAME(STR_TO_DATE(i.date_month, '%m')),' ',i.date_year) where i.parent_id is null and i.date_year is not null and i.date_month is not null and s.IssueCode not in (select ssd_issuecode from tmp_issues));

insert into tmp_issues(ssd_issuecode, issue_id) (select s.IssueCode,i.id from ssd.ssd_issues s inner join tmp_magazines t on t.ssd_mag_id = s.mag_id inner join issues i on i.magazine_id = t.magazine_id and i.number = substring(substring_index(s.Issue,',',1),7) where i.parent_id is null and s.Issue like 'Issue %,%' and s.IssueCode not in (select ssd_issuecode from tmp_issues));

select * from ssd.ssd_issues r where r.IssueCode not in (select t.ssd_issuecode from tmp_issues t);
select * from ssd.ssd_reviews r where r.issue_code not in (select t.ssd_issuecode from tmp_issues t);

-- Build a ZXDB-friendly version of SSD_Reviews
create table tmp_reviews (
    id int(11) not null primary key,
    entry_id int(11) not null,
    issue_id int(11) not null,
    page smallint(6) not null,
    is_supplement tinyint(1) not null,
    mag_section varchar(50),
    review_text longtext,
    review_comments longtext,
    review_rating longtext,
    reviewers longtext,
    award_id tinyint(4),
    score_group varchar(100) not null default '',
    variant tinyint(4) not null default 0,
    parent_id int(11),
    magref_id int(11),
    prefix_review_text varchar(100) not null default '',
    constraint fk_tmp_review_entry foreign key (entry_id) references entries(id),
    constraint fk_tmp_review_issue foreign key (issue_id) references issues(id),
    constraint fk_tmp_review_award foreign key (award_id) references zxsr_awards(id),
    constraint fk_tmp_review_parent foreign key (parent_id) references tmp_reviews(id),
    constraint fk_tmp_review_magref foreign key (magref_id) references magrefs(id),
    index ix_tmp_text(prefix_review_text)
);

insert into tmp_reviews(id, entry_id, issue_id, page, is_supplement, mag_section, review_text, review_comments, review_rating, reviewers, award_id) (
select s.review_id, s.game_id, i.issue_id,
nullif(trim(substring_index(replace(replace(s.review_page,'(Supplement)',''),'.',','),',',1)),''),
if (s.review_page like '%(Supplement)',1,0),
m.mag_name,
nullif(replace(s.review_text,'\r',''),''),
nullif(replace(replace(s.review_comments,'\r',''),'¬','\n\n\n\n'),''),
nullif(replace(s.review_rating,'\r',''),''),
nullif(s.reviewers,''),
if (s.award_id<>999,s.award_id,null)
from ssd.ssd_reviews s
left join tmp_issues i on s.issue_code=i.ssd_issuecode
left join ssd.ssd_magazines m on m.mag_id = s.mag_type and m.mag_id between 7 and 18);

-- Fix issue supplement references
update tmp_reviews r left join issues i on r.issue_id = i.parent_id set r.issue_id = i.id where r.is_supplement = 1;
alter table tmp_reviews drop column is_supplement;

-- Choose a single copy of duplicated reviews
update tmp_reviews set parent_id = id where id in (select min(id) from tmp_reviews group by review_text,review_comments,review_rating,reviewers);

update tmp_reviews set prefix_review_text = substr(review_text,1,100) where review_text is not null;

update tmp_reviews s1 inner join tmp_reviews s2
on s1.prefix_review_text = s2.prefix_review_text
and coalesce(s1.review_text,'') = coalesce(s2.review_text,'')
and coalesce(s1.review_comments,'') = coalesce(s2.review_comments,'')
and coalesce(s1.review_rating,'') = coalesce(s2.review_rating,'')
and coalesce(s1.reviewers,'') = coalesce(s2.reviewers,'')
set s1.parent_id = s2.parent_id
where s1.parent_id is null and s2.parent_id is not null;

-- Whenever the same review of the same game appears twice in SSD_Reviews, give each one a "score_group" name to distinguish between them
create table tmp_score_groups (
    entry_id int(11) not null,
    issue_id int(11) not null,
    page smallint(6) not null,
    overall_score varchar(255) not null,
    variant tinyint(4) not null,
    score_group varchar(100) not null,
    primary key(entry_id, issue_id, page, overall_score)
);

update tmp_reviews set variant=0, score_group='Classic Adventure' where entry_id = 6087 and issue_id=971 and page = 73 and review_text like 'Producer: M%';
update tmp_reviews set variant=1, score_group='Colossal Caves' where entry_id = 6087 and issue_id=971 and page = 73 and review_text like 'Producer: C%';

insert into tmp_score_groups (entry_id, issue_id, page, overall_score, variant, score_group) values
(176, 1007, 116, 94, 1, '128K'),   -- Amaurote
(176, 1007, 116, 92, 0, '48K'),
(4863, 1003, 22, 97, 1, '128K'),   -- Starglider
(4863, 1003, 22, 95, 0, '48K'),
(2054, 1001, 18, 92, 1, '128K'),   -- Glider Rider
(2054, 1001, 18, 80, 0, '48K'),
(4448, 94, 50, 85, 0, 'Charles Wood'),   -- Shark
(4448, 94, 50, 78, 1, 'Garth Sumpter'),
(5630, 94, 51, 35, 0, 'Andrew Buchan'),   -- War Machine
(5630, 94, 51, 61, 1, 'Garth Sumpter'),
(5218, 94, 50, 65, 0, 'Editor'),          -- Thanatos
(5218, 94, 50, 73, 1, 'Garth Sumpter'),
(5061, 995, 24, 86, 0, 'Pros'),   -- SuperCom
(5061, 995, 24, 21, 1, 'Cons');

update tmp_reviews t inner join ssd.ssd_reviews_scores s on t.id = s.review_id inner join tmp_score_groups x on t.entry_id = x.entry_id and t.issue_id = x.issue_id and t.page = x.page set t.variant = x.variant, t.score_group = x.score_group where s.review_header='Overall' and s.review_score = x.overall_score;

drop table tmp_score_groups;

-- Store review text in ZXDB
insert into zxsr_reviews(id, review_text, review_comments, review_rating, reviewers) (select parent_id, review_text, review_comments, review_rating, reviewers from tmp_reviews group by parent_id, review_text, review_comments, review_rating, reviewers);

-- Add a magazine reference in magrefs if it's not already there
insert into magrefs(referencetype_id, entry_id, issue_id, page) (select 10, entry_id, issue_id, page from tmp_reviews where id not in (select t.id from tmp_reviews t inner join magrefs r on t.entry_id = r.entry_id and t.issue_id = r.issue_id and t.page = r.page and r.referencetype_id = 10) group by entry_id, issue_id, page);

-- Store review information in magrefs
update tmp_reviews t inner join magrefs r on t.entry_id = r.entry_id and t.issue_id = r.issue_id and t.page = r.page and r.referencetype_id = 10 set r.score_group = t.score_group, r.review_id = t.parent_id, r.award_id = t.award_id where t.variant = 0;

insert into magrefs(referencetype_id, entry_id, issue_id, page, score_group, review_id, award_id) (select 10, entry_id, issue_id, page, score_group, parent_id, award_id from tmp_reviews where variant=1);

update tmp_reviews t inner join magrefs r on t.entry_id = r.entry_id
and t.issue_id = r.issue_id
and t.page = r.page
and t.score_group = r.score_group
and r.referencetype_id = 10
set t.magref_id = r.id
where 1=1;

-- Store review "mag section" in ZXDB
insert into magreffeats (magref_id, feature_id) (select t.magref_id, f.id from tmp_reviews t left join features f on f.name = t.mag_section and f.id between 100 and 800 left join magreffeats z on z.magref_id = t.magref_id and z.feature_id = f.id where t.mag_section is not null and z.magref_id is null group by t.magref_id, f.id);

-- Store review scores in ZXDB
insert into zxsr_scores(magref_id, score_seq, category, is_overall, score, comments) (select t.magref_id, s.header_order, s.review_header, 0, nullif(concat(coalesce(trim(s.review_score),''),coalesce(trim(s.score_suffix),'')),''),nullif(replace(s.score_text,'\r',''),'') from ssd.ssd_reviews_scores s inner join tmp_reviews t on s.review_id = t.id);

-- Add a reference to the compilation content's review in ZXDB if it's not already there
insert into magrefs(referencetype_id, entry_id, issue_id, page)
(select 10, c.game_id, t.issue_id, t.page from ssd.ssd_reviews_scores_compilations c
inner join tmp_reviews t on c.review_id = t.id
where c.score_id not in (
select c.score_id from ssd.ssd_reviews_scores_compilations c
inner join tmp_reviews t on c.review_id = t.id
inner join magrefs r on c.game_id = r.entry_id
and t.issue_id = r.issue_id
and t.page = r.page
and r.referencetype_id = 10)
group by c.game_id, t.issue_id, t.page);

-- Store compilation content's review information in magrefs
update ssd.ssd_reviews_scores_compilations c
inner join tmp_reviews t on c.review_id = t.id
inner join magrefs r on c.game_id = r.entry_id
and t.issue_id = r.issue_id
and t.page = r.page
and r.referencetype_id = 10
and r.score_group = ''
set r.review_id = t.parent_id
where 1=1;

-- Store compilation content's review scores in ZXDB
insert into zxsr_scores(magref_id, score_seq, category, is_overall, score) (select r.id, c.header_order, c.review_header, 0, nullif(concat(coalesce(trim(c.review_score),''),coalesce(trim(c.score_suffix),'')),'')
from ssd.ssd_reviews_scores_compilations c
inner join tmp_reviews t on c.review_id = t.id
inner join magrefs r on c.game_id = r.entry_id
and t.issue_id = r.issue_id
and t.page = r.page
and r.referencetype_id = 10 and
r.score_group = '');

-- Identify overall scores
update zxsr_scores s1 left join zxsr_scores s2 on s1.magref_id = s2.magref_id and s2.score_seq > s1.score_seq set s1.is_overall = 1 where s2.magref_id is null and (s1.score_seq = 1 or s1.category = 'Ace Rating' or s1.category = 'ACE Rating' or s1.category = 'Verdict' or (s1.category like 'Overall%' and s1.category not like 'Overall (%') and s1.score not like '%K)');

-- Store review picture descriptions in ZXDB
insert into zxsr_captions(id, magref_id, caption_seq, text, is_banner) (select s.id,t.magref_id, 0, replace(s.TheText,'\r',''), s.IsBanner from ssd.ssd_reviews_picturetext s inner join tmp_reviews t on s.ReviewId = t.id);

update zxsr_reviews set review_text = SUBSTR(review_text,2) where review_text like '\n%';
update zxsr_reviews set review_text = SUBSTR(review_text,1,CHAR_LENGTH(review_text)-1) where review_text like '%\n';
update zxsr_reviews set review_text = SUBSTR(review_text,1,CHAR_LENGTH(review_text)-1) where review_text like '%\n';

update zxsr_reviews set review_comments = SUBSTR(review_comments,2) where review_comments like '\n%';
update zxsr_reviews set review_comments = SUBSTR(review_comments,1,CHAR_LENGTH(review_comments)-1) where review_comments like '%\n';

update zxsr_reviews set review_rating = SUBSTR(review_rating,2) where review_rating like '\n%';
update zxsr_reviews set review_rating = SUBSTR(review_rating,1,CHAR_LENGTH(review_rating)-1) where review_rating like '%\n';
update zxsr_reviews set review_rating = SUBSTR(review_rating,1,CHAR_LENGTH(review_rating)-1) where review_rating like '%\n';
update zxsr_reviews set review_rating = SUBSTR(review_rating,1,CHAR_LENGTH(review_rating)-1) where review_rating like '%\n';

update zxsr_scores set comments = SUBSTR(comments,2) where comments like '\n%';
update zxsr_scores set comments = SUBSTR(comments,1,CHAR_LENGTH(comments)-1) where comments like '%\n';

update zxsr_captions set text = SUBSTR(text,2) where text like '\n%';
update zxsr_captions set text = SUBSTR(text,1,CHAR_LENGTH(text)-1) where text like '%\n';

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

alter table zxsr_captions add primary key(magref_id,caption_seq,is_banner);
alter table zxsr_captions drop column id;

drop table tmp_reviews;
drop table tmp_issues;
drop table tmp_magazines;

-- END
