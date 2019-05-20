require_relative '../lib/sierra_postgres_utilities.rb'

RSpec.describe Sierra::DerivativeBib do
  let(:marc) do
    MARC::Reader.new('spec/spec_data/b1841152a.mrc').to_a.first
  end

  let(:bib) do
    b = Sierra::Record.get('b1841152a')
    b.marc = marc
    b
  end

  let(:alt) { Sierra::DerivativeBib.new(bib) }

  let(:xml) do
    <<~XML
      <record>
        <leader>00469cam  2200169Ia 4500</leader>
        <controlfield tag='001'>b1841152</controlfield>
        <controlfield tag='003'>NcU</controlfield>
        <controlfield tag='005'>19820807000000.0</controlfield>
        <controlfield tag='008'>820807s1981    enk           000 1 eng d</controlfield>
        <datafield tag='020' ind1=' ' ind2=' '>
          <subfield code='a'>0094643407</subfield>
        </datafield>
        <datafield tag='035' ind1=' ' ind2=' '>
          <subfield code='a'>(OCoLC)8671134</subfield>
        </datafield>
        <datafield tag='040' ind1=' ' ind2=' '>
          <subfield code='a'>NOC</subfield>
          <subfield code='c'>NOC</subfield>
        </datafield>
        <datafield tag='100' ind1='1' ind2=' '>
          <subfield code='a'>Fassnidge, Virginia.</subfield>
        </datafield>
        <datafield tag='245' ind1='1' ind2='0'>
          <subfield code='a'>Something else :</subfield>
          <subfield code='b'>a novel /</subfield>
          <subfield code='c'>Virginia Fassnidge.</subfield>
        </datafield>
        <datafield tag='260' ind1=' ' ind2=' '>
          <subfield code='a'>London :</subfield>
          <subfield code='b'>Constable,</subfield>
          <subfield code='c'>1981.</subfield>
        </datafield>
        <datafield tag='300' ind1=' ' ind2=' '>
          <subfield code='a'>152 p. ;</subfield>
          <subfield code='c'>23 cm.</subfield>
        </datafield>
      </record>
    XML
  end

  describe '#get_alt_marc' do
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

  describe '#xml' do
    it 'returns altmarc as xml' do
      expect(alt.xml).to eq(File.read('spec/spec_data/b1841152a.altmarc.xml'))
    end

    it 'accepts strip_datafields: false' do
      marc << MARC::DataField.new('030', ' ', ' ', ['a', 'blah '])
      expect(alt.xml(strip_datafields: false)).to include('blah ')
    end
  end
end
