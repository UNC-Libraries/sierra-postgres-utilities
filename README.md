# sierra-postgres-utilities

Ruby connection and ORM for iii Sierra ILS postgres database / SierraDNA, meant to simplify making querying, manipulating, and exporting MARC or non-MARC Sierra data and records.

__NOTE: This is in early development and future changes may well not be backwards compatible.__

__NOTE: Some sites may have iii setups that store different data in different places (e.g. bcode1, bcode2, bcode3) or differing local MARC practices (is the 001 an OCLC number?), and parts of these scripts do not account for that.__

## Usage overview

### Interact with bib (and other) records

```ruby
require 'sierra_postgres_utilities'

# Retrieve record by bnum/rnum
bnum = 'b9256886a'
bib = Sierra::Record.get(bnum)

# or retrieve by id
bib = Sierra::Record.get(id: 420916051894)

bib.suppressed?     #=> false
bib.deleted?        #=> false
bib.mat_type        #=> "a"

# Get data from record_metadata and bib_record/item_record/etc. as a hash
bib.values          #=> {:id=>420916051894,
                    #    :record_num=>9256886
                    #    :record_id=>420916051894,
                    #    :creation_date_gmt=>2018-07-24 16:02:39 -0400,
                    #    :deletion_date_gmt=>nil,
                    #    ...
                    #    :bcode1=>"m",
                    #    :bcode2=>"a",
                    #    :bcode3=>"-",
                    #    ....
                    #    :is_suppressed=>false}

# All of those hash keys are also available as methods
bib.bcode1          #=> "m"

# Get rec's MARC as a ruby-marc object (https://github.com/ruby-marc/ruby-marc/)
bib.marc

# Write MARC to binary file (as per normal ruby-marc)
w = MARC::Writer.new('bib.mrc')
w.write(bib.marc)
w.close

# Get MARC as mrk
puts bib.marc.to_mrk
    #=> =LDR  01398cam  2200373Ii 4500
    #   =001  1030972212
    #   =003  OCoLC
    #   =005  20180727041344.0
    #   =008  180410t20182018enk      b    001 0 eng d
    #   =010  \\$a  2018938050
    #   =019  \\$a1031042882
    #   =020  \\$a1788744039
    #   ...

# Get an array of item records attached to the bib
bib.items                #=> [#<Sierra::Data::Item i11736082a ...>]

item = bib.items.first
item.status_code         #=> "-"
item.status_description  #=> "Available"
item.barcodes            #=> ["00053203834"]
```

### Sequel Datasets, Associations, and Querying

Many record-types, fields, properties (e.g. itype) have Sequel models and associations available under Sierra::Data (though some have not been implemented due to lack of local relevance or use).

See <http://sequel.jeremyevans.net/> for Sequel documentation

```ruby

b = Sierra::Data::Bib.first    #=> #<Sierra::Data::Bib b1370009a...

i = b.items.first              #=> #<Sierra::Data::Item i1869459a...

# 856 fields with 'hathitrust.org'
v = Sierra::Data::Varfield.where(marc_tag: '856',
                                field_content: /hathitrust\.org/)

# bibs for those 856s
v.bibs.distinct

# items with location code 'ddda' on unsuppressed bibs
Sierra::Data::Bib.exclude(:is_suppressed).
                  items.
                  where(location_code: 'ddda')
```

### Run arbitrary queries against the PostgresDB / SierraDNA

```ruby
query = "select * from sierra_view.subfield limit 1"

# Execute query and return a Sequel::Dataset object
Sierra::DB.query(query)

Sierra::DB.results # reference the same Dataset object

Sierra::DB.results.sql

Sierra::DB.results.all # results as array of record hashes
  #=> [{"record_id"=>"425206113029", "varfield_id"=>"57093780", ...}]

# Write results to file
Sierra::DB.write_results('output.tsv')
Sierra::DB.write_results('output.csv', format: 'csv')
Sierra::DB.write_results('output.xlsx', format: 'xlsx') # Requires WIN32OLE so probably Windows-only.

# Send results as attachment
details =  {from:    'user@example.com',
            to:      'other@example.com',
            cc:      'also@example.com',
            subject: 'that query',
            body:    'Attached.'}
Sierra::DB.mail_results('output.tsv', mail_details: details)
```

### Retrieve arbitrary views

Retrieve arbitrary views as arrays of hashes via `Sierra::DB.db[:view_name]`.

```ruby
Sierra::DB.db[:request_rule].first
  #=> {:id=>6265, :record_type_code=>"i", :query ...
```

## SETUP

* git clone <https://github.com/UNC-Libraries/sierra-postgres-utilities>
* `cd sierra-postgres-utilities`
* `bundle install`
* `bundle exec rake install`
* supply the Sierra postgres credentials per the below
* optionally supply smtp server address

When possible, it is recommended that you also install the `sequel_pg` gem which makes database access significantly faster. See <https://github.com/jeremyevans/sequel_pg> for installation details / requirements.

### Credentials

Create a yaml/text file like so:

```yaml
host: myhost.example.com
port: 1032
dbname: mydb
user: myusername
password: mypassword
```

You may need to quote values (e.g. password) if they contain special characters.

By default, sierra_postgres_utilities will try to read credentials from:
- a file `sierra_prod.secret` in the current working directory
- failing that, a file `sierra_prod.secret` in the user's home directory

For casual use, we recommend keeping the credentials in your home directory,
in a file called `sierra_prod.secret`.

#### Credentials via environment variables

Alternately, you can specify a credential file location as an environment variable, e.g.:

```bash
SIERRA_INIT_CREDS=my/path/file.yaml irb
```

or set the file location in ruby:

```ruby
# File location
ENV['SIERRA_INIT_CREDS'] = 'my/path/file.yaml'
require 'sierra_postgres_utilities'
```

This still relies on credentials being stored in a file. The path to the
credential file, not the credentials themselves, is set as an env variable.

### SMTP connection / email address storage

Define an smtp connection (that does not require authentication) if you'll use this to send emails.
Create `smtp.secret` in the working directory or home directory:

```yaml
address: smtp.example.com
port: 25
```
