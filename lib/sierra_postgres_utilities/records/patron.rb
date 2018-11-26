# coding: utf-8
require_relative 'record'

class SierraPatron < SierraRecord
  attr_reader :pnum, :given_pnum

  include SierraPostgresUtilities::Views::Patron

  @rtype = 'p'
  @sql_name = 'patron'

  # These map codes to descriptions/text. They are read live from the
  # postgres DB are populated when needed.
  @@ptype_code_map = nil

  def initialize(rnum)
    super(rnum: rnum, rtype: rtype)
    @pnum = @rnum
  end

  def ptype_code
    patron_record[:ptype_code]
  end

  def pcode3
    patron_record[:pcode3_code]
  end

  def expired?
    expiration_date <= Date.today
  end

  def expiration_date
    patron_record[:expiration_date_gmt]
  end

  def emails(value_only: true)
    varfields('z', value_only: value_only)
  end

  def email
    emails.first
  end

  def barcodes(value_only: true)
    varfields('b', value_only: value_only)
  end

  def barcode
    barcodes.first
  end

  # Lastname Firstname Middlename Suffix
  def fullname_concat_reverse
    f = patron_record_fullname.first
    return unless f
    "#{f[:last_name]} #{f[:first_name]} #{f[:middle_name]} #{f[:suffix_name]}".
      gsub(/\s+/, ' ').
      strip
  end

  # Firstname Middlename Lastname Suffix
  def fullname_concat
    f = patron_record_fullname.first
    return unless f
    "#{f[:first_name]} #{f[:middle_name]} #{f[:last_name]} #{f[:suffix_name]}".
      gsub(/\s+/, ' ').
      strip
  end

  def ptype_description
    self.class.load_ptype_descs unless @@ptype_code_map
    @@ptype_code_map[ptype_code]
  end

  def self.load_ptype_descs
    @@ptype_code_map = SierraDB.ptype_property_myuser.
                                map { |x| [x.value, x.name] }.
                                to_h
  end
end
