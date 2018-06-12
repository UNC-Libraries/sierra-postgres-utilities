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
      if self.indicator1 == ' '
        ind1 = '\\'
      else
        ind1 = self.indicator1
      end
      if self.indicator2 == ' '
        ind2 = '\\'
      else
        ind2 = self.indicator2
      end
      f = "=#{self.tag}  #{ind1}#{ind2}"
      self.subfields.each do |sf|
        f += "#{delimiter}#{sf.code}#{sf.value}"
      end
      f
    end
  end
end