# coding: utf-8
require_relative 'sierradb'

class SierraRecord
  attr_reader :rnum, :given_rnum, :deleted, :warnings

  def conn
    SierraDB
  end

  def initialize(rnum:, rtype:)
    # Must be given an rnum that does not include an actual check digit.
    #   Good: 'i2661010a', 'i26610102'
    #   Bad:  'i26610103'
    # If all goes well, creates a SierraWhatever object like so:
    # <SierraBib:0x0000000475d498
    #   @given_rnum="b1094852a",
    #   @warnings=[],
    #   @rnum="b1094852a",
    #   @rec_metadata={:id=>"420907889860", ... }
    # >
    rnum = rnum.strip
    @given_rnum = rnum
    @warnings = []
    if rnum =~ /^#{rtype}[0-9]+a?$/
      @rnum = rnum.dup
      @rnum += 'a' unless rnum[-1] == 'a'
    else
      @warnings << "Cannot retrieve Sierra record. Rnum must start with #{rtype}"
      return
    end
    if record_id.nil?
      @warnings << 'No record was found in Sierra for this record number'
    elsif deleted?
      @warnings << 'This Sierra record was deleted'
    end
  end

  # e.g. #<SierraBib:b9256886a>"
  def inspect
    "#<#{self.class.name}:#{rnum}>"
  end

  # @rnum           = i1094852a
  # rnum_trunc      = i1094852
  def rnum_trunc
    return nil unless @rnum
    @rnum.chop
  end

  # @rnum           = i1094852a
  # inum_with_check = i10948521
  def rnum_with_check
    return nil unless @rnum
    @rnum.chop + check_digit(recnum)
  end

  # @rnum           = i1094852a
  # recnum          = 1094852
  def recnum
    return nil unless @rnum
    @rnum[/\d+/]
  end

  # Returns record id
  # nil when record does not exist (e.g. given bad recnum)
  def record_id
    rec_metadata[:id]
  end

  def check_digit(recnum)
    digits = recnum.split('').reverse
    y = 2
    sum = 0
    digits.each do |digit|
      sum += digit.to_i * y
      y += 1
    end
    remainder = sum % 11
    if remainder == 10
      'x'
    else
      remainder.to_s
    end
  end

  # returns array of sql varfield records
  # empty hash if no varfields
  def read_varfields
    return {} unless record_id
    query = <<-SQL
      select *
      from sierra_view.varfield v
      where v.record_id = \'#{record_id}\'
      order by v.marc_tag, v.varfield_type_code, v.occ_num, v.id
    SQL
    conn.make_query(query)
    conn.results.entries.map { |entry|
      entry.collect { |k, v| [k.to_sym, v] }.to_h
    }
  end

  def varfield_data
    @varfield_data ||= read_varfields
  end

  # Returns all varfields (non-marc and marc)
  #   { varfield_type_code: array of field_content(s),... }
  # Is nil when no such varfields
  def varfields(type_or_tag = nil, value_only: false)
    @varfields ||= vf
    a =
      if type_or_tag
        @varfields[type_or_tag] || marc_varfields[type_or_tag]
      else
        @varfields
      end
    if value_only
      a&.map { |f| f[:field_content] }
    else
      a
    end
  end

  def vf
    vf = {}
    fields = varfield_data.sort_by { |field|
      [field[:varfield_type_code], field[:occ_num], field[:id]]
    }
    fields.each do |field|
      unless vf.include?(field[:varfield_type_code])
        vf[field[:varfield_type_code]] = []
      end
      vf[field[:varfield_type_code]] << field
    end
    vf
  end

  # Returns marc varfields
  def marc_varfields
    @marc_varfields ||= marc_vf
  end

  # Finds marc varfields
  def marc_vf
    vf = {}
    marc = varfield_data.select { |field| field[:marc_tag] }.
                         sort_by { |field|
      [field[:marc_tag], field[:varfield_type_code], field[:occ_num], field[:id]]
    }
    marc.each do |field|
      unless vf.include?(field[:marc_tag])
        vf[field[:marc_tag]] = []
      end
      vf[field[:marc_tag]] << field
    end
    vf
  end

  # Returns bib/item/etc data from [rectype]_record
  def rec_data
    @rec_data ||= read_record(sql_name: sql_name)
  end

  # Reads/sets rec data from [rectype]_record (e.g. bib_record; item_record)
  def read_record(sql_name:)
    return {} unless record_id
    query = <<-SQL
      select *
      from sierra_view.#{sql_name}_record r
      where r.id = #{record_id}
    SQL
    conn.make_query(query)
    return {} if conn.results.entries.empty?
    conn.results.entries[0].collect { |k,v| [k.to_sym, v] }.to_h
  end

  # Returns rec data from record_metadata
  def rec_metadata
    @rec_metadata ||= read_record_metadata
  end

  # Reads/sets rec data from record_metadata by recnum lookup
  def read_record_metadata
    return {} unless recnum
    query = <<-SQL
      select *
      from sierra_view.record_metadata rm
      where record_type_code = \'#{rtype}\'
      and record_num = \'#{recnum}\'
    SQL
    conn.make_query(query)
    return {} if conn.results.entries.empty?
    conn.results.entries.first.collect { |k,v| [k.to_sym, v] }.to_h
  end

  def deleted?
    rec_metadata[:deletion_date_gmt] ? true : false
  end

  # Returns rec creation date (default: as YYYMMDD string)
  # strformat of nil gets a DateTime object
  def created_date(strformat: '%Y%m%d')
    raw = strip_date(date: rec_metadata[:creation_date_gmt])
    format_date(date: raw, strformat: strformat)
  end

  # Returns rec updated date (default: as YYYMMDD string)
  # strformat of nil gets a DateTime object
  def updated_date(strformat: '%Y%m%d')
    raw = strip_date(date: rec_metadata[:record_last_updated_gmt])
    format_date(date: raw, strformat: strformat)
  end

  # Gets a DateTime object from a Sierra Postgres string
  # Most sierra dates seem to be:
  #   '2017-11-11 09:53:07-05'
  # Some seem to be (e.g. b4966956a updated date):
  #   '2017-11-11 09:53:07.666-05'
  def strip_date(date:)
    return DateTime.strptime(date,
                             '%Y-%m-%d %H:%M:%S%z')
  rescue ArgumentError
    #e.g. b4966956a updated date = '2017-11-11 09:53:07.666-05'
    return DateTime.strptime(date,
                             '%Y-%m-%d %H:%M:%S.%N%z')
  rescue TypeError
    return nil
  end

  def format_date(date:, strformat: nil)
    return nil unless date
    if strformat
      date.strftime(strformat)
    else
      date
    end
  end
end
