# coding: utf-8
require_relative 'record'
require_relative 'connect'
require 'marc'
require_relative '../../ext/marc/record'
require_relative '../../ext/marc/datafield'


class SierraBib < SierraRecord
  attr_reader :record_id, :bnum, :m006, :m007s, :m008, :marc, :oclcnum, :blvl, :warnings, :given_bnum, :deleted, :multiple_LDRs_flag


  # use self.rec_data
  # @rec_data=
  # {"id"=>"420907889860",
  #  "record_id"=>"420907889860",
  #  "language_code"=>"eng",
  #  "bcode1"=>"m",
  #  "bcode2"=>"a",
  #  "bcode3"=>"-",
  #  "country_code"=>"enk",
  #  "index_change_count"=>"11",
  #  "is_on_course_reserve"=>"f",
  #  "is_right_result_exact"=>"f",
  #  "allocation_rule_code"=>"0",
  #  "skip_num"=>"4",
  #  "cataloging_date_gmt"=>"2004-10-01 00:00:00-04",
  #  "marc_type_code"=>" "}


  attr_accessor :stub, :items


  @rtype = 'b'
  @sql_name = 'bib'

  def self.rtype
    @rtype
  end

  def rtype
    self.class.rtype
  end

  def self.sql_name
    @sql_name
  end

  def sql_name
    self.class.sql_name
  end

  def initialize(bnum)
=begin
Must be given a bnum that does not include an actual check digit.
  Good: 'b1094852a', 'b1094852'
  Bad:  'b10948521'
If all goes well, creates a SierraBib object like so: 
<SierraBib:0x0000000001fd9728
 @bnum="b1094852a",
 @deleted=false,
 @given_bnum="b1094852",
 @record_id="420907889860",
 @warnings=[]>
