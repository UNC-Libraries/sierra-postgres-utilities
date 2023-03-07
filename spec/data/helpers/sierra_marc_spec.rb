require 'spec_helper'

module Sierra
  module Data
    module Helpers
      RSpec.describe SierraMARC do
        describe '#marc' do
          xit 'tests pending' do
          end
        end

        describe '.compile_marc' do
          xit 'factory tests pending' do
          end

          context 'marc production' do
            let(:bib) { Sierra::Record.get('b1841152a') }
            let(:correct_mrc) do
              MARC::Reader.new('spec/spec_data/b1841152a.mrc').to_a.first
            end

            describe '#marc' do
              it 'returns a MARC::Record object' do
                expect(bib.marc).to be_a(MARC::Record)
              end

              it 'contains correct marc fields', :aggregate_failures do
                marc_bib = newrec(Sierra::Data::Bib, build(:metadata_b), build(:data_b))
                marc_bib.set_data(:control_fields, [build(:control_008)])
                marc_bib.set_data(
                  :varfields,
                  [build(:varfield_001), build(:varfield_005), build(:varfield_245),
                   ]
                )
                expect(marc_bib.marc['001'].to_s).to eq('001 8671134')
                expect(marc_bib.marc['005'].to_s).to eq('005 19820807000000.0')
                expect(marc_bib.marc['008'].to_s).to eq('008 140912n| azannaabn          |n aaa      ')
                expect(marc_bib.marc['245'].to_s).to eq('245 10 $a Something else : $b a novel / $c Virginia Fassnidge. ')
              end

              it 'returns proper leader, apart from pseudo-value fields/chars' do
                bib.marc.leader[0..4] = '00000'
                bib.marc.leader[12..16] = '00000'
                correct_mrc.leader[0..4] = '00000'
                correct_mrc.leader[12..16] = '00000'
                expect(bib.marc.leader).to eq(correct_mrc.leader)
              end
            end
          end
        end
      end
    end
  end
end
