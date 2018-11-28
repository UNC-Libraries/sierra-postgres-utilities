require_relative '../../lib/sierra_postgres_utilities.rb'

class SpecDummy
  include SierraPostgresUtilities::Helpers::Varfields
end

RSpec.describe SierraPostgresUtilities::Helpers::Varfields do
  let(:dummy) { SpecDummy.new }

  describe 'get_varfields' do
    let(:bib) { SierraBib.new('b3260099a') }
    let(:vf) { bib.get_varfields(['245b']) }

    it 'returns array' do
      expect(vf).to be_an(Array)
    end

    it 'returns array of hashed field representations' do
      expect(vf[0]).to be_a(Hash)
    end

    it 'adds extracted content value for each field' do
      expect(vf[0]['extracted_content'][0]).to eq(
        'agriculture and education, planting the seeds of opportunity'
      )
    end
  end

  describe '#add_explicit_sf_a' do
    let(:fc) { '|aIDEBK|beng|erda|cIDEBK|dCOO|aAAA' }
    let(:fc_no_a) { 'IDEBK|beng|erda|cIDEBK|dCOO|aAAA' }

    context 'when field_content lacks initial "|a"' do
      it 'adds explcit initial |a' do
        expect(dummy.add_explicit_sf_a(fc_no_a)).to eq(fc)
      end

      it 'does not modify original object' do
        dummy.add_explicit_sf_a(fc_no_a)
        expect(fc_no_a).to eq('IDEBK|beng|erda|cIDEBK|dCOO|aAAA')
      end
    end

    context 'when field_content lacks initial "|a"' do
      it 'makes no changes' do
        expect(dummy.add_explicit_sf_a(fc)).to eq(fc)
      end
    end
  end

  describe '#subfield_from_field_content' do
    let(:fc) { '|aIDEBK|beng|erda|cIDEBK|dCOO|aAAA' }
    let(:fc_no_a) { 'IDEBK|beng|erda|cIDEBK|dCOO|aAAA' }

    it 'returns value of first matching subfield' do
      expect(dummy.subfield_from_field_content(fc, 'a')).
        to eq('IDEBK')
    end

    context 'when implicit_sfa: true' do
      it 'adds initial |a if content lacks initial sf delimiter' do
        expect(dummy.subfield_from_field_content(fc_no_a, 'a',
                                                 implicit_sfa: true)).
          to eq('IDEBK')
      end
    end

    it 'it implict_sfa is true by default' do
      expect(dummy.subfield_from_field_content(fc_no_a, 'a')).
        to eq(dummy.subfield_from_field_content(fc_no_a, 'a',
                                              implicit_sfa: true))
    end

    context 'when implicit_sfa: false' do
      it 'does not add initial |a when content lacks initial sf delimiter' do
        expect(dummy.subfield_from_field_content(fc_no_a, 'a',
                                                 implicit_sfa: false)).
          to eq('AAA')
      end
    end
  end

  describe '#extract_subfields' do

    # accepts desired_subfields string
    # accepts desired_subfield array of strings
    # trim punct
    # remove sf6880
    # implicit_sfa

  end

  describe '#subfield_arry' do
    let(:fc) { '|aIDEBK|beng|erda|cIDEBK|dCOO|aAAA' }
    let(:fc_arry) {
      [["a", "IDEBK"], ["b", "eng"], ["e", "rda"],
      ["c", "IDEBK"], ["d", "COO"], ["a", "AAA"]]
    }
    let(:fc_no_a) { 'IDEBK|beng|erda|cIDEBK|dCOO|aAAA' }

    it 'returns array of subfield,value pairs' do
      expect(dummy.subfield_arry(fc)).to eq(fc_arry)
    end

    context 'when implicit_sfa: true' do
      it 'adds initial |a if content lacks initial sf delimiter' do
        expect(dummy.subfield_arry(fc_no_a, implicit_sfa: true)).
          to eq(fc_arry)
      end
    end

    it 'it implict_sfa is true by default' do
      expect(dummy.subfield_arry(fc_no_a)).
        to eq(dummy.subfield_arry(fc, implicit_sfa: true))
    end

    context 'when implicit_sfa: false' do
      it 'does not add initial |a when content lacks initial sf delimiter' do
        expect(dummy.subfield_arry(fc_no_a, implicit_sfa: false)).
          to eq(fc_arry[1..-1])
      end
    end

    context 'when subfield lacks subfield code' do
      it 'discards that subfield' do
        expect(dummy.subfield_arry('|adata||balso data')).
          to eq([['a', 'data'], ['b', 'also data']])
      end

      it 'returns empty array if no subfields left' do
        expect(dummy.subfield_arry('|')).to eq([])
      end
    end
  end
end
