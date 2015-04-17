require './lib/diplomat/version'

Gem::Specification.new "diplomat", Diplomat::VERSION do |spec|
  spec.authors       = ["John Hamelink"]
  spec.email         = ["john@johnhamelink.com"]
  spec.description   = spec.summary = "Diplomat is a simple wrapper for Consul"
  spec.homepage      = "https://github.com/johnhamelink/diplomat"
  spec.license       = "BSD"

  spec.files         = `git ls-files lib README.md LICENSE features`.split($/)

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10.3"
  spec.add_development_dependency "pry", "~> 0.9"
  spec.add_development_dependency "rspec", "~> 3.2"
  spec.add_development_dependency "fakes-rspec", "~> 2.1"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 0.4.0"
  spec.add_development_dependency "fivemat"
  spec.add_development_dependency "gem-release", "~> 0.7"
  spec.add_development_dependency "cucumber", "~> 2.0"

  spec.add_runtime_dependency "json", "~> 1.8"
  spec.add_runtime_dependency "faraday", "~> 0.9"
end
