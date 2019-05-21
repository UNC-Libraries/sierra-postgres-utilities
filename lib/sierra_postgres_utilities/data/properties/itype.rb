module Sierra
  module Data
    class Itype < Sequel::Model(DB.db[:itype_property])
      set_primary_key :id

      one_to_many :items, key: :itype_code_num, primary_key: :code_num

      def name
        @name ||= DB.db[:itype_property_name].
                  first(itype_property_id: @values[:id])[:name]
      end

      def self.list
        order(:code_num).to_a.map { |x| [x.code_num, x.name] }.to_h
      end

      def self.get(code)
        first(code_num: code)
      end
    end
  end
end
