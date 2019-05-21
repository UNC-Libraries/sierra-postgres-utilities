module Sierra
  module Data
    # Methods common to Sierra records (Bib, Item, etc. -- things reflected in
    # record_metadata.)
    module GenericRecord
      # @example
      #   #=> "#<Sierra::Data::Item i1000001a @values={:id=>450972566081, ...
      #        :is_available_at_library=>true}>"
      def inspect
        "#<#{self.class} #{rnum} @values=#{values}>"
      end

      # @example
      #   #=> "#<Sierra::Data::Item i1000001a>"
      def to_s
        "#<#{self.class} #{rnum}>"
      end

      #####################
      # @!group Record id/number formats
      # record_id       = 420907889860
      # rnum            = 'b1094852a'
      # rnum_trunc      = 'b1094852'
      # rnum_with_check = 'b10948521'
      # recnum          = '1094852'

      # @return [Bigint] id / record_id (e.g. 420907889860)
      def record_id
        id
      end

      # @return [String] rnum (e.g. 'b1094852a')
      def rnum
        @rnum ||= "#{record_type_code}#{record_num}a"
      end

      # @return [String] rnum without check digit (e.g. 'b1094852')
      def rnum_trunc
        rnum.chop
      end

      # @return [String] rnum with check digit (e.g. 'b10948521')
      def rnum_with_check
        rnum.chop + check_digit(recnum)
      end

      # @return [String] record_num (e.g. '1094852')
      def recnum
        record_num.to_s
      end

      # @!endgroup

      # @param [String] recnum record_num
      # @return [String] check digit for given recnum
      def check_digit(recnum)
        digits = recnum.split('').reverse
        y = 2
        sum = 0
        digits.each do |digit|
          sum += digit.to_i * y
          y += 1
        end
        remainder = sum % 11
        if remainder == 10
          'x'
        else
          remainder.to_s
        end
      end

      #####################

      def suppressed?
        is_suppressed
      end

      def deleted?
        return true if deletion_date_gmt
        false
      end

      # @return [String] record's record_type_code (e.g. "b", "i", etc.)
      def type
        record_type_code
      end

      # @return [Time] record's creation date
      def created_date
        creation_date_gmt
      end

      # @return [Time] record's updated date
      def updated_date
        record_last_updated_gmt
      end

      ######################
      # MARC fields and non-MARC varfields
      #######

      def varfield_search(tag_or_type, value_only: true)
        vfs =
          if tag_or_type =~ /\d{3}/
            varfields.select { |v| v.marc_tag == tag_or_type }
          else
            varfields.select { |v| v.varfield_type_code == tag_or_type }
          end
        return vfs.map(&:field_content) if value_only
        vfs
      end

      # @return [Hash<String, String>] mapping of vf codes to names for record's
      #   type
      # @example item varfield code=>types
      #   # Sierra::Data::Item.first.vf_codes
      #   #=> {..., "a"=>"DRA Item Field", "b"=>"Barcode", "c"=>"Call No.",
      #        "d"=>"DRA Created Date", "f"=>"Library", ... }
      def vf_codes
        Sierra::Data::VarfieldType.list(type)
      end

      ####

      # @param [String, Int] list_num review_file / list number
      # @return [Boolean] whether record is present in specified list
      def in_list?(list_num)
        create_lists.any? { |l| l.id == list_num.to_i }
      end
    end
  end
end
