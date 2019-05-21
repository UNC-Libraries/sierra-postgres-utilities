module Sierra
  module Data
    FactoryBot.define do
      factory :data_c, class: Holdings do
        id { 425211911992 }
        record_type_code { 'c' }
        record_num { 10149688 }
        creation_date_gmt { Time.parse('2002-01-16 10:31:00 -0500') }
        deletion_date_gmt { nil }
        campus_code { '' }
        agency_code_num { 0 }
        num_revisions { 36 }
        record_last_updated_gmt { Time.parse('2018-01-29 17:28:29 -0500') }
        previous_last_updated_gmt { Time.parse('2017-08-02 16:16:00 -0400') }
        record_id { 425211911992 }
        is_inherit_loc { false }
        allocation_rule_code { '0' }
        accounting_unit_code_num { 2 }
        label_code { 'n' }
        scode1 { 'c' }
        scode2 { '-' }
        claimon_date_gmt { nil }
        receiving_location_code { '1' }
        vendor_code { 'yankf' }
        scode3 { '-' }
        scode4 { '-' }
        update_cnt { 'i' }
        piece_cnt { 0 }
        echeckin_code { ' ' }
        media_type_code { ' ' }
        is_suppressed { false }
      end
    end
  end
end
