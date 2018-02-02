require_relative '../PostgresConnect'
require_relative '../SierraBib'

RSpec.describe SierraBib do
  $c.close if $c
  $c = Connect.new

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
      expect(sb2.warnings).to include('No record was found in Sierra for this bnum')
    end

    # TODO: j: how is object numbering supposed to happen? find out, clean up numbers.
    sb00 = SierraBib.new('b6780003')
    it 'sets bib identifier if bib is deleted' do
      expect(sb00.record_id).to eq('420913575011')
    end

    it 'warn if bib deleted' do
      expect(sb00.warnings).to include('This Sierra bib was deleted')
    end
 
    sb3 = SierraBib.new('bzq6780003')
    it 'warn if bnum starts with letters other than b' do
      expect(sb3.warnings).to include('Cannot retrieve Sierra bib. Bnum must start with b')
    end

    sb4 = SierraBib.new('b996780003')
    it 'warn if bib identifier not retrieved' do
      expect(sb4.warnings).to include('No record was found in Sierra for this bnum')
    end

=begin
Note: 
If we do: SierraBib.new('b9996780003') and try to set identifier, we will get a failure:
  PG::NumericValueOutOfRange:
  ERROR:  value "9996780003" is out of range for type integer
  LINE 4:        and record_num = '9996780003'

Shouldn't be a problem, so leaving it to fail in a nasty way for now.
=end

    # TODO: j: how is object numbering supposed to happen? find out, clean up numbers.
    sb05 = SierraBib.new('b1191693x')
    it 'sets bnum when given bnum with check digit' do
      expect(sb05.bnum).to eq('b1191693a')
    end
  end

  describe 'bnum_trunc' do
    # TODO: j: how is object numbering supposed to happen? find out, clean up numbers.
    sb06 = SierraBib.new('b1191683a')

    it 'yields bnum without check digit or "a"' do
      expect(sb06.bnum_trunc).to eq('b1191683')
    end
  end

  describe 'bnum_with_check' do
    # TODO: j: how is object numbering supposed to happen? find out, clean up numbers.
    sb07 = SierraBib.new('b1191683a')
    
    it 'yields bnum including actual check digit' do
      expect(sb07.bnum_with_check).to eq('b11916837')
    end
  end

  describe 'recnum' do
    # TODO: j: how is object numbering supposed to happen? find out, clean up numbers.
    sb08 = SierraBib.new('b1191683a')
    
    it 'yields recnum' do
      expect(sb08.recnum).to eq('1191683')
    end
  end

  describe 'check_digit' do
    # TODO: j: how is object numbering supposed to happen? find out, clean up numbers.
    sb09 = SierraBib.new('b1191683')

    it 'yields a string' do
      expect(sb09.check_digit('1191683')).to be_an(String)
    end

    it 'calculates check digit for a recnum' do
      expect(sb09.check_digit('1191683')).to eq('7')
    end

    # TODO: j: how is object numbering supposed to happen? find out, clean up numbers.
    sb010 = SierraBib.new('b1191693')
    it 'correctly calculates a check digit of "x"' do
      expect(sb010.check_digit('1191693')).to eq('x')
    end
  end

  describe 'given_check_digit?' do

    sb011 = SierraBib.new('b1191693x')
    it 'returns true when given_bnum includes check digit' do
      expect(sb011.given_check_digit?).to eq(true)
    end

    sb012 = SierraBib.new('b1191693')
    it 'returns false when given_bnum does not include check digit' do
      expect(sb012.given_check_digit?).to eq(false)
    end

    sb013 = SierraBib.new('b6780003')
    # check digit for '678000' would be 3, but 3 is not a check digit here
    it 'returns false if recnum would be 7 or fewer digits' do
      expect(sb013.given_check_digit?).to eq(false)
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
      expect(vf5[0]['extracted_content'][0]).to eq('agriculture and education, planting the seeds of opportunity')
    end
  end

  describe 'find_oclcnum' do
    
    
   end
  
end
