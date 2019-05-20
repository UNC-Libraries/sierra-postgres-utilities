require 'spec_helper'

describe Sierra::Data::Varfield do
  let(:v) { build(:varfield_marc) }
  let(:v005) { build(:varfield_005) }
  let(:v245) { build(:varfield_245) }

  context 'when a marc_varfield' do
    describe '#marc_varfield?' do
      it 'returns true' do
        v.marc_tag = '100'
        expect(v.marc_varfield?).to be true
      end
    end

    describe '#nonmarc_varfield?' do
      it 'returns false' do
        v.marc_tag = '100'
        expect(v.nonmarc_varfield?).to be false
      end
    end
  end

  context 'when NOT a marc_varfield' do
    describe '#marc_varfield?' do
      it 'returns false' do
        v.marc_tag = nil
        expect(v.marc_varfield?).to be false
      end
    end

    describe '#nonmarc_varfield?' do
      it 'returns true' do
        v.marc_tag = nil
        expect(v.nonmarc_varfield?).to be true
      end
    end

    describe '#control_field?' do
      context 'when marc_tag <= "009"' do
        it 'returns true' do
          expect(v005.control_field?).to be true
        end
      end

      context 'when marc_tag >= "010"' do
        it 'returns false' do
          v.marc_tag = '010'
          expect(v.control_field?).to be false
        end
      end
    end

    describe '#to_marc' do
      context 'when varfield is a non_marc varfield' do
        it 'returns nil' do
          v.marc_tag = nil
          expect(v.to_marc).to be_nil
        end
      end

      context 'when varfield is a control field' do
        it 'returns a MARC::ControlField' do
          expect(v005.to_marc).to eq(
            MARC::ControlField.new('005', '19820807000000.0')
          )
        end
      end

      context 'when varfield is a data field' do
        it 'returns a MARC::DataField' do
          expect(v245.to_marc).to eq(
            MARC::DataField.new('245', '1', '0',
                                ['a', 'Something else :'],
                                ['b', 'a novel'])
          )
        end
      end
    end

    describe '.subfield_arry' do
      subject { Sierra::Data::Varfield }

      let(:fc) { '|aIDEBK|beng|erda|cIDEBK|dCOO|aAAA' }
      let(:fc_arry) do
        [['a', 'IDEBK'], ['b', 'eng'], ['e', 'rda'],
         ['c', 'IDEBK'], ['d', 'COO'], ['a', 'AAA']]
      end
      let(:fc_no_a) { 'IDEBK|beng|erda|cIDEBK|dCOO|aAAA' }

      it 'returns array of subfield,value pairs' do
        expect(subject.subfield_arry(fc)).to eq(fc_arry)
      end

      context 'when implicit_sfa: true' do
        it 'adds initial |a if content lacks initial sf delimiter' do
          expect(subject.subfield_arry(fc_no_a, implicit_sfa: true)).
            to eq(fc_arry)
        end
      end

      it 'it implict_sfa is true by default' do
        expect(subject.subfield_arry(fc_no_a)).
          to eq(subject.subfield_arry(fc, implicit_sfa: true))
      end

      context 'when implicit_sfa: false' do
        it 'does not add initial |a when content lacks initial sf delimiter' do
          expect(subject.subfield_arry(fc_no_a, implicit_sfa: false)).
            to eq(fc_arry[1..-1])
        end
      end

      context 'when subfield lacks subfield code' do
        it 'discards that subfield' do
          expect(subject.subfield_arry('|adata||balso data')).
            to eq([['a', 'data'], ['b', 'also data']])
        end

        it 'returns empty array if no subfields left' do
          expect(subject.subfield_arry('|')).to eq([])
        end
      end
    end

    describe '.add_explicit_sf_a' do
      subject { Sierra::Data::Varfield }

      let(:fc) { '|aIDEBK|beng|erda|cIDEBK|dCOO|aAAA' }
      let(:fc_no_a) { 'IDEBK|beng|erda|cIDEBK|dCOO|aAAA' }

      context 'when field_content lacks initial "|a"' do
        it 'adds explcit initial |a' do
          expect(subject.add_explicit_sf_a(fc_no_a)).to eq(fc)
        end

        it 'does not modify original object' do
          subject.add_explicit_sf_a(fc_no_a)
          expect(fc_no_a).to eq('IDEBK|beng|erda|cIDEBK|dCOO|aAAA')
        end
      end

      context 'when field_content lacks initial "|a"' do
        it 'makes no changes' do
          expect(subject.add_explicit_sf_a(fc)).to eq(fc)
        end
      end
    end
  end
end
