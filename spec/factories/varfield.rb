module Sierra
  module Data
    FactoryBot.define do
      factory :varfield, class: Varfield do
        id { 114483 }
        record_id { 450972566081 }
        marc_ind1 { ' ' }
        marc_ind2 { ' ' }
        occ_num { 0 }

        factory :varfield_marc do
          marc_tag { '245' }
          marc_ind1 { '1' }
          marc_ind2 { '0' }
          varfield_type_code { 't' }
          field_content { '|aSomething else :|ba novel' }

          factory :varfield_245 do
            field_content { '|aSomething else :|ba novel /|cVirginia Fassnidge.' }
          end

          factory :varfield_001 do
            marc_tag { '001' }
            field_content { '8671134' }
          end

          factory :varfield_005 do
            marc_tag { '005' }
            varfield_type_code { 'y' }
            field_content { '19820807000000.0' }
          end

          factory :varfield_852 do
            marc_tag { '852' }
            varfield_type_code { 'c' }
            field_content { '|hQV 704|iR388|zEarlier editions in stacks' }
          end

          factory :varfield_implicit_sfa do
            field_content { 'Something else :|ba novel' }
          end
        end

        factory :varfield_i do
          marc_tag { nil }

          factory :varfield_i_b do
            varfield_type_code { 'b' }
            field_content { '00050035567' }
          end

          factory :varfield_i_c do
            varfield_type_code { 'c' }
            marc_tag { '090' }
            field_content { '|aTR655|b.H66 2015' }
          end

          factory :varfield_i_f do
            varfield_type_code { 'f' }
            field_content { 'ART' }
          end

          factory :varfield_i_j do
            varfield_type_code { 'j' }
            field_content { 'VENDOR: YBP uncat' }
          end

          factory :varfield_i_m do
            varfield_type_code { 'm' }
            field_content { 'Message' }
          end

          factory :varfield_i_v do
            varfield_type_code { 'v' }
            field_content { 'Suppl.' }
          end

          factory :varfield_i_x do
            varfield_type_code { 'x' }
            field_content { 'jc' }
          end

          factory :varfield_i_z do
            varfield_type_code { 'z' }
            field_content { 'Second nature ; Reflections' }
          end
        end
      end
    end
  end
end
