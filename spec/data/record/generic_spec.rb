require 'spec_helper'

describe Sierra::Data::GenericRecord do
  let(:metadata) { build(:metadata_a) }
  let(:data) { build(:data_a) }
  let(:rec) { newrec(Sierra::Data::Authority, metadata, data) }

  describe '#deleted?' do
    context 'when record has been deleted' do
      it 'returns true' do
        rec2 = newrec(Sierra::Data::Authority, build(:metadata_deleted))
        expect(rec2.deleted?).to be true
      end
    end

    context 'when record has not been deleted' do
      it 'returns false' do
        expect(rec.deleted?).to be false
      end
    end
  end

  describe '#suppressed?' do
    context 'when record.is_suppressed' do
      it 'returns true' do
        rec.is_suppressed = true
        expect(rec.suppressed?).to be true
      end
    end

    context 'when record.is_suppressed is false' do
      it 'returns false' do
        rec.is_suppressed = false
        expect(rec.suppressed?).to be false
      end
    end
  end

  describe '#record_id' do
    it 'returns Sierra record id' do
      expect(rec.record_id).to eq(416615865210)
    end
  end

  describe '#rnum' do
    it 'returns Sierra rnum (including trailing a)' do
      expect(rec.rnum).to eq('a2661010a')
    end
  end

  describe '#rnum_trunc' do
    it 'returns Sierra rnum (omitting trailing a)' do
      expect(rec.rnum_trunc).to eq('a2661010')
    end
  end

  describe '#rnum_with_check' do
    it 'returns Sierra rnum including actual check digit' do
      expect(rec.rnum_with_check).to eq('a26610103')
    end
  end

  describe '#recnum' do
    it 'returns Sierra record_num (i.e. numbers only)' do
      expect(rec.recnum).to eq('2661010')
    end
  end

  describe 'check_digit' do
    it 'yields a string' do
      expect(rec.check_digit('2661010')).to be_an(String)
    end

    it 'calculates check digit for a recnum' do
      expect(rec.check_digit('2661010')).to eq('3')
    end

    it 'correctly calculates a check digit of "x"' do
      expect(rec.check_digit('1191693')).to eq('x')
    end
  end

  describe '#standardize_rnum' do
    xit 'tests pending' do
    end
  end

  describe '#type' do
    xit 'tests pending' do
    end
  end

  describe '#created_date' do
    subject { rec.created_date }

    it 'returns time created' do
      expect(subject).to eq(Time.parse('2004-11-04 12:55:00 -0500'))
    end

    it 'returns a Time object' do
      expect(subject).to be_a(Time)
    end
  end

  describe '#updated_date' do
    subject { rec.updated_date }

    it 'returns time last updated' do
      expect(subject).to eq(Time.parse('2018-10-11 07:30:34 -0400'))
    end

    it 'returns a Time object' do
      expect(subject).to be_a(Time)
    end
  end

  describe '#varfields' do
    xit 'tests pending' do
    end
  end

  describe '#vf_codes' do
    it "returns a hash of vf code => vf_name for record's type" do
      expect(Sierra::Data::Bib.first.vf_codes['b']).to eq('Added Author')
    end

    it 'returns item vf code' do
      expect(Sierra::Data::Item.first.vf_codes['b']).to eq('Barcode')
    end
  end
end
