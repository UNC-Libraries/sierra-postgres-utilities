module Sierra
  module Data
    class OrderCMF < Sequel::Model(DB.db[:order_record_cmf])
      set_primary_key :id

      many_to_one :order, primary_key: :record_id, key: :order_record_id
      one_to_one :location, key: :code, primary_key: :location_code

      def fund
        Sierra::Data::Fund.first(code_num: fund_code,
                                 accounting_unit_id: accounting_unit_id)
      end

      def accounting_unit_id
        DB.db[:accounting_unit].
          first(code_num: order.accounting_unit_code_num)[:id]
      end
    end
  end
end
