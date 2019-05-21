require 'spec_helper'

describe Sierra::Data::Item do
  let(:metadata) { build(:metadata_i) }
  let(:data) { build(:data_i) }
  let(:item) { newrec(Sierra::Data::Item, metadata, data) }

  describe '#inum' do
    it 'returns rnum (including leading-letter and trailing-a)' do
      expect(item.inum).to eq(item.inum)
      expect(item.inum).to eq('i2661010a')
    end
  end

  describe '#inum_trunc' do
    it 'returns without check digit or "a"' do
      expect(item.inum_trunc).to eq('i2661010')
    end
  end

  describe '#inum_with_check' do
    it 'yields rnum including actual check digit' do
      expect(item.inum_with_check).to eq('i26610103')
    end
  end

  describe 'helpers to access varfields by varfield type' do
    context 'when varfields of that type exist' do
      context 'by default (or when value_only is explicitly true)' do
        it 'returns varfield(s) value/field_content as array of strings' do
          item.set_data(:varfields, [build(:varfield_i_b)])
          expect(item.barcodes).to eq(['00050035567'])
        end
      end

      context 'when value_only is explicitly false' do
        it 'returns varfield(s) as array of hash-like objects' do
          item.set_data(:varfields, [build(:varfield_i_b)])
          expect(item.barcodes(value_only: false).first).to respond_to(:values)
        end
      end
    end

    context 'otherwise' do
      it 'is empty' do
        item.set_data(:varfields, [])
        expect(item.barcodes).to be_empty
      end
    end
  end

  describe 'varfield retrieval by type' do
    types = [
      {method: 'barcodes', values: ['00050035567']},
      {method: 'volumes', values: ['Suppl.']},
      {method: 'public_notes', values: ['Second nature ; Reflections']},
      {method: 'internal_notes', values: ['jc']},
      {method: 'messages', values: ['Message']},
      {method: 'stats_fields', values: ['VENDOR: YBP uncat']},
      {method: 'varfield_librarys', values: ['ART']},
      {method: 'callnos', values: ['TR655.H66 2015']}
    ]
    types.each do |type_hsh|
      it "returns array of #{type_hsh[:method]} as strings" do
        item.set_data(
          :varfields,
          [build(:varfield_i_b), build(:varfield_i_c), build(:varfield_i_f),
           build(:varfield_i_j), build(:varfield_i_m), build(:varfield_i_v),
           build(:varfield_i_x), build(:varfield_i_z)]
        )
        expect(item.send(type_hsh[:method])).to eq(type_hsh[:values])
      end
    end
  end

  describe 'callnos' do
    context 'by default (or when keep_delimiters: false)' do
      it 'removes delimiters from field contents' do
        item.set_data(:varfields, [build(:varfield_i_c)])
        expect(item.callnos.first).to eq('TR655.H66 2015')
      end
    end
    context 'when keep_delimiters: true' do
      it 'leaves delimiters in the field contents' do
        item.set_data(:varfields, [build(:varfield_i_c)])
        expect(item.callnos(keep_delimiters: true).first).to eq(
          '|aTR655|b.H66 2015'
        )
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

  describe '#checkout_total' do
    it 'returns checkout_total as a number' do
      expect(item.checkout_total).to eq(19)
    end
  end

  describe '#suppressed?' do
    it 'returns boolean for suppression value' do
      expect(item.suppressed?).to be false
    end
  end

  describe '#itype_desc' do
    it 'returns itype description / longname' do
      expect(item.itype_desc).to eq('Book')
    end
  end

  describe '#location_desc' do
    it 'returns location description / longname' do
      expect(
        item.location_desc
      ).to eq('Library Service Center — Request from Storage')
    end
  end

  describe '#status_desc' do
    it 'returns status description / longname' do
      expect(item.status_desc).to eq('Available')
    end
  end

  describe '#due_date' do
    context 'when item is checked out' do
      it 'returns due date' do
        item.set_data(:checkout, build(:checkout))
        expect(item.due_date).to eq(Time.parse('2019-01-02 00:00:00 -0500'))
      end

      it 'returns due date as Time object' do
        item = Sierra::Data::Checkout.first.item
        expect(item.due_date).to be_a(Time)
      end
    end

    context 'when item is not checked out' do
      it 'returns nil' do
        item.set_data(:checkout, nil)
        expect(item.due_date).to be_nil
      end
    end
  end

  describe '#bib' do
    it 'returns array of attached bibs' do
      row = Sierra::DB.db[:bib_record_item_record_link].
            select(:bib_record_id, :item_record_id).first.values
      b = Sierra::Record.get(id: row.first)
      i = Sierra::Record.get(id: row.last)
      expect(i.bibs).to include(b)
    end
  end

  describe '#holdings' do
    it 'returns attached holdings record' do
      row = Sierra::DB.db[:holding_record_item_record_link].
            select(:holding_record_id, :item_record_id).first.values
      h = Sierra::Record.get(id: row.first)
      i = Sierra::Record.get(id: row.last)
      expect(i.holdings).to eq(h)
    end
  end

  describe '#is_oca?' do
    xit 'returns true when book note present' do
      oca_book = Sierra::Record.get('i7364701a')
      expect(oca_book.is_oca?).to be true
    end

    xit 'returns true when journal note present' do
      oca_journal = Sierra::Record.get('i7364813a')
      expect(oca_journal.is_oca?).to be true
    end

    xit 'falsey if no oca note present' do
      non_oca = Sierra::Record.get('i1000035a')
      expect(non_oca.is_oca?).to be_falsey
    end
  end
end
