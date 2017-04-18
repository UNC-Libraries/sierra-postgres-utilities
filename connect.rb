require 'pg'

prod_secret = File.dirname(__FILE__).to_s + '/sierra_prod.secret'
test_secret = File.dirname(__FILE__).to_s + '/sierra_test.secret'
@email_secret = File.dirname(__FILE__).to_s + '/email.secret'


def get_keys(filename)
  @secrets = {}
  lines = File.read(filename).split("\n")
  lines.each { |line| @secrets[line.split(" = ")[0]] = line.split(" = ")[1].rstrip }
  return @secrets
end

def make_query(query_file)
  query = File.read(query_file)
  puts 'running query'
  results = run_query(query, @prod_cred)
  return results
end

def write_results(outfile, results, headers='', format='tsv')
  # needs relative path for xlsx output
  puts 'writing results'
  if format == 'tsv'
    write_tsv(outfile, results, headers)
  elsif format == 'csv'
    write_csv(outfile, results, headers)
  elsif format == 'xlsx'
    write_xlsx(outfile, results, headers)
  end
end

def write_tsv(outfile, results, headers)
  File.open(outfile, 'w') do |file|
    results.each do |record|
      #
      #Lazily relying on unofficially ordered, or whatever, hash values, instead of explicit, e.g.:
      #[record['bnum'], record['collection'], record['isbn'], record['title']]
      # 
      file << record.values().join("\t") + "\n"
    end
  end
end

def write_csv(outfile, results, headers)
  require 'csv'
  CSV.open(outfile, 'wb') do |csv|
    if not headers.empty?
      csv << headers
    end
    results.each do |record|
      csv << record.values
    end
  end
end

def write_xlsx(outfile, results, headers)
  require 'win32ole'
  excel = WIN32OLE.new('Excel.Application')
  excel.visible = false
  workbook = excel.Workbooks.Add()
  worksheet = workbook.Worksheets(1)
  # find end column letter
  end_col = ('A'..'ZZ').to_a[(headers.length-1)]
  # write headers
  worksheet.Range("A1:#{end_col}1").value = headers
  # write data
  i = 1
  results.each do |result|
    i += 1
    worksheet.Range("A#{i}:#{end_col}#{i}").value = result.values
  end
  # save and close excel
  outfilepath = File.join(Dir.pwd, outfile).gsub(/\//, "\\\\")
  if File.exist?(outfilepath)
    File.delete(outfilepath)
  end
  workbook.saveas(outfilepath)
  excel.quit()
end


def get_email_secret(secretfile)
   return File.read(secretfile).rstrip
end

def mail_results(outfile, mail_details)
  require 'mail'
  Mail.defaults do
    delivery_method :smtp, address: "relay.unc.edu", port: 25
  end
  Mail.deliver do
    from  mail_details[:from]
    to    mail_details[:to]
    subject mail_details[:subject]
    body  mail_details[:body]
    if outfile
      add_file  outfile
    end
  end
end

# query is just an SQL query as a string
#   query = "SELECT * FROM table WHERE a = 2 and b like 'thing'"
#
def run_query(query, cred=@test_cred)
  conn = PG::Connection.new(cred)
  results = []
  conn.exec(query) do |result|
    result.each do |row|
      results << row
    end
  end
  return results
end

@prod_cred = get_keys(prod_secret)
@test_cred = get_keys(test_secret)
