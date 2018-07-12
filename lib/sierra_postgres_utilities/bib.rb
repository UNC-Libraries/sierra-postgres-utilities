# coding: utf-8

require_relative 'record'
require 'marc'
require_relative '../../ext/marc/record'
require_relative '../../ext/marc/datafield'

class SierraBib < SierraRecord
  attr_reader :bnum, :given_bnum, :multiple_LDRs_flag
  attr_accessor :stub, :items

  @rtype = 'b'
  @sql_name = 'bib'

  def self.rtype
    @rtype
  end

  def rtype
    self.class.rtype
  end

  def self.sql_name
    @sql_name
  end

  def sql_name
    self.class.sql_name
  end

# Must be given a bnum that does not include an actual check digit.
#   Good: 'b1094852a', 'b1094852'
#   Bad:  'b10948521'
# If all goes well, creates a SierraBib object like so:
# <SierraBib:0x0000000475d498
#   @given_rnum="b1094852a",
#   @warnings=[],
#   @rnum="b1094852a",
#   @rec_metadata={:id=>"420907889860", ... }
#   @given_bnum="b1094852a",
#   @bnum="b1094852a"
# >
  def initialize(bnum)
    super(rnum: bnum, rtype: rtype)
    @given_bnum = @given_rnum
    @bnum = @rnum
  end

  # @bnum           = b1094852a
  # bnum_trunc      = b1094852
  def bnum_trunc
    rnum_trunc
  end

  # @bnum           = b1094852a
  # bnum_with_check = b10948521
  def bnum_with_check
    rnum_with_check
  end

  # not the same value as iii's is_suppressed SQL field which
  # does not consider 'c' a suppression bcode3
  def suppressed?
    %w[d n c].include?(rec_data[:bcode3])
  end

  # cat_date(strformat: nil) yields DateTime obj
  def cat_date(strformat: '%Y%m%d')
    raw = strip_date(date: rec_data[:cataloging_date_gmt])
    format_date(date: raw, strformat: strformat)
  end

  # returns an array
  # where each element of the array
  # is a hash of one row of the query results, with an added extracted content
  # field
  #
  # 'tags' contains marc fields and associated subfields to be retrieved
  # it can be a string of a single tag (e.g '130' or '210abnp')
  # or an array of tags (e.g. ['130', '210abnp'])
  # if no subfields are listed, all subfields are retrieved
  # tag should consist of three characters, so '020' and never '20'
  def get_varfields(tags)
    tags = [tags] unless tags.is_a?(Array)
    makedict = {}
    tags.each do |entry|
      m = entry.match(/^(?<tag>[0-9]{3})(?<subfields>.*)$/)
      marc_tag = m['tag']
      subfields = m['subfields'] unless m['subfields'].empty?
      if makedict.include?(marc_tag)
        makedict[marc_tag] << subfields
      else
        makedict[marc_tag] = [subfields]
      end
    end
    tags = makedict
    tag_phrase = tags.map { |x| "'#{x[0].to_s}'" }.join(', ')
    query = <<-SQL
    select * from sierra_view.varfield v
    where v.record_id = #{record_id}
    and v.marc_tag in (#{tag_phrase})
    order by marc_tag, occ_num
    SQL
    conn.make_query(query)
    return nil if conn.results.entries.empty?
    varfields = conn.results.entries
    varfields.each do |varfield|
      varfield['extracted_content'] = []
      subfields = tags[varfield['marc_tag']]
      subfields.each do |subfield|
        varfield['extracted_content'] << extract_subfields(
          varfield['field_content'], subfield, trim_punct: true
        )
      end
    end
    varfields
  end

  # returns an array of the field_contents of the requested
  # tags/subfields
  def compile_varfields(tags)
    varfields = get_varfields(tags)
    return nil unless varfields
    compiled = varfields.map { |x| x['extracted_content'] }
    compiled.flatten!
    compiled.delete('')
    compiled
  end

  def compile_titles
    tags = %w[130abnp 210abnp 240abnp 242abnp 245abnp 246abnp 247abnp 730abnp]
    compile_varfields(record_id, tags)
  end

  def compile_authors
    tags = %w[100ac 110a 111a 511a 700ac 710a 711a 245c]
    compile_varfields(record_id, tags)
  end

  def subfield_from_field_content(subfield_tag, field_content)
    # returns first of a given subfield from varfield field_content string
    subfields = field_content.split('|')
    sf_hash = {}
    subfields.each do |sf|
      sf_hash[sf[0]] = sf[1..-1] unless sf_hash.include?(sf[0])
    end
    sf_hash[subfield_tag]
  end

  def extract_subfields(whole_field, desired_subfields, trim_punct: false)
    field = whole_field.dup
    desired_subfields ||= ''
    desired_subfields = desired_subfields.join if desired_subfields.is_a?(Array)
    # we don't assume anything before a valid subfield delimiter is |a, so
    # remove all from beginning to first pipe
    field.gsub!(/^[^|]*/, '')
    field.gsub!(/\|[^#{desired_subfields}][^|]*/, '') unless desired_subfields.empty?
    extraction = field.gsub(/\|./, ' ').lstrip
    extraction.sub!(/[.,;: \/]*$/, '') if trim_punct
    extraction
  end

  # field_content: "|aIDEBK|beng|erda|cIDEBK|dCOO"
  # returns:
  #   [["a", "IDEBK"], ["b", "eng"], ["e", "rda"], ["c", "IDEBK"], ["d", "COO"]]
  def subfield_arry(field_content)
    # TODO: assuming |a at beginning if no subfield present is correct here?
    # At least for trln_discovery extract, we do assume an implicit |a when the
    # data does not begin with another subfield and need to make that an
    # explicit |a
    field_content = field_content.insert(0, '|a') if field_content[0] != '|'
    arry = field_content.split('|')
    arry[1..-1].map { |x| [x[0], x[1..-1]] }
  end

  def get_marc_varfields
    marc_varfields
  end

  # Returns all of a records control fields
  def control_fields
    @control_fields ||= read_control_fields
  end

  # Returns all control fields as array of sql result hashes
  # Gathers 006/007/008 stored in control_field and any 00X in varfield)
  # Fields in control_field are given proper marc_tag and field_content entries
  # e.g.
  # [{:id=>"63824254", ... :marc_tag=>"001", ... :field_content=>"830511"},
  #  {:id=>"63824283", ... :marc_tag=>"003", ... :field_content=>"OCoLC"},
  #  {:id=>"90120881", ... :control_num=>"8", :p00=>"7", ...:marc_tag=>"008",
  #     :field_content=>"740314c19719999oncqr4p  s   f0   a0eng d"}]
  def read_control_fields
    return {} unless record_id
    var_control = marc_varfields.
                  select { |tag, _| tag =~ /^00/ }.
                  values.flatten
    query = <<-SQL
      select *
      from sierra_view.control_field cf
      where control_num in ('6', '7', '8') and record_id = #{record_id}
      order by cf.control_num, cf.varfield_type_code, cf.occ_num, cf.id ASC
    SQL
    conn.make_query(query)
    conn.results.entries.each do |entry|
      entry = entry.collect { |k, v| [k.to_sym, v] }.to_h
      control_num = entry[:control_num]
      next unless %w[6 7 8].include?(control_num)
      marc_tag = "00#{control_num}"
      value = entry.values[4..43].map(&:to_s).join
      value.strip! unless control_num == '8'
      entry[:marc_tag] = marc_tag
      entry[:field_content] = value
      var_control << entry
    end
    var_control
  end

  # returns leader as string
  def ldr
    return @ldr if @ldr
    read_ldr
    @ldr
  end

  # returns leader data as sql table hash
  def ldr_data
    @ldr_data ||= read_ldr
  end

  def blvl
    ldr_data[:bib_level_code]
  end

  def ctrl_type
    ldr_data[:control_type_code]
  end

  def rec_type
    ldr_data[:record_type_code]
  end

  def read_ldr
    return {} unless record_id
    # ldr building logic from: https://github.com/trln/extract_marcxml_for_argot_unc/blob/master/marc_for_argot.pl
    query = "select * from sierra_view.leader_field ldr where ldr.record_id = #{record_id}"
    conn.make_query(query)
    @multiple_LDRs_flag = true if conn.results.entries.length >= 2
    if conn.results.entries.empty?
      @ldr = nil
      @ldr_data = {}
      return @ldr_data
    end
    myldr = conn.results.entries.first.collect { |k, v| [k.to_sym, v] }.to_h
    @ldr = ldr_data_to_string(myldr)
    @ldr_data = myldr
  end

  def ldr_data_to_string(myldr)
    rec_status = myldr[:record_status_code]
    rec_type = myldr[:record_type_code]
    blvl = myldr[:bib_level_code]
    ctrl_type = myldr[:control_type_code]
    char_enc = myldr[:char_encoding_scheme_code]
    elvl = myldr[:encoding_level_code]
    desc_form = myldr[:descriptive_cat_form_code]
    multipart = myldr[:multipart_level_code]
    base_address = myldr[:base_address].rjust(5, '0')
    # for data below, we use default or fake values
    rec_length = '00000'
    indicator_ct = '2'
    subf_ct = '2'
    ldr_end = '4500'
    @ldr = "#{rec_length}#{rec_status}#{rec_type}#{blvl}#{ctrl_type}"   \
           "#{char_enc}#{indicator_ct}#{subf_ct}#{base_address}#{elvl}" \
           "#{desc_form}#{multipart}#{ldr_end}"
  end

  def bcode1_blvl
    # this usually, but not always, is the same as LDR/07(set as @blvl)
    # and in cases where they do not agree, it has seemed that
    # MAYBE bcode1 is more accurate and iii failed to update the LDR/07
    rec_data[:bcode1]
  end

  def mat_type
    rec_data[:bcode2]
  end

  def bib_locs
    @bib_locs ||= get_bib_locs
  end

  # returns array of strings
  def get_bib_locs
    return {} unless record_id
    query = <<-SQL
      select STRING_AGG(Trim(trailing FROM location_code), ';;;' order by id) AS bib_locs
      from   sierra_view.bib_record_location
      where location_code != 'multi' and bib_record_id = #{record_id}
    SQL
    conn.make_query(query)
    return nil unless conn.results.entries
    conn.results.entries.first['bib_locs'].split(';;;')
  end

  def mrk
    marc.to_mrk
  end

  def marchash
    mh = {}
    mh['leader'] = ldr
    mh['fields'] = []

    # add control fields stored in control_field or varfield
    control_fields.each do |cf|
      mh['fields'] << [cf[:marc_tag], cf[:field_content]]
    end

    # add data fields stored in varfield
    var_varfield =
      marc_varfields.
      reject { |tag, _| tag =~ /^00/ }.
      values.flatten
    var_varfield.each do |vf|
      mh['fields'] << [vf[:marc_tag], vf[:marc_ind1], vf[:marc_ind2],
                       subfield_arry(vf[:field_content].strip)]
    end
    mh
  end

  def marc
    @marc ||= MARC::Record.new_from_marchash(marchash)
  end

  # deprecated
  # returns [008/35-37, full language name]
  # if invalid language code, returns [008/35-37, nil]
  def lang008
    @marc.language_from_008
  end

  def oclcnum
    # This method allows us to get oclcnum without doing
    #   any kind of explicit find_oclcnum first
    # We could also set the oclcnum manually and have that
    #   given value returned
    @oclcnum ||= marc.oclcnum
  end

  def stub
    return @stub if @stub
    @stub = MARC::Record.new
    @stub << MARC::DataField.new('907', ' ', ' ', ['a', ".#{@bnum}"])
    load_note = 'Batch load history: 999 Something records loaded 20180000, xxx.'
    @stub << MARC::DataField.new('944', ' ', ' ', ['a', load_note])
    @stub
  end

  # sets and returns @items as array of attached irecs as SierraItem objects
  def items
    @items ||= get_attached(rtype: 'i')
  end

  # sets and returns @orders as array of attached irecs as SierraOrder objects
  def orders
    @orders ||= get_attached(rtype: 'o')
  end

  # sets and returns @holdings as array of attached irecs as SierraHoldings
  #   objects
  def holdings
    @holdings ||= get_attached(rtype: 'c')
  end

  # returns array of attached [rtype] records as Sierra[Type] objects
  def get_attached(rtype:)
    return {} unless record_id
    case rtype
    when 'i'
      sql_name = 'item'
      klass = SierraItem
    when 'c'
      sql_name = 'holding'
      klass = SierraHoldings
    when 'o'
      sql_name = 'order'
      klass = SierraOrder
    end
    attached_query = <<-SQL
      select \'#{rtype}\' || rm.record_num || 'a' as rnum
      from sierra_view.bib_record b
      inner join sierra_view.bib_record_#{sql_name}_record_link link on link.bib_record_id = b.id
      inner join sierra_view.record_metadata rm on rm.id = link.#{sql_name}_record_id
      where b.id = #{record_id}
      order by link.#{sql_name}s_display_order ASC
    SQL
    conn.make_query(attached_query)
    attached = conn.results.values.flatten.map { |rnum| klass.new(rnum) }
    attached = nil if attached.empty?
    attached
  end

  def proper_506s(strict: true, yield_errors: false)
    need_x = collections.length > 1
    p506s = collections.map { |c| c.m506(include_x: need_x) }.uniq
    return p506s unless strict
    errors = collections.map(&:m506_error).uniq.compact
    if errors.empty?
      p506s
    elsif yield_errors
      errors
    end
  end

  def extra_506s(whitelisted: [])
    extra = proper_506s.sort - marc.fields('506')
    extra - whitelisted
  end

  def lacking_506s
    marc.fields('506') - proper_506s.sort
  end

  def collections
    @collections ||= get_collections
  end

  def get_collections
    require_relative 'ebook_collections'
    my_colls = marc.fields('773')
    my_colls.reject! do |f|
      f.value =~ /^OCLC WorldShare Collection Manager managed collection/
    end
    my_colls.map! { |m773| EbookCollections.colls[m773['t']] }
    my_colls.delete(nil)
    @collections = my_colls
  end
end
