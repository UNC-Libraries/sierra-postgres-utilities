require 'spec_helper'

module MARC
  RSpec.describe XMLHelper do
    describe '#escape_xml_reserved' do
      xit 'passes data to XMLHelper.escape_xml_reserved and returns result' do
      end
    end

    describe '.escape_xml_reserved' do
      it 'escapes ampersands' do
        data = 'foo&bar'
        expect(XMLHelper.escape_xml_reserved(data)).
          to eq('foo&amp;bar')
      end

      it 'escapes left/right angle brackets' do
        data = '<foo>'
        expect(XMLHelper.escape_xml_reserved(data)).
          to eq('&lt;foo&gt;')
      end

      it 'escapes single quotes' do
        data = "'foo'"
        expect(XMLHelper.escape_xml_reserved(data)).
          to eq('&apos;foo&apos;')
      end

      it 'escapes double quotes' do
        data = '"foo"'
        expect(XMLHelper.escape_xml_reserved(data)).
          to eq('&quot;foo&quot;')
      end
    end
  end
end
