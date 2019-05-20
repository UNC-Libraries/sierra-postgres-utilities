module Sierra
  module Data
    FactoryBot.define do
      factory :data_b, class: Bib do
        id { 420907986691 }
        record_id { 420907986691 }
        language_code { 'eng' }
        bcode1 { 's' }
        bcode2 { 'a' }
        bcode3 { '-' }
        country_code { 'onc' }
        index_change_count { 17 }
        is_on_course_reserve { false }
        is_right_result_exact { false }
        allocation_rule_code { nil }
        skip_num { 0 }
        cataloging_date_gmt { Time.parse('2005-07-13 00:00:00 -0400') }
        marc_type_code { ' ' }
        is_suppressed { false }
      end
    end
  end
end
