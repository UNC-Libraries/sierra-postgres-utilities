# coding: utf-8
require_relative 'connect'
require_relative 'record'

class SierraHoldings < SierraRecord
  attr_reader :cnum, :given_cnum, :record_id, :deleted, :suppressed, :warnings

  @@rtype = 'c'
  @@sql_name =  'holding'



  def initialize(cnum)
    super(rnum: cnum, rtype: self.rtype)
    @cnum = @rnum
  end

  def rtype
    @@rtype
  end

  def sql_name
    @@sql_name
  end

  def suppressed?
    self.rec_data[:scode2] == 'n'
  end

end