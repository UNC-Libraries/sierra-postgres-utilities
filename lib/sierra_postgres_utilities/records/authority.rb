# coding: utf-8
require_relative 'record'

class SierraAuthority < SierraRecord
  attr_reader :anum, :given_anum, :suppressed

  include SierraPostgresUtilities::Views::Authority

  @rtype = 'a'
  @sql_name = 'authority'

  def initialize(rnum)
    super(rnum: rnum, rtype: rtype)
    @anum = @rnum
  end

  def suppressed?
    authority_record.is_suppressed
  end

end
