# coding: utf-8
require_relative 'record'

class SierraItem < SierraRecord
  attr_reader :inum, :given_inum

  @@rtype = 'i'
  @@sql_name = 'item'

  # These map codes to descriptions/text. They are read live from the
  # postgres DB are populated when needed.
  @@itype_code_map = nil
  @@location_code_map = nil
  @@status_code_map = nil

  def initialize(inum)
    # Must be given an inum that does not include an actual check digit.
    #   Good: 'i2661010a', 'i2661010'
    #   Bad:  'i26610103'
    # If all goes well, creates a SierraItem object like so:
    # <SierraItem:0x00000004527930
    # @given_rnum="i2661010a",
    # @warnings=[],
    # @rnum="i2661010a",
    # @rec_metadata={:id=>"450974227090", ...},
    # @given_inum="i2661010a",
    # @inum="i2661010a">
    super(rnum: inum, rtype: rtype)
    @given_inum = @given_rnum
    @inum = @rnum
  end

  def rtype
    @@rtype
  end

  def sql_name
    @@sql_name
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
    varfields('b', value_only: value_only)
  end

  # array of "Library" varfields, nil when none exist
  def varfield_librarys(value_only: true)
    varfields('f', value_only: value_only)
  end

  # array of Stats fields, nil when none exist
  def stats_fields(value_only: true)
    varfields('j', value_only: value_only)
  end

  #array of message fields, nil when none exist
  def messages(value_only: true)
    varfields('m', value_only: value_only)
  end

  # array of volume fields, nil when none exist
  def volumes(value_only: true)
    varfields('v', value_only: value_only)
  end

  # array of internal notes fields, nil when none exist
  def internal_notes(value_only: true)
    varfields('x', value_only: value_only)
  end

  # array of public_notes fields, nil when none exist
  def public_notes(value_only: true)
    varfields('z', value_only: value_only)
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
    data = varfields('c', value_only: value_only)
    #varfield_type = 'c'
    #data = vf_helper(varfield_type: varfield_type, value_only: value_only)
    if value_only && !keep_delimiters
      data&.map { |x| x.gsub(/\|./, '').strip }
    else
      data
    end
  end

  def icode2
    rec_data[:icode2]
  end

  def itype_code
    rec_data[:itype_code_num]
  end

  def location_code
    rec_data[:location_code]
  end

  def status_code
    rec_data[:item_status_code]
  end

  def copy_num
    rec_data[:copy_num]
  end

  def suppressed?
    rec_data[:is_suppressed] == 't'
  end

  # Returns checkout data and reads/sets it if it hasn't already been read.
  #
  # Default is to remove the patron_record_id from the data. Without the
  # patron_record_id, ptype and checkout_gmt are the most de-anonymizing fields.
  def checkout_data(drop_patron: true)
    if @checkout_data
      return @checkout_data
    # items not checked out have no checkout data
    # read a flag so we don't recheck
    elsif @queried_checkout_data
      return nil
    else
      @checkout_data ||= read_checkout(drop_patron: drop_patron)
    end
  end

  # Reads checkout data.
  #
  # Default is to remove the patron_record_id from the data. Without the
  # patron_record_id, ptype and checkout_gmt are the most de-anonymizing fields.
  def read_checkout(drop_patron: true)
    return {} unless record_id
    query = <<-SQL
      select *
      from sierra_view.checkout c
      where c.item_record_id = #{record_id}
    SQL
    conn.make_query(query)
    # items not checked out have no checkout data
    # set a flag so we don't recheck
    @queried_checkout_data = true
    data = conn.results.entries[0]&.collect { |k,v| [k.to_sym, v] }.to_h
    data.delete(:patron_record_id) if drop_patron
    data
  end

  def due_date(strformat: '%Y%m%d')
    return nil unless checkout_data
    raw = strip_date(date: checkout_data[:due_gmt])
    format_date(date: raw, strformat: strformat)
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
    SierraDB.make_query(
      'select code, name
      from sierra_view.itype_property_myuser
      order by code ASC'
    )
    @@itype_code_map = SierraDB.results.values.to_h
  end

  def self.load_location_descs
    SierraDB.make_query(
      'select code, name
      from sierra_view.location_myuser
      order by code ASC'
    )
    @@location_code_map = SierraDB.results.values.to_h
  end

  def self.load_status_descs
    SierraDB.make_query(
      'select code, name
      from sierra_view.item_status_property_myuser
      order by code ASC'
    )
    @@status_code_map = SierraDB.results.values.to_h
  end

    def is_oca?
      stats_fields&.any? { |x| x.match(/OCA electronic (?:book|journal)/i) }
    end
end
