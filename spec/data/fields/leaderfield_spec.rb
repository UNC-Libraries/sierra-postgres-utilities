require 'spec_helper'

describe Sierra::Data::LeaderField do
  let(:ldr) { build(:leader) }

  describe '#to_s' do
    subject { ldr.to_s }

    it 'returns leader field as a string' do
      expect(subject).to eq('00000cam  2200145Ia 4500')
    end

    it 'is 24 bytes/chars' do
      expect(subject.length).to eq(24)
    end

    it 'uses pseudo values for record length (ldr/00-04)' do
      expect(subject[0..4]).to eq('00000')
    end

    it 'uses pseudo values for indicator count (ldr/10)' do
      expect(subject[10]).to eq('2')
    end

    it 'uses pseudo values for subfield code count (ldr/11)' do
      expect(subject[11]).to eq('2')
    end

    it 'uses pseudo values for misc tail values (ldr/20-23)' do
      expect(subject[20..23]).to eq('4500')
    end
  end
end
