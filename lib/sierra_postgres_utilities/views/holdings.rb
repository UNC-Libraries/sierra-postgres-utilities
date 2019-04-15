module SierraPostgresUtilities
  module Views
    module Holdings
      extend Views::MethodConstructor

      views = [
        {
          view: :bib_record_holding_record_link,
          view_match: :holding_record_id, obj_match: :record_id,
          entries: :first
        },
        {
          view: :holding_record,
          view_match: :id, obj_match: :record_id,
          entries: :first
        },
        {
          view: :holding_record_card,
          view_match: :holding_record_id, obj_match: :record_id,
          entries: :all, sort: :id
        },
        {
          view: :holding_record_location,
          view_match: :holding_record_id, obj_match: :record_id,
          entries: :all, sort: :display_order
        },
        {
          view: :holding_record_item_record_link,
          view_match: :holding_record_id, obj_match: :record_id,
          entries: :all, sort: :items_display_order
        },
        {
          view: :holding_view,
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
