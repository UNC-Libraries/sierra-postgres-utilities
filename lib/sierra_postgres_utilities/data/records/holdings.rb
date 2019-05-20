module Sierra
  module Data
    class Holdings < Sequel::Model(DB.db[:record_metadata].
                                      inner_join(:holding_record, [:id]))
      include Sierra::Data::GenericRecord
      include Sierra::Data::Helpers::SierraMARC

      set_primary_key :id

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
      many_to_many :create_lists,
                   class: :'Sierra::Data::CreateList', right_key: :bool_info_id,
                   left_key: :record_metadata_id, left_primary_key: :id,
                   join_table: :bool_set

      # Attributes/properties
      one_to_many :cards,
                  class: :'Sierra::Data::HoldingsCard', key: :holding_record_id,
                  order: :id
      many_to_many :locations,
                   left_key: :holding_record_id, right_key: :location_code,
                   right_primary_key: :code,
                   join_table: :holding_record_location, order: :display_order

      # Attachments
      one_through_one :bib,
                      left_key: :holding_record_id, right_key: :bib_record_id,
                      join_table: :bib_record_holding_record_link
      many_to_many :items,
                   left_key: :holding_record_id, right_key: :item_record_id,
                   join_table: :holding_record_item_record_link,
                   order: :items_display_order

      #### Logic

      def card_count
        cards.length
      end
    end
  end
end
