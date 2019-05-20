module Sierra
  module Data
    class Order < Sequel::Model(DB.db[:record_metadata].
                                   inner_join(:order_record, [:id]))
      include Sierra::Data::GenericRecord

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

      # Attributes/properties
      one_to_many :cmfs,
                  class: :'Sierra::Data::OrderCMF', key: :order_record_id,
                  order: :display_order

      # Attachments
      one_through_one :bib,
                      left_key: :order_record_id, right_key: :bib_record_id,
                      join_table: :bib_record_order_record_link

      alias cat_date catalog_date_gmt
      alias received_date received_date_gmt
      alias status_code order_status_code

      def funds
        @funds ||= cmfs.map(&:fund).uniq
      end

      #### Logic

      def number_copies
        cmfs.map(&:copies)
      end

      def location
        cmfs.map(&:location_code)
      end
    end
  end
end
