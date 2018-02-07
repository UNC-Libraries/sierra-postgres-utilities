# coding: utf-8
require_relative 'PostgresConnect'
require 'marc'
require_relative 'ext/marc/record'

class SierraBib
  attr_reader :record_id, :bnum, :varfields, :varfields_sql, :varfields_str, :m006, :m007s, :m008, :marc, :oclcnum, :oclcnum035s, :blvl, :warnings, :given_bnum, :deleted, :bib_record_view


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
    @given_bnum = bnum
    @warnings = []
    if bnum =~ /^b[0-9]+a?$/
      @bnum = bnum.dup
      @bnum += 'a' unless bnum[-1] == 'a'
    else
      @warnings << 'Cannot retrieve Sierra bib. Bnum must start with b'
      return
    end
    @record_id = get_record_id(@bnum)
    if @record_id == nil
      @warnings << 'No record was found in Sierra for this bnum'
    end
    @warnings << 'This Sierra bib was deleted'if @deleted
  end

  # @bnum           = b1094852a
  # bnum_trunc      = b1094852
  def bnum_trunc
    return nil unless @bnum
    return @bnum.chop
  end

  # @bnum           = b1094852a
  # bnum_with_check = b10948521
  def bnum_with_check
    return nil unless @bnum
    return @bnum.chop + check_digit(self.recnum)
  end

  # @bnum           = b1094852a
  # recnum          = 1094852
  def recnum
    return nil unless @bnum
    return @bnum[/\d+/]
  end

  def get_record_id(bnum)
    recnum = bnum[/\d+/]
    # this is a cheaper query than using the reckey2id function, I believe
    # unless the calculation of a record_id when one isn't found is helpful
    #  in a way I'm missing (seems like a liability), prefer to not use
    #  that function --kms
    $c.make_query(
      "select id, deletion_date_gmt
       from sierra_view.record_metadata
       where record_type_code = 'b' 
       and record_num = \'#{recnum}\'"
    )
    if $c.results.values.empty?
      return nil
    else
      deletion_date = $c.results.values[0][1]
      @deleted = deletion_date ? true : false
      return $c.results.values[0][0]
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

  def get_bib_record_view
=begin
Adds hash of values from SierraDNA bib_record_view to SierraBib.bib_record_view:
#<SierraBib:0x0000000002b9c9c0
 @bib_record_view=
  {"id"=>"420907889860",
   "record_id"=>"420907889860",
   "language_code"=>"eng",
   "bcode1"=>"m",
   "bcode2"=>"a",
   "bcode3"=>"-",
   "country_code"=>"enk",
   "index_change_count"=>"11",
   "is_on_course_reserve"=>"f",
   "is_right_result_exact"=>"f",
   "allocation_rule_code"=>"0",
   "skip_num"=>"4",
   "cataloging_date_gmt"=>"2004-10-01 00:00:00-04",
   "marc_type_code"=>" ",
   "is_suppressed"=>"f"},
 @bnum="b1094852a",
 @deleted=false,
 @given_bnum="b1094852",
 @record_id="420907889860",
 @warnings=[]>
