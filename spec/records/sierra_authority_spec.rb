require_relative '../../lib/sierra_postgres_utilities.rb'

def set_attr(obj, attr, value)
  obj.instance_variable_set("@#{attr}", value)
end

def mock_struct(hsh = {zzz: nil})
  Struct.new(*hsh.keys).new(*hsh.values)
end


RSpec.describe SierraAuthority do
  let(:auth001) { SierraAuthority.new('a1500197a') }

  describe '#suppressed?' do

    context 'when #authority.record.is_suppressed' do
      it 'returns true' do
        set_attr(auth001, :authority_record, mock_struct(
          id: 416613046253,
          is_suppressed: true
        ))
        expect(auth001.suppressed?).to be true
      end
    end

    context 'when #authority.record.is_suppressed is false' do
      it 'returns false' do
        set_attr(auth001, :authority_record, mock_struct(
          id: 416613046253,
          is_suppressed: false
        ))
        expect(auth001.suppressed?).to be false
      end
    end
  end
end
