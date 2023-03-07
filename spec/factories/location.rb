module Sierra
  module Data
    FactoryBot.define do
      factory :loc, class: Location do
        id { 277 }
        branch_code_num { nil }
        parent_location_code { nil }
        is_public { false }
        is_requestable { true }

        factory :loc_ddda do
          code { 'ddda' }
        end

        factory :loc_trln do
          code { 'trln' }
        end

        factory :loc_wbba do
          code { 'wbba' }
        end

        factory :loc_dd do
          code { 'dd' }
        end

        factory :loc_wb do
          code { 'wb' }
        end

        factory :loc_multi do
          code { 'multi' }
        end
      end
    end
  end
end
