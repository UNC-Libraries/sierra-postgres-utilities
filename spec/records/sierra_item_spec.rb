require_relative '../../lib/sierra_postgres_utilities.rb'

class SierraItem
  def set_varfield_data(hsh)
    @varfield_data = hsh
  end

  def set_checkout(hsh)
    @checkout = Struct.new(*hsh.keys).new(*hsh.values)
  end
end

RSpec.describe SierraItem do
  let(:item) { SierraItem.new('i2661010a') }
  let(:item_no_vf) { SierraItem.new('i11136193a') }
  let(:item_many_vf) { SierraItem.new('i10998994a') }

  describe '#inum_trunc' do
    it 'returns without check digit or "a"' do
      expect(item.inum_trunc).to eq('i2661010')
    end
  end

  describe '#barcodes' do

    it 'is empty when no "b" varfields' do
      expect(item_no_vf.barcodes.empty?).to be true
    end

    context 'by default (when value_only is explicitly true)' do
      it 'returns barcodes as array of strings' do
        expect(item.barcodes).to eq(['00001254305'])
      end
    end

    context 'when value_only is explicitly false' do
      it 'returns barcodes as array of sql varfields' do
        expect(
          item.barcodes(value_only: false).first[:field_content]
        ).to eq('00001254305')
      end
    end
  end

  describe 'varfield retrieval by type' do
    types = [
      {method: 'barcodes', values: ['00050035567']},
      {method: 'volumes', values: ['Suppl.']},
      {method: 'public_notes', values: ['Second nature ; Reflections']},
      {method: 'internal_notes', values: ["jc", "Shelf date 4/26/16 jhg"]},
      {method: 'stats_fields', values: ['VENDOR: YBP uncat']},
      {method: 'varfield_librarys', values: ['ART']},
      {method: 'callnos', values: ['TR655.H66 2015']}
    ]
    types.each do |type_hsh|
      it "returns array of #{type_hsh[:method]} as strings" do
        expect(item_many_vf.send(type_hsh[:method])).to eq(type_hsh[:values])
      end
    end
  end

  describe 'callnos' do
    context 'when keep_delimiters: true' do
      it 'leaves delimiters in the field contents' do
        expect(
          item_many_vf.callnos(keep_delimiters: true).first
        ).to eq('|aTR655|b.H66 2015')
      end
    end
  end

  describe '#icode2' do
    it 'returns icode2' do
      expect(item.icode2).to eq('-')
    end
  end

  describe '#itype_code' do

    # note that item_record.itype_code_num is a number
    it 'returns itype code as a string' do
      expect(item.itype_code).to eq('0')
    end
  end

  describe '#location_code' do
    it 'returns location code' do
      expect(item.location_code).to eq('trln')
    end
  end

  describe '#status_code' do
    it 'returns status code' do
      expect(item.status_code).to eq('-')
    end
  end

  describe '#copy_num' do
    it 'returns copy num as a number' do
      expect(item.copy_num).to eq(1)
    end
  end

  describe '#suppressed?' do
    it 'returns boolean for suppression value' do
      expect(item.suppressed?).to be false
    end
  end

  describe '#itype_description' do
    it 'returns itype description / longname' do
      expect(item.itype_description).to eq('Book')
    end
  end

  describe '#location_description' do
    it 'returns location description / longname' do
      expect(
        item.location_description
      ).to eq('Library Service Center — Request from Storage')
    end
  end

  describe '#status_description' do
    it 'returns status description / longname' do
      expect(item.status_description).to eq('Available')
    end
  end

  describe '#due_date' do
    it 'returns due date as DateTime object' do
      checked_item = SierraItem.new('i2661010a')
      checked_item.set_checkout(due_gmt: Time.new(2018,8, 8, 4))
      expect(checked_item.due_date.is_a?(Time)).to be true
    end
  end

  describe '#is_oca?' do

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
