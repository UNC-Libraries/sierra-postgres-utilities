require 'csv'
require 'yaml'
require 'mail'
require 'pg'

require 'marc'
require_relative '../ext/marc/record'
require_relative '../ext/marc/datafield'
require_relative '../ext/marc/controlfield'



require_relative 'sierra_postgres_utilities/sierradb'
# As it loads, sierra-postgres-utilities connects to the DB to prepare some
# queries, etc. Defining SIERRA_INIT_CREDS before loading sierra-postgres-utilities
# allows that initial connection to use the specified credentials
creds =
  if defined? SIERRA_INIT_CREDS
    SIERRA_INIT_CREDS
  else
    'prod'
  end
SierraDB.initial_creds(creds)

require_relative 'sierra_postgres_utilities/views'
require_relative 'sierra_postgres_utilities/helpers'
require_relative 'sierra_postgres_utilities/records'

require_relative 'sierra_postgres_utilities/hold'
require_relative 'sierra_postgres_utilities/user'
require_relative 'sierra_postgres_utilities/derivative_record'
