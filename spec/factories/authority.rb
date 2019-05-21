module Sierra
  module Data
    FactoryBot.define do
      factory :data_a, class: Authority do
        id { 416615865210 }
        record_id { 416615865210 }
        marc_type_code { ' ' }
        code1 { '-' }
        code2 { '-' }
        suppress_code { '-' }
        is_suppressed { false }
      end
    end
  end
end
