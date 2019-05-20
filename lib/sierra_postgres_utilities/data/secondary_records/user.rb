module Sierra
  module Data
    class User < Sequel::Model(DB.db[:iii_user])
      set_primary_key :id

      one_to_many :permissions,
                  class: :'Sierra::Data::Permission', key: :iii_user_id,
                  primary_key: :id

      def record
        @record ||= bib_record || item_record
      end

      def pretty_permissions
        puts permissions.
          sort_by(&:permission_num).
          map { |p| "#{p.permission_num}\t#{p.permission_name}" }.
          join("\n")
      end

      def self.get(login)
        Sierra::Data::User.first(name: login)
      end
    end
  end
end
