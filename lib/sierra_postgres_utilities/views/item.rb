
module SierraPostgresUtilities
  module Views
    module Item
      extend Views::MethodConstructor

      views = [
        {
          view: :bib_record_item_record_link,
          view_match: :item_record_id, obj_match: :record_id,
          entries: :all, sort: :bibs_display_order
        },
        {
          view: :checkout,
          view_match: :item_record_id, obj_match: :record_id,
          entries: :first
        },
        {
          view: :hold,
          view_match: :record_id, obj_match: :record_id,
          entries: :all, sort: :records_display_order
        },
        {
          view: :holding_record_item_record_link,
          view_match: :item_record_id, obj_match: :record_id,
          entries: :all, sort: :holdings_display_order
        },
        {
          view: :item_record,
          view_match: :id, obj_match: :record_id,
          entries: :first
        },
        {
          view: :item_record_property,
          view_match: :item_record_id, obj_match: :record_id,
          entries: :first
        },
        {
          view: :item_view,
          view_match: :id, obj_match: :record_id,
          entries: :first
        },
      ]

      views.each do |hsh|
        match_view(hsh)
        access_view(hsh)
      end
    end
  end
end
