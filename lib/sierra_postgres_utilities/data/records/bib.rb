module Sierra
  module Data
    class Bib < Sequel::Model(DB.db[:record_metadata].
                                 inner_join(:bib_record, [:id]))
      include Sierra::Data::GenericRecord
      include Sierra::Data::Helpers::SierraMARC

      attr_writer :stub

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
      many_to_many :locations,
                   left_key: :bib_record_id, right_key: :location_code,
                   right_primary_key: :code, join_table: :bib_record_location,
                   order: :location_code
      one_to_one :property,
                 class: :'Sierra::Data::BibRecordProperty',
                 key: :bib_record_id, primary_key: :id

      # Attachments
      many_to_many :items,
                   left_key: :bib_record_id, right_key: :item_record_id,
                   join_table: :bib_record_item_record_link,
                   order: :items_display_order
      many_to_many :holdings,
                   class: :'Sierra::Data::Holdings',
                   left_key: :bib_record_id, right_key: :holding_record_id,
                   join_table: :bib_record_holding_record_link,
                   order: :holdings_display_order
      many_to_many :orders,
                   left_key: :bib_record_id, right_key: :order_record_id,
                   join_table: :bib_record_order_record_link,
                   order: :orders_display_order

      # Other
      one_to_many :circ_trans,
                  class: :'Sierra::Data::CircTrans', key: :bib_record_id
      one_to_many :holds,
                  key: :record_id

      # Returns array of call number prefix(es)
      #   e.g. ["n", "pq"]
      def call_number_prefixes
        @call_number_prefixes ||= DB.db[:bib_record_call_number_prefix].
                                  where(bib_record_id: @values[:id]).
                                  map { |r| r[:call_number_prefix] }
      end

      ##### Logic
      alias bnum rnum
      alias bnum_trunc rnum_trunc
      alias bnum_with_check rnum_with_check

      alias cat_date cataloging_date_gmt

      def mat_type
        property[:material_code]
      end

      # @return [Array<String>] record's location code(s) excepting "multi"
      def location_codes
        locations.map(&:code).reject { |c| c == 'multi' }
      end

      def best_title
        property.best_title
      end

      def best_author
        property.best_author
      end

      # Returns record's imprint.
      #
      # Uses the first 260/264 by occ_num.
      #
      # @return [String] record's imprint
      # @example
      #   bib.marc['260'].to_mrk
      #   #=> "=260  \\\\$aSanta Barbara :$bBlack Sparrow Press,$c1976."
      #   bib.imprint
      #   #=> "Santa Barbara : Black Sparrow Press, 1976."
      def imprint
        varfields.
          select { |v| v.marc_tag =~ /26[04]/ }.
          min_by(&:occ_num).
          field_content.
          gsub(/\|./, ' ').lstrip
      end

      # LDR/06
      def rec_type
        leader_field&.record_type_code
      end

      # LDR/07; bcode1 also represents blvl and is not always the same
      def blvl
        leader_field&.bib_level_code
      end

      # LDR/08
      def ctrl_type
        leader_field&.control_type_code
      end

      # Record's OCLC# derived from MARC record.
      #
      # Uses UNC-specific logic
      # @return [String] oclc number
      def oclcnum
        marc.oclcnum
      end

      # Creates a marc stub record for batch loading.
      #
      # Stub contains:
      #   - a 907 with bnum suitable for overlaying
      #   - a 944 with batch load note template
      #
      # @return [MARC::Record]
      def stub
        return @stub if @stub
        @stub = MARC::Record.new
        @stub << MARC::DataField.new('907', ' ', ' ', ['a', ".#{bnum}"])
        load_note =
          'Batch load history: 999 Something records loaded 20190000, xxx.'
        @stub << MARC::DataField.new('944', ' ', ' ', ['a', load_note])
        @stub
      end
    end
  end
end
