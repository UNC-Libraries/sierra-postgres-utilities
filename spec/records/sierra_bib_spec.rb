require_relative '../../lib/sierra_postgres_utilities.rb'

def set_attr(obj, attr, value)
  obj.instance_variable_set("@#{attr}", value)
end


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

  describe '@bnum' do
    it 'is set as bnum (including leading-b and trailing-a' do
      expect(bib001.bnum).to eq('b1191683a')
    end
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

  context 'bib_record aliases' do
    let(:bib) { SierraBib.new('b1841152a') }

    describe '#bcode1_blvl' do
    end

    describe '#mat_type' do
    end
  end

  describe '#control_fields' do
    let(:bib) { SierraBib.new('b3260099a') }
    let(:cfs) { bib.control_fields }

    it 'includes control_fields stored in sierra_view.varfield' do
      expect(cfs.select { |f| f.marc_tag == '001' }.empty?).to be false
    end

    it 'includes 006/007/008 control_fields from sierra_view.control_field' do
      expect(cfs.select { |f| f.marc_tag == '008' }.empty?).to be false
    end

    it 'creates a field_content string from individual character positions' do
      expect(cfs.select { |f| f.marc_tag == '008' }.first.field_content).
        to eq('990707s1999    dcu          f000 0 eng d')
    end

    it 'does not strip 008s' do
      set_attr(
        bib,
        :control_field,
        [OpenStruct.new(
          {:id=>"9805...", :record_id=>"420910055107", :varfield_type_code=>"y",
          :control_num=>"8", :p00=>"9", :p01=>"9", :p02=>"0", :p03=>"7",
          :p04=>"0", :p05=>"7", :p06=>"s", :p07=>"1", :p08=>"9", :p09=>"9",
          :p10=>"9", :p11=>" ", :p12=>" ", :p13=>" ", :p14=>" ", :p15=>"d",
          :p16=>"c", :p17=>"u", :p18=>" ", :p19=>" ", :p20=>" ", :p21=>" ",
          :p22=>" ", :p23=>" ", :p24=>" ", :p25=>" ", :p26=>" ", :p27=>" ",
          :p28=>"f", :p29=>"0", :p30=>"0", :p31=>"0", :p32=>" ", :p33=>"0",
          :p34=>" ", :p35=>"e", :p36=>"n", :p37=>" ", :p38=>" ", :p39=>" ",
          :p40=>"c", :p41=>"a", :p42=>"m", :p43=>"7", :occ_num=>"5",
          :remainder=>"a "}
        )]
      )
      expect(cfs.select { |f| f.marc_tag == '008' }.first.field_content).
        to eq('990707s1999    dcu          f000 0 en   ')
    end

    it 'strips 006s/007s' do
      expect(cfs.select { |f| f.marc_tag == '006' }.first.field_content).
        to eq('m        u f')
    end
  end

  describe '#ldr' do
    let(:bib) { SierraBib.new('b1841152a') }

    it 'returns leader field as a string' do
      expect(bib.ldr).to eq ('00000cam  2200145Ia 4500')
    end

    it 'is 24 bytes/chars' do
      expect(bib.ldr.length).to eq(24)
    end

    it 'is nil when no leader field exists' do
      set_attr(bib, :leader_field, OpenStruct.new)
      expect(bib.ldr).to be nil
    end
  end

  context 'leader aliases' do
    let(:bib) { SierraBib.new('b1841152a') }

    describe '#rec_type' do
      it 'returns record type code' do
        expect(bib.rec_type).to eq('a')
      end
    end

    describe '#blvl' do
      it 'returns bib level code from leader' do
        expect(bib.blvl).to eq('m')
      end
    end

    describe '#ctrl_type' do
      it 'returns control type code' do
        expect(bib.ctrl_type).to eq(' ')
      end
    end
  end

  describe '#bib_locs' do
    let(:bib) { SierraBib.new('b3439973') }
    let(:locs) { bib.bib_locs }

    it 'returns array' do
      expect(locs).to be_an(Array)
    end

    it 'returns bib locations' do
      expect(locs.include?('dd')).to be true
    end

    it 'excludes "multi" as a bib location' do
      expect(locs.length > 1 && !locs.include?('multi')).to be true
    end
  end

  describe '#best_title' do
    let(:bib) { SierraBib.new('b1841152a') }

    it 'returns iii best_title' do
      expect(bib.best_title).to eq('Something else : a novel')
    end
  end

  describe '#best_author' do
    let(:bib) { SierraBib.new('b1841152a') }

    it 'returns iii best_author' do
      expect(bib.best_author).to eq('Fassnidge, Virginia.')
    end
  end

  describe '#imprint' do
    let(:bib) { SierraBib.new('b1841152a') }

    it 'returns cleaned value of first 260/264 field' do
      expect(bib.imprint).to eq('London : Constable, 1981.')
    end
  end

  describe 'oclcnum' do
    it 'gets oclcnum from MARC::Record' do
      bib = SierraBib.new('b5244621')
      expect(bib.oclcnum).to eq(bib.marc.oclcnum)
    end
  end

  context 'marc production' do
    let(:bib) { SierraBib.new('b1841152a') }
    let(:correct_mrc) {
      m = MARC::Reader.new('spec/data/b1841152a.mrc').to_a.first
    }

    describe '#marc' do
      it 'returns a ruby-marc object' do
        expect(bib.marc).to be_a(MARC::Record)
      end

      it 'contains correct marc fields' do
        expect(bib.marc.fields).to eq(correct_mrc.fields)
      end

      it 'returns proper leader, apart from dummied fields/chars' do
        bib.marc.leader[0..4] = '00000'
        bib.marc.leader[12..16] = '00000'
        correct_mrc.leader[0..4] = '00000'
        correct_mrc.leader[12..16] = '00000'
        expect(bib.marc.leader).to eq(correct_mrc.leader)
      end
    end

    describe '#marchash' do
      it 'returns a marchash' do
        expect(bib.marchash.keys).to eq(["leader", "fields"])
      end

      it 'contains correct marc fields' do
        expect(bib.marchash['fields']).to eq(correct_mrc.to_marchash['fields'])
      end
    end
  end
end
