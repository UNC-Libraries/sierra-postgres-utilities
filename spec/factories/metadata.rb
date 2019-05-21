module Sierra
  module Data
    FactoryBot.define do
      factory :metadata, class: Metadata do
        id { 450974227090 }
        record_num { 2661010 }
        creation_date_gmt { Time.parse('2004-11-04 12:55:00 -0500') }
        deletion_date_gmt { nil }
        campus_code { '' }
        agency_code_num { 0 }
        num_revisions { 226 }
        record_last_updated_gmt { Time.parse('2018-10-11 07:30:34 -0400') }
        previous_last_updated_gmt { Time.parse('2017-06-30 21:41:00 -0400') }

        factory :metadata_deleted do
          deletion_date_gmt { Time.parse('2004-11-04 12:55:00 -0500') }
        end

        factory :metadata_a do
          record_type_code { 'a' }
        end

        factory :metadata_b do
          record_type_code { 'b' }
        end

        factory :metadata_c do
          record_type_code { 'c' }
        end

        factory :metadata_i do
          record_type_code { 'i' }
        end

        factory :metadata_o do
          record_type_code { 'o' }
        end

        factory :metadata_p do
          record_type_code { 'p' }
        end
      end
    end
  end
end
