module Sierra
  module Data
    class ItemRecordProperty < Sequel::Model(DB.db[:item_record_property])
      set_primary_key :id

      one_to_one :item, key: :id, primary_key: :item_record_id
    end
  end
end
