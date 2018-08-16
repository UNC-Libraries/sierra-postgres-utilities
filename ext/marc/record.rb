module MARC
  # Extend the MARC::Record class with some UNC-specific helpers

  XML_HEADER = <<~XML.freeze
    <?xml version='1.0'?>
    <collection xmlns='http://www.loc.gov/MARC21/slim' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xsi:schemaLocation='http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd'>
  XML
  XML_FOOTER = '</collection>'.freeze

  class Record
    attr_reader :oclcnum

    # lazy evaluated
    @lang_code_map = nil

    def to_mrk
      mrk = ''
      mrk += "=LDR  #{leader}\n" if leader
      fields.each do |f|
        mrk += "#{f.to_mrk}\n"
      end
      mrk
    end

    def oclcnum
      @oclcnum ||= get_oclcnum
    end

    def get_oclcnum
      @oclcnum = nil # prevents using previous value if re-deriving
      oclcnum_003s = ['', 'OCoLC', 'NhCcYBP']
      my001 = self['001']&.value&.strip.to_s
      my003 = self['003']&.value&.strip.to_s

      # if appropriate 003, try for digits with optional hsl/tmp prefix
      if oclcnum_003s.include?(my003)
        m = my001.match(/^(?:hsl|tmp)?(\d+)$/)
        if m
          return @oclcnum = m[1]
        end
      end

      # try for digits followed by alphanumeric suffix
      m = my001.match(/^(\d+)\D\w+$/)
      if m
        @oclcnum = m[1]
      else # look in the 035
        m035oclcnums = get_035oclcnums
        @oclcnum = m035oclcnums&.first
      end
      @oclcnum
    end # def get_oclcnum

    def get_035oclcnums
      m035oclcnums = nil
      oclc035s = fields('035').
                 map { |f| f.subfield_search(code: 'a', value: /^\(OCoLC\)/) }.
                 flatten.
                 map(&:value)
      return nil if oclc035s.empty?
      oclc035s.map! { |v| v.gsub(/\(OCoLC\)0*/, '') }
      oclc035s.reject! { |v| v.match(/^M-ESTCN/) }
      oclc035s.map! { |v| v.gsub(/ocn|ocm|on/, '') }
      oclc035s.reject! { |v| v == '' }
      m035oclcnums = oclc035s unless oclc035s.empty?
      m035oclcnums
    end # def get_035oclcnums

    def no_leader?
      return true unless leader && !leader.empty?
    end

    def bad_leader_length?
      return nil if no_leader?
      return true if leader.length != 24
    end

    # Is rec type missing or invalid?
    #   True when no/empty leader or when ldr06 is not an allowed code
    def ldr06_invalid?
      return true unless leader
      leader[6] !~ /[acdefgijkmoprt]/
    end

    # Is blvl missing or invalid?
    #   True when no/empty leader or when ldr07 is not an allowed code
    def ldr07_invalid?
      return true unless leader
      leader[7] !~ /[abcdims]/
    end

    def bad_008_length?
      # true if any 008 length != 40
      # This check to make sure the 008 is 40 chars long. Afaik Sierra postgres
      # would store an 008 of just "a" and an 008 of "a      [...40 chars]"
      # exactly the same. We'd retrieve both as "a" followed by 39 spaces.
      # We're already checking for a valid language code in 008/35-37
      # and 008/38-39 don't need to be non-blank. So whether this check
      # has any added value seems questionable.
      my008s = find_all { |f| f.tag == '008' }
      return nil unless my008s
      my008s.reject! { |f| f.value.length == 40 }
      return true unless my008s.empty?
    end

    # returns [008/35-37, full language name]
    # if invalid language code, returns [008/35-37, nil]
    # if no 008, returns nil
    # forbid_discontinued treats discontinued language codes
    #   as invalid
    def language_from_008(forbid_discontinued: false)
      code = self['008']&.value&.slice(35..37)
      return nil unless code
      language = self.class.lang_code_map[code]

      # try for a discontinued language code when needed and
      # allowed
      unless language || forbid_discontinued
        language = self.class.lang_code_map["-#{code}"]
      end

      [code, language]
    end

    # Sets lang_code_map once requested
    def self.lang_code_map
      @lang_code_map ||= YAML.load_file(
        File.join(__dir__, '../../data/marc_language_codes.yml')
      )
    end

    # true when no 245s or no 245 contains an $a or $k
    # false when >=1 245 has >=1 $a or $k
    def no_245_has_ak?
      no_fields?(tag: '245', complex_subfields: [[:has, code: /[ak]/]])
    end

    def count(tag)
      # counts number of fields for given marc tag
      fields = find_all { |f| f.tag == tag }
      return nil unless fields
      fields.length
    end

    # true if there is >=1 300 fields without a $a
    # false if there are no 300 fields, or every 300 has a $a
    def m300_without_a?
      any_fields?(tag: '300', complex_subfields: [[:has_no, code: 'a']])
    end

    def oclc_035_count
      m035oclcnums = get_035oclcnums
      return 0 unless m035oclcnums
      m035oclcnums.length
    end

    def m035_lacks_oclcnum?
      # true if 035 lacks sierra oclcnum (e.g. from 001, 035)
      # even if 035 has some other oclcnum
      return false unless oclcnum
      my035oclcnums = get_035oclcnums
      return true unless my035oclcnums
      return false if my035oclcnums.include?(@oclcnum)
      true
    end

    # sorts marc record by tag
    # ordering of fields with the same tag is retained
    def sort
      sorter = to_hash
      sorter['fields'] =
        sorter['fields'].sort_by.with_index { |f, idx| [f.keys, idx] }
      MARC::Record.new_from_hash(sorter)
    end

    # Filters fields based on criteria.
    # Returns empty array when no matches
    # When criteria is a string, properties must equal / not equal the string.
    # When criteria is a regexp, properties must match / not match the regexp.
    # For example:
    #   Select 500 fields (same as rec.fields('500') )
    #     field_search(tag: '500')
    #   Select 856s with ind1 != 4, where content includes "http"
    #    field_search(tag: '856', ind1_not: '4', content: /http/ )
    #
    # Complex_subfields uses the subfield_search in DataField extension and
    #   :has, :has_no, :has_one, :has_as_first parameters.
    # has some $a
    #   [:has, code: 'a'},
    # has no $b
    #   [:has_no, code: 'b'},
    # has only $b(s)
    #   [:has_no, code_not: 'b'},
    # has only sf_contents = 'not_useful'
    #   [:has_no, value_not: 'not_useful'},
    # has at least one $a or $k that matches /foo/
    #   [:has, code: /[ak]/, value: /foo/},
    # has at least one $a != bar
    #   [:has, code: 'a', value_not: 'bar'},
    # does not have any $a whose content is not foo
    #   [:has_no, code: 'a', value_not: 'foo'},
    # does not have any $b whose content is bar
    #   [:has_no, code: 'b', value: 'bar'},
    # has some non-$b subfield that equals foo
    #   [:has, code_not: 'b', value: 'foo'},
    # has some non$b-subfield whose content is not bar
    #   [:has, code_not: 'b', value_not: 'bar'},
    # has no non$b-subfields whose content is foo
    #   [:has_no, code_not: /b/, value: 'foo'},
    # has no non$b-subfields whose content is not bar
    #   [:has_no, code_not: /b/, value_not: 'bar'}
    #    245s with:
    #      >=1 $a containing foo
    #      >=1 subfield that isn't $c and does equal 'foo'
    #      0 $b that do not contain bar
    #      exactly 1 $h
    #    field_search(tag: '245', complex_subfields: [
    #                               [:has, code: 'a', value: /foo/],
    #                               [:has, code_not: 'c', value: 'foo']
    #                               [:has_no, code: 'b', value_not: /bar/],
    #                               [:has_one, code: 'h']
    #                             ])
    #
    # A simple subfield criteria mirroring the tag/ind1/etc. criteria
    # is not included because value as a field_search keyword refers to the
    # value of the entire field, and it seems easy to mistake
    #   field_search(subfield: 'a', value: /foo/)
    # for something that is looking for foo inside a $a when it would
    # be looking for a field with a subfield 'a' where the field's value
    # contained foo.
    #
    def field_find_all(**args)
      # if looking for a specific field, use built-in hash for initial filter,
      #   otherwise get all fields.
      fields_in_scope =
        if args[:tag].is_a?(String)
          fields(args[:tag]).dup
        else
          @fields.dup
        end
      fields_in_scope.select { |f| f.meets_criteria?(args) }
    end

    # Returns first field that matches criteria
    #   (see field_find_all for arguments)
    def field_find(**args)
      # if looking for a specific field, use built-in hash for initial filter,
      #   otherwise get all fields.
      fields_in_scope =
        if args[:tag].is_a?(String)
          fields(args[:tag]).dup
        else
          @fields.dup
        end
      fields_in_scope.each { |f| return f if f.meets_criteria?(args) }
      nil
    end

    def any_fields?(**args)
      !!field_find(args)
    end

    def one_field?(**args)
      field_find_all(args).count == 1
    end

    def no_fields?(**args)
      field_find(args).nil?
    end
  end # class Record
end # module MARC
