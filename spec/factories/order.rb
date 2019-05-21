module Sierra
  module Data
    FactoryBot.define do
      factory :data_o, class: Order do
        id { 476743101902 }
        record_type_code { 'o' }
        record_num { 1732046 }
        creation_date_gmt { Time.parse('2015-07-02 09:53:00 -0400') }
        deletion_date_gmt { nil }
        campus_code { '' }
        agency_code_num { '0' }
        num_revisions { '8' }
        record_last_updated_gmt { Time.parse('2015-07-10 13:54:08 -0400') }
        previous_last_updated_gmt { Time.parse('2015-07-06 15:30:30 -0400') }
        record_id { 476743101902 }
        accounting_unit_code_num { 1 }
        acq_type_code { 'p' }
        catalog_date_gmt { Time.parse('2015-07-10 00:00:00 -0400') }
        claim_action_code { 'n' }
        ocode1 { '-' }
        ocode2 { '-' }
        ocode3 { '-' }
        ocode4 { 'g' }
        estimated_price { BigDecimal('0.0') }
        form_code { 'a' }
        order_date_gmt { Time.parse('2015-07-02 00:00:00 -0400') }
        order_note_code { ' ' }
        order_type_code { 'a' }
        receiving_action_code { '-' }
        received_date_gmt { Time.parse('2015-07-02 00:00:00 -0400') }
        receiving_location_code { '3' }
        billing_location_code { '3' }
        order_status_code { 'a' }
        temporary_location_code { 'c' }
        vendor_record_code { 'ya11m' }
        language_code { 'und' }
        blanket_purchase_order_num { '' }
        country_code { 'xx' }
        volume_count { 1 }
        fund_allocation_rule_code { nil }
        reopen_text { '' }
        list_price { nil }
        list_price_foreign_amt { nil }
        list_price_discount_amt { nil }
        list_price_service_charge { nil }
        is_suppressed { nil }
        fund_copies_paid { nil }
      end
    end
  end
end
