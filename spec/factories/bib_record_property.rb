module Sierra
  module Data
    FactoryBot.define do
      factory :bib_property, class: BibRecordProperty do
        id { 1076136 }
        bib_record_id { 420908636160 }
        best_title { 'Something else : a novel' }
        bib_level_code { 'm' }
        material_code { 'a' }
        publish_year { 1981 }
        best_title_norm { 'something else a novel' }
        best_author { 'Fassnidge, Virginia.' }
        best_author_norm { 'fassnidge virginia' }
      end
    end
  end
end
