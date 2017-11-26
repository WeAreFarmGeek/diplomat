require 'bundler/setup'
Bundler.setup

require 'json'
require 'base64'
require 'diplomat'
require 'fakes-rspec'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end
