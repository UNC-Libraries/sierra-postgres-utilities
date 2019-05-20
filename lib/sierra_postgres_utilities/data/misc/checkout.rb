module Sierra
  module Data
    class Checkout < Sequel::Model(DB.db[:checkout])
      set_primary_key :id

      one_to_one :item, key: :id, primary_key: :item_record_id
      one_to_one :patron, key: :id, primary_key: :patron_record_id
    end
  end
end
