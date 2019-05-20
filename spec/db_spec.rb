require 'spec_helper'

module Sierra
  RSpec.describe DB do
    let(:query) { 'select * from sierra_view.bib_record limit 1' }
    let(:io) { StringIO.new }
    before(:each) { Sierra::DB.query(query) }

    describe '.query' do
      it 'executes/stages an arbitrary sql query' do
        expect(Sierra::DB.query(query)).to be_a(Sequel::Dataset)
        expect(Sierra::DB.query(query).sql).to eq(query)
      end
    end

    describe '.write_results' do
      context 'with include_headers: true (default)' do
        it 'includes headers' do
          Sierra::DB.write_results(io)
          expect(io.string[0..1]).to eq('id')
        end
      end

      context 'with include_headers: false' do
        it 'omits headers' do
          Sierra::DB.write_results(io, include_headers: false)
          expect(io.string[0..1]).to match(/[0-9]*/)
        end
      end

      context 'with format: tsv (default)' do
        it 'writes to a tsv' do
          Sierra::DB.write_results(io)
          expect(io.string.each_line.first.split("\t").first).to eq('id')
        end
      end

      context 'with format: csv (default)' do
        it 'writes to a csv' do
          Sierra::DB.write_results(io, format: :csv)
          expect(io.string.each_line.first.split(',').first).to eq('id')
        end
      end

      context ' with format: xlsx (default)' do
        xit 'writes to an xlsx' do
        end
      end
    end

    describe '.mail_results' do
    end

    describe '.yield_email' do
    end
  end
end
