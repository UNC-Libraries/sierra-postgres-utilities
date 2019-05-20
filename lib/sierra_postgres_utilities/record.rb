module Sierra
  module Record
    # Error returned when trying to retrieve a record that does not exist amd
    # has never existed.
    class InvalidRecord < StandardError
    end

    module Factory
      # Retrieve a record by rnum or id.
      #
      # @param [String] rnum (e.g. "b7120490a", "i1096023a")
      #   - The leading rec_type letter must be present.
      #   - The check digit must be removed.
      #   - The trailing "a" is technically optional.
      # @param [String, Bignum] id optionally fetch by Sierra record id
      #   (e.g. 420908165017)
      # @raise [Sierra::Record::InvalidRecord] if there is no matching record.
      def get(rnum = nil, id: nil)
        Factory.get(rnum: rnum, id: id)
      end

      # Standardizes rnum
      #
      # Strips leading/trailing whitespace; ensures trailing "a".
      #
      # @param [String] rnum
      # @return [String] standardized form of rnum (e.g. "b7120490a")
      def self.standardize_rnum(rnum)
        rnum = rnum.dup
        rnum.strip!
        unless rnum =~ /^[abciop][0-9]+a?$/
          raise InvalidRecord, "There is no record matching rnum: #{rnum}"
        end
        rnum << 'a' unless rnum.end_with?('a')
        rnum
      end

      # (see Sierra::Record.get)
      def self.get(rnum:, id:)
        if rnum
          rnum = standardize_rnum(rnum)
          rec =
            case rnum.chr
            when 'b'
              Sierra::Data::Bib.by_record_num(record_num: rnum[1..-2])
            when 'i'
              Sierra::Data::Item.by_record_num(record_num: rnum[1..-2])
            when 'c'
              Sierra::Data::Holdings.by_record_num(record_num: rnum[1..-2])
            when 'o'
              Sierra::Data::Order.by_record_num(record_num: rnum[1..-2])
            when 'a'
              Sierra::Data::Authority.by_record_num(record_num: rnum[1..-2])
            when 'p'
              Sierra::Data::Patron.by_record_num(record_num: rnum[1..-2])
            end
          (rec ||
           # If rec is nil at this point, we still need to make sure
           # it's not a deleted record or a record type not included
           # in the case statement.
           Sierra::Data::Metadata.first(record_type_code: rnum.chr,
                                        record_num: rnum[1..-2])&.record ||
           (raise InvalidRecord, "There is no record matching rnum: #{rnum}"))
        elsif id
          Sierra::Data::Metadata.by_id(id: id)&.record ||
            (raise InvalidRecord, "There is no record matching id: #{id}")
        end
      end
    end

    extend Factory
  end
end
