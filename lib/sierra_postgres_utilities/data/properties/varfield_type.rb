module Sierra
  module Data
    class VarfieldType < Sequel::Model(DB.db[:varfield_type])
      set_primary_key :id

      # TODO: associate?

      def name
        @name ||= DB.db[:varfield_type_name].
                  first(varfield_type_id: @values[:id])[:name]
      end

      def short_name
        @short_name ||= DB.db[:varfield_type_name].
                        first(varfield_type_id: @values[:id])[:short_name]
      end

      def self.list(record_type_code)
        where(record_type_code: record_type_code).
          order(:code).to_a.
          map { |x| [x.code, x.name] }.
          to_h
      end
    end
  end
end
