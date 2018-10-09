module SierraPostgresUtilities
  module Views


    # Retrieves general views, the whole tables, not just entries related to
    # a particular record
    module General
      extend Views::MethodConstructor

      # we can define views here, but the only thing it adds is sorting
      # (which is of questionable value)
      DEFINED_VIEWS = [
        {view: :agency_property_myuser, openstruct: true, sort: :display_order},
        {view: :bib_level_property_myuser, openstruct: true, sort: :display_order},
        {view: :hold, openstruct: true, sort: :id},
        {view: :item_status_property_myuser, openstruct: true,
        sort: :display_order},
        {view: :itype_property_myuser, openstruct: true, sort: :display_order},
        {view: :location_myuser, openstruct: true, sort: :display_order},
        {view: :ptype_property_myuser, openstruct: true, sort: :display_order}
      ]

      # views we don't want to be able to read (in entirety), generally because
      # they are big
      EXCLUDED_VIEWS = [
        :authority_record,
        :authority_view,
        :bib_record,
        :bib_record_call_number_prefix,
        :bib_record_holding_record_link,
        :bib_record_item_record_link,
        :bib_record_location,
        :bib_record_order_record_link,
        :bib_record_property,
        :bib_record_volume_record_link,
        :bib_view,
        :bool_set,
        :control_field,
        :holding_record,
        :holding_record_box,
        :holding_record_item_record_link,
        :holding_record_location,
        :holding_view,
        :invoice_record,
        :invoice_record_line,
        :invoice_record_vendor_summary,
        :invoice_view,
        :item_record,
        :item_record_property,
        :item_view,
        :leader_field,
        :order_record,
        :order_record_cmf,
        :order_record_paid,
        :order_view,
        :patron_record,
        :patron_record_address,
        :patron_record_fullname,
        :patron_record_phone,
        :patron_view,
        :phrase_entry,
        :reading_history,
        :record_metadata,
        :subfield,
        :subfield_view,
        :varfield,
        :varfield_view,
        :volume_record,
        :volume_record_item_record_link,
        :volume_view
      ]

      # Create methods for any of the explicitly DEFINED_VIEWS
      DEFINED_VIEWS.each do |hsh|
        read_view(hsh)
        access_view(hsh)
      end

      def views
        @views ||= get_db_views
      end

      # Defines methods to read/access views that don't already have methods.
      def method_missing(m, *args, &block)
        if views.include?(m)
          hsh = {view: m, openstruct: true}
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

      # Returns hash of symbolized table/view names in sierra_view
      # Excludes views we've already defined or excluded
      def get_db_views
        query = <<~SQL
          select table_name
          from information_schema.views
          where table_schema = 'sierra_view'
        SQL
        SierraDB.make_query(query)
        views = SierraDB.results.values.flatten.map { |x| x.to_sym }
        views -= EXCLUDED_VIEWS
        views -= DEFINED_VIEWS.map { |x| x[:view] }
        views.sort
      end
    end
  end
end
