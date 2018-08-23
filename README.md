# sierra-postgres-utilities

Ruby connection to iii Sierra ILS postgres database / SierraDNA, meant to simplify making queries, exporting results, and some lookup / manipulation / transformation of MARC or non-MARC Sierra data and records.

__NOTE: This is in early development and future changes may well not be backwards compatible.__

__NOTE: Some sites may have iii setups that store different data in different places (e.g. bcode1, bcode2, bcode3) or differing local MARC practices (is the 001 an OCLC number?), and parts of these scripts do not account for that.__

## Usage overview

### Interact with bib (and other) records

```ruby
require_relative 'lib/sierra_postgres_utilities.rb'

bnum = 'b9256886a'
bib = SierraBib.new(bnum)

bib.suppressed?   #=> false
bib.deleted?      #=> false
bib.mat_type      #=> "a"

# Get data from sierra_view.bib_record as a hash
bib.rec_data      #=> {:id=>"420916051894",
                  #    :record_id=>"420916051894",
                  #    :language_code=>"eng",
                  #    :bcode1=>"m",
                  #    :bcode2=>"a",
                  #    :bcode3=>"-",
                  #    ....
                  #    :is_suppressed=>"f"}

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

## SETUP

* Clone or download a copy.
* ```gem install mail```
* ```gem install pg```
* ```gem install marc```
* supply the Sierra postgres credentials per the below
* optionally supply smtp server address

### Credentials

#### Stored in file

Create a yaml file in the base directory like so:

```yaml
host: myhost.example.com
port: 1032
dbname: mydb
user: myusername
password: mypassword
```

If you name the file ```sierra_prod.secret``` it will be the default connection.

Use some other file with ```SierraDB.connect_as(creds: filename)```

Set a test server connection in a file named ```sierra_test.secret```. Use it with ```SierraDB.connect_as(creds: 'test')```

#### Passed as argument

Pass the connection info (host, port, dbname, user, password) in a hash: ```SierraDB.connect_as(creds: cred_hash)```

### SMTP connection / email address storage

Define an smtp connection (that does not require authentication) if you'll use this to send emails.
Create ```smtp.secret``` in the base directory:

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

## Loading into other scripts

This isn't a gem. It isn't getting installed and can have varying paths, so we've been keeping the sierra-postgres-utilities folder and the folders for scripts dependent on sierra-postgres-utilities in the same directory, so:

* .../code/sierra-postgres-utilities/.git
* .../code/dependent_repo/dependent_thing.rb

and then in dependent_thing.rb doing:

```ruby
require_relative '../sierra-postgres-utilities/lib/sierra_postgres_utilities.rb'
```
