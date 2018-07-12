module MARC
  # Extend the MARC::Controlfield class with some UNC-specific helpers
  class ControlField

    # Convert field to a mrk-type string
    # e.g. ControlField.new('001', 'ocm12345').to_mrk
    #   yields:         "=001  ocm12345"
    # produces string even if no subfield data is present (e.g. "=856  40")
    def to_mrk
      "=#{tag}  #{value}"
    end

    # Returns Sierra style content string.
    # It's less silly than this for DataFields, but useful to also define
    #   here so we can call field_content on any field.
    def field_content
      value
    end

    def meets_criteria?(tag: nil, ind1: nil, ind2: nil, value: nil,
                        tag_not: nil, ind1_not: nil, ind2_not: nil,
                        value_not: nil, complex_subfields: [])
      # control fields cannot meet indicator criteria
      return false if ind1 || ind2

      positives = {tag: tag, value: value}
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
      negatives = {tag: tag_not, value: value_not}
      negatives.each do |method, criteria|
        next unless criteria
        if criteria.is_a?(String)
          return false if self.send(method) == criteria
        elsif criteria.is_a?(Regexp)
          return false if self.send(method) =~ criteria
        end
      end

      complex_subfields.each do |rule|
        unless rule.is_a?(Array)
          raise 'complex_subfields should be an array of arrays.'
        end
        type, _hsh = rule

        # control fields never have subfields
        return false unless type == :has_no
      end
      true
    end
  end
end
