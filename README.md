# sierra-postgres-utilities

Ruby connection to iii Sierra ILS postgres database / SierraDNA, meant to simplify making queries, exporting results, and some lookup / manipulation / transformation of MARC or non-MARC Sierra data and records.

__NOTE: This is in early development and future changes may well not be backwards compatible.__

__NOTE: Some sites may have iii setups that store different data in different places (e.g. bcode1, bcode2, bcode3) or differing local MARC practices (is the 001 an OCLC number?), and parts of these scripts do not account for that.__

## Usage overview

### Interact with bib (and other) records

```ruby
require 'sierra_postgres_utilities'

bnum = 'b9256886a'
bib = SierraBib.new(bnum)

bib.suppressed?     #=> false
bib.deleted?        #=> false
bib.mat_type        #=> "a"

# Get data from sierra_view.bib_record as a hash
bib.bib_record      #=> {:id=>420916051894,
                    #    :record_id=>420916051894,
                    #    :language_code=>"eng",
                    #    :bcode1=>"m",
                    #    :bcode2=>"a",
                    #    :bcode3=>"-",
                    #    ....
                    #    :is_suppressed=>false}

# Get bib as a ruby-marc object (https://github.com/ruby-marc/ruby-marc/)
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
bib.items                #=> [#<SierraItem:i11736082a>]

item = bib.items.first
item.status_code         #=> "-"
item.status_description  #=> "Available"
item.barcodes            #=> ["00053203834"]
```

### Run arbitrary queries against the PostgresDB / SierraDNA

```ruby
query = "select * from sierra_view.subfield limit 1"

# Execute query and return a PG::Result object
SierraDB.make_query(query)

SierraDB.results            # reference the same PG::Result object

SierraDB.results.entries    # results as array of record hashes
  #=> [{"record_id"=>"425206113029", "varfield_id"=>"57093780", ...}]

SierraDB.results.values     # results as array of record arrays
  #=> [["425206113029", "57093780", ...]]

# Write results to file
SierraDB.write_results('output.tsv')
SierraDB.write_results('output.csv', format: 'csv')
SierraDB.write_results('output.xlsx', format: 'xlsx') # Windows only. Maybe Mac. Not Linux.

# Send results as attachment
details =  {:from    => 'user@example.com',
            :to      => 'other@example.com',
            :cc      => 'also@example.com',
            :subject => 'that query',
            :body    => 'Attached.'}
SierraDB.mail_results('output.tsv', mail_details: details)
```

### Retrieve arbitrary views
Retrieve arbitrary views as arrays of OpenStruct objects via ```SierraDB.[view_name]```.
```ruby
SierraDB.item_status_property_myuser.
         map { |r| [r.code, r.name] }.
         to_h
  #=> {"!"=>"ON HOLDSHELF", "$"=>"LOST AND PAID", ...
```

### Retrieve defined views in the context of a particular record
Retrieve records related to a specific object via object.[view_name]. E.g.:
```bib.bib_record_item_record_link``` and ```bib.bib_record_property```
return any of ```bib```'s entries in those two views.

## SETUP

* git clone https://github.com/UNC-Libraries/sierra-postgres-utilities
* cd sierra-postgres-utilities
* bundle install
* bundle exec rake install
* supply the Sierra postgres credentials per the below
* optionally supply smtp server address

### Credentials

Create a yaml file in the base directory like so:

```yaml
host: myhost.example.com
port: 1032
dbname: mydb
user: myusername
password: mypassword
```

Store the creds in a file ```sierra_prod.secret``` in the
current working directory or the base directory of sierra_postgres_utilities.
Creds from this file will be used as the default connection.

Alternately, specify a credential file location as an environment variable, e.g.:

```bash
SIERRA_INIT_CREDS=my/path/file.yaml irb
```

or set the file location in ruby:

```ruby
# File location
ENV['SIERRA_INIT_CREDS'] = 'my/path/file.yaml'
require 'sierra_postgres_utilities'
```

Once connected to the Sierra DB, you can close the connection and reconnect
under alternate creds using:
-  ```SierraDB.connect_as(creds: filename)```, or
-  ```SierraDB.connect_as(creds: cred_hash)```

### SMTP connection / email address storage

Define an smtp connection (that does not require authentication) if you'll use this to send emails.
Create ```smtp.secret``` in the working directory:

```yaml
address: smtp.example.com
port: 25
```

You can create a YAML file ```email.secret```. Example contents:

```yaml
default_email: user@example.com
other_email: other_user@example.com
```

And then in ruby:

```ruby
c.yield_email                         # => user@example.com
c.yield_email(index: 'default_email') # => user@example.com
c.yield_email(index: 'other_email')   # => other_user@example.com
```
