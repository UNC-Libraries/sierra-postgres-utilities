module Sierra
  module Data
    class Ptype < Sequel::Model(DB.db[:ptype_property])
      set_primary_key :id

      one_to_many :patrons, key: :ptype_code_num, primary_key: :code_num

      alias code_num id

      def name
        @name ||= DB.db[:ptype_property_name].
                  first(ptype_id: @values[:id])[:description]
      end

      def self.list
        order(:id).to_a.map { |x| [x.id, x.name] }.to_h
      end

      def self.get(ptype)
        first(id: ptype)
      end
    end
  end
end
