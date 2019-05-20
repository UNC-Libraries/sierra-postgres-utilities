module Sierra
  module Data
    class Permission < Sequel::Model(DB.db[:iii_user_permission_myuser])
      set_primary_key :id

      one_to_many :user, primary_key: :iii_user_id, key: :id
      many_to_many :users,
                   left_key: :permission_num, left_primary_key: :permission_num,
                   right_key: :iii_user_id, right_primary_key: :id,
                   join_table: :iii_user_permission_myuser

      def record
        @record ||= bib_record || item_record
      end

      # get a list of permissions (not a list of all user-permissions)
      def self.list
        distinct.
          order(:permission_num).
          to_a.
          map { |x| [x.permission_num, x.permission_name] }.
          to_h
      end

      def self.get(num)
        first(permission_num: num)
      end
    end
  end
end
