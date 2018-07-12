# coding: utf-8
require_relative 'record'

class SierraOrder < SierraRecord
  attr_reader :onum, :given_onum, :suppressed

  @@rtype = 'o'
  @@sql_name = 'order'

  def initialize(onum)
    super(rnum: onum, rtype: rtype)
    @onum = @rnum
  end

  def rtype
    @@rtype
  end

  def sql_name
    @@sql_name
  end

  def suppressed?
    ocode3 == 'n'
  end

  def status_code
    rec_data[:order_status_code]
  end

  def ocode3
    rec_data[:ocode3]
  end

  def received_date(strformat: '%Y%m%d')
    raw = strip_date(date: rec_data[:received_date_gmt])
    format_date(date: raw, strformat: strformat)
  end

  def cat_date(strformat: '%Y%m%d')
    raw = strip_date(date: rec_data[:catalog_date_gmt])
    format_date(date: raw, strformat: strformat)
  end

  def cmf_data
    @cmf_data ||= read_cmf
  end

  def read_cmf
    return {} unless record_id
    query = <<-SQL
      select *
      from sierra_view.order_record_cmf cmf
      where cmf.order_record_id = #{@record_id}
    SQL
    conn.make_query(query)
    @cmf_data = conn.results.entries.map { |entry|
      entry.collect { |k, v| [k.to_sym, v] }.to_h
    }
  end

  def location
    cmf_data.map { |e| e[:location_code] }
  end

  def number_copies
    cmf_data.map { |e| e[:copies] }
  end
end
