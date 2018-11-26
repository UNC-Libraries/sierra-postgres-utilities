module SierraPostgresUtilities
  module Views
    module Authority
      extend Views::MethodConstructor

      views = [
        {
          view: :authority_record,
          view_match: :id, obj_match: :record_id,
          entries: :first
        },
        {
          view: :authority_view,
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
