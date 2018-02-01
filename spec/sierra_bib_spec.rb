require_relative '../PostgresConnect'
require_relative '../SierraBib'

RSpec.describe SierraBib do
  $c.close if $c
  $c = Connect.new

  describe 'initialize' do
    sb1 = SierraBib.new('b1191683')
    it 'sets bnum' do
      expect(sb1.bnum).to eq('b1191683')
    end

    it 'sets bib identifier' do
      expect(sb1.record_id).to eq('420907986691')
    end

    sb2 = SierraBib.new('b6780003')
    it 'bib identifier is nil if bad bnum' do
      expect(sb2.record_id).to eq(nil)
    end

    it 'warn if bib identifier not retrieved' do
      expect(sb2.warnings).to include('No record was found in Sierra for this bnum')
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
  end
end
