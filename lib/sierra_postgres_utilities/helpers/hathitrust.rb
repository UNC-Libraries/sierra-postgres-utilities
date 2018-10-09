require 'net/http'

module SierraPostgresUtilities
  module Helpers
    module HathiTrust
      class APIQuery
        attr_accessor :response

        def initialize(oclcnums: nil, isbns: nil, level: :full)
          @response = nil
          return unless oclcnums || isbns
          @oclcnums = oclcnums&.compact
          @isbns = isbns&.compact
          return if @oclcnums.empty? && isbns.empty?
          @url = api_query_url(oclcnums: @oclcnums, isbns: @isbns, level: level)
          @response = APIResponse.new(make_query(@url))
        end

        def marc #fulltext
          @response&.fulltext_records&.map { |r| r.marc }
        end

        def urls #fulltext
          @response&.fulltext_records&.map { |r| r.url }
        end

        def make_query(url)
          return unless url
          JSON.parse(Net::HTTP.get(URI.parse(URI.encode(url))))
        end

        def api_query_url(oclcnums: nil, isbns: nil, level: :brief)
          base = "https://catalog.hathitrust.org/api/volumes/#{level}/json/"
          terms = []
          oclcnums&.each do |num|
            terms << "oclc:#{num}"
          end
          isbns&.each do |num|
            terms << "isbn:#{num}"
          end
          base + terms.join("|")
        end

      end

      class APIResponse
        attr_accessor :json

        # The endpoint we use to search oclc/isbn identifiers
        #   e.g. https://catalog.hathitrust.org/api/volumes/full/json/oclc:85182211|isbn:1234567890
        # returns a response where response[identifier] == "Results hash"
        # Like:
        #   { "oclc:85182211" => {records: [...], items: [...]},
        #     "isbn:1234567890" => ...    }

        # Some other endpoints return these "results hashes" directly.
        #   e.g. https://catalog.hathitrust.org/api/volumes/full/oclc/124815.json
        # Results hash looks like:
        # {
        #   records: [
        #     {recnum: rec_details}
        #   ],
        #   items: [
        #     {0: item_details},
        #     {1: item_details},
        #   ]
        # }
        #
        # The records array may often contain only one record, but that is
        # presumably not always the case. Items are linked to records via
        # item_details[:fromRecord]

        # APIResponse is meant to be able to parse out the records and their
        # attached items from either response type.

        def initialize(json)
          @json = json
        end

        def records
          @records ||= get_records
        end

        def get_records
          records = {}
          if @json["records"]
            json = {key: @json}
          else
            json = @json
          end
          json.each do |k,v|
            recs = v["records"]&.map { |r| [r[0], HathiBib.new(r[1])] }.to_h
            items(v).each do |item|
              next unless item.fulltext?
              recs[item.recnum].items << item
            end
            records.merge!(recs)
          end
          records
        end

        def fulltext_records
          records.reject { |k,v| v.items.empty? }.values
        end

        def items(identifier_json)
          identifier_json["items"]&.map { |r| HathiItem.new(r) }
        end
      end

      # A Hathi "Record"/bib record
      class HathiBib
        attr_accessor :fulltext_items, :json
        def initialize(json)
          @json = json
          @fulltext_items = []
        end

        def marc
          io = StringIO.new(@json["marc-xml"])
          rec = MARC::XMLReader.new(io).to_a.first
          add_856s(rec, @fulltext_items)
        end

        def add_856s(rec, items)
          return rec if items.empty?
          if items.length > 1
            rec.append(rec_856)
          else
            rec.append(items.first.item_856)
          end
          rec
        end

        def url
          return nil if @fulltext_items.empty?
          if items.length > 1
            @json["recordURL"]
          else
            @fulltext_items.first.json["itemURL"]
          end
        end

        def rec_856
          MARC::DataField.new('856', '4', '0', ['u', @json["recordURL"]],
                              ['y', 'Full text available via HathiTrust'],
                              ['3', 'Multiple volumes'])
        end
      end

      # A Hathi item record
      class HathiItem
        attr_accessor :json

        def initialize(json)
          @json = json
        end

        def recnum
          @json["fromRecord"]
        end

        def fulltext?
          @json["usRightsString"] == "Full view"
        end

        def item_856
          MARC::DataField.new('856', '4', '0', ['u', @json["itemURL"]],
                              ['y', 'Full text available via HathiTrust'])
        end
      end
    end
  end
end
