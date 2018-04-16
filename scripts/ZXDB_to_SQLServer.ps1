$ErrorActionPreference = "Stop";
# Create output folders
if (!(Test-Path Output\Tables)) {mkdir Output\Tables}
if (!(Test-Path Output\Inserts)) {mkdir Output\Inserts}

$sourceFile = 'ZXDB_mysql.sql'
$currentOutputFile = 'Output\preamble.sql'
$postfixFile = 'Output\fixups.sql'

@"
Use ZXDB
Go

"@ | Out-File $postfixFile -Encoding utf8

write-progress -id 1 -Activity 'Rewriting files' -status "loading source data" -PercentComplete -1

$source = Get-Content $sourceFile -Encoding utf8
$totalRows = $source.count

$sw = new-object System.IO.Streamwriter($currentOutputfile, $false, [System.Text.Encoding]::UTF8)

for ($rownum =0; $rownum -lt $totalRows; $rownum++)
{
    $progress = ($rownum / $totalRows) * 100
    write-progress -id 1 -Activity 'Rewriting files' -status "% comlete: $('{0:N2}' -f $progress)" -PercentComplete $progress

    $text = $source[$rownum]

    $text = $text -replace '`text`','[text]' # escape columns with reserved word names
    $text = $text -Replace '`','' # Remove backticks
    $text = $text -Replace "\\'","''" # Change escaped quotes

    # Change file for table create
    If ($text -match '^Create Table If Not Exists (\w+)') {
        $tableName = $Matches[1]

        $text = @"
Use ZXDB
Go

If Object_ID('$($tableName)') Is Not Null Drop Table $TableName
Create Table $tableName (
"@

        $currentOutputfile = "Output\Tables\Table_$($tableName).sql"

        $sw.Close()        
        $sw = new-object System.IO.Streamwriter($currentOutputfile, $false, [System.Text.Encoding]::UTF8)
       
        $rowlimit = 0 # Can have as many rows as we like in Create Table file
        $processingTable = $true 
    }

    # Change file for insert into
    If ($text -match '^Insert Into (\w+)') {
        $tableName = $Matches[1]
        $count = 0
        $lastfile = $currentOutputFile
        $currentOutputfile = "Output\Inserts\Insert_$($tableName).sql"

        # don't recreate the file if it's a continuation (because we just hit a secondary INSERT statement)
        if ($lastfile -ne $currentOutputFile)
        {
            $sw.Close()        
            $sw = new-object System.IO.Streamwriter($currentOutputfile, $false, [System.Text.Encoding]::UTF8)
        }
        $rowlimit = 1000
        $processingTable = $false #Avoid possibility of table fixups corrupting data
        $idfix = @"
Use ZXDB
Go

If Exists(Select * From sys.columns Where is_identity = 1 And Object_Name(Object_Id) = '$TableName')
Begin
    Set Identity_Insert $tableName On
End
`n
"@ 
        $sw.WriteLine($idfix)
        $insertPreamble = $idfix + $text
    }

    if ($processingTable) {

        # Remove weird MySql column width sizes from int types and remove unsigned suffix since SQL Server doesn't have unsigned types
        $text = $text -replace '(?<name>\w+)\s+(?<type>\w+)?int\((?<size>\w+)\)\s*(?<sign>unsigned)?\s+','${name} ${type}int '

        # Rewrite mediumtext to varchar(max)
        $text = $text -replace 'mediumtext','varchar(max)'

        #Rewrite tinyint to smallint, since SQL Server doesn't allow negatives in tinyint columns
        $text = $text -replace 'tinyint','smallint'
    
        #Remove Default Null constraints, they don't make much sense
        $text = $text -replace 'DEFAULT NULL',''

        # Fix up identity values
        $text = $text -replace 'ENGINE=InnoDB AUTO_INCREMENT=(?<autoincrement>\d+)? DEFAULT CHARSET=utf8 COLLATE=utf8_bin;',"`n dbcc checkident($tablename, RESEED, `${autoincrement})"

        # For auto increment columns, make them identity columns (fix up values with dbcc later)
        $text = $text -replace 'AUTO_INCREMENT','Identity(1,1)'

        # Clean up mysql table options
        $text = $text -replace 'ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin',''

        #Rewrite Unique Constraints, make sure they're unqiue a MySql names aren't
        $text = $text -replace 'UNIQUE KEY (\[)?(?<keyname>\w+)(\])? \((?<cols>[\[|\]|\w|\s|,]+)\)',"Constraint UQ_$($TableName)_`${keyname} Unique (`${cols})"

        #Name primary keys, so it's easier to patch them up later if need be
        $text = $text -replace 'PRIMARY KEY \((?<cols>[\[|\]|\w|\s|,]+)\)',"Constraint PK_$($tableName) Primary Key Clustered (`${cols})"

        #Deal with inline indexes by writing them to a Post Fix file
        if ($text -match '^\s+KEY (?<keyname>\w+) \((?<cols>[\[|\]|\w|\s|,]+)\)')
        {
            "Create Nonclustered Index $($Matches['Keyname']) On $($TableName)($($Matches['cols']))" | Out-File $postfixFile -Encoding utf8 -Append -NoClobber
            $text = '--' + $text
        }

        # Move foreign key constraint into Post Fix file, so table order deployment doesn't have to matter
        if ($text -match '^\s+Constraint\s+(?<name>\w+)\s+Foreign Key \((?<cols>[\[|\]|\w|\s|,]+)\) References (?<foreignTable>\w+) \((?<foreignCols>[\[|\]|\w|\s|,]+)\)')
        {
            "Alter Table $TableName Add Constraint $($Matches['Name']) Foreign Key ($($Matches['cols'])) References $($Matches['foreignTable']) ($($Matches['foreignCols']))" | 
                Out-File $postfixFile -Encoding utf8 -Append -NoClobber
            $text = '--' + $text
        }

        # Fix collations
        $text = $text -replace 'COLLATE utf8_bin','COLLATE DATABASE_DEFAULT'

        # Change columns that currently need case sensitive behaviour
        if (($tableName -eq 'aliases' -and $text -match '^\s*title')`
            -or ($tableName -eq 'availabletypes' -and $text -match '^\s*id')`
            -or ($tableName -eq 'labels' -and $text -match '^\s*name')`
            -or ($tableName -eq 'magazines' -and $text -match '^\s*name')`
            -or ($tableName -eq 'origintypes' -and $text -match '^\s*id')`
            -or ($tableName -eq 'origintypes' -and $text -match '^\s*\[text\]')`
            -or ($tableName -eq 'tools' -and $text -match '^\s*title')`
            -or ($tableName -eq 'downloads' -and $text -match '^\s*origintype_id')`
            -or ($tableName -eq 'entries' -and $text -match '^\s*availabletype_id')`
            -or ($tableName -eq 'features' -and $text -match '^\s*name')`
        )
        {
            
            $text = $text -replace 'DATABASE_DEFAULT','Latin1_General_CS_AS'
        }

        # Remove unique constraints on tables that seem to have non-unique data
        if (($tableName -eq 'magrefs' -and $text -match '^\s*Constraint UQ_magrefs_uk_magref_entry')`
            -or ($tableName -eq 'magrefs' -and $text -match '^\s*Constraint UQ_magrefs_uk_magref_label')`
            -or ($tableName -eq 'magrefs' -and $text -match '^\s*Constraint UQ_magrefs_uk_magref_topic')`
            #-or ($tableName -eq 'features' -and $text -match '^\s*Constraint UQ_features_uk_feature')`
        )
        {
            $text = '--' + $text + ' -- broken constraint'
        }

    } else {
        $count++
        # Remove trailing comma from last row of insert
        if ($count -eq $rowlimit)
        {
            if ($text -match '(?<line>\s*\(.*\)),')
            {
                $text = $Matches['line'] +  '; -- reached insert limit'
            }
        }

        # Can only insert 1000 values per insert statement, so adjust and write to a new file cause SSMS copes better
        if ($rowlimit -ne 0) {
            if ($count -gt $rowlimit) {
                $count = 1

                $sw.WriteLine("Go`n")
                $sw.WriteLine($insertPreamble)
        
            }
        }
    }

    $sw.WriteLine($text)
}
$sw.Close()
