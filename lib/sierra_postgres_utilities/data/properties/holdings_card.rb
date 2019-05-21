module Sierra
  module Data
    class HoldingsCard < Sequel::Model(DB.db[:holding_record_card])
      set_primary_key :id

      many_to_one :holdings,
                  class: :'Sierra::Data::Holdings', primary_key: :id,
                  key: :holding_record_id
    end
  end
end
