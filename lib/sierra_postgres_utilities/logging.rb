require 'logger'

module Sierra
  # Logging utilities.
  module Logging
    def logger
      Logging.logger
    end

    def log_to(log)
      Logging.logger =
        if log.respond_to?(:warn)
          log
        else
          Logging.make_log(log)
        end
    end

    # Turns on (or toggles) logging of SQL queries.
    #
    # @param [Boolean] log_sql whether to log all SQL queries
    # @return void
    def log_sql(log_sql = true)
      if log_sql
        Sierra::DB.db.loggers << Sierra::Logging.logger
      else
        Sierra::DB.db.loggers.delete(Sierra::Logging.logger)
      end
    end

    # Retrieves cached logger or creates a new one.
    def self.logger
      @logger ||= make_log
    end

    # Sets log to already-instantiated log.
    def self.logger=(log)
      @logger = log
    end

    # Instantiates a log.
    #
    # @param [String, #write] file write log to this file / STDOUT / IO object
    # @return [Logger]
    def self.make_log(file = STDOUT)
      log = Logger.new(file)
      log.level = Logger::INFO
      log.datetime_format = '%Y-%m-%d %H:%M:%S%z'
      log.progname = 'sierra-postgres-utilities'
      log.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime}: #{severity} [#{progname}] #{msg}\n"
      end
      log
    end
  end

  extend Logging
end
