require 'spec_helper'

describe Sierra::Data::Bib do
  let(:metadata) { build(:metadata_b) }
  let(:data) { build(:data_b) }
  let(:bib) { newrec(Sierra::Data::Bib, metadata, data) }

  describe '#bnum' do
    it 'returns rnum (including leading-letter and trailing-a)' do
      expect(bib.bnum).to eq(bib.rnum)
      expect(bib.bnum).to eq('b2661010a')
    end
  end

  describe '#bnum_trunc' do
    it 'yields rnum without check digit or "a"' do
      expect(bib.bnum_trunc).to eq('b2661010')
    end
  end

  describe '#bnum_with_check' do
    it 'yields rnum including actual check digit' do
      expect(bib.bnum_with_check).to eq('b26610103')
    end
  end

  context 'bib_record aliases' do
    describe '#bcode1' do
      it 'returns bcode1 from bib_record' do
        expect(bib.bcode1).to eq('s')
      end
    end

    describe '#mat_type' do
      it 'returns material type from bib_record_property' do
        bib.set_data(:property, build(:bib_property))
        expect(bib.mat_type).to eq('a')
      end
    end
  end

  context 'leader aliases' do
    subject { bib.set_data(:leader_field, build(:leader)) }

    describe '#rec_type' do
      it 'returns record type code from leader' do
        expect(subject.rec_type).to eq('a')
      end
    end

    describe '#blvl' do
      it 'returns bib level code from leader' do
        expect(subject.blvl).to eq('m')
      end
    end

    describe '#ctrl_type' do
      it 'returns control type code from leader' do
        expect(subject.ctrl_type).to eq(' ')
      end
    end
  end

  describe '#location_codes' do
    subject do
      bib.set_data(:locations, [build(:loc_dd),
                                build(:loc_wb),
                                build(:loc_multi)]).
        location_codes
    end

    it 'returns array' do
      expect(subject).to be_an(Array)
    end

    it 'returns bib locations' do
      expect(subject).to include('dd')
    end

    it 'does not return other location' do
      expect(subject).not_to include('ddda')
    end

    it 'always excludes "multi"' do
      expect(subject).not_to include('multi')
    end
  end

  describe '#best_title' do
    it 'returns iii best_title' do
      bib.set_data(:property, build(:bib_property))
      expect(bib.best_title).to eq('Something else : a novel')
    end
  end

  describe '#best_author' do
    it 'returns iii best_author' do
      bib.set_data(:property, build(:bib_property))
      expect(bib.best_author).to eq('Fassnidge, Virginia.')
    end
  end

  describe '#imprint' do
    let(:bib) { Sierra::Record.get('b1841152a') }

    it 'returns cleaned value of first 260/264 field' do
      expect(bib.imprint).to eq('London : Constable, 1981.')
    end

    xit 'uses equivalent of extract_subfields' do
      expect(bib.imprint).to eq('London : Constable, 1981.')
    end
  end

  describe '#items' do
    it 'returns array of attached items' do
      row = Sierra::DB.db[:bib_record_item_record_link].
            select(:bib_record_id, :item_record_id).first.values
      b = Sierra::Record.get(id: row.first)
      i = Sierra::Record.get(id: row.last)
      expect(b.items).to include(i)
    end
  end

  describe '#holdings' do
    it 'returns array of attached holdings records' do
      row = Sierra::DB.db[:bib_record_holding_record_link].
            select(:bib_record_id, :holding_record_id).first.values
      b = Sierra::Record.get(id: row.first)
      h = Sierra::Record.get(id: row.last)
      expect(b.holdings).to include(h)
    end
  end

  describe '#orders' do
    it 'returns array of attached orders' do
      row = Sierra::DB.db[:bib_record_order_record_link].
            select(:bib_record_id, :order_record_id).first.values
      b = Sierra::Record.get(id: row.first)
      o = Sierra::Record.get(id: row.last)
      expect(b.orders).to include(o)
    end
  end

  describe '#oclcnum' do
    it 'gets oclcnum from MARC::Record' do
      marc = double('marc')
      bib.instance_variable_set(:'@marc', marc)
      allow(marc).to receive(:oclcnum).and_return('my_oclcnum')
      expect(bib.oclcnum).to eq('my_oclcnum')
    end
  end
end
