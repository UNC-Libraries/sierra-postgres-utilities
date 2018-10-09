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

  # extension allows almost all views to be read with SierraDB.view_name
  # e.g. SierraDB.branch_myuser
  extend SierraPostgresUtilities::Views::General

  def self.conn(creds: 'prod')
    @conn ||= make_connection(creds: creds)
  end

  # Re-establish a connection (with the same or alternate credentials)
  def self.connect_as(creds:)
    @conn.close if @conn && !@conn.finished?
    @conn = make_connection(creds: creds)
  end

  # Close the connection
  def self.close
    @conn.close
  end

  # Headers for the current results
  def self.headers
    @results&.fields
  end

  def self.results
    @results
  end

  def self.query
    @query
  end

  # query is just an SQL query as a string
  #   query = "SELECT * FROM table WHERE a = 2 and b like 'thing'"
  # or as a file containing such a string
  def self.make_query(query)
    run_query(query)
  end

  def self.write_results(outfile, results: self.results, headers: self.headers,
                         include_headers: true, format: :tsv)
    # needs relative path for xlsx output
    puts 'writing results'
    headers = '' unless include_headers
    format = format.to_sym unless format.is_a?(Symbol)
    if format == :tsv
      write_tsv(outfile, results, headers)
    elsif format == :csv
      write_csv(outfile, results, headers)
    elsif format == :xlsx
      raise ArgumentError('writing to xlsx requires headers') if headers == ''
      write_xlsx(outfile, results, headers)
    end
  end

  # Mail an existing file as an attachment.
  #
  # outfile: the existing file
  # mail_details: a hash of email properties
  #   required - :to, :from
  #   optional - :cc, :subject, :body
  # remove_file: delete file after sending?
  def self.mail_results(outfile, mail_details, remove_file: false)
    send_mail(outfile, mail_details, remove_file: remove_file)
  end

  def self.emails
    @emails ||= YAML.load_file(File.join(base_dir, '/email.secret'))
  end

  def self.yield_email(index = nil)
    return emails[index] if index
    emails['default_email']
  end

  def self.base_dir
    File.dirname(File.expand_path('..', __dir__)).to_s
  end

  # Connects to SierraDB using creds from specified YAML file or given hash.
  #
  # Possible specified credentials:
  # 'prod' : uses sierra_prod.secret in base directory # creds for prod db
  # 'test' : uses sierra_test.secret in base directory # creds for test db
  # [filename] : reads secrets from file specified. First looks for file in
  #            secrets dir, and looks for file in current dir if that fails
  # [somehash]: accepts a hash containing the credentials
  def self.make_connection(creds:)
    if creds == 'prod'
      @cred = YAML.load_file(File.join(base_dir, '/sierra_prod.secret'))
    elsif creds == 'test'
      @cred = YAML.load_file(File.join(base_dir, '/sierra_test.secret'))
    elsif creds.is_a?(Hash)
      @cred = creds
    else
      begin
        @cred = YAML.load_file(File.join(base_dir, creds))
      rescue Errno::ENOENT
        begin
          @cred = YAML.load_file(creds)
        rescue Errno::ENOENT
          raise('Connection credentials invalid or not found.')
        end
      end
    end
    PG::Connection.new(@cred)
  end

  def self.write_tsv(outfile, results, headers)
    write_csv(outfile, results, headers, col_sep: "\t")
  end

  def self.write_csv(outfile, results, headers, col_sep: ',')
    CSV.open(outfile, 'wb', col_sep: col_sep) do |csv|
      csv << headers unless headers.empty?
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
    end_col = ('A'..'ZZ').to_a[(headers.length - 1)]
    # write headers
    worksheet.Range("A1:#{end_col}1").value = headers
    # write data
    i = 1
    results.each do |result|
      i += 1
      worksheet.Range("A#{i}:#{end_col}#{i}").value = result.values
    end
    # save and close excel
    outfilepath = File.join(Dir.pwd, outfile).gsub(/\//, '\\\\')
    File.delete(outfilepath) if File.exist?(outfilepath)
    workbook.saveas(outfilepath)
    excel.quit
  end

  def self.smtp
    @smtp ||= YAML.load_file(File.join(base_dir, '/smtp.secret'))
  end

  def self.send_mail(outfile, mail_details, remove_file: false)
    smtp = SierraDB.smtp
    Mail.defaults do
      delivery_method :smtp, address: smtp['address'], port: smtp['port']
    end
    Mail.deliver do
      from     mail_details[:from]
      to       mail_details[:to]
      subject  mail_details[:subject]
      body     mail_details[:body]

      add_file outfile if outfile
    end
    File.delete(outfile) if remove_file
  end

  # query is just an SQL query as a string
  #   query = "SELECT * FROM table WHERE a = 2 and b like 'thing'"
  # or as a file containing such a string
  def self.run_query(query)
    @query = File.file?(query) ? File.read(query) : query
    @results = conn.exec(@query)
  end
  private_class_method :run_query
end
