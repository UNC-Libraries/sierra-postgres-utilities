require_relative '../records/metadata.rb'

module Sierra
  module Data
    class CreateList < Sequel::Model(DB.db[:bool_info])
      set_primary_key :id

      many_to_many :record_metadatas,
                   class: :'Sierra::Data::Metadata', left_key: :bool_info_id,
                   right_key: :record_metadata_id, join_table: :bool_set

      def records
        record_metadatas.lazy.map(&:record)
      end

      def empty?
        count.zero?
      end

      def self.get(num)
        first(id: num)
      end
    end

    BoolInfo = CreateList
  end
end
