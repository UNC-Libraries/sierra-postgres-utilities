module SierraPostgresUtilities
  module Views
    module Bib
      extend Views::MethodConstructor

      views = [
        {
          view: :bib_record,
          view_match: :id, obj_match: :record_id,
          entries: :first
        },
        {
          view: :bib_record_call_number_prefix,
          view_match: :bib_record_id, obj_match: :record_id,
          entries: :first
        },
        {
          view: :bib_record_holding_record_link,
          view_match: :bib_record_id, obj_match: :record_id,
          entries: :all, sort: :holdings_display_order
        },
        {
          view: :bib_record_item_record_link,
          view_match: :bib_record_id, obj_match: :record_id,
          entries: :all, sort: :items_display_order
        },
        {
          view: :bib_record_location,
          view_match: :bib_record_id, obj_match: :record_id,
          entries: :all, sort: :display_order
        },
        {
          view: :bib_record_order_record_link,
          view_match: :bib_record_id, obj_match: :record_id,
          entries: :all, sort: :orders_display_order
        },
        {
          view: :bib_record_property,
          view_match: :bib_record_id, obj_match: :record_id,
          entries: :first
        },
        {
          view: :bib_record_volume_record_link,
          view_match: :bib_record_id, obj_match: :record_id,
          entries: :all, sort: :volumes_display_order
        },
        {
          view: :bib_view,
          view_match: :id, obj_match: :record_id,
          entries: :first
        },
        {
          view: :control_field,
          view_match: :record_id, obj_match: :record_id,
          entries: :all,
          sort: %i[varfield_type_code occ_num id]
        },
        {
          view: :leader_field,
          view_match: :record_id, obj_match: :record_id,
          # No bibs had >1 leader in oct 2018. Make an assumption it's not
          # possible.
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
