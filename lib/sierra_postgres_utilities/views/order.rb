module SierraPostgresUtilities
  module Views
    module Order
      extend Views::MethodConstructor

      views = [
        {
          view: :bib_record_order_record_link,
          view_match: :order_record_id, obj_match: :record_id,
          entries: :first
        },
        {
          view: :order_record,
          view_match: :id, obj_match: :record_id,
          entries: :first
        },
        {
          view: :order_record_cmf,
          view_match: :order_record_id, obj_match: :record_id,
          entries: :all, sort: :display_order
        },
        {
          view: :order_view,
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
