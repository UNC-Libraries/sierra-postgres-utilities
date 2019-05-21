module Sierra
  module Data
    class Patron < Sequel::Model(DB.db[:record_metadata].
                                    inner_join(:patron_record, [:id]))
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
      one_to_one :ptype_property,
                 class: :'Sierra::Data::Ptype', primary_key: :ptype_code,
                 key: :value
      one_to_many :addresses,
                  class: :'Sierra::Data::PatronAddress',
                  key: :patron_record_id, order: :display_order
      one_to_many :names,
                  class: :'Sierra::Data::PatronFullname',
                  key: :patron_record_id, order: :display_order
      one_to_many :phones,
                  class: :'Sierra::Data::PatronPhone', key: :patron_record_id,
                  order: :display_order

      # Other
      one_to_many :circ_trans,
                  class: :'Sierra::Data::CircTrans', key: :patron_record_id
      one_to_many :holds, key: :patron_record_id
      one_to_many :checkouts, key: :patron_record_id

      alias ptype ptype_property
      alias expiration_date expiration_date_gmt

      #### Logic

      # Sierra manual: An expired patron is one with an EXP DATE fixed-length
      #                field value earlier than or equal to the current date
      def expired?
        expiration_date <= Time.now
      end

      def barcodes(value_only: true)
        varfield_search('b'.freeze, value_only: value_only)
      end

      def emails(value_only: true)
        varfield_search('z'.freeze, value_only: value_only)
      end

      def name
        names.first.full
      end

      def name_reverse
        names.first.full_reverse
      end
    end
  end
end
