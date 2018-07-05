# coding: utf-8
require_relative 'record'

class SierraOrder < SierraRecord
  attr_reader :onum, :given_onum, :suppressed

  @@rtype = 'o'
  @@sql_name =  'order'

  def initialize(onum)
    super(rnum: onum, rtype: self.rtype)
    @onum = @rnum
  end

  def rtype
    @@rtype
  end

  def sql_name
    @@sql_name
  end

  def suppressed?
    self.ocode3 == 'n'
  end

  def status_code
    self.rec_data[:order_status_code]
  end

  def ocode3
    self.rec_data[:ocode3]
  end

  def received_date(strformat: '%Y%m%d')
    raw = strip_date(date: self.rec_data[:received_date_gmt])
    format_date(date: raw, strformat: strformat)
  end

  def cat_date(strformat: '%Y%m%d')
    raw = strip_date(date: self.rec_data[:catalog_date_gmt])
    format_date(date: raw, strformat: strformat)
  end

  def cmf_data
    @cmf_data ||= self.read_cmf
  end

  def read_cmf
    query = <<-SQL
      select *
      from sierra_view.order_record_cmf cmf
      where cmf.order_record_id = #{@record_id}
    SQL
    self.conn.make_query(query)
    @cmf_data = self.conn.results.entries.map { |entry|
      entry.collect { |k,v| [k.to_sym, v] }.to_h
    }
  end

  def location
    self.cmf_data.map { |e| e[:location_code] }
  end

  def number_copies
    self.cmf_data.map { |e| e[:copies] }
  end


end
