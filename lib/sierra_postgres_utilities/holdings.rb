# coding: utf-8
require_relative 'record'

class SierraHoldings < SierraRecord
  attr_reader :cnum, :given_cnum, :suppressed

  @@rtype = 'c'
  @@sql_name =  'holding'



  def initialize(cnum)
    super(rnum: cnum, rtype: rtype)
    @cnum = @rnum
  end

  def rtype
    @@rtype
  end

  def sql_name
    @@sql_name
  end

  def suppressed?
    rec_data[:scode2] == 'n'
  end

end