module Sierra
  module Data
    class ItemStatus < Sequel::Model(DB.db[:item_status_property])
      set_primary_key :id

      one_to_many :items, key: :item_status_code, primary_key: :code

      def name
        @name ||= DB.db[:item_status_property_name].
                  first(item_status_property_id: @values[:id])[:name]
      end

      def self.list
        order(:code).to_a.map { |x| [x.code, x.name] }.to_h
      end

      def self.get(code)
        first(code: code)
      end
    end
  end
end
