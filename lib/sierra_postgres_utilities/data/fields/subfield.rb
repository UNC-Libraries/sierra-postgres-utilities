module Sierra
  module Data
    class Subfield < Sequel::Model(DB.db[:subfield])
      set_primary_key :id

      many_to_one :varfield, primary_key: :id, key: :varfield_id
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
    end
  end
end
