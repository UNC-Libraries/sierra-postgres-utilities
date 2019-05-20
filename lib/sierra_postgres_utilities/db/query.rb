require 'csv'
require 'yaml'
require 'mail'

module Sierra
  module DB
    # Manual/direct sql querying and exporting.
    module Query
      def query(query)
        Sierra::DB::Query.make_query(query)
      end

      def results
        Sierra::DB::Query.results
      end

      # Writes results to file.
      #
      # Formats: tsv, csv, xlsx (xlsx writable on windows only)
      #
      # @param [String] outfile path for outfile
      #   - for xlsx only: a relative path is relative to user's windows
      #     home directory, so using an absolute path may be preferable
      # @param [Enumerable<#values>] results (default: Sierra::DB.results)
      # @param [Boolean] include_headers (default: true) write headers to file?
      # @param [Symbol] format (default: tsv) format of export: :tsv, :csv,
      #   :xlsx.
      def write_results(outfile, results: self.results,
                        include_headers: true, format: :tsv)
        Sierra::DB::Query.write_results(outfile,
                                        results: results, format: format,
                                        include_headers: include_headers)
      end

      # Mail an existing file as an attachment.
      #
      # @param [String] outfile path/name of the existing file
      # @param [Hash] mail_details email properties
      #   - required: :to, :from
      #   - optional: :cc, :subject, :body
      # @param [Boolean] remove_file (default: false) delete file after mailing?
      def mail_results(outfile, mail_details, remove_file: false)
        Sierra::DB::Query.send_mail(outfile, mail_details,
                                    remove_file: remove_file)
      end

      def yield_email(index = nil)
        emails = Sierra::DB::Query.emails
        return emails[index] if index
        emails['default_email']
      end

      # Stage/execute a query.
      #
      # The query isn't actually executed until the resulting Dataset is
      # accessed.
      #
      # - Sets @query to the SQL query as a string.
      # - Sets @results as Sequel::Dataset returned.
      #
      # @param [String] query A string containing either the SQL query itself
      #   or a path to a file consisting of the query. For example:
      #     "SELECT * FROM table WHERE a = 2 and b like 'thing'"
      # @return [Sequel::Dataset] query results
      def self.make_query(query)
        @query = File.file?(query) ? File.read(query) : query
        @results = DB.db[query]
      end

      def self.results
        @results
      end

      def self.headers
        results.columns
      end

      # (see #write_results)
      def self.write_results(outfile, results: self.results,
                             include_headers: true, format: :tsv)
        puts 'writing results'
        headers =
          if include_headers
            self.headers
          else
            ''
          end

        format = format.to_sym
        case format
        when :tsv
          write_tsv(outfile, results, headers)
        when :csv
          write_csv(outfile, results, headers)
        when :xlsx
          raise ArgumentError('writing to xlsx requires headers') if headers == ''
          write_xlsx(outfile, results, headers)
        end
      end

      # Writes results as tsv.
      #
      # Delegated to by .write_results.
      def self.write_tsv(outfile, results, headers)
        write_csv(outfile, results, headers, col_sep: "\t")
      end

      # Writes results as csv.
      #
      # Delegated to by .write_results.
      def self.write_csv(outfile, results, headers, col_sep: ',')
        outfile = File.open(outfile, 'wb') unless outfile.respond_to?(:read)
        csv = CSV.new(outfile, col_sep: col_sep)
        csv << headers unless headers.empty?
        results.each do |record|
          csv << record.values
        end
        outfile.close
      end

      # Writes results as xlsx.
      #
      # Delegated to by .write_results.
      #
      # Windows only. Outfile path, if relative, is relative to user's
      # windows home directory
      def self.write_xlsx(outfile, results, headers)
        begin
          require 'win32ole'
        rescue LoadError
          puts <<~DOC
            win32ole not found. writing output to .xlsx disabled. win32ole is
            probably not available on linux/mac but should be part of the
            standardlibrary on Windows installs of Ruby
          DOC
          raise
        end
        excel = WIN32OLE.new('Excel.Application')
        excel.visible = true
        workbook = excel.Workbooks.Add()
        worksheet = workbook.Worksheets(1)
        # find end column letter
        end_col = ('A'..'ZZ').to_a[(headers.length - 1)]
        # write headers
        worksheet.Range("A1:#{end_col}1").value = headers.map(&:to_s)
        # write data
        i = 1
        results.each do |result|
          i += 1
          worksheet.Range("A#{i}:#{end_col}#{i}").value = result.values
        end
        # save and close excel
        outfilepath = outfile.gsub(/\//, '\\\\')
        puts outfilepath
        File.delete(outfilepath) if File.exist?(outfilepath)
        workbook.saveas(outfilepath)
        excel.quit
      end

      # Returns cached email "address book" or reads it from 'email.secret'
      # yaml file.
      def self.emails
        @emails ||=
          begin
            YAML.load_file('email.secret')
          rescue Errno::ENOENT
            YAML.load_file(File.join(base_dir, '/email.secret'))
          end
      end

      def self.emails=(hsh)
        @emails = hsh
      end

      # Returns cached smtp connection details or reads them from 'smtp.secret'
      # yaml file.
      #
      # @return [Hash] smtp server connection details (address, port)
      def self.smtp
        @smtp ||=
          begin
            YAML.load_file('smtp.secret')
          rescue Errno::ENOENT
            YAML.load_file(File.join(base_dir, '/smtp.secret'))
          end
      end

      def self.smtp=(hsh)
        @smtp = hsh
      end

      # (see #mail_results)
      def self.send_mail(outfile, mail_details, remove_file: false)
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
    end
  end
end
