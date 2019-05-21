require 'marc'
module MARC
  # Tools to add marc-xml headers/footers and escape xml.
  module XMLHelper
    # XML document header, to be followed with xml for each record(s)
    HEADER = <<~XML.freeze
      <?xml version='1.0'?>
      <collection xmlns='http://www.loc.gov/MARC21/slim' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xsi:schemaLocation='http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd'>
    XML

    # XML document footer, to follow xml the set of record(s)
    FOOTER = '</collection>'.freeze

    # XML-escapes ampersands, brackets, quotes in a string.
    #
    # @param [String] data
    # @return [String] escaped copy of given string
    def escape_xml_reserved(data)
      XMLHelper.escape_xml_reserved(data)
    end

    # (see #escape_xml_reserved)
    def self.escape_xml_reserved(data)
      return data unless data =~ /[<>&"']/
      data.
        gsub('&', '&amp;').
        gsub('<', '&lt;').
        gsub('>', '&gt;').
        gsub('"', '&quot;').
        gsub("'", '&apos;')
    end
  end
end
