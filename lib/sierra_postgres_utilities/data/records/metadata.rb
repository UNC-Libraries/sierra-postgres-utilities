module Sierra
  module Data
    class Metadata < Sequel::Model(DB.db[:record_metadata])
      set_primary_key :id
      prepare_retrieval_by :id, :first

      # Common to records
      one_to_many :control_fields,
                  class: :'Sierra::Data::ControlField', key: :record_id,
                  order: %i[varfield_type_code occ_num id]
      one_to_one :leader_field,
                 key: :record_id
      one_to_many :varfields,
                  key: :record_id,
                  order: %i[marc_tag varfield_type_code occ_num id]
      one_to_many :subfields,
                  key: :record_id
      one_to_many :phrase_entries,
                  key: :record_id,
                  order: %i[index_tag varfield_type_code occurrence id]

      one_to_one :bib, key: :record_id
      one_to_one :item, key: :record_id
      one_to_one :authority, key: :record_id
      one_to_one :holdings,
                 class: :'Sierra::Data::Holdings', key: :record_id
      one_to_one :order, key: :record_id
      one_to_one :patron, key: :record_id

      def record
        if deletion_date_gmt
          extend Sierra::Data::DeletedRecord
          return @record = self
        end
        @record ||=
          case record_type_code
          when 'b'
            bib
          when 'i'
            item
          when 'c'
            holdings
          when 'o'
            order
          when 'a'
            authority
          when 'p'
            patron
          end
      end

      def deleted?
        return true if deletion_date_gmt
        false
      end
    end
  end
end
