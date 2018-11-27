module SierraPostgresUtilities
  module Views


    # Retrieves general views( as in the whole tables, not just entries in the
    # context of a particular record)
    module General
      extend Views::MethodConstructor


      # We can define views here, but the only thing it adds is sorting
      # (which is of questionable value). Undefined views will still be
      # made available.
      DEFINED_VIEWS = [
        {view: :agency_property_myuser, sort: :display_order},
        {view: :bib_level_property_myuser, sort: :display_order},
        {view: :hold, sort: :id},
        {view: :item_status_property_myuser, sort: :display_order},
        {view: :itype_property_myuser, sort: :display_order},
        {view: :location_myuser, sort: :display_order},
        {view: :ptype_property_myuser, sort: :display_order}
      ]

      # For large views we don't want to grab in their entirety, we define
      # them here to get enumerators that read a chunk of the view at a time.
      # Sorting matters for these views because the chunks are retrieved
      # using offsets. We default sort everything by id unless otherwise
      # defined, and only the subfield views lack is columns and need sorting
      # specified here.
      STREAMED_VIEWS = {
        authority_record: nil,
        authority_view: nil,
        bib_record: nil,
        bib_record_call_number_prefix: nil,
        bib_record_holding_record_link: nil,
        bib_record_item_record_link: nil,
        bib_record_location: nil,
        bib_record_order_record_link: nil,
        bib_record_property: nil,
        bib_record_volume_record_link: nil,
        bib_view: nil,
        bool_set: nil,
        control_field: nil,
        holding_record: nil,
        holding_record_box: nil,
        holding_record_item_record_link: nil,
        holding_record_location: nil,
        holding_view: nil,
        invoice_record: nil,
        invoice_record_line: nil,
        invoice_record_vendor_summary: nil,
        invoice_view: nil,
        item_record: nil,
        item_record_property: nil,
        item_view: nil,
        leader_field: nil,
        order_record: nil,
        order_record_cmf: nil,
        order_record_paid: nil,
        order_view: nil,
        patron_record: nil,
        patron_record_address: nil,
        patron_record_fullname: nil,
        patron_record_phone: nil,
        patron_view: nil,
        phrase_entry: nil,
        reading_history: nil,
        record_metadata: nil,
        subfield: {sort: [:record_id, :varfield_id]},
        subfield_view: {sort: [:record_id, :varfield_id]},
        varfield: nil,
        varfield_view: nil,
        volume_record: nil,
        volume_record_item_record_link: nil,
        volume_view: nil,
      }

      # Create methods for any of the explicitly DEFINED_VIEWS
      # Methods for other views will be created on demand.
      DEFINED_VIEWS.each do |hsh|
        read_view(hsh)
        access_view(hsh)
      end

      # Defines methods to read/access views that don't already have methods.
      def method_missing(m, *args, &block)
        if STREAMED_VIEWS.has_key?(m)
          hsh = {view: m}
          hsh.merge!(STREAMED_VIEWS[m]) if STREAMED_VIEWS[m]
          Views::General.stream_view(hsh)
          return self.send(m.to_sym)
        elsif views.include?(m)
          hsh = {view: m}
          Views::General.read_view(hsh)
          Views::General.access_view(hsh)
          return self.send(m.to_sym)
        else
          raise NoMethodError, "undefined method '#{m}'"
        end
      end

      def respond_to?(method_name, include_private = false)
        @views.include?(method_name.to_sym) || super
      end

      def views
        @views ||= get_db_views
      end

      # Returns array of symbolized table/view names in sierra_view
      # Excludes views we've already defined or excluded
      def get_db_views
        query = <<~SQL
          select table_name
          from information_schema.views
          where table_schema = 'sierra_view'
        SQL
        SierraDB.make_query(query)
        SierraDB.results.values.flatten.map { |x| x.to_sym }.sort
      end

      # refreshes a cached view that has presumably already had a method defined
      def refresh_view(name)
        self.instance_variable_set("@#{name}", self.send("read_#{name}"))
      end
    end
  end
end
