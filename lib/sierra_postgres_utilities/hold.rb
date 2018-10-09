# coding: utf-8
class SierraHold
  attr_accessor :id

  include SierraPostgresUtilities::Views::Hold
  include SierraPostgresUtilities::Helpers

  def initialize(id)
    @id = id
  end

  def self.status_desc(status_code)
    case status_code
    when '0'
      'On hold.'
    when 'i', 'b', 'j'
      'Ready for pickup.'
    when 't'
      'In transit to pickup.'
    end
  end

  def status_desc
    self.class.status_desc(hold.status)
  end

  def placed_date
    @placed_date ||= strip_date(date: hold.placed_gmt)
  end

  def object # the item/bib/volume on hold
    @object ||= SierraRecord.from_id(hold.record_id)
  end

  # 'item' or 'bib'; volume holds return nil
  def type
    object&.sql_name
  end

  def patron
    @patron ||= SierraPatron.from_id(hold.patron_record_id)
  end
end
