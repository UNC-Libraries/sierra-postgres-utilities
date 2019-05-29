require 'spec_helper'

describe Sierra::Data::DeletedRecord do
  let(:rec) { Sierra::Data::Metadata.first.extend Sierra::Data::DeletedRecord }

  it 'raises a DeletedRecordError on method_missing' do
    expect{ rec.non_existent_method }.
      to raise_error(Sierra::Data::DeletedRecord::DeletedRecordError)
  end
end
