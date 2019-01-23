require_relative '../../lib/sierra_postgres_utilities.rb'

def set_attr(obj, attr, value)
  obj.instance_variable_set("@#{attr}", value)
end


RSpec.describe SierraRecord do
  let(:rec) { SierraRecord.new(rnum: 'b1841152a', rtype: 'b') }
  let(:del_rec) { SierraRecord.new(rnum: 'b6780003a', rtype: 'b') }
  let(:invalid_rec) { SierraRecord.new(rnum: 'b1111111111a', rtype: 'b')}

  describe '#deleted?' do

    context 'record has been deleted' do
      it 'returns boolean true' do
        expect(del_rec.deleted?).to be true
      end
    end

    context 'record has not been deleted' do
      it 'returns falsey' do
        expect(rec.deleted?).to be_falsey
      end
    end

    context 'record is invalid' do
      it 'returns falsey' do
        expect(invalid_rec.deleted?).to be_falsey
      end
    end
  end

  describe '#invalid?' do

    context 'record never existed' do
      it 'returns boolean true' do
        expect(invalid_rec.invalid?).to be true
      end
    end

    context 'undeleted record exists' do
      it 'returns falsey' do
        expect(rec.invalid?).to be_falsey
      end
    end

    context 'deleted record exists' do
      it 'returns falsey' do
        expect(del_rec.invalid?).to be_falsey
      end
    end


  end

  describe '.vf_codes' do
    it 'returns hash of type_codes:type_names' do
      expect(SierraItem.vf_codes['b']).to eq('Barcode')
    end

    it 'uses varfield_type_name.short_name when name is empty' do
      expect(SierraItem.vf_codes['8']).to eq('HOLD')
    end
  end

  describe '#vf_codes' do
    it 'returns hash of type_codes:type_names' do
      expect(rec.vf_codes['c']).to eq('Call No.')
    end

    it 'uses varfield_type_name.short_name when name is empty' do
      expect(rec.vf_codes['8']).to eq('HOLD')
    end
  end
end
