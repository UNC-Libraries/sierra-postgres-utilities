# coding: utf-8
require_relative 'sierradb'

class SierraRecord
  attr_reader :rnum, :given_rnum, :record_id, :deleted, :warnings

  #@@conn = SierraDB
#
  #def self.conn
  #  @@conn
  #end

  def conn
    SierraDB
  end

  def initialize(rnum:, rtype:)
    # Must be given an rnum that does not include an actual check digit.
    #   Good: 'i2661010a', 'i26610102'
    #   Bad:  'i26610103'
    # If all goes well, creates a SierraWhatever object like so: 
    # <SierraItem:0x0000000001fd9728
    #  @inum="i2661010a",
    #  @deleted=false,
    #  @given_inum="i2661010a",
    #  @record_id="450974227090",
    #  @warnings=[]
    rnum = rnum.strip
    @given_rnum = rnum
    @warnings = []
    if rnum =~ /^#{self.rtype}[0-9]+a?$/
      @rnum = rnum.dup
      @rnum += 'a' unless rnum[-1] == 'a'
    else
      @warnings << "Cannot retrieve Sierra record. Rnum must start with #{self.rtype}"
      return
    end
    @record_id = get_record_id(@rnum)
    if @record_id == nil
      @warnings << 'No record was found in Sierra for this record number'
    end
    @warnings << 'This Sierra record was deleted'if @deleted
  end

  # @rnum           = i1094852a
  # rnum_trunc      = i1094852
  def rnum_trunc
    return nil unless @rnum
    return @rnum.chop
  end

  # @rnum           = i1094852a
  # inum_with_check = i10948521
  def rnum_with_check
    return nil unless @rnum
    return @rnum.chop + check_digit(self.recnum)
  end

  # @rnum           = i1094852a
  # recnum          = 1094852
  def recnum
    return nil unless @rnum
    return @rnum[/\d+/]
  end

  def get_record_id(rnum)
    recnum = rnum[/\d+/]
    # this is a cheaper query than using the reckey2id function, I believe
    # unless the calculation of a record_id when one isn't found is helpful
    #  in a way I'm missing (seems like a liability), prefer to not use
    #  that function --kms
    self.conn.make_query(
      "select id, deletion_date_gmt
      from sierra_view.record_metadata
      where record_type_code = \'#{self.rtype}\' 
      and record_num = \'#{recnum}\'"
    )
    if self.conn.results.values.empty?
      return nil
    else
      deletion_date = self.conn.results.values[0][1]
      @deleted = deletion_date ? true : false
      return self.conn.results.values[0][0]
    end
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
    return remainder == 10 ? 'x' : remainder.to_s
  end

  # returns array of sql varfield records
  # empty hash if no varfields
  def read_varfields
    query = <<-SQL
      select *
      from sierra_view.varfield v
      where v.record_id = '#{@record_id}'
      order by v.marc_tag, v.varfield_type_code, v.occ_num, v.id
    SQL
    self.conn.make_query(query)
    varfields = self.conn.results.entries.map { |entry|
      entry.collect { |k,v| [k.to_sym, v] }.to_h
    }
  end

  def varfields_sql
    @varfields_sql ||= self.read_varfields
  end

  # { varfield_type_code: array of field_content(s),... }
  # doesn't exclude marc varfields
  def varfields
    @varfields ||= self.vf
  end

  def vf
    vf = {}
    nonmarc = self.varfields_sql.
                   sort_by { |field|
      [field[:varfield_type_code], field[:occ_num], field[:id]]
    }
    nonmarc.each do |field|
      unless vf.include?(field[:varfield_type_code])
        vf[field[:varfield_type_code]] = []
      end
      vf[field[:varfield_type_code]] << field
    end
    vf
  end

  #excludes nonmarc varfields
  def marc_varfields
    @marc_varfields ||= self.marc_vf
  end

  
  def marc_vf
    vf = {}
    marc = self.varfields_sql.
                   select { |field| field[:marc_tag] }.
                   sort_by { |field|
      [field[:marc_tag], field[:occ_num], field[:id]]
    }
    marc.each do |field|
      unless vf.include?(field[:marc_tag])
        vf[field[:marc_tag]] = []
      end
      vf[field[:marc_tag]] << field
    end
    vf
  end

  def varfield(type_or_tag)
    self.varfields[type_or_tag] || self.marc_varfields[type_or_tag]
  end

  def varfield_value(type_or_tag)
    self.varfield(type_or_tag)&.
         map { |f| f[:field_content]}
  end

  def vf_helper(varfield_type: nil, varfield_tag: nil, value_only:)
    limiter = varfield_type || varfield_tag
    return nil unless limiter
    if value_only
      self.varfield_value(limiter)
    else
      self.varfield(limiter)
    end
  end

  def rec_data
    @rec_data ||= self.read_record(sql_name: self.sql_name)
  end

  def read_record(sql_name:)
    query = <<-SQL
      select *
      from sierra_view.#{sql_name}_record r
      where r.id = #{@record_id}
    SQL
    self.conn.make_query(query)
    @rec_data = self.conn.results.entries[0].collect { |k,v| [k.to_sym, v] }.to_h
  end

  def rec_metadata
    @rec_metadata ||= self.read_record_metadata
  end

  def read_record_metadata
    query = <<-SQL
      select *
      from sierra_view.record_metadata rm
      where rm.id = #{@record_id}
    SQL
    self.conn.make_query(query)
    @rec_data = self.conn.results.entries[0].collect { |k,v| [k.to_sym, v] }.to_h
  end

  def created_date(strformat: '%Y%m%d')
    raw = strip_date(date: self.rec_metadata[:creation_date_gmt])
    format_date(date: raw, strformat: strformat)
  end

  def updated_date(strformat: '%Y%m%d')
    raw = strip_date(date: self.rec_metadata[:record_last_updated_gmt])
    format_date(date: raw, strformat: strformat)
  end

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