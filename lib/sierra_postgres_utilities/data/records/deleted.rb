module Sierra
  module Data
    # Used for deleted records in place of Sierra::Data::Bib, ::Item, etc.
    # Deleted records have access to data/methods available through
    # record_metadata but lack data/methods from their record_type class.
    module DeletedRecord
      # Error to raise when treating a DeletedRecord as if it were not deleted.
      class DeletedRecordError < StandardError
      end

      def deleted?
        true
      end

      # Raise DeletedRecordError when method is missing.
      #
      # We don't know whether it was a bib/item/other_record_type method
      # being called on this deleted record, but we want to warn especially
      # in case it was.
      def method_missing
        raise DeletedRecordError, "Deleted record #{record_type_code}" \
        "#{record_num} lacks methods associated with undeleted records."
      end

      def respond_to_missing?(*)
        true
      end
    end
  end
end
