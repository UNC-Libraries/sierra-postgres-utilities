module Sierra
  module Data
    class PatronFullname < Sequel::Model(DB.db[:patron_record_fullname])
      set_primary_key :id

      many_to_one :patron, primary_key: :id, key: :patron_record_id

      def full
        [first_name, middle_name, last_name, suffix].
          join(' ').
          gsub(/\s+/, ' ').
          strip
      end

      def full_reverse
        [last_name, first_name, middle_name, suffix].
          join(' ').
          gsub(/\s+/, ' ').
          strip
      end
    end
  end
end
