module Sierra
  module Data
    class CircTrans < Sequel::Model(DB.db[:circ_trans])
      set_primary_key :id

      one_to_one :bib, key: :id, primary_key: :bib_record_id
      one_to_one :item, key: :id, primary_key: :item_record_id

      one_to_one :patron, key: :id, primary_key: :patron_record_id
    end
  end
end
