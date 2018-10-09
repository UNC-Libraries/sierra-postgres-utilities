# coding: utf-8
require_relative 'record'

class SierraOrder < SierraRecord
  attr_reader :onum, :given_onum, :suppressed

  include SierraPostgresUtilities::Views::Order

  @rtype = 'o'
  @sql_name = 'order'

  def initialize(rnum)
    super(rnum: rnum, rtype: rtype)
    @onum = @rnum
  end

  def suppressed?
    ocode3 == 'n'
  end

  def status_code
    order_record[:order_status_code]
  end

  def ocode3
    order_record[:ocode3]
  end

  def received_date
    strip_date(date: order_record[:received_date_gmt])
  end

  def cat_date
    strip_date(date: order_record[:catalog_date_gmt])
  end

  def location
    order_record_cmf.map { |e| e[:location_code] }
  end

  def number_copies
    order_record_cmf.map { |e| e[:copies] }
  end

  # set and returns array of records as Sierra[Type] objects.
  # nil when none exist
  #

  def bibs
    @bibs ||= get_attached(:bib, :bib_record_order_record_link)
  end

  # orders are attached to at most one bib
  def bib
    bibs&.first
  end
end
