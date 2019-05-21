require 'spec_helper'

module Sierra
  module DB
    RSpec.describe Query do
      let(:query) { 'select * from sierra_view.bib_record limit 1' }
      let(:io) { StringIO.new }
      before(:each) { Sierra::DB.query(query) }

      describe '.headers' do
        it 'returns array of field names as symbols' do
          expect(Sierra::DB::Query.headers.first).to eq(:id)
        end
      end
    end
  end
end
