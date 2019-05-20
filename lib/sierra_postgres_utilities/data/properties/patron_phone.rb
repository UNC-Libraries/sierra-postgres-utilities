module Sierra
  module Data
    class PatronPhone < Sequel::Model(DB.db[:patron_record_phone])
      set_primary_key :id

      many_to_one :patron, primary_key: :id, key: :patron_record_id
    end
  end
end
