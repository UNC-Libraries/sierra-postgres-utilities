module Sierra
  module SpecSupport
    # Location of sierra_postgres_utilities testing factories.
    #
    # @example Include those factories in another app
    #   FactoryBot.definition_file_paths << Sierra::SpecSupport::FACTORY_PATH
    FACTORY_PATH = File.expand_path('../../spec/factories', __dir__)
  end
end
