module MARC
  #Extend the MARC::Controlfield class with some UNC-specific helpers
  class ControlField

    # Convert field to a mrk-type string
    # e.g. ControlField.new('001', 'ocm12345').to_mrk
    #   yields:         "=001  ocm12345"
    # produces string even if no subfield data is present (e.g. "=856  40")
    def to_mrk
      f = "=#{self.tag}  #{value}"
    end
  end
end