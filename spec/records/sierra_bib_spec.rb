require_relative '../lib/sierra_postgres_utilities.rb'

RSpec.describe SierraBib do
  let(:bib001) { SierraBib.new('b1191683a') }

  describe 'initialize' do
    sb1 = SierraBib.new('b1191683')

    it 'sets given bnum' do
      expect(sb1.given_bnum).to eq('b1191683')
    end

    it 'sets bnum' do
      expect(sb1.bnum).to eq('b1191683a')
    end

    it 'sets bib identifier' do
      expect(sb1.record_id).to eq('420907986691')
    end

    sb2 = SierraBib.new('b00000000547475')
    it 'bib identifier is nil if bad bnum' do
      expect(sb2.record_id).to eq(nil)
    end

    it 'warn if bib identifier not retrieved' do
      expect(sb2.warnings).to include(
        'No record was found in Sierra for this record number'
      )
    end

    sb00 = SierraBib.new('b6780003')
    it 'sets bib identifier if bib is deleted' do
      expect(sb00.record_id).to eq('420913575011')
    end

    it 'warn if bib deleted' do
      expect(sb00.warnings).to include('This Sierra record was deleted')
    end

    sb3 = SierraBib.new('bzq6780003')
    it 'warn if bnum starts with letters other than b' do
      expect(sb3.warnings).to include(
        'Cannot retrieve Sierra record. Rnum must start with b'
      )
    end

    sb4 = SierraBib.new('b996780003')
    it 'warn if bib identifier not retrieved' do
      expect(sb4.warnings).to include(
        'No record was found in Sierra for this record number'
      )
    end

=begin
Note:
If we do: SierraBib.new('b9996780003') and try to set identifier, we will get a failure:
  PG::NumericValueOutOfRange:
  ERROR:  value "9996780003" is out of range for type integer
  LINE 4:        and record_num = '9996780003'

Shouldn't be a problem, so leaving it to fail in a nasty way for now.
=end
  end

  describe 'bnum_trunc' do
    it 'yields bnum without check digit or "a"' do
      expect(bib001.bnum_trunc).to eq('b1191683')
    end
  end

  describe 'bnum_with_check' do
    it 'yields bnum including actual check digit' do
      expect(bib001.bnum_with_check).to eq('b11916837')
    end
  end

  describe 'recnum' do
    it 'yields recnum' do
      expect(bib001.recnum).to eq('1191683')
    end
  end

  describe 'check_digit' do
    it 'yields a string' do
      expect(bib001.check_digit('1191683')).to be_an(String)
    end

    it 'calculates check digit for a recnum' do
      expect(bib001.check_digit('1191683')).to eq('7')
    end

    it 'correctly calculates a check digit of "x"' do
      expect(bib001.check_digit('1191693')).to eq('x')
    end
  end

  describe 'get_varfields' do
    sb5 = SierraBib.new('b3260099')
    vf5 = sb5.get_varfields(['245b'])

    it 'returns array' do
      expect(vf5).to be_an(Array)
    end

    it 'returns array of hashed field representations' do
      expect(vf5[0]).to be_a(Hash)
    end

    it 'adds extracted content value for each field' do
      expect(vf5[0]['extracted_content'][0]).to eq(
        'agriculture and education, planting the seeds of opportunity'
      )
    end
  end

  describe 'suppressed?' do
    it 'returns true if bib is suppressed' do
      bib = SierraBib.new('b5877843')
      expect(bib.suppressed?).to eq(true)
    end

    it 'returns false if bib is unsuppressed' do
      bib = SierraBib.new('b3260099')
      expect(bib.suppressed?).to eq(false)
    end

    it 'counts bcode3 == "c" as suppressed' do
      bib = SierraBib.new('b4576646')
      expect(bib.suppressed?).to eq(true)
    end
  end

  describe 'oclcnum' do
    it 'gets oclcnum from MARC::Record' do
      bib = SierraBib.new('b5244621')
      expect(bib.oclcnum).to eq(bib.marc.oclcnum)
    end
  end
end
