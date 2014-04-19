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
  spec.add_development_dependency "rake", "~> 10.3"
  spec.add_development_dependency "pry", "~> 0.9"
  spec.add_development_dependency "rspec", "~> 2.14"
  spec.add_development_dependency "fakes-rspec", "~> 1.0"
  spec.add_development_dependency "json", "~> 1.8"
  spec.add_development_dependency "codeclimate-test-reporter"
  spec.add_dependency "faraday", "~> 0.9"
end
