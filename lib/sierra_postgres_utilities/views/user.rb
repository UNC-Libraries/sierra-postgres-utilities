module SierraPostgresUtilities
  module Views
    module User
      extend Views::MethodConstructor

      views = [
        {
          view: :iii_user,
          view_match: :name, obj_match: :login,
          entries: :first, cast: :text
        },
        {
          view: :iii_user_permission_myuser,
          view_match: :iii_user_id, obj_match: :id,
          entries: :all, sort: :permission_num
        },
        {
          view: :iii_user_workflow,
          view_match: :iii_user_id, obj_match: :id,
          entries: :all, sort: :display_order
        },
        {
          view: :statistic_group_myuser,
          view_match: :code, obj_match: :statistic_group_code_num,
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
