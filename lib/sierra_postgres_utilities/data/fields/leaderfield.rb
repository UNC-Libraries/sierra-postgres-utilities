module Sierra
  module Data
    class LeaderField < Sequel::Model(DB.db[:leader_field])
      set_primary_key :id
      prepare_retrieval_by :record_id, :first

      many_to_one :record_metadata,
                  class: :'Sierra::Data::Metadata', primary_key: :id,
                  key: :record_id

      one_to_one :bib, primary_key: :id, key: :record_id
      one_to_one :item, primary_key: :id, key: :record_id
      one_to_one :authority, primary_key: :id, key: :record_id
      one_to_one :holdings,
                 class: :'Sierra::Data::Holdings', primary_key: :id,
                 key: :record_id
      one_to_one :order, primary_key: :id, key: :record_id
      one_to_one :patron, primary_key: :id, key: :record_id

      def record
        record_metadata.record
      end

      def to_s
        [
          '00000'.freeze,  # rec_length
          record_status_code,
          record_type_code,
          bib_level_code,
          control_type_code,
          char_encoding_scheme_code,
          '2'.freeze,      # indicator count
          '2'.freeze,      # subf_ct
          base_address.to_s.rjust(5, '0'),
          encoding_level_code,
          descriptive_cat_form_code,
          multipart_level_code,
          '4500'.freeze    # ldr_end
        ].join
      end

      def to_xml
        "  <leader>#{marc.leader}</leader>"
      end
    end
  end
end
