require_relative 'views/method_constructor.rb'
require_relative 'views/authority.rb'
require_relative 'views/bib.rb'
require_relative 'views/general.rb'
require_relative 'views/hold.rb'
require_relative 'views/holdings.rb'
require_relative 'views/item.rb'
require_relative 'views/order.rb'
require_relative 'views/patron.rb'
require_relative 'views/record.rb'
require_relative 'views/user.rb'

module SierraDB
  extend SierraPostgresUtilities::Views::General
end
