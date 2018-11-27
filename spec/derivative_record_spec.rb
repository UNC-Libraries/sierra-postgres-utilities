require_relative '../lib/sierra_postgres_utilities.rb'

RSpec.describe DerivativeRecord do
  describe '#get_alt_marc' do
    let(:bib) { SierraBib.new('b1841152a') }
    let(:alt) { DerivativeRecord.new(bib) }

    it 'modifies a copy of the marc on the sierra bib' do
      alt.altmarc
      expect(alt.smarc['001'].value).to eq('8671134')
    end

    it 'writes bnum_trunc to 001' do
      expect(alt.altmarc['001'].value).to eq(bib.bnum_trunc)
    end

    it 'writes an 001 oclcnumber to the 035' do
      expect(alt.altmarc['035'].value).to eq('(OCoLC)8671134')
    end
  end
end
