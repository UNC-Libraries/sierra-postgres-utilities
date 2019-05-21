require 'English'
require 'i18n'
I18n.available_locales = [:en]

# diacritics sometimes have multiple mapping entries. category 24,
# "standrule.unicode," may be the default, but not sure what rule really wins
# out. Here we sort the query so that category 24 mappings come last and
# overwrite any previously seen mappings when we make the hash.
sierra_mappings =
  Sierra::DB.query(
    "select diacritic, mapped_string from diacritic_mapping " \
    "order by diacritic_category_id = '24'"
  ).to_a.
  map(&:values).
  to_h
I18n.backend.store_translations(
  :en,
  i18n: {transliterate: {rule: sierra_mappings}}
)

module Sierra
  module Data
    module Helpers
      # Methods that replicate Sierra's phrase_entry normalization functions
      # for various index types.
      # Actual Sierra documentation isn't specific enough to reconstruct
      # Sierra's normalization. So this reconstruction is based on what
      # Sierra seems to be doing and largely what it's doing to UNC's actual
      # set of field. Because of this, there are surely edge cases
      # where this normalization will not match Sierra's. For example,
      # there are punctuation characters that we

      # Also, not much has been done beyond trying to get the normalizations
      # to be correct. So, within normalization methods, expect that a more
      # logical ordering of transformations than what we have is possible.
      # Across normalization methods, assume that we may have separate
      # methods for different indexes when Sierra may be using the same method
      # (e.g. we have separate methods for bib utility numbers and "standard"
      # normalization for titles/authors/etc. I'm unsure whether Sierra handles
      # them differently. Our standard normalization is the fallback method
      # for lc normalization when the call no does not conform to lc format.
      # I'm unsure whether Sierra uses that as the fallback or if it falls back
      # to char by char normalization.)

      module PhraseNormalization
        # view index codes/names
        #   select * from sierra_view.phrase_type t
        #   inner join sierra_view.phrase_type_name n on n.phrase_type_id = t.id
        #   where n.iii_language_id = '1'
        #   order by varfield_type_code
        #
        # things where search is somewhat in place
        # o OCLC#   - works for oclc# in sierra
        # i isbn/issn
        # b barcode  - works for barcodes in Sierra
        # c lc call - works for lc call numbers. "not really lc call numbers"
        #             that are in an lc call number field generally work;
        #             there are ~1000 at UNC that we don't normalize correctly
        # e local/dewey call - there are ~3 we don't normalize correctly
        # g sudoc call - works for sudocs in Sierra

        # things we may want to search
        # a t s d j (wxy)?

        # things where search is not in place
        # k, q, a, t, h, s, d, r, f, j, p, l, n, z, 'v', 'u', 'y'

        def normalize(phrase, index = nil)
          PhraseNormalization.normalize(phrase, index&.to_sym)
        end

        def self.normalize(phrase, index = nil)
          normalize_by_index_type(index, phrase)
        end

        def self.normalize_by_index_type(index, phrase)
          case index.to_sym
          when :i, :b
            number_normalize(phrase)
          when :o
            bib_utility_normalize(phrase)
          when :a, :t, :s, :d, :j, nil
            standard_normalize(phrase)
          when :n
            name_normalize(phrase)
          when :c
            lc_normalize(phrase)
          when :e
            dewey_normalize(phrase)
          when :g
            sudoc_normalize(phrase)
          end
        end

        def self.remove_punct(str)
          # we need the spaces around and; dupe spaces will be removed
          str = str.gsub('&', ' and ')

          # selectively remove punctuation:
          # keep:
          #   +%$#@
          # remove:
          str.gsub!(/["']/, '')
          # replace with spaces:
          str.gsub!(/[!\&'()*,\-.\/:;<=>?\[\\\]^_`{|}~]/, ' ')
          str.squeeze!(' ')
          str.strip!
          str
        end

        def self.test_pad_numbers(str, char: ' ')
          str.gsub!(/(?<![#])(?<head>\b)(?<orig>[0-9,-]+)(?<tail> *)/) do
            head = $LAST_MATCH_INFO[:head]
            orig = $LAST_MATCH_INFO[:orig]
            tail = $LAST_MATCH_INFO[:tail]
            sum = ''
            orig.split('-').each_with_index do |hfrag, index|
              sum << ' ' if index.positive?
              next if hfrag.empty?
              sum +=
                if orig.split('-')[index - 1]&.scan(/^[0-9]*/)&.first&.length == 4
                  if hfrag[/^[0-9]{2}([^0-9]|$)/]
                    (hfrag.delete(',')&.rjust(0, char)).to_s
                  else
                    (hfrag.delete(',')&.rjust(8, char)).to_s
                  end
                else
                  (hfrag.delete(',')&.rjust(8, char)).to_s
                end
              sum << ' ' if orig.end_with?('-')
            end
            sum << ' ' if orig == '-'

            head + sum + tail
          end
          str
        end

        def self.bib_utility_normalize(str)
          # Takes the first 150 characters of the string to be indexed
          str = str[0..149]

          ## downcase str
          str = str.downcase

          # Strips non-filing characters from titles as designated by MARC tag indicators
          #   ignore here

          # TODO: Remove select punctuation?
          # We previously used this
          #   str.gsub!(/\u02B9|\u02BB|\uFE20|\uFE21/, '') # remove select punct
          # before transliteration to remove special punct or diacritics

          # Strips apostrophes and diacritics
          str.delete!('"\'')
          str.gsub!(/[{}]/, ' ')
          str = I18n.transliterate(str, replacement: '')
          # Downcase anything transliterated into uppercase
          str.downcase!

          # "Converts ampersands to the word for "and" in the primary language
          #   of your system"
          # (we need the spaces around and; dupe spaces will be removed)
          str.gsub!('&', ' and ')

          # Replace tildes with spaces. We'll replace other punct later, but
          # this allows us to pad numbers with tildes and swap those tildes for
          # spaces later
          str.tr!('~', ' ')

          # number padding is affected by commas and hyphens; those chars still
          # need to be present when we pad numbers.
          punct_remove ||= /[.!\&'()*\/:;<=>?\[\\\]^_`]/
          str.gsub!(punct_remove, ' ')
          str = test_pad_numbers(str, char: '~')

          str.gsub!(/\|./, ' ')
          str.gsub!(/[\-,]/, ' ')

          # Collapses multiple spaces to a single space
          str.squeeze!(' ')

          ###  replace number padding with spaces
          str.strip!
          str.tr!('~', ' ')

          return nil if str == ''
          str[0..124].rstrip
        end

        def self.pad_numbers(str, char: ' ', pad_decimals: true, pad_length: 8)
          # remove commas from comma-separated number groups
          str = str.gsub(/(?<=[0-9]),(?=[0-9]{3})/, '')

          except_preceded_by = '\+#${'
          except_preceded_by += '\.' unless pad_decimals
          regexp = /
            (?<![#{except_preceded_by}]) # not when preceded by these chars
            \b
            ([0-9]+)                # main number block, which gets justified
            (-[[:digit:]]{2}(?![0-9])(.*?)?(?=\b))?   # main number block ends
          /x
          str.gsub(regexp) do
            $2 ? $1.rjust(8, char) + $2 : $1.rjust(pad_length, char)
          end
        end

        def self.standard_normalize(str, pad_length: 8, punct_remove: nil)
          # Takes the first 150 characters of the string to be indexed
          str = str[0..149]

          ## downcase str
          str = str.downcase

          # Strips non-filing characters from titles as designated by MARC tag indicators
          #   sierra does this but irrelevant here

          # TODO: Remove select punctuation?
          # We previously used this
          #   str.gsub!(/\u02B9|\u02BB|\uFE20|\uFE21/, '') # remove select punct
          # before transliteration to remove special punct or diacritics

          # Strips apostrophes and diacritics
          str.delete!('"\'')
          str.gsub!(/[{}]/, ' ')
          str = I18n.transliterate(str, replacement: '')
          # Downcase anything transliterated into uppercase
          str.downcase!

          # Converts ampersands to the word for "and" in the primary language of your system
          #   (we need the spaces around and; dupe spaces will be removed)
          str.gsub!('&', ' and ')

          # Replace tildes with spaces. We'll replace other punct later, but
          # this allows us to pad numbers with tildes and swap those tildes
          # for spaces later
          str.tr!('~', ' ')

          # number padding is affected by commas and hyphens; those chars still
          # need to be present when we pad numbers.
          str = pad_numbers(str, char: '~', pad_length: pad_length)

          # Retains the punctuation symbols + # $ % @ within the index
          # Replaces subfield delimiters and many other punctuation marks with a space
          str.gsub!(/\|./, ' ')
          punct_remove ||= /[!\&'()*,#.\/:;<=>?\-\[\\\]^_`|]/
          str.gsub!(punct_remove, ' ')

          # Collapses multiple spaces to a single space
          str.squeeze!(' ')

          ###  replace number padding with spaces
          str.strip!
          str.tr!('~', ' ')

          return nil if str == ''

          # This truncation does not work for some strings, seemingly with many
          # multi-byte characters, e.g. long Russian titles. Those strings end up
          # stored in Sierra's phrase_entry more heavily truncated than we truncate.
          # e.g. b4954879a has a 490:
          #   "Anadolu'da Türk vatanı (1071, Malazgirt) ve Türk devleti (1075, İznik)nin kuruluşu 900. yıl dönümü hatırasına armaǧan ;"
          # We normalize that to 123 chars (it's short enough we don't truncate):
          #   "anadoluda turk vatani     1071 malazgirt ve turk devleti     1075 iznik nin kurulusu      900 yil donumu hatirasina armagan"
          # Sierra phrase_entry has (103 chars):
          #   "anadoluda turk vatani     1071 malazgirt ve turk devleti     1075 iznik nin kurulusu      900 yil donum"
          # e.g. b28704939a has a 245:
          #   Zhurnal iskhod︠i︡ashchim bumagam kan︠t︡sel︠i︡arīi Moskovskago general-gubernatora grafa Rostopchina s ī︠i︡un︠i︡a po dekabrʹ 1812 goda"
          # We normalize and truncate it to max 125 chars:
          #   "zhurnal iskhodiashchim bumagam kantseliarii moskovskago general gubernatora grafa rostopchina s iiunia po dekabr     1812 god"
          # Sierra phrase_entry has (95 chars):
          #   "zhurnal iskhodiashchim bumagam kantseliarii moskovskago general gubernatora grafa rostopchina s"
          #
          # So, this could possibly be better. However, searching in the Sierra
          # client for a longer title than is indexed also ends up returning no
          # exact match results, so the problem is at least not unique to us.
          str[0..124].rstrip
        end

        def self.number_normalize(str)
          str = str.downcase
          str.gsub!(/["']/, '')
          str.gsub!(/[$!\&'()*,.\/:;<=>\-?\[\\\]^_`{|}~]/, ' ')
          str.delete!(' ')
          str
        end

        def self.name_normalize(str)
          str = str.downcase
          str.delete!('"\'')
          str.gsub!(/[!\&'()*,.\/:;<=>\-?\[\\\]^_`{|}~]/, ' ')
          str
        end

        def self.lc_normalize(str)
          str = str.dup

          vol_designators = 'no|v|sv|zv|liv|rev'
          str.gsub!(/[{}]/, ' ')
          str = I18n.transliterate(str, replacement: '')
          # remove any "prestamp" before the call number starts
          #   'a PS10.A1' => 'PS10.A1'

          regexp = /                # 'blah  PS3545.5 A1 1960'
            ^(?<prestamp>.*?)       # 'blah  '
            (?<cls>(?<![A-z])[A-z]{1,3})      # 'PS'
            ([\/\s-])?                     # possible space or hyphen
            (?<num>[0-9]{1,4})      # '3545'
            (?<dec>\.[0-9]+)?        # '.5'
            (?<remainder>.*)?       # ' A1 1960'
          /x

          m = str.match(regexp)
          return standard_normalize(str, pad_length: 0, punct_remove: /[!\&'()*,#\/:;<=>?\-\[\\\]^_`{|}]/) unless m
          cls = m[:cls].downcase.ljust(3, ' ')
          num = m[:num].rjust(4, ' ')
          dec = m[:dec]
          remainder = m[:remainder].downcase
          return standard_normalize(str, pad_length: 0) if remainder =~ /^[0-9]/
          remainder.tr!('~', ' ')
          remainder.gsub!(/(?<=[0-9])\.(?=[0-9])/, ' ')
          remainder.gsub!(/(?<![A-z])\.(?![0-9])/, ' ')
          remainder.gsub!(/[']/, '')
          remainder.gsub!(/[$+#"!\&'()*,\/:;<=>\-?\[\\\]^_`|]/, ' ')
          remainder.gsub!(/(?<=#{vol_designators})\.(?=[ 0-9])/, '~')
          remainder.gsub!(/\./, '')
          remainder = " #{remainder}"

          remainder.squeeze!(' ')
          remainder.gsub!(/(?<cap>\b(#{vol_designators}))~ ?(?<numer>[0-9]+)/) do
            caption = $LAST_MATCH_INFO[:cap]
            numer = $LAST_MATCH_INFO[:numer]
            caption + ' ' + numer.rjust(4, '~')
          end

          remainder.gsub!(/([0-9])([a-z])/, '\1 \2')
          remainder.squeeze!(' ')
          remainder.gsub!(/~ /, ' ')
          remainder.tr!('~', ' ')

          "#{cls}#{num}#{dec}#{remainder}".strip
        end

        def self.dewey_normalize(str)
          str.gsub!(/[{}]/, ' ')
          str = I18n.transliterate(str, replacement: '')
          str = str.downcase
          str.gsub!(/(?<![0-9]),/, ' ')
          str.gsub!(/ #/, ' ')
          str.gsub!(/[']/, '')
          str.gsub!(/[$+"!()#*\/:;<=>\-?\[\\\]^_`|~]/, ' ')
          str.gsub!('&', ' and ')
          str.squeeze!(' ')
          str.strip!
          str = dewey_pad_numbers(str)
          str.delete!(',')
          str.rstrip
        end

        def self.dewey_pad_numbers(str, char: ' ')
          str = str.dup
          str.gsub!(/(?<![{])(?<head>\b|\.)(?<orig>[0-9,-.]+)(?<tail> *)/) do
            head = $LAST_MATCH_INFO[:head]
            orig = $LAST_MATCH_INFO[:orig]
            tail = $LAST_MATCH_INFO[:tail]
            pad =
              orig.split('-').map { |hfrag|
                csplit = hfrag.split(',')
                sum = ''
                csplit.each_with_index do |cfrag, index|
                  sum << ' ' if index.positive?
                  padding =
                    case csplit[index + 1]&.scan(/^[0-9]*/)&.first&.length
                    when 3
                      5
                    when 4
                      4
                    else
                      8
                    end
                  sum += (cfrag[/^[^.]+/]&.rjust(padding, char)).to_s
                  sum += cfrag[/\..*/].to_s
                end
                sum << ' ' if hfrag.end_with?(',')
                sum
              }.flatten.join(' ')
            if !orig.match(/[0-9]/) || head == '.'
              head + orig + tail
            elsif pad.end_with?(' ')
              pad
            else
              pad + tail
            end
          end
          str
        end

        def self.sudoc_normalize(str)
          str.lstrip!
          str.gsub!(/[{}]/, ' ')
          str = I18n.transliterate(str, replacement: '')
          str = str.downcase
          str.squeeze!(' ')
          str.gsub!(/ ?([a-z]) ?/, '\1')

          # remove spaces before/after select punctuation
          # this is probably not a complete list of punctuation
          # but it is likely a list of all puncuation in UNC's Sierra sudocs
          str.gsub!(/ ?([#?\[\]&.()<>\/,;-]) ?/, '\1')

          str.gsub!(/ ?: ?/, ' :')
          str.gsub!(/([0-9]+)/) { $1.rjust(5, ' ') }
          str.rstrip!
          str
        end
      end
    end
  end
end
