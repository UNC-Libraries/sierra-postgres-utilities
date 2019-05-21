module Sierra
  module Data
    FactoryBot.define do
      factory :checkout, class: Checkout do
        id { 654949 }
        patron_record_id { 400000000000 }
        item_record_id { 450974227090 }
        items_display_order { nil }
        due_gmt { Time.parse('2019-01-02 00:00:00 -0500') }
        loanrule_code_num { 1 }
        checkout_gmt { Time.parse('2019-01-01 00:00:00 -0500') }
        renewal_count { 0 }
        overdue_count { 2 }
        overdue_gmt { Time.parse('2019-01-03 00:00:00 -0500') }
        recall_gmt { nil }
        ptype { 0 }
      end
    end
  end
end
