require 'ostruct'

module SierraPostgresUtilities
  module Views

    # Creates methods to read/cache a given view either in the view's entrirety
    # or limited to the context of, for example, a specific record.
    module MethodConstructor

      # Creates a method that retrieves an entire DB view
      #
      # Arguments:
      #   view: name of the view to be read
      #     (i.e. :bib_record for "sierra_view.bib_record")
      #   sort: field or array of fields to sort results by
      #   openstruct:
      #     when true (default): return entries as OpenStruct objects
      #     when false: return entries as hashes
      def read_view(hsh)
        define_method("read_#{hsh[:view]}") do
          query = <<~SQL
            select *
            from sierra_view.#{hsh[:view]}
          SQL
          SierraDB.make_query(query)
          entries = SierraDB.results.entries.sort_by { |x| x[hsh[:sort].to_s] }
          if hsh[:openstruct]
            entries.map { |r| OpenStruct.new(r) }
          else
            entries
          end
        end
      end

      # Creates a method that retrieves matching records in a DB view that
      #
      # Generally used to scope DB results to entries that match a given
      # object/record_id
      #
      # Arguments:
      #   view: name of the view to be read
      #     (i.e. :bib_record for "sierra_view.bib_record")
      #
      #   view_match: field from the DB view to match on
      #   obj_match:  object property to match on
      #
      #   require: object method which, if not met, will cause
      #     "require_fail_return" to be returned.
      #   require_fail_return: value to return if "require" not met
      #
      #     For example, {require: :record_id,
      #                   require_fail_return: OpenStruct.new}
      #     would return an empty OpenStruct unless obj.record_id is truthy
      #
      #   if_empty: value to return if no responsive entries found
      #   sort: field or array of fields to sort results by
      #   entries:
      #     when 'all': return all entries in an array
      #     when 'first': return first of any entries
      #   openstruct:
      #     when true (default): return entries as OpenStruct objects
      #     when false: return entries as hashes

      def match_view(hsh)
        define_method("read_#{hsh[:view]}") do
          return hsh[:require_fail_return] unless self.send(hsh[:require])
          query = <<~SQL
            select *
            from sierra_view.#{hsh[:view]}
            where #{hsh[:view_match]} = #{self.send(hsh[:obj_match])}
          SQL
          SierraDB.make_query(query)
          return hsh[:if_empty] if SierraDB.results.entries.empty?

          # make hsh[:sort] an array if it isn't
          unless hsh[:sort].is_a?(Array)
            hsh[:sort] = [hsh[:sort]].compact
          end
          # sort entries by fields specified in hsh[:sort], if any
          entries = SierraDB.results.
                            entries.
                            sort_by { |e| hsh[:sort].map { |k| e[k.to_s] || '0' } }

          case hsh[:entries]
          when :all
            if hsh[:openstruct]
              entries.map { |r| OpenStruct.new(r) }
            else
              entries
            end
          when :first
            if hsh[:openstruct]
              OpenStruct.new(entries.first)
            else
              entries.first
            end
          end
        end
      end

      # Creates method to return cached view or retrieve view if not yet cached.
      def access_view(hsh)
        define_method(hsh[:view]) do
          (self.instance_variable_get("@#{hsh[:view]}") ||
          self.instance_variable_set("@#{hsh[:view]}", self.send("read_#{hsh[:view]}")))
        end
      end
    end
  end
end

