
class DerivativeRecord
  attr_reader :bnum, :warnings, :sierra, :smarc

  def initialize(sierra_bib)
    @warnings = []
    @sierra = sierra_bib
    @bnum = @sierra.bnum
    if @sierra.record_id.nil?
      self.warn('No record was found in Sierra for this bnum')
      return
    elsif @sierra.deleted?
      self.warn('Sierra bib for this bnum was deleted')
      return
    end
    @smarc = @sierra.marc
  end

  def altmarc
    @altmarc ||= get_alt_marc
  end

  # default marc transformation before export
  # suitable for hathi and google marcxml
  # otherwise, have a subclass overwrite it

  def get_alt_marc
    # copy Sierra MARC
    altmarc = MARC::Record.new_from_hash(@smarc.to_hash)

    # delete things
    altmarc.fields.delete_if { |f| f.tag =~ /001|003|9../ }

    # add things
    altmarc.append(
      MARC::ControlField.new('001', @bnum.chop) # chop trailing 'a'
    )
    altmarc.append(MARC::ControlField.new('003', 'NcU'))
    # look for oclcnum in sierra marc; not altmarc where we may have e.g.
    # just deleted the 001
    if @smarc.m035_lacks_oclcnum?
      altmarc.append(MARC::DataField.new('035', ' ', ' ',
                                         ['a', "(OCoLC)#{@smarc.oclcnum}"]))
    end
    altmarc.append(my955) if my955
    altmarc.sort
  end

  def warn(message)
    @warnings << message
    # if given garbage bnum, we want that to display in error
    # log rather than nothing
    bnum = @bnum || @sierra.given_bnum
    puts "#{bnum}\t#{message}\n"
  end

  # stub to be overwritten by subclass
  # perform any necessary marc (or record) checks
  #
  # example check:
  # if @smarc.no_leader?
  #   warn('This bib record has no Leader. A Leader field is required. Report to cataloging staff to add Leader to record.')
  # end

  def check_marc; end

  # Manually writes xml, with "sensible" whitespacing.
  #   whitespace in text nodes retained
  #   linebreaks added to make human readable
  # I believe options for in-built readers we tried were
  # either/or in those areas.
  # datafields (not controlfields) are stripped of leading/trailing whitespace
  #
  # outfile: open outfile for marcxml
  # strict:
  #   true: perform any tests in check_marc and abort writing
  #     unless tests pass
  #   false: skip check_marc; never abort
  # reverse_xml:
  # false: <datafield tag='#{f.tag}' ind1='#{f.indicator1}' ind2='#{f.indicator2}'>
  #  true: <datafield ind1='#{f.indicator1}' ind2='#{f.indicator2}' tag='#{f.tag}'>

  def manual_write_xml(options)
    xml = options[:outfile]
    if options[:strict]
      check_marc
      return unless @warnings.empty?
    end

    marc = altmarc.to_a
    xml << "<record>\n"
    xml << "  <leader>#{altmarc.leader}</leader>\n" if altmarc.leader
    marc.each do |f|
      if f.tag =~ /^00/
        # drop /00[249]
        if f.tag =~ /00[135678]/
          data = escape_xml_reserved(f.value)
          xml << "  <controlfield tag='#{f.tag}'>#{data}</controlfield>\n"
        end
      else
        xml << "  <datafield tag='#{f.tag}' ind1='#{f.indicator1}' ind2='#{f.indicator2}'>\n"
        f.subfields.each do |sf|
          data = escape_xml_reserved(sf.value)
          xml << "    <subfield code='#{sf.code}'>#{data.strip}</subfield>\n"
        end
        xml << "  </datafield>\n"
      end
    end
    xml << "</record>\n"
  end

  def escape_xml_reserved(data)
    return data unless data =~ /[<>&"']/
    data.
      gsub('&', '&amp;').
      gsub('<', '&lt;').
      gsub('>', '&gt;').
      gsub('"', '&quot;').
      gsub("'", '&apos;')
  end
end
