# ZXDB

ZXDB is an open database containing historical information of software, hardware, magazines and books about ZX-Spectrum and related machines.

It was created by **Einar Saukas**, starting from the full content of **Martijn van der Heide**'s [Original WorldOfSpectrum](https://web.archive.org/web/20151117205811/http://www.worldofspectrum.org/), **Jim Grimwood**'s [SPOT/SPEX](http://www.users.globalnet.co.uk/~jg27paw4/spot-on/), **Daren Pearcy**'s [RZX Archive](http://www.rzxarchive.co.uk/), and **Chris Bourne**'s [ZXSR](http://www.zxspectrumreviews.co.uk/) repositories (all of them imported with consent, directly from their internal files). Afterwards it was expanded with literally tens of thousands of corrections, additions, and integration from many other sources. It's currently the most widely used Sinclair related database, feeding several Spectrum websites, an [open API](https://api.zxinfo.dk/v3/) at [ZXInfo](https://zxinfo.dk/), and the mobile application [Zx App](https://play.google.com/store/apps/details?id=com.bricboys.zxapp) that uses this API. It's also used as index reference by a dozen different websites and services.

For further details, visit the [ZXDB forum section](https://spectrumcomputing.co.uk/forums/viewforum.php?f=32) at [Spectrum Computing](https://spectrumcomputing.co.uk/).


## Getting Started

Simply download the latest database content, then load it into MySQL/MariaDB:

* `ZXDB_mysql.sql` - The latest complete ZXDB database script for MySQL/MariaDB. That's all you really need!

Optionally you can execute one of the provided scripts to convert file `ZXDB_mysql.sql` above to a different RDBMS:

* `scripts/ZXDB_to_SQLServer.ps1` - Powershell script to convert ZXDB into SQL Server compatible T-SQL

* `scripts/ZXDB_to_SQLite.py` - Python script to convert ZXDB into SQLite compatible SQL

* `scripts/ZXDB_to_generic.groovy` - Groovy script to convert ZXDB into a (more) generic SQL

The ZXDB distribution already includes all links to [RZX Archive](http://www.rzxarchive.co.uk/), but these links can also be updated independently. There's a separate script to import these links into ZXDB:

* `scripts/ZXDB_import_rzx.sql` - Script to import [RZX Archive](http://www.rzxarchive.co.uk/) links from file [RZXArchiveZXDB.txt](https://spectrumcomputing.co.uk/RZXArchiveZXDB.txt)

The ZXDB distribution already includes all links to [Speccy Screenshot Maps](http://maps.speccy.cz/), but these links can also be updated independently. There's another separate script to import these links into ZXDB:

* `scripts/ZXDB_import_mapy.sql` - Script to import [Speccy Screenshot Maps](http://maps.speccy.cz/) links from file [mapy.txt](https://maps.speccy.cz/mapy.txt)

There's also an optional script to create auxiliary tables, that can be used to help database searches. Ideally these tables must be repopulated whenever ZXDB content changes, or defined as materialized views in a RDBMS that supports it:

* `scripts/ZXDB_help_search.sql` - Script to create auxiliary tables prefixed with `search_by_`

Finally there's a script for health checking, that validates ZXDB consistency rules that cannot be enforced by check constraints:

* `scripts/ZXDB_health_check.sql` - Script to identify data inconsistencies in ZXDB


## Database model

The ZXDB schema is described below:


#### _PRIMARY TABLES_

* `entries` - Spectrum-related items (programs, books, computers and peripherals)

* `labels` - individuals and companies (authors, publishers, development teams, copyright holders)

* `magazines` - published magazines (printed or electronic). The magazine link mask follows this convention:
  * `{i#}` - magazine issue number, with (at least) # digits
  * `{v#}` - magazine issue volume number, with (at least) # digits
  * `{y#}` - magazine issue year, with (at least) # digits
  * `{m#}` - magazine issue month, with (at least) # digits
  * `{M#}` - magazine issue month name, with exactly # letters (starting with uppercase)
  * `{d#}` - magazine issue day, with (at least) # digits
  * `{p#}` - page number, with (at least) # digits
  * `{s#}` - magazine special issue string, preceded by character '#'
  * `{u#}` - magazine issue supplement string, preceded by character '#'

* `releases` - each release of an item (date, price, publisher, etc)
  * `release_seq=0` - original release
  * `release_seq=1` - 1st re-release
  * `release_seq=2` - 2nd re-release
  * `...`

* `tools` - Spectrum-related cross-platform utilities and development tools (emulators, compilers, editors, etc)

* `websites` - main websites that provide information about items (MobyGames, Tipshop, Wikipedia, etc). The website link mask follows this convention:
  * `{e#}` - entry ID, with (at least) # digits


#### _SECONDARY TABLES_

* `aliases` - alternate titles for items (sometimes generic, sometimes just for a specific release and/or language)

* `articles` - online articles about authors (profile, interview, memoir, etc)

* `downloads` - available material related to a specific entry/release (screenshot, tape image, inlay, map, instructions, etc)

* `features` - magazine sections that featured certain entry or label references

* `files` - available material related to a label (photos, posters, advertisements, etc), magazine issue (electronic magazine files, printed magazine scans, covertape music, etc), or cross-platform tool (installation files, instructions, etc)

* `hosts` - main services that provide information about certain features

* `issues` - each published issue of a magazine

* `licenses` - inspirations or tie-in licenses (from arcades, books, movies, etc)

* `notes` - additional information about each entry (known errors, received awards, etc)

* `nvgs` - oldest files preserved from ftp.nvg.unit.no

* `ports` - Spectrum programs also released on other platforms

* `remakes` - modern remakes of Spectrum programs

* `scores` - average score received by each entry at main websites

* `scraps` - obsolete files from the Original WorldOfSpectrum

* `tags` - sets of programs with similar characteristics (participants in the same competition, based on the same original game, etc)

* `topics` - catalogue of magazine sections


#### _RELATIONSHIP TABLES_

* `authors` - associate entries to their authors
  * `author_seq=1` - 1st author (or only author)
  * `author_seq=2` - 2nd author
  * `...`

* `booktypeins` - associate typed-in programs to the books that published them

* `contents` - associate list of programs contained in compilations, covertapes or electronic magazines

* `licensors` - associate licenses to their license owners

* `magrefs` - associate entries or labels to pages from magazine issues about them (magazine references)

* `magreffeats` - associate magazine references to features

* `magreflinks` - associate magazine references to links about them

* `members` - associate tags to their list of programs
  * `series_seq` - only required for sequenced series

* `permissions` - associate labels to distribution permissions granted to websites

* `publishers` - associate entries to their publishers
  * `publisher_seq=1` - 1st publisher of a specific release (or unique publisher)
  * `publisher_seq=2` - 2nd publisher (only if same release has multiple publishers)
  * `...`

* `relatedlicenses` - associate programs to their inspirations or tie-in licenses

* `relations` - relationships between programs (inspired by, authored with, etc)

* `roles` - associate authors to their roles (for each entry)

* `webrefs` - associate programs to webpages about them at other main websites


#### _ENUMERATION TABLES_

* `articletypes` - list of article types (profile, interview, memoir, etc)

* `availabletypes` - list of availability status for entries:
  * `MIA` - released items not (yet) found/preserved
  * `Available` - released items already preserved
  * `Distribution denied` - items unauthorized for distribution
  * `Distribution denied - still for sale` - items unauthorized for distribution
  * `Never released` - items never released (for whatever reason)
  * `Never released - recovered` - items never officially released, later recovered/preserved

* `contenttypes` - list of content types in compilations, covertapes or electronic magazines (full version, demo, soundtrack only, etc)

* `countries` - list of countries (using ISO 3166-1 Alpha-2 standard codes)

* `currencies` - list of `currencies (using ISO 4217 standard codes)

* `extensions` - list of supported filename extensions in ZXDB

* `filetypes` - list of file types (screenshot, tape image, inlay, photo, poster, etc)

* `genretypes` - list of entry types (program type, book type, hardware type, etc)

* `labeltypes` - list of label types (person, nickname, companies)

* `languages` - list of languages (using ISO 639-1 standard codes)

* `licensetypes` - list of license types (arcade coin-up, book, movie, etc)

* `machinetypes` - list of machine types required for each program:
  * `ZX-Spectrum 16K` - programs that require (at least) 16K
  * `ZX-Spectrum 16K/48K` - programs that work on (at least) 16K, but provide additional features in 48K
  * `ZX-Spectrum 48K` - programs that require (at least) 48K
  * `ZX-Spectrum 48K/128K` - programs that work on (at least) 48K, but provide additional features in 128K (AY music, more levels, etc)
  * `ZX-Spectrum 128K` - programs that require (at least) 128K
  * `ZX-Spectrum 128K (load in USR0 mode)` - programs that require (at least) 128K, and must be loaded in USR0 mode
  * `...`

* `notetypes` - list of note types (awards, errors, etc)

* `origintypes` - list of indirect original publication types (covertape from magazine, type-in from book, etc)

* `permissiontypes` - permission types:
  * `Allowed` - copyright owner allowed distribution permission for all titles
  * `Denied` - copyright owner denied distribution permission for all titles
  * `Partial` - copyright owner denied distribution permission for some titles only (must check text for further details)
  * `Non-copyright holder` - person or company reported not being copyright owner anymore (must check text for further details)

* `platforms` - list of computer platforms

* `referencetypes` - references from magazines about entries or labels (preview, review, advert, type-in, solution, etc)

* `relationtypes` - types of relationships between programs (inspired by, authored with, etc)

* `roletypes` - roles by authors on program development (design, graphics, code, music, etc)

* `schemetypes` - tape protection schemes for programs

* `sourcetypes` - indicates "source" of certain files (according to Martijn's internal notes)

* `tagtypes` - list of tag types:
  * `Series` - programs from the same series, following a specific order
  * `Unsorted Group` - programs from the same collection, but without any specific order
  * `Theme` - programs that share the same theme (Ancient Mythology, Christmas, etc)
  * `Feature` - programs that share the same feature (isometric 3D graphics, AY support, etc)
  * `Competition` - programs that participated in the same competition
  * `Multiplay Mode` - programs that support a certain multiplayer mode (Cooperative, Teamplay, Versus)
  * `Turn Mode` - programs that support a certain multiplayer turn mode (Alternating, Simultaneous, Turn based)
  * `Control Option` - programs that support a certain control option (Kempston joystick, redefineable keys, etc)

* `tooltypes` - list of tool types (emulator, cross-development utility, etc)

* `topictypes` - magazine section types


#### _ZXSR TABLES_

* `zxsr_awards` - magazine review awards

* `zxsr_captions` - magazine review captions

* `zxsr_reviews` - magazine review texts

* `zxsr_scores` - magazine review scores


#### _ADDITIONAL DETAILS_

Tables prefixed with `spex_` contain information from SPOT/SPEX archive that differs from the Original WorldOfSpectrum archive, thus pending further investigation later.

Local file links starting with `/pub/` refer to content previously available at the Original WorldOfSpectrum archive. These files are currently accessible from [Archive.org](https://archive.org/) mirror at https://archive.org/download/World_of_Spectrum_June_2017_Mirror/World%20of%20Spectrum%20June%202017%20Mirror.zip/World%20of%20Spectrum%20June%202017%20Mirror/

Local file links starting with `/nvg/` refer to content previously available at the ftp.nvg.unit.no archive. These files are currently accessible from [Archive.org](https://archive.org/) mirror at https://archive.org/download/mirror-ftp-nvg/Mirror_ftp_nvg.zip/

Local file links starting with `/zxdb/` refer to content added afterwards. These files are currently stored at https://spectrumcomputing.co.uk/zxdb/


## Concepts

#### _ABOUT RELEASES_

Each release in ZXDB corresponds to a standalone publication of a certain product (program, book, etc) as follows:

* Release #0 means the original release;
* Release #1 means the 1st re-release;
* Release #2 means the 2nd re-release;
* etc.

Normally it doesn't count as release when a product re-appears in non-standalone publications, such as included in a compilation, covertape, electronic magazine, bonus B-side of another program, or printed as type-in within a book or magazine. For instance [Target Renegade](https://spectrumcomputing.co.uk/entry/4087) was originally published by **Imagine** (release #0), later re-published by **Erbe** (release #1) and **Hit Squad** (release #2). It was also included in a few compilations and covertapes, but none of them count as standalone releases. Another example is [Showdown](https://spectrumcomputing.co.uk/entry/4483) that was originally published by **Artic Computing** (release #0) and later re-appeared in **Your Spectrum** as type-in, but the **Your Spectrum** publication is not considered a release.

However there's an exception to this rule. If a certain program was _not originally published as standalone_, then release #0 should reflect this information. Technically it means assigning a blank release #0 to this title (without publisher, release date or price), and flagging the original appearance of this program elsewhere as "original". For instance a program that was originally published within a [compilation](https://spectrumcomputing.co.uk/entry/9340), [covertape](https://spectrumcomputing.co.uk/entry/2420), [electronic magazine](https://spectrumcomputing.co.uk/entry/399), [bonus B-side of another program](https://spectrumcomputing.co.uk/entry/5675), or originally printed as type-in within a [book](https://spectrumcomputing.co.uk/entry/17668) or [magazine](https://spectrumcomputing.co.uk/entry/13286).


## Disclaimer

* _Copyright_: ZXDB doesn't contain any copyrighted content. ZXDB is a database containing metadata information only. It doesn't store any kind of copyrighted material internally.

* _Redistribution_: ZXDB cannot grant any rights to redistribute any external copyrighted content. You are welcome to build websites and services using ZXDB but, if you plan to host or provide links for users to download copyrighted material referenced by ZXDB, it's your responsibility to ensure you are allowed to do it.

* _Privacy_: No personal information is stored in ZXDB (email, residence address, etc). ZXDB only stores publicly available information, mainly about authors and publishers (name, official website, etc).

* _Consent_: Whenever ZXDB imported any information from other databases, it was always done with consent from their respective owners, for the purpose of preserving information and improving integration with different websites and services.

* _Validity_: Everybody involved in ZXDB continuously make their best efforts to ensure accuracy of information stored in ZXDB. Even so, ZXDB cannot provide any formal guarantees about the validity of this information. Neither it can be used as base for legal claims about intellectual property or anything else. Use it at your own risk! For a more formal disclaimer, please refer to [Wikipedia disclaimer](https://en.wikipedia.org/wiki/Wikipedia:General_disclaimer).


## License

ZXDB is an open database. Everyone is welcome to contribute and/or use it!

Just please remember to mention somewhere if you used it and, if you decide to create a derived database from ZXDB, please keep it open! For a more formal license model, please refer to ODC [Open Database License](https://en.wikipedia.org/wiki/Open_Database_License) (ODbL 1.0).


## Credits

ZXDB was created and it's maintained by **Einar Saukas**, with very special thanks to many contributors:

* **Dave Hughes**: for directly working on ZXDB, patiently cataloguing each new individual ZX-Spectrum title in ZXDB;

* **Dario Ruellan**: for directly working on ZXDB, patiently cataloguing each recovered old ZX-Spectrum title and fixing inaccurate information in ZXDB;

* **Pavel Pliva**: for directly working on ZXDB, patiently cataloguing typed instructions and hires inlays, and implementing our internal file upload tool;

* **Thomas Kolbeck**: for directly working on ZXDB, maintaining the ZX81 section of ZXDB, and implementing the open [ZXInfo API](https://api.zxinfo.dk/v3/);

* **Elia Iliashenko**: for maintaining in [ZX Pokemaster](https://sourceforge.net/projects/zx-pokemaster/) a complete mapping of TOSEC files to their corresponding ZXDB entries (and also providing inumerous other contributions to ZXDB content);

* **Peter Jones**, and **Ricardo Nunes**: for building [Spectrum Computing](https://spectrumcomputing.co.uk/) that hosts the [ZXDB forum section](https://spectrumcomputing.co.uk/forums/viewforum.php?f=32) (and also providing inumerous other contributions to ZXDB content);

* **Steven Brown**: for recovering and preserving a huge amount of rare programs at [TZXVault](https://tzxvault.org/), and helping to add them to ZXDB;

* **Andre Luna Leao**: for collecting all kinds of programs at [Planeta Sinclair](https://planetasinclair.blogspot.com/), and helping to add them to ZXDB;

* **Hikoki**, **Neil Parsons** and everybody else that have contributed, assisted and supported this project since the beginning!

Also special thanks to everyone that contributed to the creation of ZXDB, particularly:

* **Martijn van der Heide**: for creating and maintaining the [Original WorldOfSpectrum](https://web.archive.org/web/20151117205811/http://www.worldofspectrum.org/) archive, and directly helping to import it into ZXDB (clarifying our trickiest questions about the most obscure flags in the [Original WorldOfSpectrum](https://web.archive.org/web/20151117205811/http://www.worldofspectrum.org/) internal files).

* **Jim Grimwood**: for creating and maintaining the original [SPOT/SPEX](http://www.users.globalnet.co.uk/~jg27paw4/spot-on/) archive.

* **Daren Pearcy**: for creating and maintaining the original [RZX Archive](http://www.rzxarchive.co.uk/).

* **Chris Bourne**: for creating and maintaining the original [ZXSR](http://www.zxspectrumreviews.co.uk/) archive.

* **Gerard Sweeney**: for invaluable assistance on importing all original content from the [Original WorldOfSpectrum](https://web.archive.org/web/20151117205811/http://www.worldofspectrum.org/) archive.

* **AndyC**: for reviewing the ZXDB schema, and implementing both SQL Server and SQLite converters.

* **Lee Fogarty**: for providing full access to internal files from Martijn's [Original WorldOfSpectrum](https://web.archive.org/web/20151117205811/http://www.worldofspectrum.org/) archive and declaring them as "open source".


## References

The following websites directly use ZXDB internally:

* [Spectrum Computing](https://spectrumcomputing.co.uk/) - ZX-Spectrum archive based on ZXDB, maintained by **Peter Jones** and **Ricardo Nunes**.

* [ZXInfo](https://zxinfo.dk/) - ZX-Spectrum archive based on ZXDB, built with ElasticSearch by **Thomas Kolbeck**.

* [ZXInfo API](https://api.zxinfo.dk/v3/) - Open ZXDB API, provided by **Thomas Kolbeck**.

* [ZX-Spectrum Reviews (ZXSR)](http://zxspectrumreviews.co.uk/) - ZX-Spectrum Reviews archive by **Chris Bourne**, it now runs ZXSR database integrated with ZXDB.

* [ZX-Art](https://zxart.ee/) - ZX-Spectrum art archive by **Dmitri Ponomarjov**, it includes content imported periodically from ZXDB.

* [ZX Pokemaster](https://sourceforge.net/projects/zx-pokemaster/) - Tool for organizing ZX-Spectrum files by **Elia Iliashenko**, it includes content imported periodically from ZXDB.

* [Lisias' Raspberry Pi](http://service.retro.lisias.net/db/) - ZX-Spectrum search engine based on ZXDB, built on Raspberry Pi by **Lisias Toledo**.

* [WorldOfSpectrum Classic](https://worldofspectrum.net/) - The remake of Martijn's original ZX-Spectrum archive is now powered by ZXDB.

* [New WorldOfSpectrum](https://worldofspectrum.org/) - ZX-Spectrum archive rebuilt by **Lee Fogarty**, it was launched in June 2020 although using ZXDB version 1.08 from September 2018.

The following websites are fully integrated with ZXDB:

* [RZX Archive](http://www.rzxarchive.co.uk/) - Each ZXDB title links to the corresponding webpage at **Daren Pearcy**'s site, and vice-versa.

* [Speccy Screenshot Maps](http://maps.speccy.cz/) - Each ZXDB title links to the corresponding map at **Pavero**'s site, and vice-versa.

* [ZX-Spectrum Reviews (ZXSR)](http://www.zxspectrumreviews.co.uk/) - Each ZXDB title or magazine review links to the corresponding webpage at **Chris Bourne**'s site, and vice-versa.

* [Lemon64](https://www.lemon64.com/) - Each ZXDB title links to the corresponding Commodore 64 version at **Kim Lemon**'s site (whenever it exists), and vice-versa.

* [LemonAmiga](https://www.lemonamiga.com/) - Each ZXDB title links to the corresponding Amiga version at another **Kim Lemon**'s site (whenever it exists), and vice-versa.

* [Classic Adventures Solution Archive](http://www.solutionarchive.com/) - Each adventure title in ZXDB links to the corresponding webpage at CASA, and vice-versa.

* [Demozoo](https://demozoo.org/) - Each scene demo in ZXDB links to the corresponding webpage at **Matt Westcott**'s site, and vice-versa.

* [Spectrum 2.0](http://spectrum20.zxdemo.org/) - Each ZXDB title links to the corresponding webpage at **Philip Kendall**'s site.

* [ZX81 Stuff](http://www.zx81stuff.org.uk/) - Each ZX81 title in ZXDB links to the corresponding webpage at **Simon Holdsworth**'s site.

* [WorldOfSAM](https://www.worldofsam.org/) - Each SAM Coupe title in ZXDB links to the corresponding webpage at **Andrew Collier**'s site.

* [JSW Central](https://jswcentral.org/) - Each Jet Set Willy mod in ZXDB links to the corresponding webpage at **Daniel Gromann**'s site.

* [Wikipedia](https://en.wikipedia.org/) - Each ZXDB title, person or company links to the corresponding webpage at Wikipedia.

* [MobyGames](http://www.mobygames.com/) - Each ZXDB title links to the corresponding webpage at MobyGames.

* [Lost in Translation](http://www.exotica.org.uk/) - Each ZXDB title links to the corresponding webpage at Lost in Translation.

* [Freebase](http://zxspectrum.freebase.com/) - Each ZXDB title links to the corresponding webpage at Freebase.

* [Pouet](https://www.pouet.net/) - Each scene demo in ZXDB links to the corresponding webpage at Pouet.

* [ZXAAA](https://zxaaa.net/) - Each scene demo in ZXDB links to the corresponding webpage at ZXAAA.

* [The Tipshop](http://www.the-tipshop.co.uk/) - Each ZXDB title links to the corresponding webpage at **Gerard Sweeney**'s site.

* [Original WorldOfSpectrum](http://www.worldofspectrum.org/) - Each ZXDB title still links to the corresponding archived webpage of **Martijn van der Heide**'s site.

* [SPOT/SPEX](http://www.users.globalnet.co.uk/~jg27paw4/spot-on/) - Each ZXDB magazine reference links to the corresponding webpage at **Jim Grimwood**'s site.

* [RZX Archive Channel](https://www.youtube.com/user/rzxarchive) - Each ZXDB title links to the corresponding video at **Daren Pearcy**'s channel.

* [The Spectrum Show](http://www.thespectrumshow.co.uk/) - Each ZXDB title links to the corresponding video at **Paul Jenkinson**'s channel.


![ZXDB](images/ZXDB_8.png)
