require './lib/diplomat/version'

Gem::Specification.new 'diplomatic_bag', Diplomat::VERSION do |spec|
  spec.authors       = ['Nicolas Benoit']
  spec.email         = ['n.benoit@criteo.com']
  spec.description   = spec.summary = 'Toolbox for Consul'
  spec.homepage      = 'https://github.com/WeAreFarmGeek/diplomat'
  spec.license       = 'BSD-3-Clause'

  spec.files         = `git ls-files bin lib README.md LICENSE features`.split("\n")

  spec.add_development_dependency 'diplomat', "=#{Diplomat::VERSION}"
end
