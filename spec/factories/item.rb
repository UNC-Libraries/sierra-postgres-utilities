module Sierra
  module Data
    FactoryBot.define do
      factory :data_i, class: Item do
        id { 450974227090 }
        record_id { 450974227090 }
        icode1 { 0 }
        icode2 { '-' }
        itype_code_num { 0 }
        location_code { 'trln' }
        agency_code_num { 0 }
        item_status_code { '-' }
        is_inherit_loc { false }
        price { BigDecimal('0.0') }
        last_checkin_gmt { Time.parse('2016-09-21 12:18:00 -0400') }
        checkout_total { 19 }
        renewal_total { 2 }
        last_year_to_date_checkout_total { 1 }
        year_to_date_checkout_total { 0 }
        is_bib_hold { false }
        copy_num { 1 }
        checkout_statistic_group_code_num { 0 }
        last_patron_record_metadata_id { 400000000000 }
        inventory_gmt { nil }
        checkin_statistics_group_code_num { 1 }
        use3_count { 0 }
        last_checkout_gmt { Time.parse('2016-09-21 12:17:00 -0400,') }
        internal_use_count { 0 }
        copy_use_count { 0 }
        item_message_code { '-' }
        opac_message_code { '-' }
        virtual_type_code { nil }
        virtual_item_central_code_num { 0 }
        holdings_code { '6' }
        save_itype_code_num { nil }
        save_location_code { nil }
        save_checkout_total { nil }
        old_location_code { nil }
        distance_learning_status { 0 }
        is_suppressed { false }
        is_available_at_library { true }
      end
    end
  end
end
