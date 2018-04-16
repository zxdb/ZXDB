import re
import codecs

linecount=0
inHeader = 1
outFile = codecs.open(r"ZXDB_sqlite.sql",'w','utf-8')
with codecs.open(r"ZXDB_mysql.sql",'r','utf-8') as f:
    for line in f:
        linecount = linecount + 1
        if inHeader:
            if line.startswith('USE'):
                inHeader = 0
        else:
            # strip out backticks
            line = line.replace('`','') 
            # convert escaped single quotes
            line = line.replace(r"\'","''") 
            # change collation 
            line = line.replace('utf8_bin','rtrim') 
            # get rid of auto-increment, as SQLite doesn't support it well enough
            line = line.replace('AUTO_INCREMENT','') 
            # tidy up MySql-isms from end of table definitions
            if line.startswith(') ENGINE'):
                line =')'          

            # SQLite doesn't like unsigned, so manually convert to an integer
            line = re.sub('int\s*\(\d+\)\s+unsigned','INTEGER',line, flags=re.I)

            # strip out indexes
            if re.match('\s*KEY',line,re.I):
                line = '' 

            # fix unique constraint syntax and remove names
            line = re.sub('\s*UNIQUE KEY \w*\s*\(','UNIQUE (',line)

            outFile.write(line)
            
        if linecount % 10000 == 0:
            print(linecount)        
outFile.close()
