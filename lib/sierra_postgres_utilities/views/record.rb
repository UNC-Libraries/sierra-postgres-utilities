module SierraPostgresUtilities
  module Views
    module Record
      extend Views::MethodConstructor

      views = [
        {
          view: :phrase_entry,
          view_match: :record_id, obj_match: :record_id,
          entries: :all,
          sort: [:index_tag, :varfield_type_code, :occurrence, :id]
        },
        {
          view: :varfield,
          view_match: :record_id, obj_match: :record_id,
          entries: :all,
          sort: [:marc_tag, :varfield_type_code, :occ_num, :id]
        },
      ]

      views.each do |hsh|
        match_view(hsh)
        access_view(hsh)
      end

      def record_metadata
        @record_metadata ||= read_record_metadata
      end

      def self.record_metadata_struct
        @record_metadata_struct ||= SierraDB.viewstruct(:record_metadata)
      end

      statement = <<~SQL
        select record_id
        from sierra_view.phrase_entry phe
        where (phe.index_tag || phe.index_entry) ~ $1::text
      SQL
      SierraDB.prepare_query('search_phrase_entry', statement)


      statement = <<~SQL
        select *
        from sierra_view.record_metadata rm
        where id = $1::bigint
      SQL
      SierraDB.prepare_query("id_find_record_metadata", statement)

      statement = <<~SQL
        select *
        from sierra_view.record_metadata rm
        where record_type_code = $1::char
        and record_num = $2::int
      SQL
      SierraDB.prepare_query("recnum_find_record_metadata", statement)

      # Reads/sets rec data from record_metadata by recnum lookup
      def read_record_metadata
        return {} unless recnum

        metadata = SierraDB.conn.exec_prepared(
          'recnum_find_record_metadata',
          [rtype, recnum]
        ).first&.values
        return {} unless metadata

        SierraPostgresUtilities::Views::Record.record_metadata_struct.new(
          *metadata
        )
      end
    end
  end
end
