module Sierra
  module Data
    class Location < Sequel::Model(DB.db[:location])
      set_primary_key :id

      one_to_many :items, key: :location_code, primary_key: :code
      many_to_many :bibs,
                   left_primary_key: :code, left_key: :location_code,
                   right_key: :bib_record_id, right_primary_key: :id,
                   join_table: :bib_record_location

      def name
        @name ||= DB.db[:location_name].first(location_id: @values[:id])[:name]
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