=end
    $c.make_query(
      "select * from sierra_view.bib_record b
      where b.id = #{@record_id}")
    return nil if $c.results.values.empty?
    @bib_record_view = $c.results.entries[0]
  end

  def suppressed
    @suppressed ||= self.is_suppressed?
  end

  def is_suppressed?
    # not the same value as iii's is_suppressed SQL field which
    # does not consider 'c' a suppression bcode3
    self.get_bib_record_view unless @bib_record_view
    return nil unless @bib_record_view
    @suppressed = %w(d n c).include?(@bib_record_view['bcode3'])
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

  def m856s
    @m856s ||= self.get_varfields('856')
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
    field_content = field_content.insert(0, '|a') if field_content[0] != '|'
    arry = field_content.split('|')
    return arry[1..-1].map { |x| [x[0], x[1..-1]] }
  end

  def get_marc_varfields
    # get all varfields where marc tag is not null
    # returns Array of Hashed varfield representations
    # set @varfields_sql
    query = "select * from sierra_view.varfield where record_id = #{@record_id} and marc_tag is not null order by marc_tag, occ_num;"
    $c.make_query(query)
    @varfields_sql = $c.results.entries
    @varfields = {}
    @varfields_sql.each do |field|
      if @varfields.include?(field['marc_tag'])
        @varfields[field['marc_tag']] << {
          ind1: field['marc_ind1'].to_s,
          ind2: field['marc_ind2'].to_s,
          field_content: field['field_content'].to_s
        }
      else
        @varfields[field['marc_tag']] = [{
                                           ind1: field['marc_ind1'].to_s,
                                           ind2: field['marc_ind2'].to_s,
                                           field_content: field['field_content'].to_s
                                         }]
      end
    end
  end

  def varfields_str
    get_marc_varfields if !@varfields_sql
    strings = {}
    @varfields_sql.each do |x|
      indicators = "#{x['marc_ind1']}#{x['marc_ind2']}"
      indicators = '' if x['marc_tag'] =~ /^00/
      if strings.include?(x['marc_tag'])
        strings[x['marc_tag']] << "=#{x['marc_tag']}  #{indicators}#{x['field_content']}"
      else
        strings[x['marc_tag']] = ["=#{x['marc_tag']}  #{indicators}#{x['field_content']}"]
      end
    end
    return strings
  end

  def get_006s
    query = "select * from sierra_view.control_field where control_num = '6' and record_id = #{@record_id};"
    $c.make_query(query)
    #todo warn if more than 1 field
    return nil if $c.results.entries.empty?
    @m006s = $c.results.values.map { |f| f[4..21].map{ |x| x.to_s }.join }
  end

  def get_007s
    query = "select * from sierra_view.control_field where control_num = '7' and record_id = #{@record_id};"
    $c.make_query(query)
    return nil if $c.results.values.empty?
    @m007s = $c.results.values.map { |f| f[4..28].map{ |x| x.to_s }.join }
  end

  def get_008s
    query = "select * from sierra_view.control_field where control_num = '8' and record_id = #{@record_id};"
    $c.make_query(query)
    #todo warn if more than 1 field
    return nil if $c.results.values.empty?
    @m008s = $c.results.values.map { |f| f[4..43].map{ |x| x.to_s }.join }
  end

  def get_control_fields
    # just what iii has in sierra_view.control_field
    # i.e. 006, 007, 008; not 001, 003, 005
    query = "select * from sierra_view.control_field where control_num in ('6', '7', '8') and record_id = #{@record_id};"
    $c.make_query(query)
    @m006s = $c.results.values.select { |r| r[3] == '6'}.map { |f| f[4..21].map{ |x| x.to_s }.join }
    @m007s = $c.results.values.select { |r| r[3] == '7'}.map { |f| f[4..28].map{ |x| x.to_s }.join }
    @m008s = $c.results.values.select { |r| r[3] == '8'}.map { |f| f[4..43].map{ |x| x.to_s }.join }
  end

  def _006s
    @m006s ||= get_006s
  end

  def _007s
    @m007s ||= get_007s
  end

  def _008s
    @m008s ||= get_008s
  end

  def _ldr
    @ldr ||= get_ldr
  end

  def blvl
    self.get_ldr unless @blvl
    return @blvl
  end

  def get_ldr
    # ldr building logic from: https://github.com/trln/extract_marcxml_for_argot_unc/blob/master/marc_for_argot.pl
    query = "select * from sierra_view.leader_field ldr where ldr.record_id = #{@record_id}"
    $c.make_query(query)
    @multiple_LDRs_flag = true if $c.results.entries.length >= 2
    myldr = $c.results.entries.first
    @rec_status = myldr['record_status_code']
    @rec_type = myldr['record_type_code']
    @blvl = myldr['bib_level_code']
    @ctrl_type = myldr['control_type_code']
    @char_enc = myldr['char_encoding_scheme_code']
    @elvl = myldr['encoding_level_code']
    @desc_form = myldr['descriptive_cat_form_code']
    @multipart = myldr['multipart_level_code']
    @base_address = myldr['base_address'].rjust(5, '0')
    # for data below, we use default or fake values
    rec_length = '00000'
    indicator_ct = '2'
    subf_ct = '2'
    ldr_end = '4500'
    @ldr = rec_length + @rec_status + @rec_type + @blvl + @ctrl_type +
           @char_enc + indicator_ct + subf_ct + @base_address + @elvl +
           @desc_form + @multipart + ldr_end
  end

  def bcode1_blvl
    # this usually, but not always, is the same as LDR/07(set as @blvl)
    # and in cases where they do not agree, it has seemed that
    # MAYBE bcode1 is more accurate and iii failed to update the LDR/07
    self.get_bib_record_view if !@bib_record_view
    return nil unless @bib_record_view
    @bib_record_view['bcode1']
  end

  def mat_type
    self.get_bib_record_view if !@bib_record_view
    return nil unless @bib_record_view
    @bib_record_view['bcode2']
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
    ldr = @ldr ? @ldr : self.get_ldr
    mymrk = "=LDR  #{ldr}\n" if ldr
    var_control = self.varfields_str.select { |k, v| k =~ /^00/ }
    var_varfield = self.varfields_str.reject { |k, v| k =~ /^00/ }
    var_control.each do |k, v|
      v.each { |field| mymrk += field + "\n" }
    end
    self.get_control_fields
    self._006s.each do |_006_content|
      mymrk += "=006  #{_006_content}\n"
    end
    self._007s.each do |_007_content|
      mymrk += "=007  #{_007_content}\n"
    end
    self._008s.each do |_008_content|
      mymrk += "=008  #{_008_content}\n"
    end
    #control fields
    var_varfield.each do |k, v|
      v.each { |field| mymrk += field + "\n" }
    end
    return mymrk
  end

  def marchash
    mh = {}
    mh['leader'] = self._ldr
    mh['fields'] = []
    get_marc_varfields if !@varfields_sql
    var_control = self.varfields_sql.select { |x| x['marc_tag'] =~ /^00/ }
    var_varfield = self.varfields_sql.reject { |x| x['marc_tag'] =~ /^00/ }
    var_control.each { |f| mh['fields'] << [f['marc_tag'], f['field_content']] }
    self._006s.each { |field| mh['fields'] << ['006', field] } if self._006s
    self._007s.each { |field| mh['fields'] << ['007', field] } if self._007s
    self._008s.each { |field| mh['fields'] << ['008', field] } if self._008s
    var_varfield.each do |field|
      mh['fields'] << [field['marc_tag'], field['marc_ind1'],
                       field['marc_ind2'],
                       self.subfield_arry(field['field_content'].strip)
                      ]
    end
    return mh
  end

  def marcrecord
    @marc = MARC::Record.new_from_marchash(self.marchash)
  end

  def marc
    @marc ||= self.marcrecord
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
    return nil if !self._008s
    code = self._008s.first[35..37]
    language = $marc_language_codes[code.to_sym]
    return [code, language]
  end

  def oclcnum
    # This method allows us to get sb2.oclcnum without doing
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
    return "=944  \\$aBatch load history: 999 Something records to fix URLs loaded 20180000, xxx."
  end

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
