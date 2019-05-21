module Sierra
  module Data
    class ControlField < Sequel::Model(DB.db[:control_field])
      set_primary_key :id
      prepare_retrieval_by :record_id, :select,
                           sorting: %i[varfield_type_code occ_num id]

      many_to_one :record_metadata,
                  class: :'Sierra::Data::Metadata', primary_key: :id,
                  key: :record_id

      many_to_one :bib, primary_key: :id, key: :record_id
      many_to_one :item, primary_key: :id, key: :record_id
      many_to_one :authority, primary_key: :id, key: :record_id
      many_to_one :holdings,
                  class: :'Sierra::Data::Holdings', primary_key: :id,
                  key: :record_id
      many_to_one :order, primary_key: :id, key: :record_id
      many_to_one :patron, primary_key: :id, key: :record_id

      def record
        record_metadata.record
      end

      def to_s
        value = to_hash.select { |k, _| k[/p\d+/] }.
                values[0..39].
                map(&:to_s).
                join
        return value if control_num == 8
        return value[0..17] if control_num == 6
        return value.rstrip if control_num == 7
      end

      def to_marc
        MARC::ControlField.new("00#{control_num}", to_s)
      end
    end
  end
end
