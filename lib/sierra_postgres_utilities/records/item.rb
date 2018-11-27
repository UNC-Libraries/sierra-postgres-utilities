# coding: utf-8
require_relative 'record'

class SierraItem < SierraRecord
  attr_reader :inum, :given_inum

  include SierraPostgresUtilities::Views::Item

  @rtype = 'i'.freeze
  @sql_name = 'item'.freeze

  # These map codes to descriptions/text. They are read live from the
  # postgres DB are populated when needed.
  @@itype_code_map = nil
  @@location_code_map = nil
  @@status_code_map = nil

  def initialize(rnum)
    # Must be given an inum that does not include an actual check digit.
    #   Good: 'i2661010a', 'i2661010'
    #   Bad:  'i26610103'
    # If all goes well, creates a SierraItem object like so:
    # <SierraItem:0x00000004527930
    # @given_rnum="i2661010a",
    # @warnings=[],
    # @rnum="i2661010a",
    # @record_metadata=#<OpenStruct id=>"450974227090", ...},
    # @given_inum="i2661010a",
    # @inum="i2661010a">
    super(rnum: rnum, rtype: rtype)
    @given_inum = @given_rnum
    @inum = @rnum
  end

  # @inum           = i1094852a
  # inum_trunc      = i1094852
  def inum_trunc
    rnum_trunc
  end

  # @inum           = i1094852a
  # inum_with_check = i10948521
  def inum_with_check
    rnum_with_check
  end

  # array of barcode fields, nil when none exist
  def barcodes(value_only: true)
    varfields('b'.freeze, value_only: value_only)
  end

  # array of "Library" varfields, nil when none exist
  def varfield_librarys(value_only: true)
    varfields('f'.freeze, value_only: value_only)
  end

  # array of Stats fields, nil when none exist
  def stats_fields(value_only: true)
    varfields('j'.freeze, value_only: value_only)
  end

  #array of message fields, nil when none exist
  def messages(value_only: true)
    varfields('m'.freeze, value_only: value_only)
  end

  # array of volume fields, nil when none exist
  def volumes(value_only: true)
    varfields('v'.freeze, value_only: value_only)
  end

  # array of internal notes fields, nil when none exist
  def internal_notes(value_only: true)
    varfields('x'.freeze, value_only: value_only)
  end

  # array of public_notes fields, nil when none exist
  def public_notes(value_only: true)
    varfields('z'.freeze, value_only: value_only)
  end

  # array of call number fields, nil when none exist
  # subfield delimiters are stripped unless keep_delimiters: true
  # e.g.
  # item.callnos                        => ["PR6056.A82 S6"]
  # item.callnos(keep_delimiters: true) => ["|aPR6056.A82 S6"]
  # item.callnos(value_only: false)     => [{
  #   :id=>"8978779", :record_id=>"450974227090", :varfield_type_code=>"c",
  #   :marc_tag=>"090", :marc_ind1=>" ", :marc_ind2=>" ", :occ_num=>"0",
  #   :field_content=>"|aPR6056.A82 S6"
  # }]
  def callnos(value_only: true, keep_delimiters: false)
    data = varfields('c'.freeze, value_only: value_only)
    if value_only && !keep_delimiters
      data&.map { |x| x.gsub(/\|./, '').strip }
    else
      data
    end
  end

  def icode2
    item_record[:icode2]
  end

  def itype_code
    item_record[:itype_code_num].to_s
  end

  def location_code
    item_record[:location_code]
  end

  def status_code
    item_record[:item_status_code]
  end

  def copy_num
    item_record[:copy_num]
  end

  def suppressed?
    item_record[:is_suppressed]
  end

  def checked_out?
    checkout.any?
  end

  def due_date
    return unless checked_out?
    checkout.due_gmt
  end

  def itype_description
    self.class.load_itype_descs unless @@itype_code_map
    @@itype_code_map[itype_code]
  end

  def location_description
    self.class.load_location_descs unless @@location_code_map
    @@location_code_map[location_code]
  end

  def status_description
    self.class.load_status_descs unless @@status_code_map
    @@status_code_map[status_code].capitalize
  end

  def self.load_itype_descs
    @@itype_code_map = SierraDB.itype_property_myuser.
                                map { |x| [x.code.to_s, x.name] }.
                                sort_by { |x| x.first.to_i }.
                                to_h
  end

  def self.load_location_descs
    @@location_code_map = SierraDB.location_myuser.
                                   map { |x| [x.code, x.name] }.
                                   sort.
                                   to_h
  end

  def self.load_status_descs
    @@status_code_map = SierraDB.item_status_property_myuser.
                                 map { |x| [x.code, x.name] }.
                                 sort.
                                 to_h
  end

  # set and returns array of records as Sierra[Type] objects.
  # empty array when none exist
  #

  def bibs
    @bibs ||= get_attached(:bib, :bib_record_item_record_link)
  end

  def holdings
    @holdings ||= get_attached(:holding, :holding_record_item_record_link)
  end

  def is_oca?
    stats_fields.any? { |x| x.match(/OCA electronic (?:book|journal)/i) }
  end
end
