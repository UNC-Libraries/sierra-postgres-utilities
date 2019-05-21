require 'sequel'

Sequel::Model.plugin :dataset_associations

module Sierra
  # Includes Sierra database connection, direct querying, export functions.
  module DB
    require_relative 'db/connection'
    require_relative 'db/query'

    extend Sierra::DB::Connection
    extend Sierra::DB::Query

    # Connects using default credentials / connection options.
    # Setting ENV['SIERRA_DELAY_CONNECT'] defers connection and allows
    # connection using custom credentials / options.
    Sierra::DB.connect unless ENV['SIERRA_DELAY_CONNECT']
  end
end
