# frozen_string_literal: true

require './lib/diplomat/version'

Gem::Specification.new 'diplomat', Diplomat::VERSION do |spec|
  spec.authors       = ['John Hamelink', 'Trevor Wood', 'Pierre Souchay']
  spec.email         = ['john@johnhamelink.com', 'trevor.g.wood@gmail.com', 'p.souchay@criteo.com']
  spec.description   = spec.summary = 'Diplomat is a simple wrapper for Consul'
  spec.homepage      = 'https://github.com/WeAreFarmGeek/diplomat'
  spec.license       = 'BSD-3-Clause'

  spec.files         = `git ls-files lib/diplomat.rb lib/diplomat README.md LICENSE features`.split("\n")
  spec.required_ruby_version = '>= 2.0' # Does not work with 1.9 and below

  spec.add_development_dependency 'bundler', '~> 2.0', '>= 2.0.1'
  spec.add_development_dependency 'codeclimate-test-reporter', '~> 0.4.0'
  spec.add_development_dependency 'cucumber', '~> 2.0'
  spec.add_development_dependency 'fakes-rspec', '~> 2.1'
  spec.add_development_dependency 'fivemat', '~> 1.3'
  spec.add_development_dependency 'gem-release', '~> 0.7'
  spec.add_development_dependency 'pry', '~> 0.9'
  spec.add_development_dependency 'rake', '~> 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'rubocop', '~> 0.80.0'
  spec.add_development_dependency 'webmock'

  spec.add_runtime_dependency 'deep_merge', '~> 1.0', '>= 1.0.1'
  spec.add_runtime_dependency 'faraday', '~> 1.0.0'
  spec.add_runtime_dependency 'json_pure' if RUBY_VERSION < '1.9.3'
end
