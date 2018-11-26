# coding: utf-8
require_relative '../sierradb'

class SierraRecord
  attr_reader :rnum, :given_rnum, :deleted, :warnings

  include SierraPostgresUtilities::Views::Record
  include SierraPostgresUtilities::Helpers::Varfields

  def self.rtype
    @rtype
  end

  def self.sql_name
    @sql_name
  end

  def rtype
    self.class.rtype || @rnum[0]
  end

  def sql_name
    self.class.sql_name
  end

  def initialize(rnum: nil, rtype: nil)
    # Must be given an rnum that does not include an actual check digit.
    #   Good: 'i2661010a', 'i26610102'
    #   Bad:  'i26610103'
    # If all goes well, creates a SierraWhatever object like so:
    # <SierraBib:0x0000000475d498
    #   @given_rnum="b1094852a",
    #   @warnings=[],
    #   @rnum="b1094852a",
    #   @record_metadata= #<Struct id="420907986691", ...
    # >
    rnum = rnum.strip
    @given_rnum = rnum
    @warnings = []
    if rnum =~ /^#{rtype}[0-9]+a?$/
      @rnum = rnum.dup
      @rnum << 'a' unless rnum.end_with?('a')
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
    @record_id ||= record_metadata[:id]
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

  # Returns all varfields (non-marc and marc)
  #   { varfield_type_code: array of field_content(s),... }
  # empty array when no such varfields
  def varfields(type_or_tag = nil, value_only: false)
    arry =
      if type_or_tag
        varfields_by_type[type_or_tag] || marc_varfields[type_or_tag] || []
      else
        varfields_by_type.values.flatten
      end
    if value_only
      arry&.map { |f| f[:field_content] }
    else
      arry
    end
  end

  # Sets/returns hash of varfields with varfield_type tags as keys
  def varfields_by_type
    @varfields_by_type ||= type_vf
  end

  # Returns hash of varfields with varfield_type tags as keys
  def type_vf
    fields = varfield.sort_by { |field|
      [field[:varfield_type_code], field[:occ_num], field[:id]]
    }
    vf = fields.group_by { |f| f[:varfield_type_code] }
    vf.delete(nil)
    vf
  end

  # Sets/returns hash of marc varfields with marc_tag's as keys
  def marc_varfields
    @marc_varfields ||= marc_vf
  end

  # Returns hash of marc varfields with marc_tag's as keys
  def marc_vf
    vf = varfield.group_by { |f| f.marc_tag }
    vf.delete(nil)
    vf
  end

  # Returns hash of varfield_type_codes and their names
  # e.g., for items, { 'b' => 'Barcode', ...}
  def self.vf_codes(rtype: self.rtype)
    return @vf_codes if @vf_codes
    query = <<~SQL
      select t.code,
             case when n.name = '' then n.short_name else n.name end
      from sierra_view.varfield_type t
      inner join sierra_view.varfield_type_name n
        on n.varfield_type_id = t.id
      where t.record_type_code = '#{rtype}'
      order by t.code
    SQL
    SierraDB.make_query(query)
    @vf_codes = SierraDB.results.values.to_h
  end

  def vf_codes
    self.class.vf_codes(rtype: rtype)
  end

  def deleted?
    true if record_metadata.deletion_date_gmt
  end

  # Returns rec creation date
  def created_date
    record_metadata.creation_date_gmt
  end

  # Returns rec updated date
  def updated_date
    record_metadata.record_last_updated_gmt
  end

  # Returns array of attached Sierra[name] objects
  # empty array when none exist
  def get_attached(name, view)
    send(view).map { |r| SierraRecord.from_id(r.send("#{name}_record_id")) }
  end

  def self.from_id(id)
    return nil unless id
    values = SierraDB.conn.exec_prepared(
      'id_find_record_metadata',
      [id]
    ).first&.values
    return nil unless values
    metadata =
      SierraPostgresUtilities::Views::Record.record_metadata_struct.new(
        *values
      )
    rm_factory(metadata)
  end

  def self.rm_factory(record_metadata)
    rtype = record_metadata[:record_type_code]
    rnum = "#{rtype}#{record_metadata[:record_num]}a"
    rec = factory(rnum, rtype: rtype)
    rec.instance_variable_set("@read_record_metadata", record_metadata)
    rec
  end

  def self.factory(rnum, rtype: nil)
    rtype = rnum[0] unless rtype
    case rtype
    when 'b'
      SierraBib.new(rnum)
    when 'i'
      SierraItem.new(rnum)
    when 'c'
      SierraHoldings.new(rnum)
    when 'o'
      SierraOrder.new(rnum)
    when 'a'
      SierraAuthority.new(rnum)
    when 'p'
      SierraPatron.new(rnum)
    end
  end

  def self.from_phrase_search(index:, entry:)
    regexp = "^#{index}#{entry.downcase}"
    recs = SierraDB.conn.exec_prepared('search_phrase_entry', [regexp]).
                         column_values(0).
                         map { |id| SierraRecord.from_id(id)}
    return recs if recs.length > 1
    return if recs.empty?
    recs.first
  end

  def self.from_create_list(listnum)
    query = <<~SQL
      select record_metadata_id
      from sierra_view.bool_set
      where bool_info_id = #{listnum}
    SQL
    recs = SierraDB.make_query(query).
                    column_values(0).
                    map! { |id| SierraRecord.from_id(id)}
    return if recs.empty?
    recs
  end


  # items = SierraItem.by_field(:location_code, 'aahd')
  # items = SierraRecord.by_field(:itype_code_num, '87', sqlname: 'item')
  # bibs = SierraBib.by_field(:bcode3, 'c')
  def self.by_field(field, criteria, sqlname: nil)
    sqlname = sqlname || sql_name
    criteria = [criteria] unless criteria.is_a?(Array)
    query = <<~SQL
      select id
      from sierra_view.#{sqlname}_record
      where #{field} in ('#{criteria.join("', '")}')
    SQL
    SierraDB.make_query(query).
             column_values(0).
             map! { |rid| SierraRecord.from_id(rid) }
  end

  # SierraBib.random.best_title
  # SierraRecord.random(sqlname: 'item')
  # SierraItem.random(limit: 10).map { |i| i.barcodes.first }
  def self.random(limit: 1, sqlname: nil)
    sqlname = sqlname || sql_name
    query = <<~SQL
      select id
      from sierra_view.#{sqlname}_record
      where random() < 0.01
      limit 10000
    SQL
    SierraDB.make_query(query)
    recs = SierraDB.results.column_values(0).
                            sort_by { |x| rand }[0..-1+limit].
                            map! { |rid| SierraRecord.from_id(rid) }
    return recs if recs.length > 1
    recs.first
  end

  def self.each
    SierraDB.send(:"#{sql_name}_record").
             each.
             lazy.
             map { |r| SierraRecord.from_id(r.id) }
  end
end
