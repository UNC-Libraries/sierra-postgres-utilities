module Sierra
  module Data
    class Authority < Sequel::Model(DB.db[:record_metadata].
                                        inner_join(:authority_record, [:id]))
      include Sierra::Data::GenericRecord
      include Sierra::Data::Helpers::SierraMARC

      set_primary_key :id
      prepare_retrieval_by :record_num, :first

      # Common to records
      one_to_one :record_metadata,
                 class: :'Sierra::Data::Metadata', key: :id
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
    end
  end
end
