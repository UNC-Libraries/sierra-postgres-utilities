require 'pg'

prod_secret = File.dirname(__FILE__).to_s + '/sierra_prod.secret'
test_secret = File.dirname(__FILE__).to_s + '/sierra_test.secret'


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

def write_results(outfile, results, headers='', csv=false)
  puts 'writing results'
  if csv
    write_csv(outfile, results, headers)
  else
    write_tsv(outfile, results, headers)
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
