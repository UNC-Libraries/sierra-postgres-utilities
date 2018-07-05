require 'csv'
require 'yaml'
require 'mail'
require 'pg'
begin
  require 'win32ole'
rescue LoadError
  puts "\n\nwin32ole not found. writing output to .xlsx disabled. win32ole is
    probably not available on linux/mac but should be part of the standard
    library on Windows installs of Ruby"
end

module SierraDB

  def self.conn(cred: 'prod')
    @conn ||= self.make_connection(cred: cred)
  end

  def self.connect_as(cred: )
    @conn.close if @conn && !@conn.finished?
    @conn = self.make_connection(cred: cred)
  end

  def self.close
    @conn.close
  end

  def self.headers
    @results&.fields
  end

  def self.results
    @results
  end

  def self.query
    @query
  end

  def self.make_query(query)
    run_query(query)
  end  

  def self.write_results(outfile, results: self.results, headers: self.headers, include_headers: true, format: 'tsv')
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

  def self.mail_results(outfile, mail_details, remove_file: false)
    send_mail(outfile, mail_details, remove_file: remove_file)
  end

  def self.yield_email(index='')
    unless index.empty?
      return @@emails[index]
    end
    return @@emails['default_email']
  end

  # Connects to SierraDB using specified credentials
  def self.make_connection(cred:)
    @@secrets_dir = File.dirname(File.expand_path('../..', __FILE__)).to_s
    @@prod_cred = YAML.load_file(File.join(@@secrets_dir, '/sierra_prod.secret'))
    @@test_cred = YAML.load_file(File.join(@@secrets_dir, '/sierra_test.secret'))
    @@emails = YAML.load_file(File.join(@@secrets_dir, '/email.secret'))
    if cred == 'prod'
      @@cred = @@prod_cred
    elsif cred == 'test'
      @@cred = @@test_cred
    else
      begin
        @@cred = YAML.load_file(File.join(@@secrets_dir, cred))
      rescue Errno::ENOENT
        begin
          @@cred = YAML.load_file(cred)
        rescue Errno::ENOENT
          @@cred = cred
        end
      end
    end
    PG::Connection.new(@@cred)
  end

  def self.write_tsv(outfile, results, headers)
    write_csv(outfile, results, headers, col_sep: "\t")
  end

  def self.write_csv(outfile, results, headers, col_sep: ",")
    CSV.open(outfile, 'wb', col_sep: col_sep) do |csv|
      if !headers.empty?
        csv << headers
      end
      results.each do |record|
        csv << record.values
      end
    end
  end

  def self.write_xlsx(outfile, results, headers)
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

  def self.send_mail(outfile, mail_details, remove_file: false)
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
  
  def self.run_query(query)
    @query = File.file?(query) ? File.read(query) : query
    #puts 'running query'
    @results = self.conn.exec(@query)
  end
  private_class_method :run_query
end
