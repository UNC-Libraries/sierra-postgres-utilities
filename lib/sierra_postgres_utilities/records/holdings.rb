# coding: utf-8
require_relative 'record'

class SierraHoldings < SierraRecord
  attr_reader :cnum, :given_cnum, :suppressed

  include SierraPostgresUtilities::Views::Holdings

  @rtype = 'c'
  @sql_name =  'holding'

  def initialize(rnum)
    super(rnum: rnum, rtype: rtype)
    @cnum = @rnum
  end

  def suppressed?
    # scode 2 == n or scode4 == n
    holding_record[:scode2] == 'n'
  end

  # set and returns array of records as Sierra[Type] objects.
  # empty array when none exist
  #

  def bibs
    @bibs ||= get_attached(:bib, :bib_record_holding_record_link)
  end

  # holdings are attached to at most one bib
  def bib
    bibs.first
  end

  def items
    @items ||= get_attached(:item, :holding_record_item_record_link)
  end
end
