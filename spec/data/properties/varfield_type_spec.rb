require 'spec_helper'

describe Sierra::Data::VarfieldType do
  subject { Sierra::Data::VarfieldType }

  describe '.list' do
    it 'returns a hash of vf code => vf_name for given record type' do
      expect(subject.list('b')['b']).to eq('Added Author')
    end

    it 'returns item vf code' do
      expect(subject.list('i')['b']).to eq('Barcode')
    end
  end
end
