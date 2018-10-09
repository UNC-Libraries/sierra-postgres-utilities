require 'time'

module SierraPostgresUtilities
  module Helpers
    module Dates
      # Gets a DateTime object from a Sierra Postgres string
      # Most sierra dates seem to be:
      #   '2017-11-11 09:53:07-05'
      # Some seem to be (e.g. b4966956a updated date):
      #   '2017-11-11 09:53:07.666-05'
      def strip_date(date:)
        return Time.strptime(date, '%Y-%m-%d %H:%M:%S%z')
      rescue ArgumentError
        #e.g. b4966956a updated date = '2017-11-11 09:53:07.666-05'
        return Time.strptime(date, '%Y-%m-%d %H:%M:%S.%N%z')
      rescue TypeError
        return nil
      end

      def format_date(date:, strformat: nil)
        return nil unless date
        if strformat
          date.strftime(strformat)
        else
          date
        end
      end
    end
  end
end
