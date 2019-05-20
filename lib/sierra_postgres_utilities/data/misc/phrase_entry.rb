module Sierra
  module Data
    class PhraseEntry < Sequel::Model(DB.db[:phrase_entry])
      set_primary_key :id

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
