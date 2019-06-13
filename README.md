# taxdb
Transform a taxonomy database into sqlite and manipulate it from there.

## Usage

Run any script with `--help`.

Basic workflow:

1. Get flatfiles
2. Create blank database
3. Add flatfiles to the blank database

## Some basic workflows

Note: these workflows use the entire NCBI taxonomy database, but you can use a prepackaged
_Listeria_ database included under `data/` instead.

### Create a database from NCBI

Download the NCBI database

    mkdir flat
    cd flat
    wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
    tar zxvf taxdump.tar.gz
    cd ..

Create and add to a taxdb

    perl scripts/taxdb_create.pl taxdb.sqlite
    perl scripts/taxdb_add.pl taxdb.sqlite flat/

### Create a database for _Listeria monocytogenes_ (taxid: 1639) and its ancestor lineage

    perl scripts/taxdb_extract.pl --taxon 1639 taxdb.sqlite --outdir lmono.flat
    perl scripts/taxdb_create.pl lmono.sqlite
    perl scripts/taxdb_add.pl lmono.sqlite lmono.flat

### Dump the database back to flat files

    perl scripts/taxdb_dump.pl lmono.sqlite --outdir lmono.flat.replicate2

## Advanced

If you are familiar with sqlite, you can run custom queries.
The database scheme is the same as the flat files `nodes.dmp` and `names.dmp`.

|**NODE**| |
|--------|-|
|tax\_id |INTEGER  PRIMARY KEY|
|parent\_tax\_id|INTEGER|
|rank    |TEXT|
|embl\_code|INTEGER|
|division\_id|INTEGER|
|inherited\_div\_flag|INTEGER|
|genetic\_code\_id|INTEGER|
|inherited\_gc\_flag|INTEGER|
|mitochondrial\_genetic\_code\_id|INTEGER|
|inherited\_mgc\_flag|INTEGER|
|genbank\_hidden\_flag|INTEGER|
|hidden\_subtree\_root\_flag|INTEGER|
|comments|TEXT|
    CONSTRAINT parent_tax_id_constraint FOREIGN KEY (parent_tax_id) REFERENCES NODE(tax_id) ON DELETE CASCADE ON UPDATE CASCADE

|**NAME**||
|--------|-|
|tax\_id |INTEGER|
|name\_txt|TEXT|
|unique\_name|TEXT|
|name\_class|TEXT|
    PRIMARY KEY(tax_id, name_txt, unique_name, name_class)
    FOREIGN KEY(tax_id) REFERENCES NODE(tax_id) ON DELETE CASCADE ON UPDATE CASCADE

### Example advanced queries

Count how many nodes are in the database

    sqlite3 taxdb.sqlite 'SELECT count(tax_id) FROM NODE

Display how many ways _Listeria monocytogenes_ is described

    sqlite3 taxdb.sqlite 'SELECT * FROM NAME WHERE tax_id = 1639'

## CONTRIBUTIONS

Please submit ideas as issues.  I usually accept pull requests as long as they pass the unit tests.

[![Build Status](https://travis-ci.com/lskatz/taxdb.svg?branch=master)](https://travis-ci.com/lskatz/taxdb)

