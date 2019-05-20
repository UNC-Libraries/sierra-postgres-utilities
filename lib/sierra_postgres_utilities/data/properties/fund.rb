module Sierra
  module Data
    class Fund < Sequel::Model(DB.db[:fund_master])
      set_primary_key :code_num

      def cmfs
        Sierra::Data::OrderCMF.where(fund_code: code_num.to_s.rjust(5, '0')).
          all.lazy.
          select { |cmf| cmf.accounting_unit_id == accounting_unit_id }
      end

      def orders
        cmfs.map(&:order)
      end
    end
  end
end
