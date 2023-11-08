require 'yaml'
require 'pg'
require 'sequel'

module Sierra
  module DB
    module Connection
      CREDS = {}

      # @return [Sequel::Database] the Sequel::Database "connection" to the db.
      def db
        Sierra::DB::Connection.db
      end

      # Whether a valid connection to Sierra database exists.
      #
      # @return [Boolean]
      def connected?
        Sierra::DB::Connection.connected?
      end

      # Establish connection to Sierra postgres database.
      #
      # @param [String, Hash] creds optionally specify credentials to use
      #
      #   If given, creds can be a:
      #     - String containing the filepath to a yaml file containing creds
      #     - Hash containing the creds
      #   If creds is not given, connects using the first existing of these:
      #     - Sierra::DB::Connection::CREDS (Hash), if populated
      #     - SIERRA_INIT_CREDS (String) environment variable
      #     - 'sierra_prod.secret'
      #   yaml files are searched for in this order:
      #     - working directory
      #     - sierra_postgres_utilities install / base directory
      #
      #   Credentials needed are: host, post, username, password.
      # @param [Hash] options options to pass directly to Sequel.connect
      #
      #   @see http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html#label-General+connection+options
      def connect(creds: nil, options: {})
        return if connected?
        Sierra::DB::Connection.connect(creds, options: options)
      end

      # (view documentation on #db)
      def self.db
        @db
      end

      # (view documentation on #connected?)
      def self.connected?
        @db.test_connection
      rescue
        false
      end

      # (view documentation on #connect)
      def self.connect(creds = nil, options: {})
        set_creds(creds) if creds || Sierra::DB::Connection::CREDS.empty?
        make_connection(Sierra::DB::Connection::CREDS.merge(options))
      end

      # Returns a hash of credentials along with some connection constants.
      # Accepts a hash or a yaml filename (expected to contain connection
      # variables). Tries default credential locations if nothing given.
      # @param [Hash, String] creds hash of credentials or string with
      #   path to yaml file containing credentials. refer to #connect
      # @return [Hash, nil] hash of connection credentials and Sierra
      #   connection constants. nil if valid-looking credentials were
      #   not given/found.
      def self.set_creds(creds)
        creds ||= ENV['SIERRA_INIT_CREDS'] || 'sierra_prod.secret'
        creds = creds_from_file(creds) unless creds.is_a?(Hash)
        return unless creds

        CREDS['host'] = creds['host']
        CREDS['port'] = creds['port']
        CREDS['user'] = creds['user']
        CREDS['password'] = creds['password']

        CREDS['database'] = 'iii'
        CREDS['adapter'] = 'postgres'
        CREDS['search_path'] = 'sierra_view'
      end

      # Establishes connection to Sierra database
      #
      # If connection is established, tries to reload any
      # sierra_postgres_utilities files that are skipped when a valid
      # connection does not exist.
      #
      # @param [Hash] creds Here, creds is a hash containing
      #   - credentials (host/port/username/constant)
      #   - Sierra connection constants (database/adapter/search_path)
      #   - any other connection options previously supplied
      # @return void
      def self.make_connection(creds)
        @db = Sequel::Database.connect(creds)
        return unless connected?

        # If lack of a connection caused loading of some files to be skipped,
        # go back and load them
        load File.join(base_dir, 'lib/sierra_postgres_utilities.rb')
      end

      # Reads credentials from yaml file.
      #
      # @param [String] path to credentials yaml file
      # @return [Hash] credentials read from file
      def self.creds_from_file(file)
        begin
          creds = YAML.load_file(file)
        rescue Errno::ENOENT
          begin
            creds = YAML.load_file(File.join(Dir.home, file))
          rescue Errno::ENOENT
            puts 'WARN: Connection credentials invalid or not found.'
          end
        end
        creds
      end

      # @return [String] sierra_postgres_utilities base/install directory
      # @example
      #   "#=> path/to/sierra-postgres-utilities"
      def self.base_dir
        File.dirname(File.expand_path('../..', __dir__)).to_s
      end
    end
  end
end
