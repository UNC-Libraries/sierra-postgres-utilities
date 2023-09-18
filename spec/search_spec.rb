require 'spec_helper'

module Sierra::Search
  RSpec.describe PhraseSearch do
    it 'finds record by ocn' do
      expect(PhraseSearch.phrase_search(:o, 'ccn00828088')&.
                          first&.
                          record_id).
        to eq(420915771633)
    end

    it 'ocn search is case-insenstive' do
      expect(PhraseSearch.phrase_search(:o, 'CCN00828088')&.
                          first&.
                          record_id).
        to eq(420915771633)
    end

    ocns = [
      # 019
      ['5916808', 420908463899],
      # atypical 001
      ['B-1565-11', 420911493821],
      # atypical 001
      ['nchg2df651fe-7079-47a2-b29d-77ea90702dc1', 420915817690],
      # 001 w/ subfield not present in Sierra 001
      ['|z60618545', 420912632268],
      # one ocn in a Sierra multi-entry 019
      ['1238201683', 420917953976],
    ]
    ocns.each do |ocn, record_id|
      it "matches ocn: #{ocn} to rec: #{record_id}" do
        expect(PhraseSearch.phrase_search(:o, ocn)&.
              first&.
              record_id).
          to eq(record_id)
      end
    end

    it 'returns nil when normalized search term is empty' do
      expect(PhraseSearch.phrase_search(:o, ' ')&.first&.record_id).
        to be_nil
    end

    xit 'search terms including Han characters succeed' do
      # Han characters stored as kCCCII values in phrase_entry and
      # our search ought to properly translate them
    end

    xit 'searching a 10-digit ISBN returns recs where Sierra has only a 13' do
      # and vice versa
    end

    xit 'search rec_type specification works' do
    end

    xit 'search match strategy specification works' do
    end
  end
end
