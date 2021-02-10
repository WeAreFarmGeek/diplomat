# frozen_string_literal: true

require './lib/diplomat/version'

Gem::Specification.new 'diplomat', Diplomat::VERSION do |spec|
  spec.authors       = ['John Hamelink', 'Trevor Wood', 'Pierre Souchay']
  spec.email         = ['john@johnhamelink.com', 'trevor.g.wood@gmail.com', 'p.souchay@criteo.com']
  spec.description   = spec.summary = 'Diplomat is a simple wrapper for Consul'
  spec.homepage      = 'https://github.com/WeAreFarmGeek/diplomat'
  spec.license       = 'BSD-3-Clause'

  spec.files         = `git ls-files lib/diplomat.rb lib/diplomat README.md LICENSE features`.split("\n")
  spec.required_ruby_version = '>= 2.5' # Matches simplecov 0.21

  spec.add_development_dependency 'bundler', '~> 2.2'
  spec.add_development_dependency 'cucumber', '~> 5.3'
  spec.add_development_dependency 'fakes-rspec', '~> 2.1'
  spec.add_development_dependency 'fivemat', '~> 1.3'
  spec.add_development_dependency 'gem-release', '~> 2.2'
  spec.add_development_dependency 'pry', '~> 0.14'
  spec.add_development_dependency 'rake', '~> 13.0.3'
  spec.add_development_dependency 'rspec', '~> 3.10'
  spec.add_development_dependency 'rubocop', '~> 0.93.1'
  spec.add_development_dependency 'simplecov', '~> 0.21.2'
  spec.add_development_dependency 'webmock'

  spec.add_runtime_dependency 'deep_merge', '~> 1.2'
  spec.add_runtime_dependency 'faraday', '>= 0.9'
end
