require 'spec_helper'

describe Sierra::Data::Authority do
  let(:metadata) { build(:metadata_a) }
  let(:data) { build(:data_a) }
  let(:auth) { newrec(Sierra::Data::Authority, metadata, data) }
end
