require 'spec_helper'

def ocn_stub_builder(m001, m003, m035s)
  rec = MARC::Record.new
  rec << MARC::ControlField.new('001', m001) if m001
  rec << MARC::ControlField.new('003', m003) if m003
  if m035s
    m035s.each do |v|
      rec << MARC::DataField.new('035', ' ', ' ', ['a', v])
    end
  end
  rec
end

def new_rec_with_fields(*fields)
  rec = MARC::Record.new
  fields.each { |f| rec << f }
  rec
end

RSpec.describe MARC::Record do
  describe 'get_oclcnum' do
    it 'returns oclc_number when 001 is digits only and there is no 003' do
      r = ocn_stub_builder('123', '', [])
      expect(r.get_oclcnum).to eq('123')
    end

    it 'strips 001 value before determining 001 composition' do
      r = ocn_stub_builder('698212827  ', '', [])
      expect(r.get_oclcnum).to eq('698212827')
    end

    it 'sets oclc_number when 001 is digits only and 003 = OCoLC' do
      r = ocn_stub_builder('123', 'OCoLC', [])
      expect(r.get_oclcnum).to eq('123')
    end

    it 'does NOT set oclc_number when 001 is digits only and 003 = ItFiC' do
      r = ocn_stub_builder('123', 'ItFiC', [])
      expect(r.get_oclcnum).to eq(nil)
    end

    it 'sets oclc_number from 035 with (OCoLC) when not set from 001' do
      r = ocn_stub_builder('123', 'ItFiC', ['(OCoLC)567'])
      expect(r.get_oclcnum).to eq('567')
    end

    it 'does NOT set oclc_number when 001 is digits only and 003 = DLC' do
      r = ocn_stub_builder('123', 'DLC', [])
      expect(r.get_oclcnum).to eq(nil)
    end

    # it 'strips leading zero(s) from oclc_number set from 035' do
    #   r = ocn_stub_builder('123', 'ItFiC', ['(OCoLC)000000567'])
    #   expect(r.get_oclcnum).to eq('567')
    # end

    it 'sets oclc_number when 001 is digits only and 003 = NhCcYBP' do
      r = ocn_stub_builder('123', 'NhCcYBP', [])
      expect(r.get_oclcnum).to eq('123')
    end

    it 'sets oclc_number when 001 has prefix tmp and 003 = OCoLC' do
      r = ocn_stub_builder('tmp123', 'OCoLC', [])
      expect(r.get_oclcnum).to eq('123')
    end

    it 'sets oclc_number when 001 is digits with alphanum suffix' do
      r = ocn_stub_builder('123wcmSPR99', '', [])
      expect(r.get_oclcnum).to eq('123')
    end

    it 'does NOT set oclc_number when 001 has prefix M-ESTCN and 003 = OCoLC with prefixed 035' do
      r = ocn_stub_builder('M-ESTCN123', 'OCoLC', ['(OCoLC)M-ESTCN987'])
      expect(r.get_oclcnum).to eq(nil)
    end

    # it 'sets oclc_number from 035 when it starts with ocm' do
    #   r = ocn_stub_builder('M-ESTCN123', 'OCoLC', ['(OCoLC)M-ESTCN987', '(OCoLC)ocm444'])
    #   expect(r.get_oclcnum).to eq('444')
    # end

    it 'does NOT set oclc_number when 001 has prefix moml and 003 = OCoLC' do
      r = ocn_stub_builder('moml123', 'OCoLC', [])
      expect(r.get_oclcnum).to eq(nil)
    end

    it 'sets oclc_number when 001 has hsl prefix and 003 = OCoLC' do
      r = ocn_stub_builder('hsl123', 'OCoLC', [])
      expect(r.get_oclcnum).to eq('123')
    end

    it 'does NOT set oclc_number when 001 has WHO prefix and 003 = OCoLC' do
      r = ocn_stub_builder('WHO123', 'OCoLC', [])
      expect(r.get_oclcnum).to eq(nil)
    end
  end

  describe 'get_035oclcnums' do
    it 'returns oclc_number even when 001 is digits only and 003 = OCoLC' do
      r = ocn_stub_builder('123', 'OCoLC', ['(OCoLC)000000567'])
      expect(r.get_035oclcnums).to eq(['567'])
    end

    it 'strips leading zero(s) from oclc_numbers' do
      r = ocn_stub_builder('123', 'ItFiC', ['(OCoLC)000000567'])
      expect(r.get_035oclcnums).to eq(['567'])
    end

    it 'includes oclc_number from 035 when it starts with ocm' do
      r = ocn_stub_builder('M-ESTCN123', 'OCoLC', ['(OCoLC)M-ESTCN987', '(OCoLC)ocm444'])
      expect(r.get_035oclcnums).to eq(['444'])
    end

    it 'does not include oclc_number when 035 has prefix M-ESTCN' do
      r = ocn_stub_builder('', '', ['(OCoLC)M-ESTCN987'])
      expect(r.get_035oclcnums).to be_nil
    end

    it 'is nil if no OCLC 035s' do
      r = ocn_stub_builder('', '', [])
      expect(r.get_035oclcnums).to be_nil
    end

    it 'happily returns multiple 035s' do
      r = ocn_stub_builder('123', 'ItFiC', ['(OCoLC)000000567'])
      r << MARC::DataField.new('035', ' ', ' ', ['a', '(OCoLC)000000123'])
      expect(r.get_035oclcnums).to eq(['567', '123'])
    end

    it 'does not return an 035 oclcnum of ""' do
      r = ocn_stub_builder('123', 'ItFiC', ['(OCoLC)'])
      expect(r.get_035oclcnums).to be_nil
    end
  end

  describe 'oclcnum' do
    it 'sets MARC::Record oclcnum instance attribute when OCLC Number present' do
      r = ocn_stub_builder('123', '', [])
      expect(r.oclcnum).to eq('123')
    end

    it 'sets MARC::Record oclcnum instance attribute to nil if there is no OCLC number' do
      r = ocn_stub_builder('WHO123', 'OCoLC', [])
      expect(r.oclcnum).to eq(nil)
    end
  end

  describe '.xml_string' do
    let(:marc) do
      MARC::Reader.new('spec/spec_data/b1841152a.mrc').to_a.first
    end

    it 'returns given marc as xml' do
      expect(MARC::Record.xml_string(marc)).
        to eq(File.read('spec/spec_data/b1841152a.xml'))
    end

    context 'when strip_datafields: true' do
      it 'strips trailing spaces from data' do
        marc << MARC::DataField.new('030', ' ', ' ', ['a', 'blah '])
        expect(MARC::Record.xml_string(marc, strip_datafields: true)).not_to include('blah ')
      end

      it 'and strip_datafields: true is the default' do
        marc << MARC::DataField.new('030', ' ', ' ', ['a', 'blah '])
        expect(MARC::Record.xml_string(marc)).not_to include('blah ')
      end
    end

    context 'when strip_datafields: false' do
      it 'does not strip trailing spaces from data' do
        marc << MARC::DataField.new('030', ' ', ' ', ['a', 'blah '])
        expect(MARC::Record.xml_string(marc, strip_datafields: false)).to include('blah ')
      end
    end
  end

  describe '.language_from_008' do
    let(:eng008) do
      MARC::ControlField.new('008', '0.........1.........2.........3....eng...')
    end
    let(:invalid008) do
      MARC::ControlField.new('008', '0.........1.........2.........3....xxx...')
    end
    let(:discontinued008) do
      MARC::ControlField.new('008', '0.........1.........2.........3....cam...')
    end
    let(:rec_eng) { new_rec_with_fields(eng008) }
    let(:rec_invalid) { new_rec_with_fields(invalid008) }
    let(:rec_discontinued) { new_rec_with_fields(discontinued008) }
    let(:rec_no008) { new_rec_with_fields }

    context 'when record has current, valid language code' do
      it 'returns language code, language name pair' do
        expect(rec_eng.language_from_008).to eq(['eng', 'English'])
      end
    end

    context 'when record has invalid language code' do
      it 'returns language code, nil pair' do
        expect(rec_invalid.language_from_008).to eq(['xxx', nil])
      end
    end

    context 'when record has discontinued language code' do
      context 'by default (or if forbid_discontinued is explicitly false)' do
        it 'returns language code, language name pair' do
          expect(rec_discontinued.language_from_008).to eq(['cam', 'Khmer'])
        end
      end

      context 'and argument forbid_discontinued is true' do
        it 'returns language code, nil pair' do
          expect(
            rec_discontinued.language_from_008(forbid_discontinued: true)
          ).to eq(['cam', nil])
        end
      end
    end

    context 'when record has no 008 / no 008/35-37' do
      it 'returns nil' do
        expect(rec_no008.language_from_008).to be_nil
      end
    end
  end

  describe 'no_245_has_ak' do
    rec1 = MARC::Record.new
    rec1 << MARC::DataField.new('245', ' ', ' ', ['b', 'title'])
    rec1 << MARC::DataField.new('245', ' ', ' ', ['a', 'title'])
    it 'is false if any 245 has 245$a' do
      expect(rec1.no_245_has_ak?).to be false
    end

    rec2 = MARC::Record.new
    rec2 << MARC::DataField.new('245', ' ', ' ', ['b', 'title'], ['k', 'title'])
    it 'is false if any 245 has 245$k' do
      expect(rec2.no_245_has_ak?).to be false
    end

    rec3 = MARC::Record.new
    rec3 << MARC::DataField.new('245', ' ', ' ', ['b', 'title'])
    it 'is true if no 245 has 245$k' do
      expect(rec3.no_245_has_ak?).to be true
    end

    rec4 = MARC::Record.new
    it 'is true if no 245s exist' do
      expect(rec4.no_245_has_ak?).to be true
    end
  end

  describe 'm300_without_a' do
    rec1 = MARC::Record.new
    rec1 << MARC::DataField.new('300', ' ', ' ', ['a', ''])
    rec1 << MARC::DataField.new('300', ' ', ' ', ['b', ''])
    it 'is true if any 300 lacks 300$a' do
      expect(rec1.m300_without_a?).to be true
    end

    rec2 = MARC::Record.new
    rec2 << MARC::DataField.new('300', ' ', ' ', ['a', ''], ['b', ''])
    rec2 << MARC::DataField.new('300', ' ', ' ', ['z', ''], ['a', ''])
    it 'is false if all 300s have 300$a' do
      expect(rec2.m300_without_a?).to be false
    end

    rec4 = MARC::Record.new
    it 'is false if no 300s exist' do
      expect(rec4.m300_without_a?).to be false
    end
  end

  describe 'count' do
    rec1 = MARC::Record.new
    rec1 << MARC::ControlField.new('001', 'value')
    rec1 << MARC::DataField.new('300', ' ', ' ', ['a', ''])
    rec1 << MARC::DataField.new('300', ' ', ' ', ['b', ''])

    it 'returns number of fields with given tag' do
      expect(rec1.count('300')).to eq(2)
    end

    it 'can also count control fields' do
      expect(rec1.count('001')).to eq(1)
    end

    it 'returns 0 if no fields' do
      expect(rec1.count('999')).to eq(0)
    end
  end

  describe 'sort' do
    let(:a999) { MARC::DataField.new('999', ' ', ' ', ['3', 'v.1']) }
    let(:a856) { MARC::DataField.new('856', ' ', ' ', ['3', 'v.2']) }
    let(:b856) { MARC::DataField.new('856', ' ', ' ', ['3', 'v.1']) }
    let(:rec) do
      r = MARC::Record.new
      [a999, a856, b856].each { |f| r.append(f) }
      r
    end
    it 'reorders fields to be in ascending order by tag' do
      expect(rec.sort.fields.last).to eq(a999)
    end

    it 'within a field tag (e.g. 856) retains original order' do
      expect(rec.sort.fields.first).to eq(a856)
    end
  end

  describe 'field_find_all' do
    let(:a300) { MARC::DataField.new('300', '1', ' ', ['a', 'content']) }
    let(:b300) { MARC::DataField.new('300', '1', '2', ['a', 'other']) }
    let(:a900) do
      MARC::DataField.new('900', ' ', '1',
                          ['a', 'content'], ['a', ' more content'])
    end
    let(:b900) do
      MARC::DataField.new('900', ' ', '1',
                          ['a', 'content'], ['b', ' more content'])
    end
    let(:rec) do
      r = MARC::Record.new
      [a300, b300, a900, b900].each { |f| r.append(f) }
      r
    end

    context 'when filtering by tag' do
      context 'and positive criteria specified' do
        context 'and criteria is a string' do
          it 'return fields where datapoint equals criteria' do
            expect(rec.field_find_all(tag: '900')).to eq([a900, b900])
          end
        end

        context 'and criteria is a regexp' do
          it 'return fields where datapoint matches criteria' do
            expect(rec.field_find_all(tag: /9../)).to eq([a900, b900])
          end
        end
      end

      context 'and negative criteria specified' do
        context 'and criteria is a string' do
          it 'return fields where datapoint not equals criteria' do
            expect(rec.field_find_all(tag_not: '900')).to eq([a300, b300])
          end
        end

        context 'and criteria is a regexp' do
          it 'return fields where datapoint not matches criteria' do
            expect(rec.field_find_all(tag_not: /9../)).to eq([a300, b300])
          end
        end
      end
    end

    context 'when filtering by ind1' do
      context 'and positive criteria specified' do
        context 'and criteria is a string' do
          it 'return fields where datapoint equals criteria' do
            expect(rec.field_find_all(ind1: ' ')).to eq([a900, b900])
          end
        end

        context 'and criteria is a regexp' do
          it 'return fields where datapoint matches criteria' do
            expect(rec.field_find_all(ind1: / /)).to eq([a900, b900])
          end
        end
      end

      context 'and negative criteria specified' do
        context 'and criteria is a string' do
          it 'return fields where datapoint not equals criteria' do
            expect(rec.field_find_all(ind1_not: ' ')).to eq([a300, b300])
          end
        end

        context 'and criteria is a regexp' do
          it 'return fields where datapoint not matches criteria' do
            expect(rec.field_find_all(ind1_not: /[ ab]/)).to eq([a300, b300])
          end
        end
      end
    end

    context 'when filtering by ind2' do
      context 'and positive criteria specified' do
        context 'and criteria is a string' do
          it 'return fields where datapoint equals criteria' do
            expect(rec.field_find_all(ind2: '1')).to eq([a900, b900])
          end
        end

        context 'and criteria is a regexp' do
          it 'return fields where datapoint matches criteria' do
            expect(rec.field_find_all(ind2: /[13]/)).to eq([a900, b900])
          end
        end
      end

      context 'and negative criteria specified' do
        context 'and criteria is a string' do
          it 'return fields where datapoint not equals criteria' do
            expect(rec.field_find_all(ind2_not: '1')).to eq([a300, b300])
          end
        end

        context 'and criteria is a regexp' do
          it 'return fields where datapoint not matches criteria' do
            expect(rec.field_find_all(ind2_not: /1/)).to eq([a300, b300])
          end
        end
      end
    end

    context 'when filtering by value' do
      context 'and positive criteria specified' do
        context 'and criteria is a string' do
          it 'return fields where datapoint equals criteria' do
            expect(rec.field_find_all(value: 'content more content')).to eq([a900, b900])
          end
        end

        context 'and criteria is a regexp' do
          it 'return fields where datapoint matches criteria' do
            expect(rec.field_find_all(value: /more/)).to eq([a900, b900])
          end
        end
      end

      context 'and negative criteria specified' do
        context 'and criteria is a string' do
          it 'return fields where datapoint not equals criteria' do
            expect(rec.field_find_all(value_not: 'content more content')).to eq([a300, b300])
          end
        end

        context 'and criteria is a regexp' do
          it 'return fields where datapoint not matches criteria' do
            expect(rec.field_find_all(value_not: /more/)).to eq([a300, b300])
          end
        end
      end
    end

    context 'when complex_subfields specified' do
      xit 'requires complex_subfields to be an array of arrays' do
      end

      it 'allows searching for fields having a matching subfield' do
        expect(rec.field_find_all(
                 complex_subfields: [[:has, code: 'a', value: ' more content']]
               )).to eq([a900])
      end

      it 'allows searching for fields lacking a matching subfield' do
        expect(rec.field_find_all(
                 complex_subfields: [[:has_no, code: 'a', value: /content/]]
               )).to eq([b300])
      end

      it 'allows searching for fields having only one matching subfield' do
        expect(rec.field_find_all(
                 complex_subfields: [[:has_one, code_not: 'b']]
               )).to eq([a300, b300, b900])
      end
    end

    context 'when multiple critera are specified' do
      it 'returns fields that fit ALL criteria' do
        expect(rec.field_find_all(tag: '300', ind2: '2')).to eq([b300])
      end

      it 'returns fields that fit ALL criteria' do
        expect(rec.field_find_all(tag: '300', value_not: /other/)).to eq([a300])
      end
    end
  end
end
