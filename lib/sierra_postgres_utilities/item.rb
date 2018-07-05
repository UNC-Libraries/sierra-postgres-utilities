# coding: utf-8
require_relative 'record'

class SierraItem < SierraRecord
  attr_reader :inum, :given_inum, :suppressed

  @@rtype = 'i'
  @@sql_name = 'item'

  # These map codes to descriptions/text. They are read live from the
  # postgres DB are populated when needed.
  @@itype_code_map = nil
  @@location_code_map = nil
  @@status_code_map = nil

  
  def initialize(inum)
    # Must be given an inum that does not include an actual check digit.
    #   Good: 'i2661010a', 'i26610102'
    #   Bad:  'i26610103'
    # If all goes well, creates a SierraItem object like so: 
    # <SierraItem:0x0000000001fd9728
    #  @inum="i2661010a",
    #  @deleted=false,
    #  @given_inum="i2661010a",
    #  @record_id="450974227090",
    #  @warnings=[]>
    super(rnum: inum, rtype: self.rtype)
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
    self.rnum_trunc
  end

  # @inum           = i1094852a
  # inum_with_check = i10948521
  def inum_with_check
    self.rnum_with_check
  end

  # array of barcode fields, nil when none exist
  def barcodes(value_only: true)
    varfield_type = 'b'
    self.vf_helper(varfield_type: varfield_type, value_only: value_only)
  end

  # array of volume fields, nil when none exist
  def volumes(value_only: true)
    varfield_type = 'v'
    self.vf_helper(varfield_type: varfield_type, value_only: value_only)
  end

  # array of public_notes fields, nil when none exist
  def public_notes(value_only: true)
    varfield_type = 'z'
    self.vf_helper(varfield_type: varfield_type, value_only: value_only)
  end

  # array of internal notes fields, nil when none exist
  def internal_notes(value_only: true)
    varfield_type = 'x'
    self.vf_helper(varfield_type: varfield_type, value_only: value_only)
  end

  # array of Stats fields, nil when none exist
  def stats_fields(value_only: true)
    varfield_type = 'j'
    self.vf_helper(varfield_type: varfield_type, value_only: value_only)
  end

  # array of "Library" varfields, nil when none exist
  def varfield_librarys(value_only: true)
    varfield_type = 'f'
    self.vf_helper(varfield_type: varfield_type, value_only: value_only)
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
    varfield_type = 'c'
    data = self.vf_helper(varfield_type: varfield_type, value_only: value_only)
    if value_only && !keep_delimiters
      data&.map { |x| x.gsub(/\|./, '').strip }
    else
      data
    end
  end

  def icode2
    self.rec_data[:icode2]
  end

  def itype_code
    self.rec_data[:itype_code_num]
  end

  def location_code
    self.rec_data[:location_code]
  end

  def status_code
    self.rec_data[:item_status_code]
  end

  def copy_num
    self.rec_data[:copy_num]
  end

  def suppressed?
    self.rec_data[:is_suppressed] == 't'
  end

  def checkout_data(drop_patron: true)
    if @checkout_data
      return @checkout_data 
    # items not checked out have no checkout data
    # read a flag so we don't recheck
    elsif @queried_checkout_data
      return nil
    else
      @checkout_data ||= self.read_checkout(drop_patron: drop_patron)
    end
  end

  def read_checkout(drop_patron:)
    query = <<-SQL
      select c.due_gmt
      from sierra_view.checkout c
      where c.item_record_id = #{@record_id}
    SQL
    SierraDB.make_query(query)
    # items not checked out have no checkout data
    # set a flag so we don't recheck
    @queried_checkout_data = true
    @checkout_data = SierraDB.results.entries[0]&.collect { |k,v| [k.to_sym, v] }.to_h
  end

  def due_date(strformat: '%Y%m%d')
    return nil unless self.checkout_data
    raw = strip_date(date: self.checkout_data[:due_gmt])
    format_date(date: raw, strformat: strformat)
  end

  def itype_description
    self.class.load_itype_descs unless @@itype_code_map
    @@itype_code_map[self.itype_code]
  end

  def location_description
    self.class.load_location_descs unless @@location_code_map
    @@location_code_map[self.location_code]
  end

  def status_description
    self.class.load_status_descs unless @@status_code_map
    @@status_code_map[self.status_code].capitalize
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
      self.stats_fields&.any? { |x| x.match(/OCA electronic (?:book|journal)/i) }
    end
end