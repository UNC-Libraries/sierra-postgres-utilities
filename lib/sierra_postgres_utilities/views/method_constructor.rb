module SierraPostgresUtilities
  module Views

    # Creates methods to read/cache a given view either in the view's entirety
    # or limited to the context of, for example, a specific record.
    module MethodConstructor

      # Creates a method that retrieves an entire DB view
      #
      # Arguments:
      #   view: name of the view to be read
      #     (i.e. :bib_record for "sierra_view.bib_record")
      #   sort: field or array of fields to sort results by
      def read_view(hsh)
        viewstruct = SierraDB.viewstruct(hsh[:view])
        define_method("read_#{hsh[:view]}") do
          query = <<~SQL
            select *
            from sierra_view.#{hsh[:view]}
          SQL
          SierraDB.make_query(query).
                   entries.
                   sort_by! { |x| x[hsh[:sort].to_s] }
          SierraDB.results.values.map! { |r| viewstruct.new(*r) }
        end
      end

      # Create a method that returns an enumerator for larger DB views
      def stream_view(hsh)
        viewstruct = SierraDB.viewstruct(hsh[:view])
        sort = hsh[:sort] || [:id]
        sort.flatten!
        sort.compact!
        statement = <<~SQL
          select * from sierra_view.#{hsh[:view]}
          order by #{sort.join(', ')}
          limit 10000
          offset $1::int
        SQL
        SierraDB.prepare_query("stream_#{hsh[:view]}", statement)

        define_method("stream_#{hsh[:view]}") do
          stream = Enumerator.new do |y|
            n = 0
            not_done = true
            while not_done
              values = SierraDB.conn.exec_prepared(
                "stream_#{hsh[:view]}",
                [n]).values
              not_done = false if values.empty?
              values.each { |r| y << viewstruct.new(*r) }
              n += 10000
            end
          end
        end

        # The enumeration isn't memoized, so we just alias, for example,
        # SierraDB.stream_bib_record as SierraDB.bib_record
        define_method(hsh[:view]) do
          self.send("stream_#{hsh[:view]}")
        end
      end

      # Creates a method that retrieves matching records in a DB view.
      # Generally used to scope DB results to entries that match a given
      # object/record_id
      #
      # Returns nil unless obj_match returns truthy
      #
      # Arguments:
      #   view: name of the view to be read
      #     (i.e. :bib_record for "sierra_view.bib_record")
      #
      #   view_match: field from the DB view to match on
      #   obj_match:  object method to match on
      #   cast: will cast obj_match to given sql type
      #     (default is bigint, appropriate for record_id's)
      #
      #
      #   sort: field or array of fields to sort results by
      #   entries:
      #     when 'all': return all entries in an array
      #     when 'first': return first of any entries

      def match_view(hsh)
        viewstruct = SierraDB.viewstruct(hsh[:view])
        cast = hsh[:cast] || :bigint
        statement = <<~SQL
          select *
          from sierra_view.#{hsh[:view]}
          where #{hsh[:view_match]} = $1::#{cast}
        SQL
        sort = [hsh[:sort]].flatten.compact
        statement << "order by #{sort.join(', ')}" if sort.any?
        name = self.name
        SierraDB.prepare_query("#{name}_match_#{hsh[:view]}", statement)

        define_method("read_#{hsh[:view]}") do
          obj_match = self.send(hsh[:obj_match])
          return unless obj_match
          results = SierraDB.conn.exec_prepared(
            "#{name}_match_#{hsh[:view]}",
            [obj_match]
          ).values

          case hsh[:entries]
          when :all
            results.map! { |r| viewstruct.new(*r) }
          when :first
            viewstruct.new(*results&.first)
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

      # refreshes a cached view that has presumably already had a method defined
      def refresh_view(name)
        self.instance_variable_set("@#{name}", self.send("read_#{name}"))
      end
    end
  end
end
