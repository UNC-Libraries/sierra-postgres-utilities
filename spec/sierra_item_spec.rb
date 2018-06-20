require_relative '../lib/sierra_postgres_utilities.rb'

RSpec.describe SierraItem do

  describe 'is_oca?' do

    oca_book = SierraItem.new('i7364701a')
    it 'returns true when book note present' do
      expect(oca_book.is_oca?).to be true
    end

    oca_journal = SierraItem.new('i7364813a')
    it 'returns true when journal note present' do
      expect(oca_journal.is_oca?).to be true
    end

    non_oca = SierraItem.new('i1000035a')
    it 'falsey if no oca note present' do
      expect(non_oca.is_oca?).to be_falsey
    end
  end
end