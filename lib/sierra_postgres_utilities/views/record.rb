module SierraPostgresUtilities
  module Views
    module Record
      extend Views::MethodConstructor

      views = [
        {
          view: :phrase_entry,
          view_match: :record_id, obj_match: :record_id, require: :record_id,
          openstruct: true, entries: :all,
          sort: [:index_tag, :varfield_type_code, :occurence, :id],
          require_fail_return: {}, if_empty: {}
        },
        {
          view: :varfield,
          view_match: :record_id, obj_match: :record_id, require: :record_id,
          openstruct: true, entries: :all,
          sort: [:marc_tag, :varfield_type_code, :occ_num, :id],
          require_fail_return: {}, if_empty: {}
        },
      ]

      views.each do |hsh|
        match_view(hsh)
        access_view(hsh)
      end


      def record_metadata
        @record_metadata ||= read_record_metadata
      end

      # Reads/sets rec data from record_metadata by recnum lookup
      def read_record_metadata
        return {} unless recnum
        query = <<-SQL
          select *
          from sierra_view.record_metadata rm
          where record_type_code = \'#{rtype}\'
          and record_num = \'#{recnum}\'
        SQL
        SierraDB.make_query(query)
        return {} if SierraDB.results.entries.empty?
        OpenStruct.new(
          SierraDB.results.entries.first.collect { |k,v| [k.to_sym, v] }.to_h
        )
      end
    end
  end
end
