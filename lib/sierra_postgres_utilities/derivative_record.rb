# Derive alternate system bib record from Sierra bib
#
# For example, take a Sierra bib and attached records and derive
# Google Books MARC/marcxml.
# Or combine with an Internet Archive record to derive MARC/marcxml
# conforming to HathiTrust ingest specs.
#
# Generally this gets subclassed to provide alternate system-specific
# transformations and checks.
#
# The major processes this class does are:
#   Modify/combine Sierra MARC into alternate marc
#   Allow for MARC quality-checks
#   Write the alternate marc to xml
class DerivativeRecord
  attr_reader :bnum, :warnings, :sierra, :smarc

  def initialize(sierra_bib)
    @warnings = []
    @sierra = sierra_bib
    @bnum = @sierra.bnum
    if @sierra.record_id.nil?
      warn('No record was found in Sierra for this bnum')
      return
    elsif @sierra.deleted?
      warn('Sierra bib for this bnum was deleted')
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
    altmarc = MARC::Record.new_from_marc(@smarc.to_marc)

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

  # This is to be defined in subclasses (when a 955 is supposed to carry
  # item/InternetArchive/whatever details)
  def my955
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
  #
  # Writes the MARC faithfully, except:
  #   datafields (not controlfields) are stripped of leading/trailing whitespace
  #   drops any 002/004/009 fields
  #   drops any datafields containing no subfields
  #   xml escapes reserved characters
  #
  # outfile: open outfile for marcxml
  # strict:
  #   true: perform any tests in check_marc and abort writing
  #     unless tests pass
  #   false: skip check_marc; never abort
  def manual_write_xml(outfile:, strict: true, strip_datafields: true)
    if strict
      check_marc
      return unless @warnings.empty?
    end

    ofile =
    if outfile.respond_to?(:write)
      outfile
    else
      File.open(outfile, 'w')
    end

    # strict is false here; we don't need to check_marc again since we
    # had the opportunity above.
    ofile.write(xml(strict: false, strip_datafields: strip_datafields))
  end

  def xml(strict: true, strip_datafields: true)
    if strict
      check_marc
      return unless @warnings.empty?
    end

    xml = ''
    marc = altmarc.to_a
    xml << "<record>\n"
    xml << "  <leader>#{altmarc.leader}</leader>\n" if altmarc.leader
    marc.each do |f|
      if f.tag =~ /^00/
        # only process /^00[135678]/ as control fields
        next if f.tag =~ /[249]$/  # drop these fields entirely

        data = escape_xml_reserved(f.value)
        xml << "  <controlfield tag='#{f.tag}'>#{data}</controlfield>\n"
      else
        # Don't write datafields where no subfield exists.
        # Note: This is not skipping fields with >= a single empty subfield
        #     e.g. not skipping "=856  42|u"
        #   This is skipping fields with no subfield
        #     e.g. skipping "=856  42|" and "=856  42"
        next if f.subfields.empty?

        xml << "  <datafield tag='#{f.tag}' ind1='#{f.indicator1}' ind2='#{f.indicator2}'>\n"
        f.subfields.each do |sf|
          data = escape_xml_reserved(sf.value)
          data.strip! if strip_datafields
          xml << "    <subfield code='#{sf.code}'>#{data}</subfield>\n"
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
