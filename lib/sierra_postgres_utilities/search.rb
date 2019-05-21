require_relative 'data/helpers/phrase_normalization.rb'

module Sierra
  module Search
    module PhraseSearch
      NORMALIZATION = Sierra::Data::Helpers::PhraseNormalization

      # Searches phrase_entry and returns matching records.
      #
      # Note: Sierra indexes an x-digit isbn as both a 10- and 13-digit isbn,
      # so searching for either form of the isbn will work, even if only
      # one form is recorded in the record.
      #
      # @param [Symbol, String] index index to search, e.g. :t, :o, :b
      # @param [String] phrase search phrase
      # @param [String] rec_type optionally limit results to specified rec_type,
      #   (e.g. 'b', 'i')
      # @param [Symbol] match_type optionally specify matching strategy to use,
      #   :exact or :startswith
      # @return [Array] array of search results as records
      #   (e.g. Sierra::Data::Bib)
      def phrase_search(index, phrase, rec_type: nil, match_type: nil)
        Sierra::Search::PhraseSearch.phrase_search(
          index, phrase, rec_type: rec_type, match_type: match_type
        ).lazy.map(&:record)
      end

      # (see #phrase_search)
      def self.phrase_search(index, phrase,
                             rec_type: nil, match_type: nil)
        index = index&.to_sym
        norm_term = NORMALIZATION.normalize(phrase, index)
        return unless norm_term

        match_type ||= match_type(index)

        dataset = Sierra::Data::PhraseEntry.
                  where(Sequel.lit(
                          '(index_tag || index_entry)   ' \
                          "#{match_statement(match_type)}#{index}#{norm_term}'"
                        ))

        return dataset unless rec_type
        dataset.
          association_join(:record_metadata).
          where(record_type_code: rec_type)
      end

      # Get the default match strategy for an index.
      #
      # @param [Symbol] index the index
      # @return [Symbol] the default match strategy
      def self.match_type(index)
        case index
        when :n, :a, :t, :s
          :startswith
        else # :i, :b, :o, :c, :e, :g
          :exact
        end
      end
      private_class_method :match_type

      # @param [Symbol] match_type the match strategy to use, :exact or
      #   :startswith
      # @return [String] SQL fragment for given match strategy
      def self.match_statement(match_type)
        case match_type
        when :exact
          "   = '"
        when :startswith
          "   ~ '^"
        end
      end
      private_class_method :match_statement
    end

    extend PhraseSearch
  end
end
