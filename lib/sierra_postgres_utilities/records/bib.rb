# coding: utf-8

require_relative 'record'
require 'marc'
require_relative '../../../ext/marc/record'
require_relative '../../../ext/marc/datafield'

class SierraBib < SierraRecord
  attr_reader :bnum, :given_bnum, :multiple_LDRs_flag
  attr_accessor :stub, :items

  include SierraPostgresUtilities::Views::Bib

  @rtype = 'b'
  @sql_name = 'bib'

# Must be given a bnum that does not include an actual check digit.
#   Good: 'b1094852a', 'b1094852'
#   Bad:  'b10948521'
# If all goes well, creates a SierraBib object like so:
# <SierraBib:0x0000000475d498
#   @given_rnum="b1094852a",
#   @warnings=[],
#   @rnum="b1094852a",
#   @record_metadata=#<OpenStruct id=>"420907889860", ... }
#   @given_bnum="b1094852a",
#   @bnum="b1094852a"
# >
  def initialize(rnum)
    super(rnum: rnum, rtype: rtype)
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
    %w[d n c].include?(bib_record[:bcode3])
  end

  # Returns cate_date as Time object
  def cat_date
    strip_date(date: bib_record[:cataloging_date_gmt])
  end

  # deprecated
  def get_marc_varfields
    marc_varfields
  end

  # Returns all of a record's control fields
  def control_fields
    @control_fields ||= compile_control_fields
  end

  # Returns all MARC control fields as array of OpenStruct'd sql result hashes
  # Gathers 006/007/008 stored in control_field and any 00X in varfield)
  # Fields in control_field are given proper marc_tag and field_content entries
  # e.g.
  # [{:id=>"63824254", ... :marc_tag=>"001", ... :field_content=>"830511"},
  #  {:id=>"63824283", ... :marc_tag=>"003", ... :field_content=>"OCoLC"},
  #  {:id=>"90120881", ... :control_num=>"8", :p00=>"7", ...:marc_tag=>"008",
  #     :field_content=>"740314c19719999oncqr4p  s   f0   a0eng d"}]
  def compile_control_fields
    return {} unless record_id
    control = marc_varfields.
                select { |tag, _| tag =~ /^00/ }.
                values.flatten
    control_field.each do |cf|
      control_num = cf.control_num
      next unless %w[6 7 8].include?(control_num)
      marc_tag = "00#{control_num}"
      value = cf.to_h.values[4..43].map(&:to_s).join
      value.strip! unless control_num == '8'
      cf.marc_tag = marc_tag
      cf.field_content = value
      control << cf
    end
    control
  end

  # returns leader as string
  # nil when no leader field
  # No bibs had >1 leader in oct 2018. We make an assumption it's not
  # possible.
  def ldr
    @ldr ||= ldr_data_to_string(leader_field)
  end


  def rec_type #LDR/06
    leader_field.record_type_code
  end

  def blvl #LDR/07
    leader_field.bib_level_code
  end

  def ctrl_type #LDR/08
    leader_field.control_type_code
  end

  def ldr_data_to_string(myldr)
    return nil if myldr.to_h.empty?

    # harcoded values are default/fake values
    # ldr building logic from:
    # https://github.com/trln/extract_marcxml_for_argot_unc/blob/master/marc_for_argot.pl
    @ldr = [
      '00000',  # rec_length
      myldr.record_status_code,
      myldr.record_type_code,
      myldr.bib_level_code,
      myldr.control_type_code,
      myldr.char_encoding_scheme_code,
      '2',      # indicator count
      '2',      # subf_ct
      myldr.base_address.rjust(5, '0'),
      myldr.encoding_level_code,
      myldr.descriptive_cat_form_code,
      myldr.multipart_level_code,
      '4500'    #ldr_end
    ].join
  end

  def bcode1_blvl
    # this usually, but not always, is the same as LDR/07(set as @blvl)
    # and in cases where they do not agree, it has seemed that
    # MAYBE bcode1 is more accurate and iii failed to update the LDR/07
    bib_record[:bcode1]
  end

  def mat_type
    bib_record[:bcode2]
  end

  # Returns array of strings
  # excludes "multi" as a location
  # e.g. ["dd", "tr"]
  def bib_locs
    bib_record_location.map { |r| r.location_code }.
                        reject { |x| x == 'multi' }
  end

  # returns iii-determines best title
  # by descending preference:
  #   The first t-tagged MARC 245 field; 245$abghnp
  #   The first t-tagged non-MARC field.
  #   The first t-tagged MARC field other than 245
  #     ( any subfields indexed for the t index display.)
  #
  # e.g. "Something else : a novel"
  def best_title
    bib_record_property.best_title
  end

  # returns iii-determines best author
  # by descending preference:
  #   The first a-tagged MARC 1XX field.
  #   The first b-tagged MARC 7XX field.
  #   The first a-tagged MARC 7XX field.
  #   The first a-tagged non-MARC field.
  #
  # e.g. "Fassnidge, Virginia."
  def best_author
    bib_record_property.best_author
  end

  # Returns cleaned value of first 260/264 field
  # e.g. "London : Constable, 1981."
  def imprint
    field_content = (marc_varfields['260'].to_a + marc_varfields['264'].to_a).
                      sort_by { |f| f[:occ_num] }.
                      first[:field_content]
    extract_subfields(field_content, nil)
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

    # add datafields stored in varfield
    datafields =
      marc_varfields.
      reject { |tag, _| tag =~ /^00/ }.
      values.
      flatten
    datafields.each do |vf|
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

  # Sets and returns array of records as Sierra[Type] objects.
  # nil when none exist

  def items
    @items ||= get_attached(:item, :bib_record_item_record_link)
  end

  def orders
    @orders ||= get_attached(:order, :bib_record_order_record_link)
  end

  def holdings
    @holdings ||= get_attached(:holding, :bib_record_holding_record_link)
  end


  def proper_506s(strict: true, yield_errors: false)
    return unless collections.first.unl? || collections.first.sersol?
    if collections.map(&:m506).map(&:to_s).uniq.count > 1
      p506s = []
      collections.each do |coll|
        coll506 = coll.m506(include_sf_3: true)
        next if p506s.map(&to_mrk).include?(coll506.to_mrk)
        p506s << coll506
      end
    else
      p506s = [collections.first.m506]
    end
    p506s&.compact!&.sort_by!(&:to_mrk)
    return p506s unless strict
    errors = collections.map(&:m506_error).uniq.compact
    if errors.empty?
      p506s
    elsif yield_errors
      errors
    end
  end

  def correct_506s?
    proper_506s == marc.fields('506').sort
  end

  def extra_506s(whitelisted: [])
    extra = marc.fields('506').sort - proper_506s.to_a
    extra - whitelisted
  end

  def lacking_506s
    proper_506s.to_a - marc.fields('506').sort
  end

  def collections
    @collections ||= get_collections
  end

  def m506_fix_output
    return if correct_506s?
    return unless proper_506s
    lack =
      if lacking_506s.empty?
        nil
      else
        lacking_506s.map(&:to_mrk).join(';;;')
      end
    extra =
      if extra_506s.empty?
        nil
      else
        extra_506s.map(&:to_mrk).join(';;;')
      end
    [@bnum, lack, extra]
  end

  def m506_error_output
    errors = collections.map(&:m506_error).uniq.compact
    unless errors.empty? ||
        (errors.count == 1 && errors.first.match(/Conc users varies by title/))
      [@bnum, errors.join(';;;')]
    end
  end

  def get_collections
    require_relative '../../../ebook_collections'
    my_colls = marc.fields('773')
    my_colls.reject! do |f|
      f.value =~ /^OCLC WorldShare Collection Manager managed collection/
    end
    my_colls.map! { |m773| CollData.colls[m773['t']] }
    my_colls.delete(nil)
    @collections = my_colls
  end

  def argot
    require_relative '../../../../TRLN-Discovery-ETL/lib/trln_discovery_etl.rb'
    @argot ||= get_argot
  end

  def get_argot
    @trln ||= TRLNDiscoveryRecord.new(self)
    @trln.argot
  end

  # Returns array of HT fulltext urls found via HT API
  #
  # There are only multiple urls when multiple matching
  # bib records exist in HT. When a HT bib record has multiple
  # items, we report the bib url, not one url for each item.
  # When a HT bib record has only a single fulltext item, we
  # report the item's direct url.
  def ht_urls
    SierraPostgresUtilities::Helpers::HathiTrust::APIQuery.new(
      oclcnums: [oclcnum],
      isbns: [argot["isbn"]&.map { |x| x["number"] }].flatten,
      level: :brief
    ).urls
  end
end
