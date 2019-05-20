require 'spec_helper'

describe Sierra::Data::ControlField do
  let(:c006) { build(:control_006) }
  let(:c007) { build(:control_007) }
  let(:c008) { build(:control_008) }

  # For control fields, Sierra database stores a space for what should be a
  # null position. (For example, p39 is meaningless/invalid for an 006, but
  # the database will has p39 of ' ' rather than null.)
  # 006s/008s are fixed length and we can assume any trailing spaces inside
  # that length are part of the field
  # 007s are variable length. We cannot trivially identify which trailing
  # spaces are part of the actual 007 vs which are just part of the sierra db
  # record, so we don't try to determine how many trailing spaces an 007 ought
  # to have.

  describe '#to_s' do
    context 'when an 006' do
      it 'takes the first 18 characters' do
        expect(c006.to_s.length).to eq(18)
      end

      it 'does NOT strip trailing spaces' do
        expect(c006.to_s).to eq('m        u f      ')
      end
    end

    context 'when an 007' do
      it 'DOES strip trailing spaces' do
        expect(c007.to_s).to eq('cr una|||unuua')
      end
    end

    context 'when an 008' do
      it 'takes the first 40 characters' do
        expect(c008.to_s.length).to eq(40)
      end

      it 'does NOT strip trailing spaces' do
        expect(c008.to_s).to eq('140912n| azannaabn          |n aaa      ')
      end
    end
  end

  describe '#to_marc' do
    it 'creates a MARC::ControlField object' do
      expect(c006.to_marc).to be_a(MARC::ControlField)
    end

    it 'uses #to_s for the ControlField value' do
      expect(c006.to_marc.value).to eq(c006.to_s)
      expect(c007.to_marc.value).to eq(c007.to_s)
      expect(c008.to_marc.value).to eq(c008.to_s)
    end
  end
end
