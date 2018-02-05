module MARC
  #Extend the MARC::Record class with some UNC-specific helpers
  class Record
    attr_reader :oclcnum

    def oclcnum
      @oclcnum ||= self.get_oclcnum
    end
    
    def get_oclcnum
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
        @oclcnum = oclc035s[0] unless oclc035s.empty?
      end
    end
    return @oclcnum
    end # def get_oclcnum
  end #class Record
  

  
end #module MARC
