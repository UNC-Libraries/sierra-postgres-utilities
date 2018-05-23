module MARC
  #Extend the MARC::Record class with some UNC-specific helpers

  XML_HEADER = <<~XML
    <?xml version='1.0'?>
    <collection xmlns='http://www.loc.gov/MARC21/slim' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xsi:schemaLocation='http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd'>
  XML
  XML_FOOTER = '</collection>'

  class Record
    attr_reader :oclcnum

    def oclcnum
      @oclcnum ||= self.get_oclcnum
    end
    
    def get_oclcnum
      @oclcnum = nil # prevents using previous value if re-deriving
      oclcnum_003s = ['', 'OCoLC', 'NhCcYBP']
      my001 = self['001'] ? self['001'].value : ''
      my003 = self['003'] ? self['003'].value : ''
      
      if my001 =~ /^\d+$/ && oclcnum_003s.include?(my003)
        @oclcnum = my001
      elsif my001 =~ /^(hsl|tmp)\d+$/ && oclcnum_003s.include?(my003)
        @oclcnum = my001.gsub('tmp', '').gsub('hsl', '')
      elsif my001 =~ /^\d+\D\w+$/i
        @oclcnum = my001.gsub(/^(\d+)\D\w+$/, '\1')
      else
        m035oclcnums = self.get_035oclcnums
        @oclcnum = m035oclcnums[0] if m035oclcnums
      end
      @oclcnum
    end # def get_oclcnum

    def get_035oclcnums
      m035oclcnums = nil
      my035s = self.find_all { |f| f.tag == '035'}
      unless my035s.empty?
        oclc035s = []
        my035s.each do |m035|
          oclc035s << m035.subfields.select { |sf| sf.code == 'a' and sf.value.match(/^\(OCoLC\)/) }
        end
        oclc035s.flatten!
        oclc035s.map! { |sf| sf.value.gsub(/\(OCoLC\)0*/,'') }
        oclc035s.reject! { |v| v.match(/^M-ESTCN/) }
        oclc035s.map! { |v| v.gsub(/ocn|ocm|on/, '') }
        m035oclcnums = oclc035s unless oclc035s.empty?
      end
      m035oclcnums
    end # def get_035oclcnums

    def no_leader?
      return true unless self.leader && !self.leader.empty?
    end

    def bad_leader_length?
      return nil if self.no_leader?
      return true if self.leader.length != 24
    end

    def ldr06_undefined?
      return nil if self.no_leader?
      return true if self.leader[6] !~ /a|[c-g]|[i-k]|m|o|p|r|t/
    end

    def ldr07_undefined?
      return nil if self.no_leader?
      return true if self.leader[7] !~ /[a-d]|i|m|s/
    end

    def bad_008_length?
      # true if any 008 length != 40
      # This check to make sure the 008 is 40 chars long. Afaik Sierra postgres
      # would store an 008 of just "a" and an 008 of "a      [...40 chars]"
      # exactly the same. We'd retrieve both as "a" followed by 39 spaces.
      # We're already checking for a valid language code in 008/35-37
      # and 008/38-39 don't need to be non-blank. So whether this check
      # has any added value seems questionable.
      my008s = self.find_all { |f| f.tag == '008' }
      return nil unless my008s
      my008s.reject! { |f| f.value.length == 40 }
      return true unless my008s.empty?
    end

    def no_245_has_ak?
      # returns nil if no 245s
      # returns true if 245(s) exist but none have 245$a or 245$k
      my245s = self.find_all { |f| f.tag == '245' }
      return nil if my245s.empty?
      # create array containing, for each 245 field, an array of its subfield codes
      # e.g. [ ['a', 'c'], ['a', 'b', 'c'], ['d'] ]
      my245s.map! { |f| f.subfields.map{ |s| s.code } }
      my245s.flatten!
      return nil if my245s.include?('a') || my245s.include?('k')
      return true
    end

    def count(tag)
      # counts number of fields for given marc tag
      fields = self.find_all { |f| f.tag == tag }
      return nil unless fields
      fields.length
    end

    def m300_without_a?
      my300s = self.find_all { |f| f.tag == '300' }
      return nil if my300s.empty?
      # create array containing, for each 300 field, an array of its subfield codes
      # e.g. [ ['a', 'c'], ['a', 'b', 'c'], ['d'] ]
      sf_codes = my300s.map { |f| f.subfields.map{ |s| s.code } }
      sf_codes.each do |arry|
        return true unless arry.include?('a')
      end
      return nil
    end

    def oclc_035_count
      m035oclcnums = self.get_035oclcnums
      return 0 unless m035oclcnums
      m035oclcnums.length
    end

    def m035_lacks_oclcnum?
      # true if 035 lacks sierra oclcnum (e.g. from 001, 035)
      # even if 035 has some other oclcnum
      return false unless self.oclcnum
      my035oclcnums = self.get_035oclcnums
      return true unless my035oclcnums
      return false if my035oclcnums.include?(@oclcnum)
      return true
    end

    # sorts marc record by tag
    # ordering of fields with the same tag is retained
    def sort
      sorter = self.to_hash
      sorter['fields'] = sorter['fields'].sort_by { |x| x.keys }
      MARC::Record.new_from_hash(sorter)
    end

  end #class Record
  

  
end #module MARC
