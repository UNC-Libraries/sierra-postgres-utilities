module Sierra
  module Data
    class Hold < Sequel::Model(DB.db[:hold])
      set_primary_key :id

      many_to_one :record_metadata,
                  class: :'Sierra::Data::Metadata', primary_key: :id,
                  key: :record_id
      many_to_one :patron, primary_key: :id, key: :patron_record_id

      many_to_one :bib, primary_key: :id, key: :record_id
      many_to_one :item, primary_key: :id, key: :record_id

      def record
        record_metadata.record
      end

      def type
        Hold.type(record.type)
      end

      def status_desc
        Hold.status_desc(status)
      end

      def self.type(record_type)
        case record_type
        when 'b'
          'bib'
        when 'i'
          'item'
        end
      end

      def self.status_desc(status_code)
        case status_code
        when '0'
          'On hold.'
        when 'i', 'b', 'j'
          'Ready for pickup.'
        when 't'
          'In transit to pickup.'
        end
      end
    end
  end
end
