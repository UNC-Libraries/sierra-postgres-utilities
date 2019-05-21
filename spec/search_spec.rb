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
      ['5916808|%1762189', 420908463899],
      ['B-1565-11', 420911493821],
      ['nchg2df651fe-7079-47a2-b29d-77ea90702dc1', 420915817690],
      ['|z60618545', 420912632268],
      ['32988245|z(OCoLC)62441777|z(OCoLC)77633390|z(OCoLC)77633393|z(OCoLC)77664829|z(OCoLC)77664832|z(OCoLC)77734146|z(OCoLC)77768001|z(OCoLC)77819922|z(OCoLC)77867473|z(OCoLC)77879873|z(OCoLC)77948921|z(OCoLC)77992118|z(OCoLC)78156448|z(OCoLC)78202144|z(OCoLC)78227074|z(OCoLC)78229478|z(OCoLC)78263835|z(OCoLC)78294354|z(OCoLC)78356784|z(OCoLC)78356786|z(OCoLC)78378278|z(OCoLC)78494104|z(OCoLC)78494106|z(OCoLC)78546807|z(OCoLC)78644222|z(OCoLC)78696909|z(OCoLC)78731572|z(OCoLC)78773090|z(OCoLC)78773094|z(OCoLC)78823416|z(OCoLC)78849123|z(OCoLC)78849128|z(OCoLC)78850176|z(OCoLC)78850178|z(OCoLC)78954175|z(OCoLC)78954180|z(OCoLC)79018046|z(OCoLC)79019238|z(OCoLC)79023976|z(OCoLC)79079593|z(OCoLC)79129035|z(OCoLC)79327189|z(OCoLC)79619320|z(OCoLC)79619321|z(OCoLC)79657868|z(OCoLC)79667407|z(OCoLC)79717203|z(OCoLC)79760843|z(OCoLC)79792915|z(OCoLC)79919861|z(OCoLC)79919870|z(OCoLC)79982952|z(OCoLC)79982954|z(OCoLC)80046751|z(OCoLC)80098487|z(OCoLC)80098490|z(OCoLC)80172878|z(OCoLC)80303652|z(OCoLC)80340445|z(OCoLC)80402874|z(OCoLC)80624299|z(OCoLC)80635972|z(OCoLC)80712023|z(OCoLC)80712027|z(OCoLC)80719584|z(OCoLC)80781063|z(OCoLC)81003423|z(OCoLC)81003427|z(OCoLC)81064327|z(OCoLC)81064351|z(OCoLC)81064353|z(OCoLC)81071054|z(OCoLC)81275351|z(OCoLC)81275354|z(OCoLC)81333101|z(OCoLC)81363913|z(OCoLC)81410442|z(OCoLC)81475533|z(OCoLC)81476337|z(OCoLC)81476340|z(OCoLC)81511140|z(OCoLC)81642668|z(OCoLC)81678817|z(OCoLC)81678826|z(OCoLC)81719138|z(OCoLC)81794381|z(OCoLC)81794382|z(OCoLC)81821005|z(OCoLC)81868540|z(OCoLC)81952264|z(OCoLC)81992783|z(OCoLC)82015486|z(OCoLC)82031277|z(OCoLC)82114916|z(OCoLC)82167627|z(OCoLC)82212378|z(OCoLC)82212514|z(OCoLC)82307779|z(OCoLC)82333563', 420913252173]
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
