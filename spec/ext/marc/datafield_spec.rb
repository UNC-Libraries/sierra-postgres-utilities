require 'marc'
require_relative '../../../ext/marc/datafield'


RSpec.describe MARC::DataField do
  describe 'to_mrk' do

    f = MARC::DataField.new('999', '1', '2', ['a', 'content'])

    it 'yields a mrk-type string of the field' do
      expect(f.to_mrk).to eq ('=999  12$acontent')
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
      expect(fempty.to_mrk).to eq ('=999  12')
    end
  end
end