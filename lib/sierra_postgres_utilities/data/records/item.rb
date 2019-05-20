module Sierra
  module Data
    # Model for item records.
    #
    # For items we cannot use a natural join between record_metadata and
    # item_record. The rm.agency_code_num only ever seems to be 0 and that
    # is not the case for i.agency_code_num. This should only be a problem
    # for item records.
    # We inner join using "USING id" (i.e. "[:id]") syntax to avoid duplicate
    # id columns and potential AmbiguousColumn errors.
    class Item < Sequel::Model(DB.db[:record_metadata].
                               inner_join(:item_record, [:id]))
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
      many_to_one :location, primary_key: :code, key: :location_code
      many_to_one :itype_property,
                  class: :'Sierra::Data::Itype', primary_key: :code_num,
                  key: :itype_code_num
      many_to_one :item_status_property,
                  class: :'Sierra::Data::ItemStatus', primary_key: :code,
                  key: :item_status_code
      one_to_one :property,
                 class: :'Sierra::Data::ItemRecordProperty',
                 key: :item_record_id, primary_key: :id

      # Attachments
      many_to_many :bibs,
                   left_key: :item_record_id, right_key: :bib_record_id,
                   join_table: :bib_record_item_record_link
      one_through_one :holdings,
                      left_key: :item_record_id, right_key: :holding_record_id,
                      join_table: :holding_record_item_record_link

      # Other
      one_to_many :circ_trans,
                  class: :'Sierra::Data::CircTrans', key: :item_record_id
      one_to_many :holds, key: :record_id
      one_to_one :checkout, key: :item_record_id

      alias itype itype_property
      alias status item_status_property

      #### Logic

      alias inum rnum
      alias inum_trunc rnum_trunc
      alias inum_with_check rnum_with_check

      # @param [Boolean] value_only (default: true) whether to return data as
      #   strings of the field value/content? When false, returns data as entire
      #   Sierra::Data::Varfields
      # @return [Array<String, Varfield>] record's barcode(s) data
      def barcodes(value_only: true)
        varfield_search('b'.freeze, value_only: value_only)
      end

      # @param (see #barcodes)
      # @return [Array<String, Varfield>] record's "Library" varfield data
      def varfield_librarys(value_only: true)
        varfield_search('f'.freeze, value_only: value_only)
      end

      # @param (see #barcodes)
      # @return [Array<String, Varfield>] record's "Stats" varfield data
      def stats_fields(value_only: true)
        varfield_search('j'.freeze, value_only: value_only)
      end

      # @param (see #barcodes)
      # @return [Array<String, Varfield>] record's message field data
      def messages(value_only: true)
        varfield_search('m'.freeze, value_only: value_only)
      end

      # @param (see #barcodes)
      # @return [Array<String, Varfield>] record's volume field data
      def volumes(value_only: true)
        varfield_search('v'.freeze, value_only: value_only)
      end

      # @param (see #barcodes)
      # @return [Array<String, Varfield>] record's internal_notes data
      def internal_notes(value_only: true)
        varfield_search('x'.freeze, value_only: value_only)
      end

      # @param (see #barcodes)
      # @return [Array<String, Varfield>] record's public_notes data
      def public_notes(value_only: true)
        varfield_search('z'.freeze, value_only: value_only)
      end

      # Returns record's call number data.
      #
      # Subfield delimiters are stripped unless keep_delimiters: true
      #
      # @example data without delimiters
      #   item.callnos
      #   #=> ["PR6056.A82 S6"]
      #
      # @example data with delimiters
      #   item.callnos(keep_delimiters: true)
      #   #=> ["|aPR6056.A82 S6"]
      #
      # @example data as whole Varfields
      #   item.callnos(value_only: false)
      #   #=> [#<Sierra::Data::Varfield @values={:id=>114483,
      #         :record_id=>450972566081, ..., :field_content=>"|aPR6056.A82 S6"
      #       }>]
      #
      # @param [Boolean] keep_delimiters (default: false) retain subfield
      #   delimiters when returning data as strings?
      # @param [Boolean] value_only (default: true) whether to return data as
      #   strings of the field value/content? When false, returns data as entire
      #   Sierra::Data::Varfields
      # @return [Array<String, Varfield>] record's public_notes data
      def callnos(value_only: true, keep_delimiters: false)
        cns = varfield_search('c'.freeze, value_only: value_only)
        if value_only && !keep_delimiters
          cns&.map { |x| x.gsub(/\|./, '').strip }
        else
          cns
        end
      end

      def checked_out?
        !checkout.nil?
      end

      # @return [Time, nil] due_date if item is checked out
      def due_date
        return unless checked_out?

        checkout.due_gmt
      end

      # @todo deprecate? is this used somewhere external?
      def itype_code
        itype_code_num.to_s
      end

      # @return [String] itype description/name (e.g. "Book")
      def itype_desc
        itype.name
      end

      # @return [String] location description/name (e.g. "Davis Library")
      def location_desc
        location.name
      end

      # @return [String] item_status_code (e.g. "-")
      def status_code
        item_status_code
      end

      # @return [String] item status description/name (e.g. "Available")
      def status_desc
        status.name.capitalize
      end
    end
  end
end
