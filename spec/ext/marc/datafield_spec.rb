require 'spec_helper'

RSpec.describe MARC::DataField do
  describe '#to_mrk' do
    f = MARC::DataField.new('999', '1', '2', ['a', 'content'])

    it 'yields a mrk-type string of the field' do
      expect(f.to_mrk).to eq('=999  12$acontent')
    end

    it 'uses dollar sign subfield delimiter (MarcEdit-style)' do
      expect(f.to_mrk).to match(/\$acontent/)
    end

    it 'accepts a delimiter argument to change delimiter' do
      expect(f.to_mrk(delimiter: '|')).to match(/\|acontent/)
    end

    fblank_ind = MARC::DataField.new('999', ' ', ' ', ['a', 'content'])
    it 'uses backslash characters for blank indicators' do
      expect(fblank_ind.to_mrk).to match(/999  \\\\/)
    end

    fempty = MARC::DataField.new('999', '1', '2')
    it 'produces string even if no subfield data is present' do
      expect(fempty.to_mrk).to eq('=999  12')
    end
  end

  describe '#any_subfields_ignore_repeated?' do
    let(:a300) do
      MARC::DataField.new('300', '1', ' ', ['a', 'foo'],
                          ['a', 'bar'], ['k', 'baz'])
    end

    it 'looks at non-repeated subfields and first instance of repeated subfields' do
      expect(a300.any_subfields_ignore_repeated?(code: 'a', value: 'foo')).to be true
    end

    it 'ignores second, third, etc instances of repeated subfields' do
      expect(a300.any_subfields_ignore_repeated?(code: 'a', value: 'bar')).to be false
    end

    # it searches the first subfield for each matching code
    # not searches the first subfield with a matching code
    it 'searches first instance of _each_ matching subfield code' do
      expect(a300.any_subfields_ignore_repeated?(code: /[ak]/, value: 'baz')).to be true
    end
  end

  # True when the first subfield a contains foo
  #   first_such_subfield_matches?(code: 'a', content: /foo/)
  # True when the first subfield a or first subfield k contains foo
  #   first_such_subfield_matches?(code: /[ak]/, content: /foo/)
end
