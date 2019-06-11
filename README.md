# taxdb
Manipulate taxonomy databases

## Usage

Run any script with `--help`.

Basic workflow:

1. Get flatfiles
2. Create blank database
3. Add flatfiles to the blank database

## basic workflows

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

### Create a database for _Listeria monocytogenes_ (taxid: 1639)

    perl scripts/taxdb_extract.pl --taxon 1639 taxdb.sqlite --outdir lmono.flat
    perl scripts/taxdb_create.pl lmono.sqlite
    perl scripts/taxdb_add.pl lmono.sqlite lmono.flat

