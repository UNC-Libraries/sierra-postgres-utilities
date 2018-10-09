module SierraPostgresUtilities
  module Views
    module Patron
      extend Views::MethodConstructor

      views = [
        {
          view: :patron_record,
          view_match: :id, obj_match: :record_id, require: :record_id,
          openstruct: true, entries: :first,
          require_fail_return: {}, if_empty: {}
        },
        {
          view: :patron_record_address,
          view_match: :patron_record_id,
          obj_match: :record_id, require: :record_id,
          openstruct: true, entries: :all, sort: :display_order
        },
        {
          view: :patron_record_fullname,
          view_match: :patron_record_id,
          obj_match: :record_id, require: :record_id,
          openstruct: true, entries: :all, sort: :display_order
        },
        {
          view: :patron_record_phone,
          view_match: :patron_record_id,
          obj_match: :record_id, require: :record_id,
          openstruct: true, entries: :all, sort: :display_order
        }
      ]

      views.each do |hsh|
        match_view(hsh)
        access_view(hsh)
      end
    end
  end
end
