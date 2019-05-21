# Utilities to access, model, manipulate iii Sierra data from the iii
# Sierra postgres database.
module Sierra
  require 'marc'

  require_relative 'sierra_postgres_utilities/logging'

  require 'sequel'
  require_relative 'ext_spu/sequel/model/model'

  require_relative 'sierra_postgres_utilities/db'

  # Skip loading things that require a DB connection unless there is a
  # working DB connection. If these are skipped, they will be loaded
  # if/when a DB connection is established.
  if Sierra::DB.connected?
    require_relative 'sierra_postgres_utilities/data'

    require_relative 'sierra_postgres_utilities/search'
    require_relative 'sierra_postgres_utilities/record'

    require_relative 'sierra_postgres_utilities/derivative_bib'
  end

  require_relative 'sierra_postgres_utilities/spec_support'

  # Some gems that also extend marc (e.g. marc-to-argot) only load paths
  # not already in $LOAD_PATH. We name the 'ext' dir as 'ext_spu' so that
  # 'ext/marc' will not already be in $LOAD_PATH, allowing both sets
  # of extensions to load.
  require_relative 'ext_spu/marc/xml_helper'
  require_relative 'ext_spu/marc/controlfield'
  require_relative 'ext_spu/marc/datafield'
  require_relative 'ext_spu/marc/record'
end
