module Sierra
  module Data
    FactoryBot.define do
      factory :hold, class: Hold do
        id { 100400 }
        patron_record_id { 400000001234 }
        record_id { 450982257642 }
        placed_gmt { Time.parse('2019-01-18 05:13:05 -0400') }
        is_frozen { false }
        delay_days { 0 }
        location_code { nil }
        expires_gmt { nil }
        status { 0 }
        is_ir { false }
        pickup_location_code { 'd@' }
        is_ill { false }
        note { nil }
        ir_pickup_location_code { nil }
        ir_print_name { nil }
        ir_delivery_stop_name { nil }
        is_ir_converted_request { false }
        patron_records_display_order { 0 }
        records_display_order { nil }
      end
    end
  end
end
