$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'rspec'
require 'sierra_postgres_utilities'
require 'factory_bot'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  FactoryBot.find_definitions
end

module Sierra
  module SpecUtils
    module Records
      def values=(hsh)
        @values = hsh
      end

      def set_data(field, data)
        define_singleton_method(field) { data }
        self
      end
    end
  end
end

def newrec(type, metadata = {}, data = {})
  rec = type.new
  rec.extend(Sierra::SpecUtils::Records)
  rec.values = metadata.to_hash.merge(data.to_hash)
  rec
end
