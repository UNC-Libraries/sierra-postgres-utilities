# postgres_connect

Ruby connection to iii Sierra ILS postgres database / SierraDNA, meant to simplify making queries, exporting results, and some transformation of MARC or non-MARC Sierra data.

__NOTE: This is in early development and future changes may well not be backwards compatible.__

## SETUP
* Clone or download a copy.
* gem install mail
* gem install pg
* supply the credentials per the below

### Production credentials
Create <code>sierra_prod.secret</code>, a YAML file with authentication details, in the postgres_connect directory. For example:
<pre>
host: myhost.example.com
port: 1032
dbname: mydb
user: myusername
password: mypassword
</pre>
Sorry to be storing the password in this manner.

### Test credentials
You can create <code>sierra_test.secret</code> with YAML auth details for a test server.
<pre>c = Connect.new(cred: 'test')</pre> will use those test server credentials.

### Email address storage
You can create a YAML file <code>email.secret</code>. Example contents:
<pre>
default_email: user@example.com
other_email: other_user@example.com
</pre>
And then:
<pre>
c.yield_email                         # => user@example.com
c.yield_email(index: 'default_email') # => user@example.com
c.yield_email(index: 'other_email')   # => other_user@example.com
</pre>

## USAGE
### Making queries, writing results
<pre>
c = Connect.new
query = 'select * from sierra_view.bib_record limit 1'
c.make_query(query)
c.write_results('output.txt', include_headers: true, format: 'tsv')
c.make_query('queryfile.sql')
</pre>
Valid output formats are: 'tsv', 'csv', 'xlsx'

Writing to xlsx requires <code>include_headers: true</code>

### Emailing results
Send the results as an email attachment in addition to or instead of writing to file. The UNC smtp address is just hardcoded in.
<pre>
email_address = c.yield_email  # gets default email from email.secret
mail_details = {:from => email_address,
                :to => email_address,
                :subject => 'Report: html entity cleanup',
                :body => 'Attached is the report'}
c.write_results('output.txt')
existing_file_to_mail = 'output.txt'
c.mail_results(existing_file_to_mail, mail_details, remove_file: true)
</pre>
passing <code>remove_file: true</code> deletes output.txt after sending the email; <code>remove_file: false</code> leaves output.txt in place.

### Modifying results
You can modify/select/etc the query results as you like, and write the modified array of records to file.
<pre>
c.make_query(my_query)
html_problems = []
mod = c.results.entries.dup
mod.select! { |x| detect_html(x['field_content']) }.
    map! { |x| x.merge({'flag_field' => 'html'}) }
c.write_results(mod, headers: ['bnum', 'field_content', 'html_flag'])
</pre>
By default, included headers are the headers from the sql query, so specify headers if needed.

### Loading into other scripts

sierra-postgres-utilities isn't getting installed and can have varying paths, so what I've been doing is keeping the sierra-postgres-utilities folder and the folders for scripts dependent on sierra-postgres-utilities in the same directory, so:
* .../code/sierra-postgres-utilities/.git
* .../code/dependent_repo/dependent_thing.rb

and then doing
<code>require_relative '../sierra-postgres-utilities/connect.rb'</code> in dependent_thing.rb

