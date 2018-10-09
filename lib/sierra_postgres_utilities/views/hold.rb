module SierraPostgresUtilities
  module Views
    module Hold
      extend Views::MethodConstructor

      views = [
        {
          view: :hold,
          view_match: :id, obj_match: :id, require: :id,
          openstruct: true, entries: :first
        }
      ]

      views.each do |hsh|
        match_view(hsh)
        access_view(hsh)
      end
    end
  end
end
