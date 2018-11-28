module SierraPostgresUtilities
  module Helpers
    module Varfields

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
        tag_phrase = tags.map { |x| "'#{x[0].to_s}'" }.join(', ')
        query = <<-SQL
        select * from sierra_view.varfield v
        where v.record_id = #{record_id}
        and v.marc_tag in (#{tag_phrase})
        order by marc_tag, occ_num
        SQL
        SierraDB.make_query(query)
        return nil if SierraDB.results.entries.empty?
        varfields = SierraDB.results.entries
        varfields.each do |varfield|
          varfield['extracted_content'] = []
          subfields = tags[varfield['marc_tag']]
          subfields.each do |subfield|
            varfield['extracted_content'] << extract_subfields(
              varfield['field_content'], subfield, trim_punct: true
            )
          end
        end
        varfields
      end

      def add_explicit_sf_a(field_content)
        unless field_content.chr == '|'
          field_content = field_content.clone.insert(0, '|a')
        end
        field_content
      end

      def subfield_from_field_content(field_content, subfield_tag, implicit_sfa: true)
        # returns first of a given subfield from varfield field_content string
        field_content = add_explicit_sf_a(field_content) if implicit_sfa
        subfields = field_content.split('|')
        sf_hash = {}
        subfields.each do |sf|
          sf_hash[sf[0]] = sf[1..-1] unless sf_hash.include?(sf[0])
        end
        sf_hash[subfield_tag]
      end

      def extract_subfields(field_content, desired_subfields, trim_punct: false,
                            remove_sf6880: true, implicit_sfa: true)
        field_content = add_explicit_sf_a(field_content) if implicit_sfa
        field = field_content.dup
        desired_subfields ||= ''
        desired_subfields = desired_subfields.join if desired_subfields.is_a?(Array)
        # Remove any content preceding a pipe/subfield-delimiter
        field.gsub!(/^[^|]*/, '')
        field.gsub!(/\|6880[^|]*/, '') if remove_sf6880
        field.gsub!(/\|[^#{desired_subfields}][^|]*/, '') unless desired_subfields.empty?
        extraction = field.gsub(/\|./, ' ').lstrip
        extraction.sub!(/[.,;: \/]*$/, '') if trim_punct
        extraction
      end

      # field_content: "|aIDEBK|beng|erda|cIDEBK|dCOO"
      # returns:
      #   [["a", "IDEBK"], ["b", "eng"], ["e", "rda"], ["c", "IDEBK"], ["d", "COO"]]
      def subfield_arry(field_content, implicit_sfa: true)
        field_content = add_explicit_sf_a(field_content) if implicit_sfa
        arry = field_content.split('|')

        # delete anything prior to the first subfield delimiter (which often
        #   but not always means deleting an empty string), then delete
        #   any/other empty strings
        arry.shift
        arry.delete(''.freeze)
        arry.map { |x| [x[0], x[1..-1]] }
      end
    end
  end
end
