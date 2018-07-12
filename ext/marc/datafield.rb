module MARC
  #Extend the MARC::Datafield class with some UNC-specific helpers
  class DataField

    def add_subfields!(sf_tag, new_data)
      # add a string or array of string to datafield as subfields
      #
      return unless new_data
      new_data = [new_data] unless new_data.is_a?(Array)
      new_data.each do |sf_data|
        next unless sf_data
        sf = MARC::Subfield.new(sf_tag, sf_data )
        self.append(sf)
      end
      self
    end

    # Convert field to a mrk-type string
    # e.g. DataField.new('856', '4', '0', ['u', 'http://example.com']).to_mrk
    #   yields:         "=856  40$uhttp://example.com"
    # uses dollar sign subfield delimiter (MarcEdit-style)
    # uses backslash characters for blank indicators
    # produces string even if no subfield data is present (e.g. "=856  40")
    def to_mrk(delimiter: '$')
      ind1 =
        if indicator1 == ' '
          '\\'
        else
          indicator1
        end
      ind2 =
        if indicator2 == ' '
          '\\'
        else
          indicator2
        end
      f = "=#{tag}  #{ind1}#{ind2}"
      subfields.each do |sf|
        f += "#{delimiter}#{sf.code}#{sf.value}"
      end
      f
    end

    # Yield sierra-style field content (including subfield codes and pipe delimiters)
    # e.g. DataField.new('856', '4', '0', ['u', 'http://example.com']).field_content
    #   yields:         "|uhttp://example.com"
    def field_content
      f = ''
      subfields.each do |sf|
        f += "|#{sf.code}#{sf.value}"
      end
      f
    end

    # Filters subfields based on subfield code/value criteria.
    # Returns subfields that equal / dont' equal
    #   strings, or match / don't match regexps
    # For example:
    #   Select $a's
    #     subfield_search(code: 'a')
    #   Select $a's that match /content/
    #    subfield_search(code: 'a', value: /content/)
    #   Select $a's and $b's that do not equal 'content'
    #    subfield_search(code: /[ab]/, value_not: 'content')
    #
    # If only_first_of_each_code is true, we immediately keep only the first
    # instance of each repeated subfield. This supports searching for fields
    # where the first $a matches a criteria. So:
    #   subfield_search(code: 'a', value: /foo/, only_first_of_each_code: true)
    #   TRUE for "|afoo|bbar|abar"
    #   FALSE for "|abar|bbar|afoo"
    #
    # Note that subfield_search(code: /[ak]/, value: /foo/,
    #                           only_first_of_each_code: true)
    # would be TRUE for "|abar|kfoo" It's not searching the first subfield
    # of _any_ matching subfield code, it's searching the first subfield of
    # _each_ matching subfield code
    #
    #
    def subfield_search(code: nil, value: nil, code_not: nil, value_not: nil,
                        only_first_of_each_code: false)
      # when only_first_of_each_code, drop non-first instances of repeated
      # subfields
      if only_first_of_each_code
        subfields = []
        codes.each do |sf_code|
          subfields << self.subfields.find { |sf| sf.code == sf_code }
        end
      else
        subfields = @subfields.dup
      end

      # retain candidates matching positive criteria
      {code: code, value: value}.each do |method, criteria|
        next unless criteria
        if criteria.is_a?(String)
          subfields.select! { |f| f.send(method) == criteria }
        elsif criteria.is_a?(Regexp)
          subfields.select! { |f| f.send(method) =~ criteria }
        end
      end

      # remove candidates matching negative criteria
      {code: code_not, value: value_not}.each do |method, criteria|
        next unless criteria
        if criteria.is_a?(String)
          subfields.reject! { |f| f.send(method) == criteria }
        elsif criteria.is_a?(Regexp)
          subfields.reject! { |f| f.send(method) =~ criteria }
        end
      end

      subfields
    end

    # Returns boolean for whether search returns >0 results
    def any_subfields?(**args)
      self.subfield_search(args).any?
    end

    # Returns boolean for whether search returns 0 results
    def no_subfields?(**args)
      !any_subfields(args)
    end

    # Returns boolean for whether search returns 1 result
    def one_subfield?(**args)
      self.subfield_search(args).count == 1
    end

    # True when the first subfield a contains foo
    #   first_such_subfield_matches?(code: 'a', content: /foo/)
    # True when the first subfield a or first subfield k contains foo
    #   first_such_subfield_matches?(code: /[ak]/, content: /foo/)
    def any_subfields_ignore_repeated?(**args)
      args[:only_first_of_each_code] = true
      self.subfield_search(args).any?
    end

    def meets_criteria?(tag: nil, ind1: nil, ind2: nil, value: nil,
                        tag_not: nil, ind1_not: nil, ind2_not: nil,
                        value_not: nil, complex_subfields: [])
      # retain candidates matching positive criteria
      positives = {tag: tag, indicator1: ind1, indicator2: ind2, value: value}
      positives.each do |method, criteria|
        next unless criteria
        if criteria.is_a?(String)
          return false unless self.send(method) == criteria
        elsif criteria.is_a?(Regexp)
          return false unless self.send(method) =~ criteria
        end
      end

      # ignore negative indicator criteria since control fields will always
      #   meet them
      negatives = {tag: tag_not, indicator1: ind1_not, indicator2: ind2_not,
                   value: value_not}
      negatives.each do |method, criteria|
        next unless criteria
        if criteria.is_a?(String)
          return false if self.send(method) == criteria
        elsif criteria.is_a?(Regexp)
          return false if self.send(method) =~ criteria
        end
      end

      # remove candidates according to complex subfield criteria
      complex_subfields.each do |rule|
        unless rule.is_a?(Array)
          raise "complex_subfields should be an array of arrays."
        end
        type, hsh = rule
        case type
        when :has
          return false unless any_subfields?(hsh)
        when :has_no
          return false if any_subfields?(hsh)
        when :has_one
          return false unless one_subfield?(hsh)
        when :has_as_first # a matching field must be first of its sf code
          return false unless any_subfields_ignore_repeated?(hsh)
        end
      end

      true
    end
  end
end
