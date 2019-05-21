module Sierra
  module Data
    class PatronAddress < Sequel::Model(DB.db[:patron_record_address])
      set_primary_key :id

      many_to_one :patron, primary_key: :id, key: :patron_record_id
    end
  end
end
