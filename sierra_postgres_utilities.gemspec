# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sierra_postgres_utilities/version'

Gem::Specification.new do |spec|
  spec.name          = 'sierra_postgres_utilities'
  spec.version       = Sierra::VERSION
  spec.authors       = ['ldss-jm', 'Kristina Spurgin']
  spec.email         = ['ldss-jm@users.noreply.github.com']

  spec.summary       = 'Connects to iii Sierra postgres DB and provides ' \
    'logic/utilities to interact with Sierra records in ruby.'
  spec.homepage      = 'https://github.com/UNC-Libraries/sierra-postgres-utilities'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.2', '>= 2.2.19'
  spec.add_development_dependency 'rake', '~> 12.3', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'factory_bot', '~> 5.0.0'

  spec.add_runtime_dependency 'mail', '~> 2.6'
  spec.add_runtime_dependency 'marc', '~> 1.0'
  spec.add_runtime_dependency 'pg', '~> 1.1'
  spec.add_runtime_dependency 'sequel', '~> 5.69.0'
  spec.add_runtime_dependency 'i18n', '~> 1.6.0'
end
