# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'diplomat/version'

Gem::Specification.new do |spec|
  spec.name          = "diplomat"
  spec.version       = Diplomat::VERSION
  spec.authors       = ["John Hamelink"]
  spec.email         = ["john@johnhamelink.com"]
  spec.description   = %q{Diplomat is a simple wrapper for Consul}
  spec.summary       = %q{Diplomat is a simple wrapper for Consul}
  spec.homepage      = "https://github.com/johnhamelink/diplomat"
  spec.license       = "BSD"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "fakes-rspec"
  spec.add_development_dependency "json"
  spec.add_dependency 'faraday', '~> 0.9.0'
end
