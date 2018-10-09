module SierraPostgresUtilities
  module Views
    module Holdings
      extend Views::MethodConstructor

      views = [
        {
          view: :bib_record_holding_record_link,
          view_match: :holding_record_id,
          obj_match: :record_id, require: :record_id,
          openstruct: true, entries: :first
        },
        {
          view: :holding_record,
          view_match: :id, obj_match: :record_id, require: :record_id,
          openstruct: true, entries: :first,
          require_fail_return: {}, if_empty: {}
        },
        {
          view: :holding_record_item_record_link,
          view_match: :holding_record_id,
          obj_match: :record_id, require: :record_id,
          openstruct: true, entries: :all, sort: :items_display_order
        },
        {
          view: :holding_view,
          view_match: :id, obj_match: :record_id, require: :record_id,
          openstruct: true, entries: :first
        },
      ]

      views.each do |hsh|
        match_view(hsh)
        access_view(hsh)
      end
    end
  end
end
