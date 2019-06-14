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

### Query a taxon

In the below examples with `taxdb_query.pl`, you can specify `--taxid` or `--name` for scientific names.

    perl scripts/taxdb_query.pl --name "Listeria" data/Listeria-2019-06-12.sqlite |\
      grep -m 1 "scientific name" |\
      cut -f 1-3,15,16
    # Results: `1637    186820  genus   Listeria`

#### Find the lineage of the taxon

    perl scripts/taxdb_query.pl --taxon 1639 --mode lineage data/Listeria-2019-06-12.sqlite
    1639    1637    186820  1385    91061   1239    1783272 2       131567  1

#### Find the lineage of the taxon but also get more details

With a bash loop and some piping

    for taxid in $(perl scripts/taxdb_query.pl --taxon 1639 --mode lineage data/Listeria-2019-06-12.sqlite); do 
      perl scripts/taxdb_query.pl --taxon $taxid data/Listeria-2019-06-12.sqlite |\
        grep -m 1 "scientific name"; 
    done |\
      cut -f 1-3,15,16 |\
      column -ts $'\t'
    1639     1637     species       Listeria monocytogenes
    1637     186820   genus         Listeria
    186820   1385     family        Listeriaceae
    1385     91061    order         Bacillales
    91061    1239     class         Bacilli
    1239     1783272  phylum        Firmicutes
    1783272  2        no rank       Terrabacteria group
    2        131567   superkingdom  Bacteria                Bacteria <prokaryotes>
    131567   1        no rank       cellular organisms
    1        1        no rank       root

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

