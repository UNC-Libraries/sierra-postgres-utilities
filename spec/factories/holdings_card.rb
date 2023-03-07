module Sierra
  module Data
    FactoryBot.define do
      factory :holdings_card, class: HoldingsCard do
        id { 26716 }
        holding_record_id { 425206860854 }
        status_code { 'C' }
        display_format_code { nil }
        is_suppress_opac_display { nil }
        order_record_metadata_id { nil }
        is_create_item { false }
        is_usmarc { true }
        is_marc { nil }
        is_use_default_enum { nil }
        is_use_default_date { nil }
        update_method_code { 'n' }
      end
    end
  end
end
