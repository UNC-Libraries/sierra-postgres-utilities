require 'marc'
require_relative '../../../ext/marc/record'

def stub_builder(_001, _003, _035s)
  rec = MARC::Record.new
  rec << MARC::ControlField.new('001', _001) if _001
  rec << MARC::ControlField.new('003', _003) if _003
  _035s.each { |v|  rec << MARC::DataField.new('035', ' ', ' ', ['a', v]) } if _035s
  rec
end

RSpec.describe MARC::Record do
  describe 'get_oclcnum' do
    it 'returns oclc_number when 001 is digits only and there is no 003' do
      r = stub_builder('123', '', [])
      expect(r.get_oclcnum).to eq('123')
    end

    it 'sets oclc_number when 001 is digits only and 003 = OCoLC' do
      r = stub_builder('123', 'OCoLC', [])
      expect(r.get_oclcnum).to eq('123')
    end

    it 'does NOT set oclc_number when 001 is digits only and 003 = ItFiC' do
      r = stub_builder('123', 'ItFiC', [])
      expect(r.get_oclcnum).to eq(nil)
    end

    it 'sets oclc_number from 035 with (OCoLC) when not set from 001' do
      r = stub_builder('123', 'ItFiC', ['(OCoLC)567'])
      expect(r.get_oclcnum).to eq('567')
    end

    it 'does NOT set oclc_number when 001 is digits only and 003 = DLC' do
      r = stub_builder('123', 'DLC', [])
      expect(r.get_oclcnum).to eq(nil)
    end

    it 'strips leading zero(s) from oclc_number set from 035' do
      r = stub_builder('123', 'ItFiC', ['(OCoLC)000000567'])
      expect(r.get_oclcnum).to eq('567')
    end

    it 'sets oclc_number when 001 is digits only and 003 = NhCcYBP' do
      r = stub_builder('123', 'NhCcYBP', [])
      expect(r.get_oclcnum).to eq('123')
    end

    it 'sets oclc_number when 001 has prefix tmp and 003 = OCoLC' do
      r = stub_builder('tmp123', 'OCoLC', [])
      expect(r.get_oclcnum).to eq('123')
    end

    it 'sets oclc_number when 001 is digits with alphanum suffix' do
      r = stub_builder('123wcmSPR99', '', [])
      expect(r.get_oclcnum).to eq('123')
    end

    it 'does NOT set oclc_number when 001 has prefix M-ESTCN and 003 = OCoLC with prefixed 035' do
      r = stub_builder('M-ESTCN123', 'OCoLC', ['(OCoLC)M-ESTCN987'])
      expect(r.get_oclcnum).to eq(nil)
    end

    it 'sets oclc_number from 035 when it starts with ocm' do
      r = stub_builder('M-ESTCN123', 'OCoLC', ['(OCoLC)M-ESTCN987', '(OCoLC)ocm444'])
      expect(r.get_oclcnum).to eq('444')
    end

    it 'does NOT set oclc_number when 001 has prefix moml and 003 = OCoLC' do
      r = stub_builder('moml123', 'OCoLC', [])
      expect(r.get_oclcnum).to eq(nil)
    end

    it 'sets oclc_number when 001 has hsl prefix and 003 = OCoLC' do
      r = stub_builder('hsl123', 'OCoLC', [])
      expect(r.get_oclcnum).to eq('123')
    end

    it 'does NOT set oclc_number when 001 has WHO prefix and 003 = OCoLC' do
      r = stub_builder('WHO123', 'OCoLC', [])
      expect(r.get_oclcnum).to eq(nil)
    end
  end
  
describe 'oclcnum' do
    it 'sets MARC::Record oclcnum instance attribute when OCLC Number present' do
      r = stub_builder('123', '', [])
      expect(r.oclcnum).to eq('123')
    end

    it 'sets MARC::Record oclcnum instance attribute to nil if there is no OCLC number' do
      r = stub_builder('WHO123', 'OCoLC', [])
      expect(r.oclcnum).to eq(nil)
    end
  end
end
