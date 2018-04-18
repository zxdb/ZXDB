/**
 * "ZXDB_to_generic.groovy" - by Einar Saukas
 *
 * A Groovy script to convert MySQL/MariaDB specific file "ZXDB_mysql.sql" into a more generic database file "ZXDB_generic.sql"
 *
 *
 * How to use it:
 *
 * 1. Install Groovy
 * 2. Copy "ZXDB_to_generic.groovy" and "ZXDB_mysql.sql" to the same directory
 * 3. Execute "groovy ZXDB_to_generic.groovy" from the same directory
 *
 *
 * For additional details visit:
 *
 * https://github.com/zxdb/ZXDB
 *
 */

String strip(String txt) { txt.replaceAll("`", "").replaceAll("\\\\'", "''")+"\n"; }                // Format output text

new File("ZXDB_generic.sql").withWriter("utf-8") { writer ->
    def foreignKeys = [];                                                                           // List of all foreign keys from ZXDB
    def prevLine = null;                                                                            // Previous input line
    def tableName = null;                                                                           // Current table name
    new File("ZXDB_mysql.sql").eachLine("utf-8") { line ->
        if (line.startsWith("CREATE DATABASE IF NOT EXISTS ")) {                                    // Uncomment directives from database definition
            line = line.replace("/*!40100 ", "").replace(" */;", ";");
        } else if (line.startsWith("CREATE TABLE")) {                                               // Remember current table name
            tableName = line.substring(line.indexOf('`')+1, line.lastIndexOf('`'));
        } else if (line.startsWith("  CONSTRAINT `") && line.contains("` FOREIGN KEY (`")) {        // Postpone foreign keys definitions
            foreignKeys.add("ALTER TABLE "+tableName+" ADD"+line.substring(1, line.length()-(line.charAt(line.length()-1) == ',' ? 1 : 0))+";");
            return;
        } else if (line.startsWith("  KEY `")) {                                                    // Discard key definitions
            return;
        } else if (line.startsWith("/*!") && line.endsWith("*/;")) {                                // Discard remaining MySQL specific directives
            return;
        }
        if (prevLine != null) {
            if (line.startsWith(")") && prevLine.endsWith(",")) {
                prevLine = prevLine.substring(0, prevLine.length()-1);                              // Discard extra comma from table definition whenever needed
            }
            writer.write(strip(prevLine));                                                          // Output everything else
        }
        prevLine = line;
    }
    if (prevLine != null) {
        writer.write(strip(prevLine));                                                              // Output last line
    }
    writer.write("\nSET FOREIGN_KEY_CHECKS = 0;\n\n");                                              // Output directive to disable foreign key checks
    for (String line : foreignKeys) {
        writer.write(strip(line));                                                                  // Output postponed foreign key definitions
    }
    writer.write("\nSET FOREIGN_KEY_CHECKS = 1;\n\n-- END\n");                                      // Output directive to enable foreign key checks
}
