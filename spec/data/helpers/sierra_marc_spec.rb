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

              it 'contains correct marc fields' do
                expect(bib.marc.fields).to eq(correct_mrc.fields)
              end

              it 'returns proper leader, apart from dummied fields/chars' do
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
