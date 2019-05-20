require 'marc'

module Sierra
  module Data
    class Varfield < Sequel::Model(DB.db[:varfield])
      set_primary_key :id
      prepare_retrieval_by :record_id, :select,
                           sorting: %i[marc_tag varfield_type_code occ_num id]

      one_to_many :subfields, key: :varfield_id
      many_to_one :record_metadata,
                  class: :'Sierra::Data::Metadata', primary_key: :id,
                  key: :record_id

      many_to_one :bib, primary_key: :id, key: :record_id
      many_to_one :item, primary_key: :id, key: :record_id
      many_to_one :authority, primary_key: :id, key: :record_id
      many_to_one :holdings,
                  class: :'Sierra::Data::Holdings', primary_key: :id,
                  key: :record_id
      many_to_one :order, primary_key: :id, key: :record_id
      many_to_one :patron, primary_key: :id, key: :record_id

      def record
        record_metadata.record
      end

      def marc_varfield?
        return true if marc_tag
        false
      end

      def nonmarc_varfield?
        !marc_varfield?
      end

      def control_field?
        return true if marc_tag =~ /^00/
        false
      end

      def to_marc
        return unless marc_varfield?
        if control_field?
          MARC::ControlField.new(marc_tag, field_content)
        else
          MARC::DataField.new(marc_tag, marc_ind1, marc_ind2,
                              *Varfield.subfield_arry(field_content))
        end
      end

      # Returns the first subfield with matching tag
      def subfield(tag)
        subfields.find { |sf| sf.tag == tag.to_s }
      end

      def self.subfield_arry(field_content, implicit_sfa: true)
        field_content = add_explicit_sf_a(field_content) if implicit_sfa
        arry = field_content.split('|')

        # delete anything prior to the first subfield delimiter (which often
        #   but not always means deleting an empty string), then delete
        #   any/other empty strings
        arry.shift
        arry.delete(''.freeze)
        arry.map { |x| [x[0], x[1..-1]] }
      end

      def self.add_explicit_sf_a(field_content)
        field_content = "|a#{field_content}" unless field_content.chr == '|'
        field_content
      end
    end
  end
end
