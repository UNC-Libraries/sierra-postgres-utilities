module Sierra
  module Data
    FactoryBot.define do
      factory :leader, class: LeaderField do
        id { 31 }
        record_id { 420908636160 }
        record_status_code { 'c' }
        record_type_code { 'a' }
        bib_level_code { 'm' }
        control_type_code { ' ' }
        char_encoding_scheme_code { ' ' }
        encoding_level_code { 'I' }
        descriptive_cat_form_code { 'a' }
        multipart_level_code { ' ' }
        base_address { 145 }
      end
    end
  end
end
