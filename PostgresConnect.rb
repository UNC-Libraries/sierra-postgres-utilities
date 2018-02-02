require 'csv'
require 'yaml'
require 'mail'
require 'pg'
begin
  require 'win32ole'
rescue LoadError
  puts 'win32ole not found. writing output to .xlsx disabled. win32ole is
    probably not available on linux/mac but should be part of the standard
    library on Windows installs of Ruby'
end

class Connect < PG::Connection
  attr_reader :results
  attr_reader :query
  attr_reader :emails

  def initialize(cred: 'prod')
    @secrets_dir = File.dirname(__FILE__).to_s
    @prod_cred = YAML.load_file(File.join(@secrets_dir, '/sierra_prod.secret'))
    @test_cred = YAML.load_file(File.join(@secrets_dir, '/sierra_test.secret'))
    @emails = YAML.load_file(File.join(@secrets_dir, '/email.secret'))
    if cred == 'prod'
      @cred = @prod_cred
    else
      @cred = @test_cred
    end
    super(@cred)
  end

  def inspect
    self.to_s
  end

  def make_query(query)
    return run_query(query)
  end  


  def write_results(outfile, results: @results, headers: @headers, include_headers: true, format: 'tsv')
    # needs relative path for xlsx output
    puts 'writing results'
    unless include_headers
      headers = ''
    end
    if format == 'tsv'
      write_tsv(outfile, results, headers)
    elsif format == 'csv'
      write_csv(outfile, results, headers)
    elsif format == 'xlsx'
      if headers == ''
        raise ArgumentError("writing to xlsx requires headers")
      end
      write_xlsx(outfile, results, headers)
    end
  end

  def mail_results(outfile, mail_details, remove_file: false)
    send_mail(outfile, mail_details, remove_file: remove_file)
  end

  def yield_email(index='')
    unless index.empty?
      return @emails[index]
    end
    return @emails['default_email']
  end

  def write_tsv(outfile, results, headers)
    write_csv(outfile, results, headers, col_sep: "\t")
  end

  def write_csv(outfile, results, headers, col_sep: ",")
    CSV.open(outfile, 'wb', col_sep: col_sep) do |csv|
      if !headers.empty?
        csv << headers
      end
      results.each do |record|
        csv << record.values
      end
    end
  end

  def write_xlsx(outfile, results, headers)
    unless defined?(WIN32OLE)
      raise 'WIN32OLE not loaded; cannot write to xlsx file'
    end
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

  def send_mail(outfile, mail_details, remove_file: false)
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
    if remove_file
      File.delete(outfile)
    end
  end

  # query is just an SQL query as a string
  #   query = "SELECT * FROM table WHERE a = 2 and b like 'thing'"
  # or as a file containing such a string
  #
  def run_query(query)
    @query = File.file?(query) ? File.read(query) : query
    #puts 'running query'
    @results = self.exec(@query)
    @headers = @results.fields
  end

end

