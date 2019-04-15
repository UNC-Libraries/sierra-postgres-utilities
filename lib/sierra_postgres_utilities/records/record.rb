# coding: utf-8
require_relative '../sierradb'

class SierraRecord
  attr_reader :rnum, :given_rnum, :deleted, :warnings
  attr_accessor :marc

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


  # Returns all of a record's control fields
  def control_fields
    @control_fields ||= compile_control_fields
  end

  # Returns all MARC control fields as array of sql result hashes
  # Gathers 006/007/008 stored in control_field and any 00X in varfield)
  # Fields in control_field are given proper marc_tag and field_content entries
  # e.g.
  # [{:id=>"63824254", ... :marc_tag=>"001", ... :field_content=>"830511"},
  #  {:id=>"63824283", ... :marc_tag=>"003", ... :field_content=>"OCoLC"},
  #  {:id=>"90120881", ... :control_num=>"8", :p00=>"7", ...:marc_tag=>"008",
  #     :field_content=>"740314c19719999oncqr4p  s   f0   a0eng d"}]
  def compile_control_fields
    return unless record_id
    control = marc_varfields.
                select { |tag, _| tag =~ /^00/ }.
                values.flatten
    control_field.each do |cf|
      control_num = cf.control_num
      next unless control_num.between?(6, 8)
      marc_tag = "00#{control_num}"
      cf = cf.to_h
      # specs contain stripping logic
      value = cf.values[4..43].map(&:to_s).join
      value = value[0..17] if control_num == 6
      value.rstrip! if control_num == 7
      cf[:marc_tag] = marc_tag
      cf[:field_content] = value
      control << cf
    end
    control
  end

  # returns leader as string
  # nil when no leader field
  # No bibs had >1 leader in oct 2018. We make an assumption it's not
  # possible.
  def ldr
    @ldr ||= ldr_data_to_string(leader_field)
  end

  def mrk
    marc.to_mrk
  end

  def marc
    @marc ||= get_marc
  end

  def get_marc
    m = MARC::Record.new
    m.leader = ldr if ldr


    # add control fields stored in control_field or varfield
    control_fields.each do |cf|
      m << MARC::ControlField.new(cf[:marc_tag], cf[:field_content])
    end

    # add datafields stored in varfield
    datafields =
      marc_varfields.
      reject { |tag, _| tag =~ /^00/ }.
      values.
      flatten
    datafields.each do |vf|
      m << MARC::DataField.new(vf[:marc_tag], vf[:marc_ind1], vf[:marc_ind2],
                       *subfield_arry(vf[:field_content].strip))
    end
    m
  end

  def ldr_data_to_string(myldr)
    return unless myldr.any?

    # harcoded values are default/fake values
    # ldr building logic from:
    # https://github.com/trln/extract_marcxml_for_argot_unc/blob/master/marc_for_argot.pl
    @ldr = [
      '00000'.freeze,  # rec_length
      myldr.record_status_code,
      myldr.record_type_code,
      myldr.bib_level_code,
      myldr.control_type_code,
      myldr.char_encoding_scheme_code,
      '2'.freeze,      # indicator count
      '2'.freeze,      # subf_ct
      myldr.base_address.to_s.rjust(5, '0'),
      myldr.encoding_level_code,
      myldr.descriptive_cat_form_code,
      myldr.multipart_level_code,
      '4500'.freeze    #ldr_end
    ].join
  end

  def vf_codes
    self.class.vf_codes(rtype: rtype)
  end

  def deleted?
    true if record_metadata['deletion_date_gmt']
  end

  def invalid?
    true if record_id.nil?
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
    links = [send(view)].flatten
    links.map { |r| SierraRecord.from_id(r.send("#{name}_record_id")) }
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
    return if recs.empty?
    recs
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
