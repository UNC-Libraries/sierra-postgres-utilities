require 'spec_helper'

module Sierra
  RSpec.describe Record do
    context 'when record exists' do
      describe '.get' do
        let(:bnum) { 'b1191683a' }
        let(:rec) { Sierra::Record.get(bnum) }

        it 'returns a Sierra::Data::[RecType] object for given bnum' do
          expect(rec).to be_a(Sierra::Data::Bib)
        end

        it 'bnum does not need a trailing "a"' do
          bnum_short = 'b1191683'
          expect(Sierra::Record.get(bnum_short)).to be_a(Sierra::Data::Bib)
        end

        it 'can retrieve records by id' do
          expect(Sierra::Record.get(id: 420907986691).rnum).to eq(bnum)
        end

        it 'id can be given as a string' do
          expect(Sierra::Record.get(id: '420907986691').rnum).to eq(bnum)
        end

        # See Sierra::Data::Item code for details. If using natural joins
        # in the model definition, retrieval of items with agency_code_num != 0
        # would fail.
        it "retrieves items with non-zero agency_code_num's" do
          i = Sierra::Record.get('i10195158a')
          expect(i.agency_code_num != 0).to be true
        end
      end

      context 'but is deleted' do
        let(:rec) { Sierra::Record.get('b6780003') }

        describe '#data' do
          it 'returns a DeletedRecord' do
            expect(rec).to be_a(Sierra::Data::DeletedRecord)
          end
        end
      end
    end

    context 'when record does not exist' do
      let(:rec) { Sierra::Record.get('b00000000547475') }

      describe '.fetch' do
        it 'raises an InvalidRecord error' do
          expect { rec }.to raise_error(Sierra::Record::InvalidRecord)
        end
      end
    end
  end
end