=end    
    super(rnum: bnum, rtype: self.rtype)
    @given_bnum = @given_rnum
    @bnum = @rnum
  end

  # @bnum           = b1094852a
  # bnum_trunc      = b1094852
  def bnum_trunc
    self.rnum_trunc
  end

  # @bnum           = b1094852a
  # bnum_with_check = b10948521
  def bnum_with_check
    self.rnum_with_check
  end


  # not the same value as iii's is_suppressed SQL field which
  # does not consider 'c' a suppression bcode3
  def suppressed?
    %w(d n c).include?(self.rec_data[:bcode3])
  end

  # cat_date(strformat: nil) yields DateTime obj
  def cat_date(strformat: '%Y%m%d')
    raw = strip_date(date: self.rec_data[:cataloging_date_gmt])
    format_date(date: raw, strformat: strformat)
  end

  # returns an array
  # where each element of the array
  # is a hash of one row of the query results, with an added extracted content
  # field
  #
  # 'tags' contains marc fields and associated subfields to be retrieved
  # it can be a string of a single tag (e.g '130' or '210abnp')
  # or an array of tags (e.g. ['130', '210abnp'])
  # if no subfields are listed, all subfields are retrieved
  # tag should consist of three characters, so '020' and never '20'
  def get_varfields(tags)
    tags = [tags] unless tags.is_a?(Array)
    makedict = {}
    tags.each do |entry|
      m = entry.match(/^(?<tag>[0-9]{3})(?<subfields>.*)$/)
      marc_tag = m['tag']
      subfields = m['subfields'] unless m['subfields'].empty?
      if makedict.include?(marc_tag)
        makedict[marc_tag] << subfields
      else
        makedict[marc_tag] = [subfields]
      end
    end
    tags = makedict
    tag_phrase = tags.map { |x| "'" + x[0].to_s + "'"}.join(', ')
    query = <<-SQL
    select * from sierra_view.varfield v
    where v.record_id = #{@record_id}
    and v.marc_tag in (#{tag_phrase})
    order by marc_tag, occ_num
    SQL
    $c.make_query(query)
    return nil if $c.results.entries.empty?
    varfields = $c.results.entries
    varfields.each do |varfield|
      varfield['extracted_content'] = []
      subfields = tags[varfield['marc_tag']]
      subfields.each do |subfield|
        varfield['extracted_content'] << self.extract_subfields(varfield['field_content'], subfield, trim_punct: true)
      end
    end
    return varfields
  end

  # returns an array of the field_contents of the requested
  # tags/subfields
  def compile_varfields(tags)
    varfields = get_varfields(tags)
    return nil if !varfields
    compiled = varfields.map { |x| x['extracted_content']}
    compiled.flatten!
    compiled.delete("")
    return compiled
  end

  def compile_titles
    tags = ['130abnp', '210abnp', '240abnp', '242abnp',
            '245abnp', '246abnp', '247abnp', '730abnp']
    titles = compile_varfields(@record_id, tags)
  end
  
  def compile_authors
    tags = ['100ac', '110a', '111a', '511a', '700ac',
            '710a', '711a', '245c']
    authors = compile_varfields(@record_id, tags)
  end

  def subfield_from_field_content(subfield_tag, field_content)
    #returns first of a given subfield from varfield field_content string
    subfields = field_content.split("|")
    sf_hash = {}
    subfields.each do |sf|
      sf_hash[sf[0]] = sf[1..-1] unless sf_hash.include?(sf[0])
    end
    return sf_hash[subfield_tag]
  end

  def extract_subfields(whole_field, desired_subfields, trim_punct: false)
    field = whole_field.dup
    desired_subfields = '' if !desired_subfields
    desired_subfields = desired_subfields.join() if desired_subfields.is_a?(Array)
    # we don't assume anything before a valid subfield delimiter is |a, so remove
    # all from beginning to first pipe
    field.gsub!(/^[^|]*/, '')
    field.gsub!(/\|[^#{desired_subfields}][^|]*/, '') unless desired_subfields.empty?
    extraction = field.gsub(/\|./, ' ').lstrip
    extraction.sub!(/[.,;: \/]*$/, '') if trim_punct
    return extraction
  end

  # field_content: "|aIDEBK|beng|erda|cIDEBK|dCOO"
  # returns: [["a", "IDEBK"], ["b", "eng"], ["e", "rda"], ["c", "IDEBK"], ["d", "COO"]]
  def subfield_arry(field_content)
    #TODO: assuming |a at beginning if no subfield present is correct here?
    # At least for trln_discovery extract, we do assume an implicit |a when the
    # data does not begin with another subfield and need to make that an explicit
    # |a
    field_content = field_content.insert(0, '|a') if field_content[0] != '|'
    arry = field_content.split('|')
    return arry[1..-1].map { |x| [x[0], x[1..-1]] }
  end

  def get_marc_varfields
    self.marc_varfields
  end

  # just what iii has in sierra_view.control_field
  # i.e. 006, 007, 008; not 001, 003, 005
  # ordered by marc_tag, occ_num
  def read_control_fields
    query = <<-SQL 
      select *
      from sierra_view.control_field
      where control_num in ('6', '7', '8') and record_id = #{@record_id}
      order by occ_num ASC
    SQL
    $c.make_query(query)
    cf = {}
    m006s = $c.results.values.
                select { |r| r[3] == '6'}.
                map { |f| f[4..21].map{ |x| x.to_s }.join }
    m007s = $c.results.values.
                select { |r| r[3] == '7'}.
                map { |f| f[4..28].map{ |x| x.to_s }.join }
    m008s = $c.results.values.
                select { |r| r[3] == '8'}.
                map { |f| f[4..43].map{ |x| x.to_s }.join }
    cf[:m006s] = m006s unless m006s.empty?
    cf[:m007s] = m007s unless m007s.empty?
    cf[:m008s] = m008s unless m008s.empty?
    cf
  end

  # only sierra_view.control_fields (and only 006/007/008)
  def control_fields
    @control_fields ||= self.read_control_fields
  end

  def m006s
    self.control_fields[:m006s]
  end

  def m007s
    self.control_fields[:m007s]
  end

  def m008s
    self.control_fields[:m008s]
  end

  # returns leader as string
  def ldr
    return @ldr if @ldr
    self.read_ldr
    @ldr
  end

  # returns leader data as sql table hash
  def ldr_data
    @ldr_data ||= read_ldr
  end

  def blvl
    self.ldr_data[:bib_level_code]
  end

  def ctrl_type
    self.ldr_data[:ctrl_type]
  end

  def rec_type
    self.ldr_data[:rec_type]
  end

  # temp back compatability
  def get_ldr
    self.read_ldr
  end


  def read_ldr
    # ldr building logic from: https://github.com/trln/extract_marcxml_for_argot_unc/blob/master/marc_for_argot.pl
    query = "select * from sierra_view.leader_field ldr where ldr.record_id = #{@record_id}"
    $c.make_query(query)
    @multiple_LDRs_flag = true if $c.results.entries.length >= 2
    return nil if $c.results.entries.empty?
    myldr = $c.results.entries.first.collect { |k,v| [k.to_sym, v] }.to_h
    rec_status = myldr[:record_status_code]
    rec_type = myldr[:record_type_code]
    blvl = myldr[:bib_level_code]
    ctrl_type = myldr[:control_type_code]
    char_enc = myldr[:char_encoding_scheme_code]
    elvl = myldr[:encoding_level_code]
    desc_form = myldr[:descriptive_cat_form_code]
    multipart = myldr[:multipart_level_code]
    base_address = myldr[:base_address].rjust(5, '0')
    # for data below, we use default or fake values
    rec_length = '00000'
    indicator_ct = '2'
    subf_ct = '2'
    ldr_end = '4500'
    @ldr = "#{rec_length}#{rec_status}#{rec_type}#{blvl}#{ctrl_type}"   \
           "#{char_enc}#{indicator_ct}#{subf_ct}#{base_address}#{elvl}" \
           "#{desc_form}#{multipart}#{ldr_end}"
    @ldr_data = myldr
  end

  def bcode1_blvl
    # this usually, but not always, is the same as LDR/07(set as @blvl)
    # and in cases where they do not agree, it has seemed that
    # MAYBE bcode1 is more accurate and iii failed to update the LDR/07
    self.rec_data[:bcode1]
  end

  def mat_type
    self.rec_data[:bcode2]
  end

  def bib_locs
    @bib_locs ||= self.get_bib_locs
  end

  def get_bib_locs
    query = <<-SQL
      select STRING_AGG(Trim(trailing FROM location_code), ', ' order by id) AS bib_locs
      from   sierra_view.bib_record_location
      where location_code != 'multi' and bib_record_id = #{@record_id}
    SQL
    $c.make_query(query)
    return nil unless $c.results.entries
    return $c.results.entries.first['bib_locs']
  end

  def mrk
    self.marc.to_mrk
  end

  def marchash
    mh = {}
    mh['leader'] = self.ldr
    mh['fields'] = []
    # get any 001/003/005 control fields stored in sierra_view.varfield
    var_control = self.marc_varfields.
                       select { |tag, fields| tag =~ /^00/ }.
                       values.flatten
    var_varfield = self.marc_varfields.
                        reject { |tag, fields| tag =~ /^00/ }.
                        values.flatten
    var_control.each { |f| mh['fields'] << [f[:marc_tag], f[:field_content]] }
    self.m006s&.each { |field| mh['fields'] << ['006', field] }
    self.m007s&.each { |field| mh['fields'] << ['007', field] }
    self.m008s&.each { |field| mh['fields'] << ['008', field] }
    var_varfield.each do |field|
      mh['fields'] << [field[:marc_tag], field[:marc_ind1],
                       field[:marc_ind2],
                       self.subfield_arry(field[:field_content].strip)
                      ]
    end
    return mh
  end

  def marc
    @marc ||= MARC::Record.new_from_marchash(self.marchash)
  end

  def xmlify_varfield(tag, varfield_hash)
    ind1 = varfield_hash[:ind1]
    ind2 = varfield_hash[:ind2]
    field_content = varfield_hash[:field_content]
    subfields = self.subfield_arry(field_content)
    xml = "<datafield tag=\"#{tag}\" ind1=\"#{ind1}\" ind2=\"#{ind2}\">\n"
    subfields.each do |subfield, content|
      xml += "  <subfield code=\"#{subfield}\">#{content}</subfield>\n"
    end
    xml += "</datafield>"
    return xml
  end

  # returns [008/35-37, full language name]
  # if invalid language code, returns [008/35-37, nil]
  def lang008
    return nil unless self.m008s
    code = self.m008s.first[35..37]
    language = $marc_language_codes[code.to_sym]
    return [code, language]
  end

  def oclcnum
    # This method allows us to get oclcnum without doing
    #   any kind of explicit find_oclcnum first
    # We could also set the oclcnum manually and have that
    #   given value returned
    @oclcnum ||= self.marc.oclcnum
  end  

  def fake_leader
    return '=LDR  00378nam  2200061   45e0'
  end

  # returns 907 with sierra-style (pipe) sf delimiter
  # marcedit takes dollar sign delimiters
  def proper_907
    return "=907  \\\\|a.#{@bnum}"
  end

  def stub_load_note
    return "=944  \\\\$aBatch load history: 999 Something records loaded 20180000, xxx."
  end

  def stub
    return @stub if @stub
    @stub = MARC::Record.new
    @stub << MARC::DataField.new('907', ' ', ' ', ['a', ".#{@bnum}"])
    load_note = 'Batch load history: 999 Something records loaded 20180000, xxx.'
    @stub << MARC::DataField.new('944', ' ', ' ', ['a', "#{load_note}"])
    return @stub
  end

  def get_varfields_as_marc(tags)
    # returns array of MARC DataField objects
    # Any fields < '010' Sierra has in sierra_view.varfield
    #  get returned as a MARC ControlField object
    varfields = self.get_varfields(tags)
    varfields.map! do |v|
      if v['marc_tag'] =~ /00[0-9]/
        f = MARC::ControlField.new(v['marc_tag'], v['field_content'])
      else
        subfields = self.subfield_arry(v['field_content'])        
        f = MARC::DataField.new(v['marc_tag'], v['marc_ind1'], v['marc_ind2'])
        subfields.each { |code, value| f.append(MARC::Subfield.new(code, value)) }
        f
      end
    end
  end

  # sets and returns @items as array of attached irecs as SierraItem objects
  def items
    @items ||= self.get_attached(rtype: 'i')
  end

  # sets and returns @orders as array of attached irecs as SierraOrder objects
  def orders
    @orders ||= self.get_attached(rtype: 'o')
  end

  # sets and returns @holdings as array of attached irecs as SierraHoldings objects
  def holdings
    @holdings ||= self.get_attached(rtype: 'c')
  end

  # returns array of attached [rtype] records as Sierra[Type] objects
  def get_attached(rtype:)
    case rtype
    when 'i'
      sql_name = 'item'
      klass = SierraItem
    when 'c'
      sql_name = 'holding'
      klass = SierraHoldings
    when 'o'
      sql_name = 'order'
      klass = SierraOrder
    end
    attached_query = <<-SQL
      select \'#{rtype}\' || rm.record_num || 'a' as rnum
      from sierra_view.bib_record b
      inner join sierra_view.bib_record_#{sql_name}_record_link link on link.bib_record_id = b.id
      inner join sierra_view.record_metadata rm on rm.id = link.#{sql_name}_record_id
      where b.id = #{@record_id}
      order by link.#{sql_name}s_display_order ASC
    SQL
    $c.make_query(attached_query)
    attached = $c.results.values.flatten.map { |rnum| klass.new(rnum) }
    attached = nil if attached.empty?
    attached
  end

  def proper_506s(strict: true, yield_errors: false)
    need_x = self.collections.length > 1
    p506s = self.collections.map { |c| c.m506(include_x: need_x) }.uniq
    errors = self.collections.map { |c| c.m506_error }.uniq.compact
    if strict && !errors.empty?
      if yield_errors
        return errors
      else
        nil
      end
    else
      p506s
    end
  end

  def extra_506s(whitelisted: [])
    extra = self.proper_506s.sort - self.marc.fields('506')
    extra - whitelisted
  end

  def lacking_506s
    self.marc.fields('506') - self.proper_506s.sort
  end

  def collections
    @collections ||= self.get_collections
  end

  def get_collections
    require_relative 'ebook_collections'
    my_colls = self.marc.fields('773')
    my_colls.reject! {
      |f| f.value =~ /^OCLC WorldShare Collection Manager managed collection/
    }
    my_colls.map! { |m773| EbookCollections.colls[m773['t']] }
    my_colls.delete(nil)
    @collections = my_colls
  end

  # below: things used only in the sfc/do we own this scripts
  # we should not worry atm if we break things here


  # end: things used only in the sfc/do we own this scripts
end


$marc_language_codes = {
  aar: 'Afar',
  abk: 'Abkhaz',
  ace: 'Achinese',
  ach: 'Acoli',
  ada: 'Adangme',
  ady: 'Adygei',
  afa: 'Afroasiatic (Other)',
  afh: 'Afrihili (Artificial language)',
  afr: 'Afrikaans',
  ain: 'Ainu',
  ajm: 'Aljamía',  #discontinued
  aka: 'Akan',
  akk: 'Akkadian',
  alb: 'Albanian',
  ale: 'Aleut',
  alg: 'Algonquian (Other)',
  alt: 'Altai',
  amh: 'Amharic',
  ang: 'English, Old (ca. 450-1100)',
  anp: 'Angika',
  apa: 'Apache languages',
  ara: 'Arabic',
  arc: 'Aramaic',
  arg: 'Aragonese',
  arm: 'Armenian',
  arn: 'Mapuche',
  arp: 'Arapaho',
  art: 'Artificial (Other)',
  arw: 'Arawak',
  asm: 'Assamese',
  ast: 'Bable',
  ath: 'Athapascan (Other)',
  aus: 'Australian languages',
  ava: 'Avaric',
  ave: 'Avestan',
  awa: 'Awadhi',
  aym: 'Aymara',
  aze: 'Azerbaijani',
  bad: 'Banda languages',
  bai: 'Bamileke languages',
  bak: 'Bashkir',
  bal: 'Baluchi',
  bam: 'Bambara',
  ban: 'Balinese',
  baq: 'Basque',
  bas: 'Basa',
  bat: 'Baltic (Other)',
  bej: 'Beja',
  bel: 'Belarusian',
  bem: 'Bemba',
  ben: 'Bengali',
  ber: 'Berber (Other)',
  bho: 'Bhojpuri',
  bih: 'Bihari (Other)',
  bik: 'Bikol',
  bin: 'Edo',
  bis: 'Bislama',
  bla: 'Siksika',
  bnt: 'Bantu (Other)',
  bos: 'Bosnian',
  bra: 'Braj',
  bre: 'Breton',
  btk: 'Batak',
  bua: 'Buriat',
  bug: 'Bugis',
  bul: 'Bulgarian',
  bur: 'Burmese',
  byn: 'Bilin',
  cad: 'Caddo',
  cai: 'Central American Indian (Other)',
  cam: 'Khmer',  #discontinued
  car: 'Carib',
  cat: 'Catalan',
  cau: 'Caucasian (Other)',
  ceb: 'Cebuano',
  cel: 'Celtic (Other)',
  cha: 'Chamorro',
  chb: 'Chibcha',
  che: 'Chechen',
  chg: 'Chagatai',
  chi: 'Chinese',
  chk: 'Chuukese',
  chm: 'Mari',
  chn: 'Chinook jargon',
  cho: 'Choctaw',
  chp: 'Chipewyan',
  chr: 'Cherokee',
  chu: 'Church Slavic',
  chv: 'Chuvash',
  chy: 'Cheyenne',
  cmc: 'Chamic languages',
  cop: 'Coptic',
  cor: 'Cornish',
  cos: 'Corsican',
  cpe: 'Creoles and Pidgins, English-based (Other)',
  cpf: 'Creoles and Pidgins, French-based (Other)',
  cpp: 'Creoles and Pidgins, Portuguese-based (Other)',
  cre: 'Cree',
  crh: 'Crimean Tatar',
  crp: 'Creoles and Pidgins (Other)',
  csb: 'Kashubian',
  cus: 'Cushitic (Other)',
  cze: 'Czech',
  dak: 'Dakota',
  dan: 'Danish',
  dar: 'Dargwa',
  day: 'Dayak',
  del: 'Delaware',
  den: 'Slavey',
  dgr: 'Dogrib',
  din: 'Dinka',
  div: 'Divehi',
  doi: 'Dogri',
  dra: 'Dravidian (Other)',
  dsb: 'Lower Sorbian',
  dua: 'Duala',
  dum: 'Dutch, Middle (ca. 1050-1350)',
  dut: 'Dutch',
  dyu: 'Dyula',
  dzo: 'Dzongkha',
  efi: 'Efik',
  egy: 'Egyptian',
  eka: 'Ekajuk',
  elx: 'Elamite',
  eng: 'English',
  enm: 'English, Middle (1100-1500)',
  epo: 'Esperanto',
  esk: 'Eskimo languages',  #discontinued
  esp: 'Esperanto',  #discontinued
  est: 'Estonian',
  eth: 'Ethiopic',  #discontinued
  ewe: 'Ewe',
  ewo: 'Ewondo',
  fan: 'Fang',
  fao: 'Faroese',
  far: 'Faroese',  #discontinued
  fat: 'Fanti',
  fij: 'Fijian',
  fil: 'Filipino',
  fin: 'Finnish',
  fiu: 'Finno-Ugrian (Other)',
  fon: 'Fon',
  fre: 'French',
  fri: 'Frisian',  #discontinued
  frm: 'French, Middle (ca. 1300-1600)',
  fro: 'French, Old (ca. 842-1300)',
  frr: 'North Frisian',
  frs: 'East Frisian',
  fry: 'Frisian',
  ful: 'Fula',
  fur: 'Friulian',
  gaa: 'Gã',
  gae: 'Scottish Gaelix',  #discontinued
  gag: 'Galician',  #discontinued
  gal: 'Oromo',  #discontinued
  gay: 'Gayo',
  gba: 'Gbaya',
  gem: 'Germanic (Other)',
  geo: 'Georgian',
  ger: 'German',
  gez: 'Ethiopic',
  gil: 'Gilbertese',
  gla: 'Scottish Gaelic',
  gle: 'Irish',
  glg: 'Galician',
  glv: 'Manx',
  gmh: 'German, Middle High (ca. 1050-1500)',
  goh: 'German, Old High (ca. 750-1050)',
  gon: 'Gondi',
  gor: 'Gorontalo',
  got: 'Gothic',
  grb: 'Grebo',
  grc: 'Greek, Ancient (to 1453)',
  gre: 'Greek, Modern (1453-)',
  grn: 'Guarani',
  gsw: 'Swiss German',
  gua: 'Guarani',  #discontinued
  guj: 'Gujarati',
  gwi: 'Gwich\'in',
  hai: 'Haida',
  hat: 'Haitian French Creole',
  hau: 'Hausa',
  haw: 'Hawaiian',
  heb: 'Hebrew',
  her: 'Herero',
  hil: 'Hiligaynon',
  him: 'Western Pahari languages',
  hin: 'Hindi',
  hit: 'Hittite',
  hmn: 'Hmong',
  hmo: 'Hiri Motu',
  hrv: 'Croatian',
  hsb: 'Upper Sorbian',
  hun: 'Hungarian',
  hup: 'Hupa',
  iba: 'Iban',
  ibo: 'Igbo',
  ice: 'Icelandic',
  ido: 'Ido',
  iii: 'Sichuan Yi',
  ijo: 'Ijo',
  iku: 'Inuktitut',
  ile: 'Interlingue',
  ilo: 'Iloko',
  ina: 'Interlingua (International Auxiliary Language Association)',
  inc: 'Indic (Other)',
  ind: 'Indonesian',
  ine: 'Indo-European (Other)',
  inh: 'Ingush',
  int: 'Interlingua (International Auxiliary Language Association)',  #discontinued
  ipk: 'Inupiaq',
  ira: 'Iranian (Other)',
  iri: 'Irish',  #discontinued
  iro: 'Iroquoian (Other)',
  ita: 'Italian',
  jav: 'Javanese',
  jbo: 'Lojban (Artificial language)',
  jpn: 'Japanese',
  jpr: 'Judeo-Persian',
  jrb: 'Judeo-Arabic',
  kaa: 'Kara-Kalpak',
  kab: 'Kabyle',
  kac: 'Kachin',
  kal: 'Kalâtdlisut',
  kam: 'Kamba',
  kan: 'Kannada',
  kar: 'Karen languages',
  kas: 'Kashmiri',
  kau: 'Kanuri',
  kaw: 'Kawi',
  kaz: 'Kazakh',
  kbd: 'Kabardian',
  kha: 'Khasi',
  khi: 'Khoisan (Other)',
  khm: 'Khmer',
  kho: 'Khotanese',
  kik: 'Kikuyu',
  kin: 'Kinyarwanda',
  kir: 'Kyrgyz',
  kmb: 'Kimbundu',
  kok: 'Konkani',
  kom: 'Komi',
  kon: 'Kongo',
  kor: 'Korean',
  kos: 'Kosraean',
  kpe: 'Kpelle',
  krc: 'Karachay-Balkar',
  krl: 'Karelian',
  kro: 'Kru (Other)',
  kru: 'Kurukh',
  kua: 'Kuanyama',
  kum: 'Kumyk',
  kur: 'Kurdish',
  kus: 'Kusaie',  #discontinued
  kut: 'Kootenai',
  lad: 'Ladino',
  lah: 'Lahndā',
  lam: 'Lamba (Zambia and Congo)',
  lan: 'Occitan (post 1500)',  #discontinued
  lao: 'Lao',
  lap: 'Sami',  #discontinued
  lat: 'Latin',
  lav: 'Latvian',
  lez: 'Lezgian',
  lim: 'Limburgish',
  lin: 'Lingala',
  lit: 'Lithuanian',
  lol: 'Mongo-Nkundu',
  loz: 'Lozi',
  ltz: 'Luxembourgish',
  lua: 'Luba-Lulua',
  lub: 'Luba-Katanga',
  lug: 'Ganda',
  lui: 'Luiseño',
  lun: 'Lunda',
  luo: 'Luo (Kenya and Tanzania)',
  lus: 'Lushai',
  mac: 'Macedonian',
  mad: 'Madurese',
  mag: 'Magahi',
  mah: 'Marshallese',
  mai: 'Maithili',
  mak: 'Makasar',
  mal: 'Malayalam',
  man: 'Mandingo',
  mao: 'Maori',
  map: 'Austronesian (Other)',
  mar: 'Marathi',
  mas: 'Maasai',
  max: 'Manx',  #discontinued
  may: 'Malay',
  mdf: 'Moksha',
  mdr: 'Mandar',
  men: 'Mende',
  mga: 'Irish, Middle (ca. 1100-1550)',
  mic: 'Micmac',
  min: 'Minangkabau',
  mis: 'Miscellaneous languages',
  mkh: 'Mon-Khmer (Other)',
  mla: 'Malagasy',  #discontinued
  mlg: 'Malagasy',
  mlt: 'Maltese',
  mnc: 'Manchu',
  mni: 'Manipuri',
  mno: 'Manobo languages',
  moh: 'Mohawk',
  mol: 'Moldavian',  #discontinued
  mon: 'Mongolian',
  mos: 'Mooré',
  mul: 'Multiple languages',
  mun: 'Munda (Other)',
  mus: 'Creek',
  mwl: 'Mirandese',
  mwr: 'Marwari',
  myn: 'Mayan languages',
  myv: 'Erzya',
  nah: 'Nahuatl',
  nai: 'North American Indian (Other)',
  nap: 'Neapolitan Italian',
  nau: 'Nauru',
  nav: 'Navajo',
  nbl: 'Ndebele (South Africa)',
  nde: 'Ndebele (Zimbabwe)',
  ndo: 'Ndonga',
  nds: 'Low German',
  nep: 'Nepali',
  new: 'Newari',
  nia: 'Nias',
  nic: 'Niger-Kordofanian (Other)',
  niu: 'Niuean',
  nno: 'Norwegian (Nynorsk)',
  nob: 'Norwegian (Bokmål)',
  nog: 'Nogai',
  non: 'Old Norse',
  nor: 'Norwegian',
  nqo: 'N\'Ko',
  nso: 'Northern Sotho',
  nub: 'Nubian languages',
  nwc: 'Newari, Old',
  nya: 'Nyanja',
  nym: 'Nyamwezi',
  nyn: 'Nyankole',
  nyo: 'Nyoro',
  nzi: 'Nzima',
  oci: 'Occitan (post-1500)',
  oji: 'Ojibwa',
  ori: 'Oriya',
  orm: 'Oromo',
  osa: 'Osage',
  oss: 'Ossetic',
  ota: 'Turkish, Ottoman',
  oto: 'Otomian languages',
  paa: 'Papuan (Other)',
  pag: 'Pangasinan',
  pal: 'Pahlavi',
  pam: 'Pampanga',
  pan: 'Panjabi',
  pap: 'Papiamento',
  pau: 'Palauan',
  peo: 'Old Persian (ca. 600-400 B.C.)',
  per: 'Persian',
  phi: 'Philippine (Other)',
  phn: 'Phoenician',
  pli: 'Pali',
  pol: 'Polish',
  pon: 'Pohnpeian',
  por: 'Portuguese',
  pra: 'Prakrit languages',
  pro: 'Provençal (to 1500)',
  pus: 'Pushto',
  que: 'Quechua',
  raj: 'Rajasthani',
  rap: 'Rapanui',
  rar: 'Rarotongan',
  roa: 'Romance (Other)',
  roh: 'Raeto-Romance',
  rom: 'Romani',
  rum: 'Romanian',
  run: 'Rundi',
  rup: 'Aromanian',
  rus: 'Russian',
  sad: 'Sandawe',
  sag: 'Sango (Ubangi Creole)',
  sah: 'Yakut',
  sai: 'South American Indian (Other)',
  sal: 'Salishan languages',
  sam: 'Samaritan Aramaic',
  san: 'Sanskrit',
  sao: 'Samoan',  #discontinued
  sas: 'Sasak',
  sat: 'Santali',
  scc: 'Serbian',  #discontinued
  scn: 'Sicilian Italian',
  sco: 'Scots',
  scr: 'Croatian',  #discontinued
  sel: 'Selkup',
  sem: 'Semitic (Other)',
  sga: 'Irish, Old (to 1100)',
  sgn: 'Sign languages',
  shn: 'Shan',
  sho: 'Shona',  #discontinued
  sid: 'Sidamo',
  sin: 'Sinhalese',
  sio: 'Siouan (Other)',
  sit: 'Sino-Tibetan (Other)',
  sla: 'Slavic (Other)',
  slo: 'Slovak',
  slv: 'Slovenian',
  sma: 'Southern Sami',
  sme: 'Northern Sami',
  smi: 'Sami',
  smj: 'Lule Sami',
  smn: 'Inari Sami',
  smo: 'Samoan',
  sms: 'Skolt Sami',
  sna: 'Shona',
  snd: 'Sindhi',
  snh: 'Sinhalese',  #discontinued
  snk: 'Soninke',
  sog: 'Sogdian',
  som: 'Somali',
  son: 'Songhai',
  sot: 'Sotho',
  spa: 'Spanish',
  srd: 'Sardinian',
  srn: 'Sranan',
  srp: 'Serbian',
  srr: 'Serer',
  ssa: 'Nilo-Saharan (Other)',
  sso: 'Sotho',  #discontinued
  ssw: 'Swazi',
  suk: 'Sukuma',
  sun: 'Sundanese',
  sus: 'Susu',
  sux: 'Sumerian',
  swa: 'Swahili',
  swe: 'Swedish',
  swz: 'Swazi',  #discontinued
  syc: 'Syriac',
  syr: 'Syriac, Modern',
  tag: 'Tagalog',  #discontinued
  tah: 'Tahitian',
  tai: 'Tai (Other)',
  taj: 'Tajik',  #discontinued
  tam: 'Tamil',
  tar: 'Tatar',  #discontinued
  tat: 'Tatar',
  tel: 'Telugu',
  tem: 'Temne',
  ter: 'Terena',
  tet: 'Tetum',
  tgk: 'Tajik',
  tgl: 'Tagalog',
  tha: 'Thai',
  tib: 'Tibetan',
  tig: 'Tigré',
  tir: 'Tigrinya',
  tiv: 'Tiv',
  tkl: 'Tokelauan',
  tlh: 'Klingon (Artificial language)',
  tli: 'Tlingit',
  tmh: 'Tamashek',
  tog: 'Tonga (Nyasa)',
  ton: 'Tongan',
  tpi: 'Tok Pisin',
  tru: 'Truk',  #discontinued
  tsi: 'Tsimshian',
  tsn: 'Tswana',
  tso: 'Tsonga',
  tsw: 'Tswana',  #discontinued
  tuk: 'Turkmen',
  tum: 'Tumbuka',
  tup: 'Tupi languages',
  tur: 'Turkish',
  tut: 'Altaic (Other)',
  tvl: 'Tuvaluan',
  twi: 'Twi',
  tyv: 'Tuvinian',
  udm: 'Udmurt',
  uga: 'Ugaritic',
  uig: 'Uighur',
  ukr: 'Ukrainian',
  umb: 'Umbundu',
  und: 'Undetermined',
  urd: 'Urdu',
  uzb: 'Uzbek',
  vai: 'Vai',
  ven: 'Venda',
  vie: 'Vietnamese',
  vol: 'Volapük',
  vot: 'Votic',
  wak: 'Wakashan languages',
  wal: 'Wolayta',
  war: 'Waray',
  was: 'Washoe',
  wel: 'Welsh',
  wen: 'Sorbian (Other)',
  wln: 'Walloon',
  wol: 'Wolof',
  xal: 'Oirat',
  xho: 'Xhosa',
  yao: 'Yao (Africa)',
  yap: 'Yapese',
  yid: 'Yiddish',
  yor: 'Yoruba',
  ypk: 'Yupik languages',
  zap: 'Zapotec',
  zbl: 'Blissymbolics',
  zen: 'Zenaga',
  zha: 'Zhuang',
  znd: 'Zande languages',
  zul: 'Zulu',
  zun: 'Zuni',
  zxx: 'No linguistic content',
  zza: 'Zaza',
}
