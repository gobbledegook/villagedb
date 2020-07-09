VillageDB
=========

This is the interface for the Roots Village Database, a database of villages
in Toishan 台山, Sunwui 新會, Hoiping 開平, and Chungshan 中山, as compiled by the
American Consulate General in Hong Kong in the 1960s. The database is currently
accessible here:

<https://villagedb.friendsofroots.org/>

The files in this repository include the following:

## data/

This includes the database schema, along with character lookup tables
(STC -> character, character -> jyutping/pinyin).

## *.cgi

These are all the CGI scripts. In practice most people will start with
search.cgi when using the database.

## *.html

Just your normal html files. Includes front matter from the Indexes.

## perl modules

Roots::Util will look for a `config.txt` file to figure out how to connect
to mysql.

## util/

Various perl scripts for database maintenance, error checks, etc.
